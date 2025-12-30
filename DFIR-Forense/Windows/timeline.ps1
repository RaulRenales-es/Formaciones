<#
.SYNOPSIS
    timeline.ps1

.DESCRIPTION
    Script DFIR para construir una línea temporal forense en Windows,
    combinando Event Logs, filesystem, Prefetch y Registry (timestamps).
    SOLO LECTURA.

.NOTES
    Autor: Raul Renales
    Requiere PowerShell 5.1+
    Recomendado ejecutar como Administrador
#>

############################
# PARÁMETROS
############################
param(
    [int]$DaysBack = 7,
    [int]$MaxEventsPerSource = 3000,
    [string[]]$FsRoots = @("C:\Windows", "C:\Program Files", "C:\Program Files (x86)", "C:\Users")
)

############################
# CONFIGURACIÓN GENERAL
############################
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$HostName  = $env:COMPUTERNAME
$OutputDir = "timeline_${HostName}_$TimeStamp"

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Start-Transcript -Path "$OutputDir\resultados.txt" -Force

$StartTime = (Get-Date).AddDays(-1 * $DaysBack)

Write-Host "[+] Iniciando construcción de timeline"
Write-Host "[+] Equipo: $HostName"
Write-Host "[+] Ventana temporal (días): $DaysBack"
Write-Host "========================================"

############################
# FUNCIONES AUXILIARES
############################
function Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================"
    Write-Host "[*] $Title"
    Write-Host "========================================"
}

function SafeExport-Csv {
    param([Parameter(Mandatory=$true)]$Data,[Parameter(Mandatory=$true)][string]$Path)
    try {
        $Data | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $Path -Force
        Write-Host "[+] Exportado CSV: $Path"
    } catch {
        Write-Host "[!] Error exportando CSV $Path : $($_.Exception.Message)"
    }
}

function New-TimelineItem {
    param(
        [datetime]$Time,
        [string]$Source,
        [string]$Category,
        [string]$Description,
        [string]$Details
    )
    [PSCustomObject]@{
        Time        = $Time
        Source      = $Source
        Category    = $Category
        Description = $Description
        Details     = $Details
    }
}

function Get-Events {
    param(
        [string]$LogName,
        [int[]]$Ids,
        [int]$Max = 2000
    )
    try {
        Get-WinEvent -FilterHashtable @{
            LogName   = $LogName
            Id        = $Ids
            StartTime = $StartTime
        } -MaxEvents $Max -ErrorAction Stop
    } catch { @() }
}

############################
# CONTENEDOR TIMELINE
############################
$Timeline = New-Object System.Collections.Generic.List[object]

############################
# EVENT LOGS - SECURITY
############################
Section "EVENT LOGS: Security (Auth / Proc / Logs)"

# Autenticación
$secAuth = Get-Events -LogName "Security" -Ids @(4624,4625,4634,4647) -Max $MaxEventsPerSource
foreach ($e in $secAuth) {
    $Timeline.Add( (New-TimelineItem `
        -Time $e.TimeCreated `
        -Source "EventLog:Security" `
        -Category "Authentication" `
        -Description "EventID $($e.Id)" `
        -Details ($e.Message -replace "`r`n"," ") ) )
}

# Creación de procesos
$secProc = Get-Events -LogName "Security" -Ids @(4688) -Max $MaxEventsPerSource
foreach ($e in $secProc) {
    $Timeline.Add( (New-TimelineItem `
        -Time $e.TimeCreated `
        -Source "EventLog:Security" `
        -Category "ProcessCreate" `
        -Description "Process created (4688)" `
        -Details ($e.Message -replace "`r`n"," ") ) )
}

# Limpieza de logs
$secClear = Get-Events -LogName "Security" -Ids @(1102) -Max $MaxEventsPerSource
foreach ($e in $secClear) {
    $Timeline.Add( (New-TimelineItem `
        -Time $e.TimeCreated `
        -Source "EventLog:Security" `
        -Category "LogTampering" `
        -Description "Security log cleared (1102)" `
        -Details ($e.Message -replace "`r`n"," ") ) )
}

############################
# EVENT LOGS - SYSTEM
############################
Section "EVENT LOGS: System (Boot / Services)"

$sysEvents = Get-Events -LogName "System" -Ids @(6005,6006,6008,41,1074,7045) -Max $MaxEventsPerSource
foreach ($e in $sysEvents) {
    $Timeline.Add( (New-TimelineItem `
        -Time $e.TimeCreated `
        -Source "EventLog:System" `
        -Category "System" `
        -Description "EventID $($e.Id)" `
        -Details ($e.Message -replace "`r`n"," ") ) )
}

