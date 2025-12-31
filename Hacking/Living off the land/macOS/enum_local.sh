#!/usr/bin/env bash
# ------------------------------------------------------------
# enum_local.sh (macOS)
# Enumeración local ética – Living off the Land
# Autor: RaulRenales.es
# Uso exclusivo: auditorías autorizadas / formación
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="enum_${HOSTNAME}_${TIMESTAMP}"

mkdir -p "$OUTPUT_DIR"

section() {
  echo -e "\n===================="
  echo "$1"
  echo "===================="
}

# ------------------------------------------------------------
section "Información del sistema"
# ------------------------------------------------------------
{
  sw_vers
  echo
  uname -a
  echo
  system_profiler SPSoftwareDataType
} > "$OUTPUT_DIR/system_info.txt"

# ------------------------------------------------------------
section "Usuarios locales"
# ------------------------------------------------------------
{
  dscl . list /Users
  echo
  echo "[Usuarios con UID < 500]"
  dscl . list /Users UniqueID | awk '$2 < 500 {print $1, $2}'
} > "$OUTPUT_DIR/users.txt"

# ------------------------------------------------------------
section "Grupos locales"
# ------------------------------------------------------------
{
  dscl . list /Groups
} > "$OUTPUT_DIR/groups.txt"

# ------------------------------------------------------------
section "Usuarios administradores"
# ------------------------------------------------------------
{
  dscl . read /Groups/admin GroupMembership
} > "$OUTPUT_DIR/admin_users.txt"

# ------------------------------------------------------------
section "Sesiones activas"
# ------------------------------------------------------------
{
  who
  echo
  w
} > "$OUTPUT_DIR/sessions.txt"

# ------------------------------------------------------------
section "Procesos en ejecución"
# ------------------------------------------------------------
{
  ps aux
} > "$OUTPUT_DIR/processes.txt"

# ------------------------------------------------------------
section "Servicios launchd (persistencia)"
# ------------------------------------------------------------
{
  echo "[LaunchAgents]"
  ls -la /Library/LaunchAgents
  ls -la ~/Library/LaunchAgents 2>/dev/null || true
  echo
  echo "[LaunchDaemons]"
  ls -la /Library/LaunchDaemons
} > "$OUTPUT_DIR/launchd_persistence.txt"

# ------------------------------------------------------------
section "Tareas programadas (cron)"
# ------------------------------------------------------------
{
  crontab -l 2>/dev/null || echo "Sin cron para el usuario actual"
  echo
  echo "[/etc/crontab]"
  [ -f /etc/crontab ] && cat /etc/crontab
} > "$OUTPUT_DIR/cron_jobs.txt"

# ------------------------------------------------------------
section "Interfaces de red"
# ------------------------------------------------------------
{
  ifconfig
  echo
  netstat -rn
} > "$OUTPUT_DIR/network_interfaces.txt"

# ------------------------------------------------------------
section "Puertos en escucha"
# ------------------------------------------------------------
{
  lsof -iTCP -sTCP:LISTEN -n -P
} > "$OUTPUT_DIR/listening_ports.txt"

# ------------------------------------------------------------
section "Conexiones de red activas"
# ------------------------------------------------------------
{
  netstat -anv | grep ESTABLISHED
} > "$OUTPUT_DIR/active_connections.txt"

# ------------------------------------------------------------
section "Tabla ARP"
# ------------------------------------------------------------
{
  arp -a
} > "$OUTPUT_DIR/arp_table.txt"

# ------------------------------------------------------------
section "Sockets UNIX"
# ------------------------------------------------------------
{
  lsof -U
} > "$OUTPUT_DIR/unix_sockets.txt"

# ------------------------------------------------------------
section "Discos y volúmenes"
# ------------------------------------------------------------
{
  diskutil list
  echo
  df -h
} > "$OUTPUT_DIR/disks.txt"

# ------------------------------------------------------------
section "Variables de entorno"
# ------------------------------------------------------------
{
  env
} > "$OUTPUT_DIR/environment.txt"

# ------------------------------------------------------------
section "Eventos recientes (Unified Logs – 24h)"
# ------------------------------------------------------------
{
  log show --last 24h --style compact | head -n 5000
} > "$OUTPUT_DIR/unified_logs_sample.txt"

# ------------------------------------------------------------
section "Resumen"
# ------------------------------------------------------------
{
  echo "Enumeración local macOS completada."
  echo
  echo "Directorio de salida:"
  echo "$OUTPUT_DIR"
  echo
  echo "Notas:"
  echo "- Enumeración pasiva"
  echo "- Living off the Land"
  echo "- Sin modificación del sistema"
} > "$OUTPUT_DIR/summary.txt"

echo "[+] Enumeración macOS finalizada. Resultados en: $OUTPUT_DIR"
