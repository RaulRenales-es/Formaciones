#!/usr/bin/env bash
# ------------------------------------------------------------
# network_recon.sh
# Reconocimiento de red local (Living off the Land)
# Autor: Raul Renales
# Uso legal: Uso educativo / hacking ético
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

OUTDIR="network_recon_$(hostname)_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

log() {
  echo "[*] $1"
}

section() {
  echo -e "\n===== $1 =====" | tee -a "$OUTDIR/summary.txt"
}

log "Iniciando reconocimiento de red..."
log "Resultados en: $OUTDIR"

# ------------------------------------------------------------
section "Información de interfaces de red"
# ------------------------------------------------------------
ip addr show > "$OUTDIR/interfaces.txt" 2>/dev/null || ifconfig > "$OUTDIR/interfaces.txt"

# ------------------------------------------------------------
section "Rutas y gateways"
# ------------------------------------------------------------
ip route show > "$OUTDIR/routes.txt" 2>/dev/null || route -n > "$OUTDIR/routes.txt"

# ------------------------------------------------------------
section "Tabla ARP (hosts recientemente vistos)"
# ------------------------------------------------------------
ip neigh show > "$OUTDIR/arp_table.txt" 2>/dev/null || arp -a > "$OUTDIR/arp_table.txt"

# ------------------------------------------------------------
section "Conexiones de red activas"
# ------------------------------------------------------------
ss -tunap > "$OUTDIR/connections.txt" 2>/dev/null || netstat -tunap > "$OUTDIR/connections.txt"

# ------------------------------------------------------------
section "Servicios escuchando (puertos abiertos localmente)"
# ------------------------------------------------------------
ss -tulpen > "$OUTDIR/listening_services.txt" 2>/dev/null || netstat -tulpen > "$OUTDIR/listening_services.txt"

# ------------------------------------------------------------
section "DNS configurado"
# ------------------------------------------------------------
cat /etc/resolv.conf > "$OUTDIR/dns_config.txt" 2>/dev/null

# ------------------------------------------------------------
section "Información del hostname y dominio"
# ------------------------------------------------------------
hostname > "$OUTDIR/hostname.txt"
hostnamectl > "$OUTDIR/hostnamectl.txt" 2>/dev/null || true
dnsdomainname > "$OUTDIR/domain.txt" 2>/dev/null || true

# ------------------------------------------------------------
section "Escaneo pasivo de red local (ping sweep)"
# ------------------------------------------------------------
SUBNET=$(ip route | awk '/src/ {print $1}' | head -n1 || true)

if [[ -n "${SUBNET:-}" ]]; then
  log "Subred detectada: $SUBNET"
  for ip in $(seq 1 254); do
    TARGET=$(echo "$SUBNET" | sed 's/0\/.*/'"$ip"'/')
    ping -c 1 -W 1 "$TARGET" &>/dev/null && echo "$TARGET" >> "$OUTDIR/live_hosts.txt" &
  done
  wait
else
  log "No se pudo detectar la subred automáticamente"
fi

# ------------------------------------------------------------
section "Resumen rápido"
# ------------------------------------------------------------
{
  echo "Interfaces detectadas:"
  wc -l "$OUTDIR/interfaces.txt"

  echo
  echo "Hosts vivos detectados:"
  [[ -f "$OUTDIR/live_hosts.txt" ]] && wc -l "$OUTDIR/live_hosts.txt" || echo "0"

  echo
  echo "Servicios en escucha:"
  wc -l "$OUTDIR/listening_services.txt"
} >> "$OUTDIR/summary.txt"

log "Reconocimiento de red finalizado."
log "Revisar summary.txt para visión general."