############################
# EVENT LOGS - POWERSHELL
############################
Section "EVENT LOGS: PowerShell"

$psOp = Get-Events -LogName "Microsoft-Windows-PowerShell/Operational" -Ids @(4103,4104) -Max $MaxEventsPerSource
foreach ($e in $psOp) {
    $Timeline.Add( (New-TimelineItem `
        -Time $e.TimeCreated `
        -Source "EventLog:PowerShell/Operational" `
        -Category "PowerShell" `
        -Description "ScriptBlock / Pipeline" `
        -Details ($e.Message -replace "`r`n"," ") ) )
}

############################
# PREFETCH
############################
Section "PREFETCH"

$PrefetchDir = "C:\Windows\Prefetch"
if (Test-Path $PrefetchDir) {
    Get-ChildItem $PrefetchDir -Filter *.pf -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $StartTime } |
    ForEach-Object {
        $Timeline.Add( (New-TimelineItem `
            -Time $_.LastWriteTime `
            -Source "Filesystem:Prefetch" `
            -Category "Prefetch" `
            -Description "Prefetch updated" `
            -Details $_.Name ) )
    }
} else {
    Write-Host "[+] Prefetch no disponible."
}

############################
# FILESYSTEM (MAC TIMES)
############################
Section "FILESYSTEM (MAC Times) - Roots seleccionadas"

foreach ($root in $FsRoots) {
    if (Test-Path $root) {
        Get-ChildItem $root -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.LastWriteTime -ge $StartTime -or
            $_.CreationTime  -ge $StartTime -or
            $_.LastAccessTime -ge $StartTime
        } |
        ForEach-Object {
            if ($_.LastWriteTime -ge $StartTime) {
                $Timeline.Add( (New-TimelineItem `
                    -Time $_.LastWriteTime `
                    -Source "Filesystem" `
                    -Category "Modified" `
                    -Description "File modified" `
                    -Details $_.FullName ) )
            }
            if ($_.CreationTime -ge $StartTime) {
                $Timeline.Add( (New-TimelineItem `
                    -Time $_.CreationTime `
                    -Source "Filesystem" `
                    -Category "Created" `
                    -Description "File created" `
                    -Details $_.FullName ) )
            }
            if ($_.LastAccessTime -ge $StartTime) {
                $Timeline.Add( (New-TimelineItem `
                    -Time $_.LastAccessTime `
                    -Source "Filesystem" `
                    -Category "Accessed" `
                    -Description "File accessed" `
                    -Details $_.FullName ) )
            }
        }
    }
}

############################
# REGISTRY (Run keys timestamps)
############################
Section "REGISTRY: Run/RunOnce (timestamps)"

$RunKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)

foreach ($rk in $RunKeys) {
    if (Test-Path $rk) {
        $item = Get-Item $rk
        if ($item.LastWriteTime -ge $StartTime) {
            $Timeline.Add( (New-TimelineItem `
                -Time $item.LastWriteTime `
                -Source "Registry" `
                -Category "Persistence" `
                -Description "Run/RunOnce modified" `
                -Details $rk ) )
        }
    }
}

############################
# ORDENAR Y EXPORTAR
############################
Section "EXPORTACIÓN"

$TimelineSorted = $Timeline | Sort-Object Time

$TimelineSorted | Select-Object Time,Source,Category,Description,Details |
    Format-Table -AutoSize

SafeExport-Csv -Data $TimelineSorted -Path "$OutputDir\timeline.csv"

############################
# RESUMEN
############################
Section "RESUMEN"

$Summary = [PSCustomObject]@{
    ItemsTotal = $TimelineSorted.Count
    From       = $StartTime
    To         = (Get-Date)
}

$Summary | Format-List
SafeExport-Csv -Data @($Summary) -Path "$OutputDir\resumen.csv"

############################
# FINAL
############################
Section "FINAL"

Write-Host "[+] Evidencias en: $OutputDir"
Write-Host "[+] Script finalizado"

Stop-Transcript
