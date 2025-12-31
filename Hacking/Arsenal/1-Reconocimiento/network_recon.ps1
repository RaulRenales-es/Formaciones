<#
.SYNOPSIS
  network_recon.ps1
  Reconocimiento de red local (Living off the Land)

.DESCRIPTION
  Recolecta información de red desde un sistema Windows comprometido
  utilizando únicamente binarios y cmdlets nativos.
  Autor: Raul Renales

  Orientado a:
   - Pentesting interno
   - Red Team
   - Formación ofensiva / defensiva

.NOTES
  Uso exclusivamente educativo y autorizado.
#>

$ErrorActionPreference = "SilentlyContinue"

$HostName = $env:COMPUTERNAME
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutDir = "network_recon_${HostName}_${Timestamp}"

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

function Write-Section {
    param($Title)
    $TitleLine = "===== $Title ====="
    Write-Output $TitleLine | Tee-Object -FilePath "$OutDir\summary.txt" -Append
}

Write-Output "[*] Iniciando reconocimiento de red..."
Write-Output "[*] Resultados en: $OutDir"

# ------------------------------------------------------------
Write-Section "Interfaces de red"
# ------------------------------------------------------------
Get-NetIPConfiguration |
    Format-List * |
    Out-File "$OutDir\interfaces.txt"

# ------------------------------------------------------------
Write-Section "Rutas de red"
# ------------------------------------------------------------
Get-NetRoute |
    Sort-Object -Property DestinationPrefix |
    Format-Table -AutoSize |
    Out-File "$OutDir\routes.txt"

# ------------------------------------------------------------
Write-Section "Tabla ARP (hosts recientes)"
# ------------------------------------------------------------
arp -a |
    Out-File "$OutDir\arp_table.txt"

# ------------------------------------------------------------
Write-Section "Conexiones activas"
# ------------------------------------------------------------
Get-NetTCPConnection |
    Sort-Object -Property State |
    Format-Table -AutoSize |
    Out-File "$OutDir\connections.txt"

# ------------------------------------------------------------
Write-Section "Puertos en escucha"
# ------------------------------------------------------------
Get-NetTCPConnection -State Listen |
    Format-Table -AutoSize |
    Out-File "$OutDir\listening_ports.txt"

# ------------------------------------------------------------
Write-Section "Configuración DNS"
# ------------------------------------------------------------
Get-DnsClientServerAddress |
    Format-List * |
    Out-File "$OutDir\dns_config.txt"

# ------------------------------------------------------------
Write-Section "Hostname y dominio"
# ------------------------------------------------------------
{
    "Hostname: $env:COMPUTERNAME"
    "Dominio: $env:USERDOMAIN"
    "Usuario actual: $env:USERNAME"
} | Out-File "$OutDir\host_info.txt"

# ------------------------------------------------------------
Write-Section "Ping sweep pasivo de la red local"
# ------------------------------------------------------------
$IPInfo = Get-NetIPAddress -AddressFamily IPv4 |
          Where-Object { $_.IPAddress -notlike "169.254*" } |
          Select-Object -First 1

if ($IPInfo) {
    $Subnet = ($IPInfo.IPAddress -replace '\d+$','')
    Write-Output "Subred detectada: ${Subnet}0/24" |
        Tee-Object -FilePath "$OutDir\summary.txt" -Append

    1..254 | ForEach-Object {
        $Target = "$Subnet$_"
        if (Test-Connection -ComputerName $Target -Count 1 -Quiet -TimeoutSeconds 1) {
            $Target | Out-File "$OutDir\live_hosts.txt" -Append
        }
    }
}
else {
    Write-Output "No se pudo detectar la subred automáticamente" |
        Tee-Object -FilePath "$OutDir\summary.txt" -Append
}

# ------------------------------------------------------------
Write-Section "Resumen rápido"
# ------------------------------------------------------------
{
    "Interfaces detectadas: " + (Get-Content "$OutDir\interfaces.txt").Count
    "Hosts vivos detectados: " + (Test-Path "$OutDir\live_hosts.txt" ? (Get-Content "$OutDir\live_hosts.txt").Count : 0)
    "Puertos en escucha: " + (Get-Content "$OutDir\listening_ports.txt").Count
} | Out-File "$OutDir\summary.txt" -Append

Write-Output "[*] Reconocimiento de red finalizado."
Write-Output "[*] Revisar summary.txt para visión general."
