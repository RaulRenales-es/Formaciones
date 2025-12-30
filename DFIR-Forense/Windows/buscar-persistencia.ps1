<#
.SYNOPSIS
    buscar-persistencia.ps1

.DESCRIPTION
    Script DFIR para detección de mecanismos de persistencia en sistemas Windows.
    Diseñado para respuesta a incidentes y análisis forense.

.NOTES
    Autor: Raul Renales
    Uso forense - SOLO LECTURA
#>

############################
# CONFIGURACIÓN GENERAL
############################

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$HostName  = $env:COMPUTERNAME
$OutputDir = "persistencia_${HostName}_$TimeStamp"

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Start-Transcript -Path "$OutputDir\resultados.txt" -Force

Write-Host "[+] Iniciando búsqueda de persistencia"
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

############################
# RUN / RUNONCE
############################

Section "CLAVES RUN / RUNONCE"

$RunKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
)

foreach ($Key in $RunKeys) {
    if (Test-Path $Key) {
        Write-Host "[+] $Key"
        Get-ItemProperty $Key | Format-List
    }
}

############################
# SERVICIOS SOSPECHOSOS
############################

Section "SERVICIOS SOSPECHOSOS"

Get-CimInstance Win32_Service |
Where-Object {
    $_.State -eq "Running" -and
    ($_.PathName -match "AppData|Temp|ProgramData|Users")
} |
Select-Object Name, State, StartMode, PathName |
Format-Table -AutoSize

############################
# TAREAS PROGRAMADAS
############################

Section "TAREAS PROGRAMADAS"

Get-ScheduledTask |
Where-Object {
    $_.Actions.Execute -match "AppData|Temp|ProgramData|Users"
} |
Select-Object TaskName, TaskPath, State |
Format-Table -AutoSize

############################
# STARTUP FOLDERS
############################

Section "STARTUP FOLDERS"

$StartupFolders = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)

foreach ($Folder in $StartupFolders) {
    if (Test-Path $Folder) {
        Write-Host "[+] $Folder"
        Get-ChildItem $Folder -Force |
        Select-Object Name, FullName, LastWriteTime
    }
}

############################
# WMI EVENT CONSUMERS
############################

Section "WMI EVENT CONSUMERS (PERSISTENCIA AVANZADA)"

Get-CimInstance -Namespace root\subscription -ClassName CommandLineEventConsumer |
Select-Object Name, CommandLineTemplate |
Format-List

Get-CimInstance -Namespace root\subscription -ClassName ActiveScriptEventConsumer |
Select-Object Name, ScriptText |
Format-List

############################
# POWERSHELL PROFILES
############################

Section "POWERSHELL PROFILES"

$Profiles = @(
    $profile.AllUsersAllHosts,
    $profile.AllUsersCurrentHost,
    $profile.CurrentUserAllHosts,
    $profile.CurrentUserCurrentHost
)

foreach ($Profile in $Profiles) {
    if ($Profile -and (Test-Path $Profile)) {
        Write-Host "[+] Profile encontrado: $Profile"
        Get-Content $Profile
    }
}

############################
# DLL HIJACKING (RUTAS COMUNES)
############################

Section "DLL HIJACKING - RUTAS COMUNES"

$SuspiciousDirs = @(
    "C:\Windows\Temp",
    "C:\Temp",
    "$env:LOCALAPPDATA\Temp",
    "$env:ProgramData"
)

foreach ($Dir in $SuspiciousDirs) {
    if (Test-Path $Dir) {
        Get-ChildItem $Dir -Recurse -Include *.dll -ErrorAction SilentlyContinue |
        Select-Object Name, FullName, LastWriteTime
    }
}

############################
# BINARIOS EJECUTABLES EN RUTAS ANÓMALAS
############################

Section "EJECUTABLES EN RUTAS ANÓMALAS"

foreach ($Dir in $SuspiciousDirs) {
    if (Test-Path $Dir) {
        Get-ChildItem $Dir -Recurse -Include *.exe -ErrorAction SilentlyContinue |
        Select-Object Name, FullName, LastWriteTime
    }
}

############################
# RESUMEN FINAL
############################

Section "RESUMEN"

Write-Host "[+] Directorio de evidencias: $OutputDir"
Write-Host "[+] Script finalizado"

Stop-Transcript
