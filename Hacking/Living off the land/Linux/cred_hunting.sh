#!/usr/bin/env bash
# ------------------------------------------------------------
# cred_hunting.sh
# Hunting PASIVO de credenciales en texto plano (LotL)
# Autor: RaulRenales.es
# Uso exclusivo: auditorías autorizadas / formación
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

OUTPUT_DIR="cred_hunting_$(hostname)_$(date +%Y%m%d_%H%M%S)"
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
section "Historiales de shell"
# ------------------------------------------------------------
{
  for u in $(cut -d: -f1 /etc/passwd); do
    for f in ".bash_history" ".zsh_history" ".sh_history"; do
      HIST_FILE="/home/$u/$f"
      if [ -f "$HIST_FILE" ]; then
        echo "[Usuario: $u | Archivo: $HIST_FILE]"
        grep -Ei "pass|password|passwd|token|secret|apikey|api_key" "$HIST_FILE" || true
        echo
      fi
    done
  done

  # root
  if [ -f /root/.bash_history ]; then
    echo "[Usuario: root | /root/.bash_history]"
    grep -Ei "pass|password|passwd|token|secret|apikey|api_key" /root/.bash_history || true
  fi
} > "$OUTPUT_DIR/shell_history_hits.txt"

# ------------------------------------------------------------
section "Archivos de configuración comunes"
# ------------------------------------------------------------
{
  TARGET_DIRS=(
    "/etc"
    "/opt"
    "/srv"
    "/var/www"
    "/var/lib"
    "/home"
  )

  for d in "${TARGET_DIRS[@]}"; do
    [ -d "$d" ] || continue
    echo "[Directorio: $d]"
    grep -RIE \
      --exclude-dir={proc,sys,dev,run,tmp} \
      --exclude=*.log \
      --exclude=*.bin \
      "password\s*=|passwd\s*=|secret\s*=|token\s*=|api[_-]?key\s*=" \
      "$d" 2>/dev/null || true
    echo
  done
} > "$OUTPUT_DIR/config_files_hits.txt"

# ------------------------------------------------------------
section "Archivos .env y similares"
# ------------------------------------------------------------
{
  find / -type f \( -name ".env" -o -name "*.env" -o -name ".env.*" \) 2>/dev/null | while read -r f; do
    echo "[Archivo: $f]"
    grep -Ei "pass|password|secret|token|apikey|api_key" "$f" || true
    echo
  done
} > "$OUTPUT_DIR/env_files_hits.txt"

# ------------------------------------------------------------
section "Scripts con credenciales embebidas"
# ------------------------------------------------------------
{
  find / -type f \( -name "*.sh" -o -name "*.py" -o -name "*.php" -o -name "*.js" \) 2>/dev/null | while read -r f; do
    grep -qEi "password|passwd|secret|token|apikey|api_key" "$f" && {
      echo "[Script sospechoso: $f]"
      grep -Ei "password|passwd|secret|token|apikey|api_key" "$f"
      echo
    }
  done
} > "$OUTPUT_DIR/scripts_hits.txt"

# ------------------------------------------------------------
section "Permisos débiles en archivos sensibles"
# ------------------------------------------------------------
{
  find / -type f \
    \( -name "*.env" -o -name "*.conf" -o -name "*.cfg" -o -name "*.ini" \) \
    -perm -002 2>/dev/null | while read -r f; do
      echo "[Archivo world-writable: $f]"
      ls -l "$f"
    done
} > "$OUTPUT_DIR/weak_permissions.txt"

# ------------------------------------------------------------
section "Resumen"
# ------------------------------------------------------------
{
  echo "Hunting pasivo de credenciales completado."
  echo
  echo "Revisar manualmente los siguientes ficheros:"
  ls -1 "$OUTPUT_DIR"
  echo
  echo "NOTA:"
  echo "- No se han extraído hashes"
  echo "- No se ha accedido a memoria"
  echo "- No se han usado exploits"
} > "$OUTPUT_DIR/summary.txt"

log "Cred hunting finalizado. Resultados en: $OUTPUT_DIR"
