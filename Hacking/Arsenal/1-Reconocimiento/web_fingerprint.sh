#!/usr/bin/env bash
# ------------------------------------------------------------
# web_fingerprint.sh
# Fingerprinting web pasivo - Living off the Land
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

OUTDIR="web_fingerprint_$(hostname)_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

log() {
  echo "[*] $1"
}

section() {
  echo -e "\n===== $1 =====" | tee -a "$OUTDIR/summary.txt"
}

log "Iniciando fingerprinting web..."
log "Resultados en: $OUTDIR"

# ------------------------------------------------------------
section "Objetivos web detectados (desde DNS y ARP)"
# ------------------------------------------------------------

TARGETS=()

# Desde DNS común
if [[ -f ../dns_enum_*/common_hosts.txt ]]; then
  mapfile -t TARGETS < <(awk '{print $2}' ../dns_enum_*/common_hosts.txt | sort -u)
fi

# Fallback manual: ARP + reverse DNS
if [[ ${#TARGETS[@]} -eq 0 ]] && [[ -f /proc/net/arp ]]; then
  while read -r ip; do
    host "$ip" 2>/dev/null | awk '/domain name pointer/ {print $5}' >> "$OUTDIR/targets.txt" || true
  done < <(awk 'NR>1 {print $1}' /proc/net/arp)
fi

printf "%s\n" "${TARGETS[@]}" | sort -u > "$OUTDIR/targets.txt"

# ------------------------------------------------------------
section "Cabeceras HTTP / HTTPS"
# ------------------------------------------------------------
while read -r target; do
  echo "### $target" >> "$OUTDIR/http_headers.txt"

  for proto in http https; do
    curl -k -s -I --max-time 5 "$proto://$target" \
      | grep -Ei 'Server:|X-Powered-By:|Set-Cookie:|WWW-Authenticate' \
      | sed "s/^/[$proto] /" >> "$OUTDIR/http_headers.txt"
  done

done < "$OUTDIR/targets.txt"

# ------------------------------------------------------------
section "Detección básica de tecnologías"
# ------------------------------------------------------------
while read -r target; do
  echo "### $target" >> "$OUTDIR/tech_detection.txt"

  curl -k -s --max-time 5 "http://$target" |
    grep -Ei 'wp-content|wp-includes|Drupal|Joomla|ASP.NET|PHP|jsessionid' |
    sort -u >> "$OUTDIR/tech_detection.txt" || true

done < "$OUTDIR/targets.txt"

# ------------------------------------------------------------
section "Métodos HTTP permitidos"
# ------------------------------------------------------------
while read -r target; do
  echo "### $target" >> "$OUTDIR/http_methods.txt"
  curl -k -s -X OPTIONS -I --max-time 5 "http://$target" |
    grep -i Allow >> "$OUTDIR/http_methods.txt" || true
done < "$OUTDIR/targets.txt"

# ------------------------------------------------------------
section "Comprobación de ficheros sensibles comunes"
# ------------------------------------------------------------
COMMON_PATHS=(robots.txt .git/HEAD .env web.config)

while read -r target; do
  for path in "${COMMON_PATHS[@]}"; do
    code=$(curl -k -s -o /dev/null -w "%{http_code}" "http://$target/$path")
    [[ "$code" =~ ^(200|403)$ ]] && echo "$target/$path -> $code" >> "$OUTDIR/sensitive_paths.txt"
  done
done < "$OUTDIR/targets.txt"

# ------------------------------------------------------------
section "Resumen rápido"
# ------------------------------------------------------------
{
  echo "Targets web analizados:"
  wc -l "$OUTDIR/targets.txt"

  echo
  echo "Tecnologías detectadas:"
  [[ -f "$OUTDIR/tech_detection.txt" ]] && grep -v '^###' "$OUTDIR/tech_detection.txt" | sort -u || echo "N/D"
} >> "$OUTDIR/summary.txt"

log "Fingerprinting web finalizado."
log "Revisar summary.txt para visión general."
