<#
.SYNOPSIS
  Enumeración local ética basada en Living off the Land (Windows)

.DESCRIPTION
  Script de enumeración pasiva que recopila información local del sistema
  utilizando exclusivamente binarios y cmdlets nativos de Windows.
  No realiza explotación ni modificaciones del sistema.

.AUTHOR
  RaulRenales.es

.USAGE
  powershell.exe -ExecutionPolicy Bypass -File .\enum_local.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Hostname  = $env:COMPUTERNAME
$OutDir    = "enum_${Hostname}_${Timestamp}"

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

function Write-Section {
    param([string]$Title)
    "`r`n====================`r`n$Title`r`n===================="
}

# ------------------------------------------------------------
# Información del sistema
# ------------------------------------------------------------
(
    Write-Section "Información del sistema"
    Get-ComputerInfo
) | Out-File "$OutDir\system_info.txt"

# ------------------------------------------------------------
# Usuarios locales
# ------------------------------------------------------------
(
    Write-Section "Usuarios locales"
    Get-LocalUser | Select Name, Enabled, LastLogon
) | Out-File "$OutDir\local_users.txt"

# ------------------------------------------------------------
# Grupos locales
# ------------------------------------------------------------
(
    Write-Section "Grupos locales"
    Get-LocalGroup
) | Out-File "$OutDir\local_groups.txt"

# ------------------------------------------------------------
# Usuarios en grupos privilegiados
# ------------------------------------------------------------
(
    Write-Section "Administradores locales"
    Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
) | Out-File "$OutDir\local_admins.txt"

# ------------------------------------------------------------
# Sesiones activas
# ------------------------------------------------------------
(
    Write-Section "Sesiones activas"
    quser 2>$null
) | Out-File "$OutDir\sessions.txt"

# ------------------------------------------------------------
# Procesos en ejecución
# ------------------------------------------------------------
(
    Write-Section "Procesos en ejecución"
    Get-Process | Sort-Object ProcessName
) | Out-File "$OutDir\processes.txt"

# ------------------------------------------------------------
# Servicios
# ------------------------------------------------------------
(
    Write-Section "Servicios del sistema"
    Get-Service | Sort-Object Status, Name
) | Out-File "$OutDir\services.txt"

# ------------------------------------------------------------
# Puertos en escucha
# ------------------------------------------------------------
(
    Write-Section "Puertos en escucha"
    netstat -ano | Select-String "LISTENING"
) | Out-File "$OutDir\listening_ports.txt"

# ------------------------------------------------------------
# Conexiones de red activas
# ------------------------------------------------------------
(
    Write-Section "Conexiones de red activas"
    netstat -ano | Select-String "ESTABLISHED"
) | Out-File "$OutDir\active_connections.txt"

# ------------------------------------------------------------
# Configuración de red
# ------------------------------------------------------------
(
    Write-Section "Configuración de red"
    ipconfig /all
) | Out-File "$OutDir\network_config.txt"

# ------------------------------------------------------------
# Rutas
# ------------------------------------------------------------
(
    Write-Section "Tabla de rutas"
    route print
) | Out-File "$OutDir\routes.txt"

# ------------------------------------------------------------
# Tareas programadas
# ------------------------------------------------------------
(
    Write-Section "Tareas programadas"
    schtasks /query /fo LIST /v
) | Out-File "$OutDir\scheduled_tasks.txt"

# ------------------------------------------------------------
# Claves de persistencia (Run / RunOnce)
# ------------------------------------------------------------
(
    Write-Section "Claves Run / RunOnce"
    reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" 2>$null
    reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" 2>$null
    reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2>$null
    reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" 2>$null
) | Out-File "$OutDir\registry_persistence.txt"

# ------------------------------------------------------------
# Variables de entorno
# ------------------------------------------------------------
(
    Write-Section "Variables de entorno"
    Get-ChildItem Env:
) | Out-File "$OutDir\environment.txt"

# ------------------------------------------------------------
# Software instalado
# ------------------------------------------------------------
(
    Write-Section "Software instalado"
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* `
        | Select DisplayName, DisplayVersion, Publisher, InstallDate
) | Out-File "$OutDir\installed_software.txt"

# ------------------------------------------------------------
# Resumen
# ------------------------------------------------------------
@"
Enumeración local completada correctamente.

Directorio de salida:
$OutDir

Notas:
- Enumeración pasiva
- Sin explotación
- Sin herramientas externas
- Uso exclusivo para auditorías autorizadas
"@ | Out-File "$OutDir\summary.txt"

Write-Host "[+] Enumeración finalizada. Resultados en: $OutDir"
