<#
.SYNOPSIS
    analizar-eventlog.ps1

.DESCRIPTION
    Script DFIR para análisis forense de Event Logs en Windows.
    Extrae y resume eventos relevantes para autenticación, ejecución, RDP,
    PowerShell, persistencia y borrado de logs. Genera evidencias en TXT/CSV.

.NOTES
    Autor: Raul Renales
    Uso forense - SOLO LECTURA
    Requiere PowerShell 5.1+
    Recomendado ejecutar como Administrador para acceder a Security log.
#>

############################
# CONFIGURACIÓN GENERAL
############################

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$HostName  = $env:COMPUTERNAME
$OutputDir = "eventlog_${HostName}_$TimeStamp"

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Start-Transcript -Path "$OutputDir\resultados.txt" -Force

Write-Host "[+] Iniciando análisis de Event Logs"
Write-Host "[+] Fecha: $(Get-Date)"
Write-Host "[+] Equipo: $HostName"
Write-Host "========================================"

# Ventana temporal por defecto (ajustable)
# -DaysBack 7 -> últimos 7 días
param(
    [int]$DaysBack = 7,
    [int]$MaxEventsPerQuery = 2000
)

$StartTime = (Get-Date).AddDays(-1 * $DaysBack)

############################
# FUNCIÓN AUXILIAR
############################

function Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================"
    Write-Host "[*] $Title"
    Write-Host "========================================"
}

function SafeExport-Csv {
    param(
        [Parameter(Mandatory=$true)] $Data,
        [Parameter(Mandatory=$true)][string]$Path
    )
    try {
        $Data | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $Path -Force
        Write-Host "[+] Exportado CSV: $Path"
    } catch {
        Write-Host "[!] Error exportando CSV ($Path): $($_.Exception.Message)"
    }
}

function SafeOut-File {
    param(
        [Parameter(Mandatory=$true)] $Data,
        [Parameter(Mandatory=$true)][string]$Path
    )
    try {
        $Data | Out-File -Encoding UTF8 -FilePath $Path -Force
        Write-Host "[+] Exportado TXT: $Path"
    } catch {
        Write-Host "[!] Error exportando TXT ($Path): $($_.Exception.Message)"
    }
}

function Get-Events {
    param(
        [Parameter(Mandatory=$true)][string]$LogName,
        [Parameter(Mandatory=$true)][int[]]$Ids,
        [datetime]$FromTime = $StartTime,
        [int]$MaxEvents = $MaxEventsPerQuery
    )
    try {
        Get-WinEvent -FilterHashtable @{
            LogName   = $LogName
            Id        = $Ids
            StartTime = $FromTime
        } -ErrorAction Stop -MaxEvents $MaxEvents
    } catch {
        Write-Host "[!] No se pudo leer $LogName (IDs: $($Ids -join ',')) -> $($_.Exception.Message)"
        @()
    }
}

function Get-EventsByProvider {
    param(
        [Parameter(Mandatory=$true)][string]$LogName,
        [Parameter(Mandatory=$true)][string[]]$ProviderName,
        [datetime]$FromTime = $StartTime,
        [int]$MaxEvents = $MaxEventsPerQuery
    )
    try {
        Get-WinEvent -FilterHashtable @{
            LogName      = $LogName
            ProviderName = $ProviderName
            StartTime    = $FromTime
        } -ErrorAction Stop -MaxEvents $MaxEvents
    } catch {
        Write-Host "[!] No se pudo leer $LogName (Providers: $($ProviderName -join ',')) -> $($_.Exception.Message)"
        @()
    }
}

function Parse-EventBasic {
    param([Parameter(Mandatory=$true)]$Event)

    [PSCustomObject]@{
        TimeCreated = $Event.TimeCreated
        LogName     = $Event.LogName
        Provider    = $Event.ProviderName
        EventID     = $Event.Id
        Level       = $Event.LevelDisplayName
        Computer    = $Event.MachineName
        Message     = ($Event.Message -replace "`r`n"," " -replace "\s{2,}"," ").Trim()
    }
}

############################
# INVENTARIO DE LOGS DISPONIBLES
############################

Section "INVENTARIO DE LOGS (disponibilidad rápida)"

$InterestingLogs = @(
    "Security",
    "System",
    "Microsoft-Windows-PowerShell/Operational",
    "Windows PowerShell"
)

