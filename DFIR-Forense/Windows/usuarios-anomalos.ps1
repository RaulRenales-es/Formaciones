<#
.SYNOPSIS
    usuarios-anomalos.ps1

.DESCRIPTION
    Script DFIR para detección de usuarios anómalos, abuso de privilegios
    y persistencia basada en cuentas en sistemas Windows.

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
$OutputDir = "usuarios_anomalos_${HostName}_$TimeStamp"

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Start-Transcript -Path "$OutputDir\resultados.txt" -Force

Write-Host "[+] Iniciando análisis de usuarios"
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
# USUARIOS LOCALES
############################

Section "USUARIOS LOCALES"

Get-LocalUser |
Select-Object Name, Enabled, LastLogon, PasswordRequired, PasswordExpires |
Format-Table -AutoSize

############################
# USUARIOS DESHABILITADOS
############################

Section "USUARIOS DESHABILITADOS"

Get-LocalUser | Where-Object { $_.Enabled -eq $false } |
Select-Object Name, LastLogon |
Format-Table -AutoSize

############################
# USUARIOS SIN CONTRASEÑA
############################

Section "USUARIOS SIN CONTRASEÑA REQUERIDA"

Get-LocalUser | Where-Object { $_.PasswordRequired -eq $false } |
Select-Object Name, Enabled, LastLogon |
Format-Table -AutoSize

############################
# GRUPOS PRIVILEGIADOS
############################

Section "MIEMBROS DE GRUPOS PRIVILEGIADOS"

$PrivilegedGroups = @(
    "Administrators",
    "Remote Desktop Users",
    "Backup Operators",
    "Power Users"
)

foreach ($Group in $PrivilegedGroups) {
    Write-Host "`n[+] Grupo: $Group"
    try {
        Get-LocalGroupMember $Group |
        Select-Object Name, ObjectClass |
        Format-Table -AutoSize
    } catch {
        Write-Host "[!] No se pudo enumerar el grupo $Group"
    }
}

############################
# CUENTAS OCULTAS (REGISTRO)
############################

Section "CUENTAS OCULTAS (SPECIALACCOUNTS)"

$HiddenUsersKey = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"

if (Test-Path $HiddenUsersKey) {
    Get-ItemProperty $HiddenUsersKey | Format-List
} else {
    Write-Host "[+] No se encontraron cuentas ocultas configuradas"
}

############################
# USUARIOS CON ACCESO RDP
############################

Section "USUARIOS CON ACCESO RDP"

try {
    Get-LocalGroupMember "Remote Desktop Users" |
    Select-Object Name, ObjectClass |
    Format-Table -AutoSize
} catch {
    Write-Host "[!] No se pudo enumerar Remote Desktop Users"
}

############################
# INICIO DE SESIÓN RECIENTE (EVENTOS)
############################

Section "INICIOS DE SESIÓN RECIENTES (EVENT ID 4624)"

Get-WinEvent -FilterHashtable @{
    LogName = "Security"
    Id      = 4624
} -MaxEvents 20 |
Select-Object TimeCreated, @{
    Name="Usuario"
    Expression={ $_.Properties[5].Value }
}, @{
    Name="TipoLogon"
    Expression={ $_.Properties[8].Value }
} |
Format-Table -AutoSize

############################
# CREACIÓN DE USUARIOS (EVENTOS)
############################

Section "CREACIÓN DE USUARIOS (EVENT ID 4720)"

Get-WinEvent -FilterHashtable @{
    LogName = "Security"
    Id      = 4720
} -ErrorAction SilentlyContinue |
Select-Object TimeCreated, @{
    Name="NuevoUsuario"
    Expression={ $_.Properties[0].Value }
} |
Format-Table -AutoSize

############################
# ELIMINACIÓN DE USUARIOS (EVENTOS)
############################

Section "ELIMINACIÓN DE USUARIOS (EVENT ID 4726)"

Get-WinEvent -FilterHashtable @{
    LogName = "Security"
    Id      = 4726
} -ErrorAction SilentlyContinue |
Select-Object TimeCreated, @{
    Name="UsuarioEliminado"
    Expression={ $_.Properties[0].Value }
} |
Format-Table -AutoSize

############################
# RESUMEN FINAL
############################

Section "RESUMEN"

Write-Host "[+] Directorio de evidencias: $OutputDir"
Write-Host "[+] Script finalizado"

Stop-Transcript
