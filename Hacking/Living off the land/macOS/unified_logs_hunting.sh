#!/usr/bin/env bash
# ------------------------------------------------------------
# unified_logs_hunting.sh
# Threat Hunting en Unified Logs (macOS) – Living off the Land
# Autor: RaulRenales.es
# Uso exclusivo: auditorías autorizadas / formación
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="unified_logs_${HOSTNAME}_${TIMESTAMP}"

mkdir -p "$OUTPUT_DIR"

section() {
  echo -e "\n===================="
  echo "$1"
  echo "===================="
}

# Ventana temporal (ajustable)
TIME_WINDOW="--last 24h"

# ------------------------------------------------------------
section "Ejecución de shells y comandos"
# ------------------------------------------------------------
{
  log show $TIME_WINDOW \
    --predicate 'process CONTAINS[c] "bash" OR process CONTAINS[c] "zsh" OR process CONTAINS[c] "sh"' \
    --style compact
} > "$OUTPUT_DIR/shell_execution.txt"

# ------------------------------------------------------------
section "Uso de launchctl (persistencia)"
# ------------------------------------------------------------
{
  log show $TIME_WINDOW \
    --predicate 'eventMessage CONTAINS[c] "launchctl"' \
    --style compact
} > "$OUTPUT_DIR/launchctl_activity.txt"

# ------------------------------------------------------------
section "Creación o carga de LaunchAgents / Daemons"
# ------------------------------------------------------------
{
  log show $TIME_WINDOW \
    --predicate 'eventMessage CONTAINS[c] "LaunchAgent" OR eventMessage CONTAINS[c] "LaunchDaemon"' \
    --style compact
} > "$OUTPUT_DIR/launchd_persistence.txt"

# ------------------------------------------------------------
section "Descargas y transferencias (curl / wget)"
# ------------------------------------------------------------
{
  log show $TIME_WINDOW \
    --predicate 'process CONTAINS[c] "curl" OR process CONTAINS[c] "wget"' \
    --style compact
} > "$OUTPUT_DIR/network_tools.txt"

# ------------------------------------------------------------
section "Ejecución de AppleScript / osascript"
# ------------------------------------------------------------
{
  log show $TIME_WINDOW \
    --predicate 'process CONTAINS[c] "osascript"' \
    --style compact
} > "$OUTPUT_DIR/applescript_execution.txt"

# ------------------------------------------------------------
section "Acceso a Keychain"
# ------------------------------------------------------------
{
  log show $TIME_WINDOW \
    --predicate 'process CONTAINS[c] "security" OR eventMessage CONTAINS[c] "keychain"' \
    --style compact
} > "$OUTPUT_DIR/keychain_access.txt"

# ------------------------------------------------------------
section "Creación o modificación de usuarios"
# ------------------------------------------------------------
{
  log show $TIME_WINDOW \
    --predicate 'eventMessage CONTAINS[c] "dscl" OR eventMessage CONTAINS[c] "useradd"' \
    --style compact
} > "$OUTPUT_DIR/user_management.txt"

# ------------------------------------------------------------
section "Ejecución desde ubicaciones sospechosas"
# ------------------------------------------------------------
{
  log show $TIME_WINDOW \
    --predicate 'eventMessage CONTAINS[c] "/tmp/" OR eventMessage CONTAINS[c] "/private/tmp/" OR eventMessage CONTAINS[c] "/Users/Shared/"' \
    --style compact
} > "$OUTPUT_DIR/suspicious_paths.txt"

# ------------------------------------------------------------
section "Borrado o manipulación de logs (anti-forense)"
# ------------------------------------------------------------
{
  log show $TIME_WINDOW \
    --predicate 'eventMessage CONTAINS[c] "log erase" OR eventMessage CONTAINS[c] "log collect"' \
    --style compact
} > "$OUTPUT_DIR/log_tampering.txt"

# ------------------------------------------------------------
section "Errores de ejecución repetitivos"
# ------------------------------------------------------------
{
  log show $TIME_WINDOW \
    --predicate 'eventType == logEvent AND eventMessage CONTAINS[c] "error"' \
    --style compact | head -n 5000
} > "$OUTPUT_DIR/repeated_errors.txt"

# ------------------------------------------------------------
section "Resumen"
# ------------------------------------------------------------
{
  echo "Unified Logs Hunting completado correctamente."
  echo
  echo "Ventana temporal: últimas 24 horas"
  echo "Directorio de salida:"
  echo "$OUTPUT_DIR"
  echo
  echo "Notas:"
  echo "- Análisis pasivo"
  echo "- Sin borrado ni alteración de logs"
  echo "- Living off the Land"
} > "$OUTPUT_DIR/summary.txt"

echo "[+] Unified Logs hunting finalizado. Resultados en: $OUTPUT_DIR"