$LogStatus = foreach ($ln in $InterestingLogs) {
    try {
        $l = Get-WinEvent -ListLog $ln -ErrorAction Stop
        [PSCustomObject]@{
            LogName      = $ln
            Enabled      = $l.IsEnabled
            RecordCount  = $l.RecordCount
            LastWriteTime= $l.LastWriteTime
        }
    } catch {
        [PSCustomObject]@{
            LogName      = $ln
            Enabled      = $false
            RecordCount  = $null
            LastWriteTime= $null
        }
    }
}
$LogStatus | Format-Table -AutoSize
SafeExport-Csv -Data $LogStatus -Path "$OutputDir\log_inventory.csv"

############################
# SECURITY: AUTENTICACIÓN Y CUENTAS
############################

Section "SECURITY: LOGON/LOGOFF + FALLIDOS (4624/4634/4647/4625)"

$SecAuthIds = 4624,4634,4647,4625
$SecAuthEvents = Get-Events -LogName "Security" -Ids $SecAuthIds

# Parse básico + campos clave (según orden típico de Properties)
# 4624: [5]=TargetUserName, [6]=TargetDomain, [8]=LogonType, [18]=IpAddress, [19]=IpPort (puede variar por versión)
# 4625: [5]=TargetUserName, [6]=TargetDomain, [10]=Status, [12]=SubStatus, [19]=IpAddress (puede variar)
$AuthParsed = foreach ($e in $SecAuthEvents) {
    $p = $e.Properties
    $obj = Parse-EventBasic -Event $e

    $targetUser = $null
    $logonType  = $null
    $ip         = $null
    $status     = $null
    $subStatus  = $null

    try {
        if ($e.Id -eq 4624) {
            $targetUser = $p[5].Value
            $logonType  = $p[8].Value
            $ip         = $p[18].Value
        } elseif ($e.Id -eq 4625) {
            $targetUser = $p[5].Value
            $logonType  = $p[10].Value  # en algunos sistemas aquí no es logontype; se deja por compat
            $ip         = $p[19].Value
            $status     = $p[10].Value
            $subStatus  = $p[12].Value
        } elseif ($e.Id -in 4634,4647) {
            $targetUser = $p[1].Value
            $logonType  = $p[4].Value
        }
    } catch { }

    [PSCustomObject]@{
        TimeCreated = $obj.TimeCreated
        EventID     = $obj.EventID
        User        = $targetUser
        LogonType   = $logonType
        IpAddress   = $ip
        Status      = $status
        SubStatus   = $subStatus
        Message     = $obj.Message
    }
}

$AuthParsed | Sort-Object TimeCreated -Descending | Select-Object -First 50 | Format-Table -AutoSize
SafeExport-Csv -Data $AuthParsed -Path "$OutputDir\security_auth.csv"

# Top IPs en fallidos (4625)
Section "SECURITY: TOP IPs en fallos (4625) (aprox.)"

$TopFailIps = $AuthParsed |
Where-Object { $_.EventID -eq 4625 -and $_.IpAddress -and $_.IpAddress -ne "-" } |
Group-Object IpAddress | Sort-Object Count -Descending | Select-Object -First 20 |
Select-Object Count, Name

$TopFailIps | Format-Table -AutoSize
SafeExport-Csv -Data $TopFailIps -Path "$OutputDir\security_4625_top_ips.csv"

# LogonType guía rápida
Section "GUÍA RÁPIDA: LogonType (referencia)"

$LogonTypeRef = @(
    [PSCustomObject]@{ LogonType="2";  Meaning="Interactive (consola)" }
    [PSCustomObject]@{ LogonType="3";  Meaning="Network (SMB/servicios)" }
    [PSCustomObject]@{ LogonType="4";  Meaning="Batch (tareas)" }
    [PSCustomObject]@{ LogonType="5";  Meaning="Service" }
    [PSCustomObject]@{ LogonType="7";  Meaning="Unlock" }
    [PSCustomObject]@{ LogonType="8";  Meaning="NetworkCleartext" }
    [PSCustomObject]@{ LogonType="9";  Meaning="NewCredentials (runas)" }
    [PSCustomObject]@{ LogonType="10"; Meaning="RemoteInteractive (RDP)" }
    [PSCustomObject]@{ LogonType="11"; Meaning="CachedInteractive" }
)
$LogonTypeRef | Format-Table -AutoSize

############################
# SECURITY: CREACIÓN/MODIFICACIÓN CUENTAS Y GRUPOS
############################

