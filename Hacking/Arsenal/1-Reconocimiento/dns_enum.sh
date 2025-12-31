#!/usr/bin/env bash
# ------------------------------------------------------------
# dns_enum.sh
# Enumeración DNS (interna / externa) - Living off the Land
# Autor: Raul Renales
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

OUTDIR="dns_enum_$(hostname)_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

log() {
  echo "[*] $1"
}

section() {
  echo -e "\n===== $1 =====" | tee -a "$OUTDIR/summary.txt"
}

log "Iniciando enumeración DNS..."
log "Resultados en: $OUTDIR"

# ------------------------------------------------------------
section "Configuración DNS local"
# ------------------------------------------------------------
cat /etc/resolv.conf > "$OUTDIR/resolv.conf" 2>/dev/null || true

# ------------------------------------------------------------
section "Dominio local detectado"
# ------------------------------------------------------------
DOMAIN=$(dnsdomainname 2>/dev/null || hostname -d 2>/dev/null || true)

if [[ -n "${DOMAIN:-}" ]]; then
  echo "Dominio detectado: $DOMAIN" | tee -a "$OUTDIR/domain.txt"
else
  echo "No se pudo detectar dominio local" | tee -a "$OUTDIR/domain.txt"
fi

# ------------------------------------------------------------
section "Servidores DNS configurados"
# ------------------------------------------------------------
awk '/^nameserver/ {print $2}' /etc/resolv.conf > "$OUTDIR/nameservers.txt" 2>/dev/null || true

# ------------------------------------------------------------
section "Resolución básica (A / AAAA / MX)"
# ------------------------------------------------------------
if [[ -n "${DOMAIN:-}" ]]; then
  {
    echo "A records:"
    getent ahosts "$DOMAIN"

    echo
    echo "MX records:"
    command -v dig >/dev/null && dig mx "$DOMAIN" +short || true

    echo
    echo "AAAA records:"
    command -v dig >/dev/null && dig aaaa "$DOMAIN" +short || true
  } > "$OUTDIR/basic_records.txt"
fi

# ------------------------------------------------------------
section "Enumeración pasiva de hosts comunes"
# ------------------------------------------------------------
COMMON_HOSTS=(www mail vpn intranet ldap dc ns ftp ssh)

if [[ -n "${DOMAIN:-}" ]]; then
  for host in "${COMMON_HOSTS[@]}"; do
    fqdn="${host}.${DOMAIN}"
    if getent hosts "$fqdn" &>/dev/null; then
      getent hosts "$fqdn" >> "$OUTDIR/common_hosts.txt"
    fi
  done
fi

# ------------------------------------------------------------
section "Reverse DNS de IPs locales (ARP)"
# ------------------------------------------------------------
if [[ -f /proc/net/arp ]]; then
  awk 'NR>1 {print $1}' /proc/net/arp | while read -r ip; do
    host "$ip" 2>/dev/null >> "$OUTDIR/reverse_dns.txt" || true
  done
fi

# ------------------------------------------------------------
section "Búsqueda de posibles Domain Controllers (AD)"
# ------------------------------------------------------------
if [[ -n "${DOMAIN:-}" ]] && command -v dig >/dev/null; then
  {
    echo "_ldap._tcp.$DOMAIN"
    dig SRV _ldap._tcp."$DOMAIN" +short

    echo
    echo "_kerberos._tcp.$DOMAIN"
    dig SRV _kerberos._tcp."$DOMAIN" +short
  } > "$OUTDIR/ad_srv_records.txt"
fi

# ------------------------------------------------------------
section "Resumen rápido"
# ------------------------------------------------------------
{
  echo "Dominio: ${DOMAIN:-No detectado}"
  echo "Nameservers:"
  cat "$OUTDIR/nameservers.txt" 2>/dev/null || echo "N/D"

  echo
  echo "Hosts comunes detectados:"
  [[ -f "$OUTDIR/common_hosts.txt" ]] && wc -l "$OUTDIR/common_hosts.txt" || echo "0"
} >> "$OUTDIR/summary.txt"

log "Enumeración DNS finalizada."
log "Revisar summary.txt para visión general."
