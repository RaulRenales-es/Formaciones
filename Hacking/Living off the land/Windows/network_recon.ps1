<#
.SYNOPSIS
  Reconocimiento de red pasivo basado en Living off the Land (Windows)

.DESCRIPTION
  Recopila información de red local utilizando exclusivamente
  cmdlets y binarios nativos de Windows.
  No realiza escaneos, no genera tráfico ni modifica el sistema.

.AUTHOR
  RaulRenales.es

.USAGE
  powershell.exe -ExecutionPolicy Bypass -File .\network_recon.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Hostname  = $env:COMPUTERNAME
$OutDir    = "network_recon_${Hostname}_${Timestamp}"

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

function Section {
    param([string]$Title)
    "`r`n====================`r`n$Title`r`n===================="
}

# ------------------------------------------------------------
# Interfaces de red
# ------------------------------------------------------------
(
    Section "Interfaces de red"
    Get-NetAdapter | Select Name, Status, MacAddress, LinkSpeed
) | Out-File "$OutDir\interfaces.txt"

# ------------------------------------------------------------
# Configuración IP
# ------------------------------------------------------------
(
    Section "Configuración IP"
    Get-NetIPAddress | Select InterfaceAlias, IPAddress, AddressFamily
) | Out-File "$OutDir\ip_addresses.txt"

# ------------------------------------------------------------
# Rutas
# ------------------------------------------------------------
(
    Section "Tabla de rutas"
    Get-NetRoute | Select InterfaceAlias, DestinationPrefix, NextHop, RouteMetric
) | Out-File "$OutDir\routes.txt"

# ------------------------------------------------------------
# DNS y configuración de resolución
# ------------------------------------------------------------
(
    Section "Configuración DNS"
    Get-DnsClientServerAddress
) | Out-File "$OutDir\dns_config.txt"

# ------------------------------------------------------------
# Puertos en escucha
# ------------------------------------------------------------
(
    Section "Puertos en escucha"
    netstat -ano | Select-String "LISTENING"
) | Out-File "$OutDir\listening_ports.txt"

# ------------------------------------------------------------
# Conexiones de red activas
# ------------------------------------------------------------
(
    Section "Conexiones activas"
    netstat -ano | Select-String "ESTABLISHED"
) | Out-File "$OutDir\active_connections.txt"

# ------------------------------------------------------------
# Asociación puerto → proceso
# ------------------------------------------------------------
(
    Section "Relación procesos y red"
    Get-NetTCPConnection |
        Select LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess
) | Out-File "$OutDir\net_process_mapping.txt"

# ------------------------------------------------------------
# Tabla ARP
# ------------------------------------------------------------
(
    Section "Tabla ARP"
    arp -a
) | Out-File "$OutDir\arp_table.txt"

# ------------------------------------------------------------
# Estadísticas de red
# ------------------------------------------------------------
(
    Section "Estadísticas de red"
    netstat -s
) | Out-File "$OutDir\network_stats.txt"

# ------------------------------------------------------------
# Firewall (solo lectura)
# ------------------------------------------------------------
(
    Section "Firewall de Windows"
    Get-NetFirewallProfile
    "`r`n--- Reglas habilitadas ---"
    Get-NetFirewallRule | Where-Object { $_.Enabled -eq "True" } |
        Select DisplayName, Direction, Action
) | Out-File "$OutDir\firewall.txt"

# ------------------------------------------------------------
# Resumen
# ------------------------------------------------------------
@"
Reconocimiento de red PASIVO completado correctamente.

Directorio de salida:
$OutDir

Notas:
- No se ha generado tráfico de red
- No se ha realizado escaneo activo
- Uso exclusivo de binarios nativos
- Enfoque Living off the Land
"@ | Out-File "$OutDir\summary.txt"

Write-Host "[+] Network recon finalizado. Resultados en: $OutDir"