Section "SECURITY: CUENTAS y GRUPOS (4720/4722/4723/4724/4725/4726/4728/4732/4756)"

$AcctIds = 4720,4722,4723,4724,4725,4726,4728,4732,4756
$AcctEvents = Get-Events -LogName "Security" -Ids $AcctIds

$AcctParsed = foreach ($e in $AcctEvents) {
    $obj = Parse-EventBasic -Event $e
    [PSCustomObject]@{
        TimeCreated = $obj.TimeCreated
        EventID     = $obj.EventID
        Provider    = $obj.Provider
        Message     = $obj.Message
    }
}

$AcctParsed | Sort-Object TimeCreated -Descending | Select-Object -First 50 | Format-Table -AutoSize
SafeExport-Csv -Data $AcctParsed -Path "$OutputDir\security_accounts_groups.csv"

############################
# SECURITY: CREACIÓN DE PROCESOS (4688) + INDICIOS
############################

Section "SECURITY: CREACIÓN DE PROCESOS (4688) (si está habilitado auditing)"

$ProcEvents = Get-Events -LogName "Security" -Ids @(4688)

$ProcParsed = foreach ($e in $ProcEvents) {
    $p = $e.Properties
    $time = $e.TimeCreated

    # En 4688, suele ser:
    # [1]=SubjectUserName, [5]=NewProcessName, [8]=CommandLine (puede variar), [9]=ParentProcessName (puede variar)
    $subject = $null
    $newProc = $null
    $cmd     = $null
    $parent  = $null
    try { $subject = $p[1].Value } catch {}
    try { $newProc = $p[5].Value } catch {}
    try { $cmd     = $p[8].Value } catch {}
    try { $parent  = $p[9].Value } catch {}

    [PSCustomObject]@{
        TimeCreated  = $time
        User         = $subject
        NewProcess   = $newProc
        CommandLine  = $cmd
        ParentProcess= $parent
        EventID      = 4688
    }
}

# Heurística: LOLBins y rutas típicas sospechosas
Section "SECURITY 4688: Heurística (LOLBins / Rutas sospechosas)"

$LOLRegex = "(?i)\\(powershell|pwsh|cmd|wscript|cscript|mshta|rundll32|regsvr32|certutil|bitsadmin|wmic|schtasks|sc|wevtutil|vssadmin|bcdedit|netsh)\.exe\b"
$PathSusp = "(?i)\\(AppData\\|\\Temp\\|\\ProgramData\\|\\Users\\Public\\|\\Windows\\Temp\\)"

$ProcInteresting = $ProcParsed | Where-Object {
    ($_.NewProcess -match $LOLRegex) -or
    ($_.NewProcess -match $PathSusp) -or
    ($_.CommandLine -match $PathSusp) -or
    ($_.CommandLine -match $LOLRegex)
}

$ProcInteresting | Sort-Object TimeCreated -Descending | Select-Object -First 80 | Format-Table -AutoSize
SafeExport-Csv -Data $ProcParsed        -Path "$OutputDir\security_4688_all.csv"
SafeExport-Csv -Data $ProcInteresting   -Path "$OutputDir\security_4688_interesting.csv"

############################
# SECURITY: BORRADO DE LOGS (1102)
############################

Section "SECURITY: BORRADO / LIMPIEZA DE LOG (1102)"

$ClearEvents = Get-Events -LogName "Security" -Ids @(1102)

$ClearParsed = foreach ($e in $ClearEvents) { Parse-EventBasic -Event $e }
$ClearParsed | Sort-Object TimeCreated -Descending | Format-Table -AutoSize
SafeExport-Csv -Data $ClearParsed -Path "$OutputDir\security_1102_log_cleared.csv"

############################
# SYSTEM: INICIOS/ APAGADOS / SERVICIOS
############################

Section "SYSTEM: INICIOS/APAGADOS (6005/6006/6008/41/1074) + servicios (7045)"

$SysIds = 6005,6006,6008,41,1074,7045
$SysEvents = Get-Events -LogName "System" -Ids $SysIds

$SysParsed = foreach ($e in $SysEvents) { Parse-EventBasic -Event $e }
$SysParsed | Sort-Object TimeCreated -Descending | Select-Object -First 80 | Format-Table -AutoSize
SafeExport-Csv -Data $SysParsed -Path "$OutputDir\system_key_events.csv"

Section "SYSTEM 7045: Servicios instalados (detalle)"

