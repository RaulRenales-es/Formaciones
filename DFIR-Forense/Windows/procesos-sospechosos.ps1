<#
.SYNOPSIS
    procesos-sospechosos.ps1

.DESCRIPTION
    Script DFIR para detección de procesos anómalos y sospechosos en Windows.
    Enfocado en malware fileless, LOLBins y ejecución desde rutas no estándar.

.NOTES
    Autor: Raul Renales
    Uso forense - SOLO LECTURA
    Requiere PowerShell 5.1+
#>

############################
# CONFIGURACIÓN GENERAL
############################

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$HostName  = $env:COMPUTERNAME
$OutputDir = "procesos_sospechosos_${HostName}_$TimeStamp"

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Start-Transcript -Path "$OutputDir\resultados.txt" -Force

Write-Host "[+] Iniciando análisis de procesos"
Write-Host "[+] Fecha: $(Get-Date)"
Write-Host "[+] Equipo: $HostName"
Write-Host "========================================"

############################
# FUNCIÓN AUXILIAR
############################

function Section {
    param ($Title)
    Write-Host ""
    Write-Host "========================================"
    Write-Host "[*] $Title"
    Write-Host "========================================"
}

function Get-SignatureStatus {
    param ($Path)
    if (-not $Path -or -not (Test-Path $Path)) {
        return "NoPath"
    }
    try {
        $sig = Get-AuthenticodeSignature -FilePath $Path
        return $sig.Status
    } catch {
        return "Unknown"
    }
}

############################
# LISTADO COMPLETO DE PROCESOS
############################

Section "LISTADO COMPLETO DE PROCESOS"

$Processes = Get-CimInstance Win32_Process

$ProcessData = foreach ($p in $Processes) {

    $sigStatus = Get-SignatureStatus -Path $p.ExecutablePath

    [PSCustomObject]@{
        PID           = $p.ProcessId
        Name          = $p.Name
        Path          = $p.ExecutablePath
        ParentPID     = $p.ParentProcessId
        CommandLine   = $p.CommandLine
        Signature     = $sigStatus
    }
}

$ProcessData | Format-Table -AutoSize
$ProcessData | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path "$OutputDir\procesos_todos.csv"

############################
# PROCESOS SIN RUTA
############################

Section "PROCESOS SIN RUTA (ExecutablePath NULL)"

$NoPath = $ProcessData | Where-Object { -not $_.Path }

$NoPath | Format-Table -AutoSize
$NoPath | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path "$OutputDir\procesos_sin_ruta.csv"

############################
# PROCESOS DESDE RUTAS ANÓMALAS
############################

Section "PROCESOS DESDE RUTAS ANÓMALAS"

$SuspiciousPathRegex = '(?i)\\(AppData\\|Temp\\|ProgramData\\|Users\\Public\\|Windows\\Temp\\)'

$BadPaths = $ProcessData | Where-Object {
    $_.Path -and $_.Path -match $SuspiciousPathRegex
}

$BadPaths | Format-Table -AutoSize
$BadPaths | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path "$OutputDir\procesos_rutas_anomalas.csv"

############################
# PROCESOS SIN FIRMA O FIRMA INVÁLIDA
############################

Section "PROCESOS SIN FIRMA DIGITAL VÁLIDA"

$Unsigned = $ProcessData | Where-Object {
    $_.Signature -ne "Valid"
}

$Unsigned | Format-Table -AutoSize
$Unsigned | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path "$OutputDir\procesos_sin_firma.csv"

############################
# LOLBINS EN EJECUCIÓN
############################

Section "LOLBINS EN EJECUCIÓN"

$LOLBinsRegex = '(?i)\\(powershell|pwsh|cmd|wscript|cscript|mshta|rundll32|regsvr32|certutil|bitsadmin|wmic|schtasks|sc|wevtutil|vssadmin|bcdedit|netsh)\.exe\b'

$LOLBins = $ProcessData | Where-Object {
    ($_.Path -and $_.Path -match $LOLBinsRegex) -or
    ($_.CommandLine -and $_.CommandLine -match $LOLBinsRegex)
}

$LOLBins | Format-Table -AutoSize
$LOLBins | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path "$OutputDir\procesos_lolbins.csv"

############################
# PROCESOS HUÉRFANOS (PADRE NO EXISTE)
############################

Section "PROCESOS HUÉRFANOS (ParentPID inexistente)"

$PIDs = $ProcessData.PID

$Orphans = $ProcessData | Where-Object {
    $_.ParentPID -and ($PIDs -notcontains $_.ParentPID)
}

$Orphans | Format-Table -AutoSize
$Orphans | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path "$OutputDir\procesos_huerfanos.csv"

############################
# RELACIONES PADRE-HIJO SOSPECHOSAS
############################

Section "RELACIONES PADRE-HIJO SOSPECHOSAS"

$SuspiciousParents = '(?i)(winword|excel|outlook|chrome|firefox|iexplore|edge)\.exe'

$BadParentChild = $ProcessData | Where-Object {
    $_.CommandLine -and
    $_.CommandLine -match $LOLBinsRegex -and
    ($Processes | Where-Object {
        $_.ProcessId -eq $_.ParentPID -and $_.Name -match $SuspiciousParents
    })
}

$BadParentChild | Format-Table -AutoSize
$BadParentChild | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path "$OutputDir\procesos_parent_child_sospechosos.csv"

############################
# RESUMEN EJECUTIVO
############################

Section "RESUMEN EJECUTIVO"

$Summary = [PSCustomObject]@{
    TotalProcesos           = $ProcessData.Count
    SinRuta                 = $NoPath.Count
    RutasAnomalas           = $BadPaths.Count
    SinFirma                = $Unsigned.Count
    LOLBins                 = $LOLBins.Count
    ProcesosHuerfanos       = $Orphans.Count
    ParentChildSospechosos  = $BadParentChild.Count
}

$Summary | Format-List
$Summary | Export-Csv -NoTypeInformation -Encoding UTF8 `
    -Path "$OutputDir\resumen.csv"

############################
# FINAL
############################

Section "RESUMEN FINAL"

Write-Host "[+] Evidencias almacenadas en: $OutputDir"
Write-Host "[+] Script finalizado"

Stop-Transcript
