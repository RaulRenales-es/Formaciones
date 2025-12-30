#!/usr/bin/env bash
# ------------------------------------------------------------
# network_recon.sh
# Reconocimiento de red PASIVO (Living off the Land)
# Autor: RaulRenales.es
# Uso exclusivo: auditorías autorizadas / formación
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

OUTPUT_DIR="network_recon_$(hostname)_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

log() {
  echo "[*] $1"
}

section() {
  echo -e "\n===================="
  echo "$1"
  echo "===================="
}

# ------------------------------------------------------------
section "Interfaces de red"
# ------------------------------------------------------------
{
  ip addr show
  echo
  ip link show
} > "$OUTPUT_DIR/interfaces.txt"

# ------------------------------------------------------------
section "Configuración IP y rutas"
# ------------------------------------------------------------
{
  ip route show
  echo
  ip rule show
} > "$OUTPUT_DIR/routes.txt"

# ------------------------------------------------------------
section "DNS y resolución"
# ------------------------------------------------------------
{
  echo "[/etc/resolv.conf]"
  cat /etc/resolv.conf
  echo
  echo "[Hosts locales]"
  cat /etc/hosts
} > "$OUTPUT_DIR/dns_hosts.txt"

# ------------------------------------------------------------
section "Puertos en escucha"
# ------------------------------------------------------------
{
  if command -v ss >/dev/null 2>&1; then
    ss -tulpen
  else
    netstat -tulpen
  fi
} > "$OUTPUT_DIR/listening_ports.txt"

# ------------------------------------------------------------
section "Conexiones de red activas"
# ------------------------------------------------------------
{
  if command -v ss >/dev/null 2>&1; then
    ss -tanp
  else
    netstat -tanp
  fi
} > "$OUTPUT_DIR/active_connections.txt"

# ------------------------------------------------------------
section "Tabla ARP"
# ------------------------------------------------------------
{
  ip neigh show
} > "$OUTPUT_DIR/arp_table.txt"

# ------------------------------------------------------------
section "Sockets UNIX"
# ------------------------------------------------------------
{
  ss -xap
} > "$OUTPUT_DIR/unix_sockets.txt"

# ------------------------------------------------------------
section "Estadísticas de red"
# ------------------------------------------------------------
{
  ss -s
} > "$OUTPUT_DIR/network_stats.txt"

# ------------------------------------------------------------
section "Configuración de firewall (solo lectura)"
# ------------------------------------------------------------
{
  echo "[iptables]"
  iptables -L -n -v 2>/dev/null || echo "iptables no accesible"
  echo
  echo "[nftables]"
  nft list ruleset 2>/dev/null || echo "nftables no accesible"
} > "$OUTPUT_DIR/firewall.txt"

# ------------------------------------------------------------
section "Resumen"
# ------------------------------------------------------------
{
  echo "Reconocimiento de red pasivo completado."
  echo
  echo "Contenido generado:"
  ls -1 "$OUTPUT_DIR"
  echo
  echo "NOTA:"
  echo "- No se ha generado tráfico de red"
  echo "- No se ha realizado escaneo activo"
  echo "- Observación local únicamente"
} > "$OUTPUT_DIR/summary.txt"

log "Network recon finalizado. Resultados en: $OUTPUT_DIR"
