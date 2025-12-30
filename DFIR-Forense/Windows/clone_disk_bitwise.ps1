<#
.SYNOPSIS
    clone_disk_bitwise.ps1

.DESCRIPTION
    Clonado forense bit a bit (sector a sector) de un disco físico en Windows
    usando acceso RAW a \\.\PhysicalDriveX desde PowerShell (.NET).

.NOTES
    Autor: Raul Renales
    USO DFIR - OPERACIÓN DE ALTO RIESGO
    Requiere PowerShell 5.1+
    DEBE ejecutarse como Administrador
#>

param(
    [Parameter(Mandatory=$true)]
    [int]$SourceDiskNumber,        # Ej: 1 -> \\.\PhysicalDrive1

    [Parameter(Mandatory=$true)]
    [string]$OutputImagePath,      # Ej: D:\evidencias\disk1.img

    [int]$BlockSizeMB = 4,         # Tamaño de bloque (MB)
    [string]$CaseTag = "case"
)

############################
# COMPROBACIONES INICIALES
############################

function Is-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Is-Admin)) {
    Write-Error "Este script debe ejecutarse como Administrador."
    exit 1
}

$PhysicalDrive = "\\.\PhysicalDrive$SourceDiskNumber"
$BlockSize = $BlockSizeMB * 1MB
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "========================================"
Write-Host "[+] CLONADO BIT A BIT – WINDOWS DFIR"
Write-Host "[+] Origen : $PhysicalDrive"
Write-Host "[+] Destino: $OutputImagePath"
Write-Host "[+] Bloque : $BlockSizeMB MB"
Write-Host "[+] Fecha  : $(Get-Date)"
Write-Host "========================================"

############################
# OBTENER TAMAÑO DEL DISCO
############################

try {
    $disk = Get-Disk -Number $SourceDiskNumber -ErrorAction Stop
    $DiskSize = $disk.Size
} catch {
    Write-Error "No se pudo obtener información del disco $SourceDiskNumber"
    exit 2
}

Write-Host "[+] Tamaño del disco: $DiskSize bytes"

############################
# APERTURA DE STREAMS RAW
############################

try {
    $sourceStream = New-Object System.IO.FileStream(
        $PhysicalDrive,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::ReadWrite
    )
} catch {
    Write-Error "No se pudo abrir el disco físico. ¿Está en uso?"
    exit 3
}

try {
    $destStream = New-Object System.IO.FileStream(
        $OutputImagePath,
        [System.IO.FileMode]::Create,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::None
    )
} catch {
    Write-Error "No se pudo crear el fichero de salida."
    $sourceStream.Close()
    exit 4
}

############################
# CLONADO BIT A BIT
############################

$buffer = New-Object byte[] $BlockSize
$totalRead = 0
$lastPercent = -1

Write-Host "[+] Iniciando clonado sector a sector..."

while ($totalRead -lt $DiskSize) {

    $toRead = [Math]::Min($BlockSize, $DiskSize - $totalRead)
    $bytesRead = $sourceStream.Read($buffer, 0, $toRead)

    if ($bytesRead -le 0) {
        break
    }

    $destStream.Write($buffer, 0, $bytesRead)
    $totalRead += $bytesRead

    $percent = [int](($totalRead * 100) / $DiskSize)
    if ($percent -ne $lastPercent) {
        Write-Progress -Activity "Clonando disco" `
                       -Status "$percent% completado" `
                       -PercentComplete $percent
        $lastPercent = $percent
    }
}

############################
# CIERRE DE STREAMS
############################

$sourceStream.Close()
$destStream.Close()

Write-Host "[+] Clonado finalizado"
Write-Host "[+] Bytes copiados: $totalRead"

############################
# HASH FORENSE (SHA256)
############################

Write-Host "[+] Calculando hash SHA256 de la imagen..."

$hash = Get-FileHash -Algorithm SHA256 -Path $OutputImagePath

$hash | Format-List

$hash | Out-File -Encoding UTF8 -FilePath "$OutputImagePath.sha256.txt"

############################
# RESUMEN FINAL
############################

Write-Host "========================================"
Write-Host "[+] CLONADO COMPLETADO"
Write-Host "[+] Imagen : $OutputImagePath"
Write-Host "[+] Hash   : $($hash.Hash)"
Write-Host "[+] Fecha  : $(Get-Date)"
Write-Host "========================================"