$SvcInstall = $SysEvents | Where-Object { $_.Id -eq 7045 } | ForEach-Object { Parse-EventBasic -Event $_ }
$SvcInstall | Sort-Object TimeCreated -Descending | Format-Table -AutoSize
SafeExport-Csv -Data $SvcInstall -Path "$OutputDir\system_7045_services_installed.csv"

############################
# POWERSHELL: LOGS OPERACIONALES (4103/4104) y Windows PowerShell (400/403/600/800)
############################

Section "POWERSHELL: Operational (4103/4104) y Windows PowerShell (400/403/600/800)"

# Operational
$PsOpIds = 4103,4104
$PsOperational = Get-Events -LogName "Microsoft-Windows-PowerShell/Operational" -Ids $PsOpIds

$PsOpParsed = foreach ($e in $PsOperational) {
    $obj = Parse-EventBasic -Event $e
    [PSCustomObject]@{
        TimeCreated = $obj.TimeCreated
        EventID     = $obj.EventID
        Provider    = $obj.Provider
        Message     = $obj.Message
    }
}

$PsOpParsed | Sort-Object TimeCreated -Descending | Select-Object -First 60 | Format-Table -AutoSize
SafeExport-Csv -Data $PsOpParsed -Path "$OutputDir\powershell_operational_4103_4104.csv"

# Windows PowerShell (clásico)
$PsClassicIds = 400,403,600,800
$PsClassic = Get-Events -LogName "Windows PowerShell" -Ids $PsClassicIds

$PsClassicParsed = foreach ($e in $PsClassic) { Parse-EventBasic -Event $e }
$PsClassicParsed | Sort-Object TimeCreated -Descending | Select-Object -First 60 | Format-Table -AutoSize
SafeExport-Csv -Data $PsClassicParsed -Path "$OutputDir\powershell_classic_400_403_600_800.csv"

############################
# RDP: EVENTOS TÍPICOS (TerminalServices)
############################

Section "RDP: TerminalServices (operational) (si existe)"

# Estos logs pueden no estar habilitados por defecto
$RdpLogs = @(
    "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational",
    "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational"
)

$RdpData = @()

foreach ($ln in $RdpLogs) {
    try {
        $tmp = Get-WinEvent -FilterHashtable @{ LogName=$ln; StartTime=$StartTime } -MaxEvents 500 -ErrorAction Stop
        $RdpData += ($tmp | ForEach-Object { Parse-EventBasic -Event $_ })
        Write-Host "[+] Leído: $ln"
    } catch {
        Write-Host "[!] No disponible / sin permisos: $ln -> $($_.Exception.Message)"
    }
}

if ($RdpData.Count -gt 0) {
    $RdpData | Sort-Object TimeCreated -Descending | Select-Object -First 80 | Format-Table -AutoSize
    SafeExport-Csv -Data $RdpData -Path "$OutputDir\rdp_terminalservices_events.csv"
} else {
    Write-Host "[+] No se recopilaron eventos de TerminalServices (posible no habilitado)."
}

############################
# RESUMEN EJECUTIVO (INDICIOS RÁPIDOS)
############################

Section "RESUMEN EJECUTIVO (indicadores rápidos)"

$Summary = [PSCustomObject]@{
    DaysBack                         = $DaysBack
    StartTime                        = $StartTime
    Security_Auth_Events_Collected    = $SecAuthEvents.Count
    Security_4625_Failures           = ($AuthParsed | Where-Object {$_.EventID -eq 4625}).Count
    Security_4624_Success            = ($AuthParsed | Where-Object {$_.EventID -eq 4624}).Count
    Security_4688_ProcCreate         = $ProcEvents.Count
    Security_4688_Interesting        = $ProcInteresting.Count
    Security_1102_LogCleared         = $ClearEvents.Count
    System_Key_Events                = $SysEvents.Count
    System_7045_ServiceInstall       = ($SysEvents | Where-Object {$_.Id -eq 7045}).Count
    PS_Operational_4103_4104         = $PsOperational.Count
    PS_Classic_400_403_600_800       = $PsClassic.Count
    RDP_TerminalServices_Events      = $RdpData.Count
}

$Summary | Format-List
SafeExport-Csv -Data @($Summary) -Path "$OutputDir\resumen.csv"

############################
# FINAL
############################

Section "RESUMEN FINAL"

Write-Host "[+] Evidencias almacenadas en: $OutputDir"
Write-Host "[+] Script finalizado"

Stop-Transcript
