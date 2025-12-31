#!/usr/bin/env bash
# ------------------------------------------------------------
# Script: webshell_detector.sh
# Autor: Raul Renales
# Formación y cursos: https://raulrenales.es
#
# Descripción:
#   Detector heurístico de webshells (PHP / ASPX / JSP)
#   mediante patrones comunes, permisos anómalos y fechas.
#
# Uso:
#   Exclusivamente educativo y en entornos autorizados.
#
# Ejemplo:
#   sudo ./webshell_detector.sh /var/www
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

TARGET_DIR="${1:-/var/www}"
OUTDIR="webshell_detector_$(hostname)_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

log() { echo "[*] $1"; }
warn() { echo "[!] $1"; }

log "Analizando: $TARGET_DIR"
log "Resultados en: $OUTDIR"

# ------------------------------------------------------------
# Patrones sospechosos (heurísticos)
# ------------------------------------------------------------
PHP_PATTERNS=(
  "system\("
  "exec\("
  "shell_exec\("
  "passthru\("
  "popen\("
  "proc_open\("
  "base64_decode\("
  "eval\("
  "assert\("
)

ASPX_PATTERNS=(
  "System\.Diagnostics\.Process"
  "ProcessStartInfo"
  "cmd\.exe"
  "powershell\.exe"
)

JSP_PATTERNS=(
  "Runtime\.getRuntime\(\)"
  "ProcessBuilder"
)

# ------------------------------------------------------------
# Búsqueda por extensión
# ------------------------------------------------------------
EXTENSIONS="php|phtml|php5|aspx|jsp"

# ------------------------------------------------------------
# Escaneo de contenido
# ------------------------------------------------------------
log "Buscando patrones sospechosos..."
{
  echo "=== PHP ==="
  for p in "${PHP_PATTERNS[@]}"; do
    grep -RniE --include="*.php*" "$p" "$TARGET_DIR" 2>/dev/null || true
  done

  echo
  echo "=== ASPX ==="
  for p in "${ASPX_PATTERNS[@]}"; do
    grep -RniE --include="*.aspx" "$p" "$TARGET_DIR" 2>/dev/null || true
  done

  echo
  echo "=== JSP ==="
  for p in "${JSP_PATTERNS[@]}"; do
    grep -RniE --include="*.jsp" "$p" "$TARGET_DIR" 2>/dev/null || true
  done
} > "$OUTDIR/pattern_matches.txt"

# ------------------------------------------------------------
# Archivos web recientes (últimos 7 días)
# ------------------------------------------------------------
log "Buscando archivos web recientes (7 días)..."
find "$TARGET_DIR" -type f -regextype posix-extended -regex ".*\.($EXTENSIONS)$" \
  -mtime -7 -ls > "$OUTDIR/recent_web_files.txt" 2>/dev/null || true

# ------------------------------------------------------------
# Permisos sospechosos
# ------------------------------------------------------------
log "Buscando permisos sospechosos (writable por todos)..."
find "$TARGET_DIR" -type f -regextype posix-extended -regex ".*\.($EXTENSIONS)$" \
  -perm -0002 -ls > "$OUTDIR/world_writable.txt" 2>/dev/null || true

# ------------------------------------------------------------
# Nombres de archivo comunes en webshells
# ------------------------------------------------------------
log "Buscando nombres de archivo sospechosos..."
SUS_NAMES="shell|cmd|backdoor|upload|ws|console|adminer|filemanager"
find "$TARGET_DIR" -type f -regextype posix-extended \
  -regex ".*\.($EXTENSIONS)$" | grep -Ei "$SUS_NAMES" \
  > "$OUTDIR/suspicious_names.txt" 2>/dev/null || true

# ------------------------------------------------------------
# Resumen
# ------------------------------------------------------------
{
  echo "Directorio analizado: $TARGET_DIR"
  echo
  echo "Coincidencias por patrones:"
  wc -l "$OUTDIR/pattern_matches.txt"
  echo
  echo "Archivos recientes:"
  wc -l "$OUTDIR/recent_web_files.txt"
  echo
  echo "Archivos world-writable:"
  wc -l "$OUTDIR/world_writable.txt"
  echo
  echo "Nombres sospechosos:"
  wc -l "$OUTDIR/suspicious_names.txt"
} > "$OUTDIR/summary.txt"

log "Detección finalizada."
log "Revisar summary.txt para visión general."
