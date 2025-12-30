#!/usr/bin/env bash
# ------------------------------------------------------------
# enum_local.sh
# Enumeración local ética basada en Living off the Land (LotL)
# Autor: RaulRenales.es
# Uso exclusivo: auditorías autorizadas / formación
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

OUTPUT_DIR="enum_$(hostname)_$(date +%Y%m%d_%H%M%S)"
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
section "Información del sistema"
# ------------------------------------------------------------
{
  uname -a
  echo
  echo "Hostname: $(hostname)"
  echo "Fecha: $(date)"
  echo
  echo "Distribución:"
  [ -f /etc/os-release ] && cat /etc/os-release
} > "$OUTPUT_DIR/system_info.txt"

# ------------------------------------------------------------
section "Usuarios y grupos"
# ------------------------------------------------------------
{
  echo "[Usuarios]"
  cut -d: -f1,3,4 /etc/passwd
  echo
  echo "[Grupos]"
  cut -d: -f1,3 /etc/group
  echo
  echo "[Usuarios con UID 0]"
  awk -F: '($3 == 0) {print $1}' /etc/passwd
} > "$OUTPUT_DIR/users_groups.txt"

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
section "Servicios y puertos en escucha"
# ------------------------------------------------------------
{
  if command -v ss >/dev/null 2>&1; then
    ss -tulpan
  else
    netstat -tulpan
  fi
} > "$OUTPUT_DIR/network_listening.txt"

# ------------------------------------------------------------
section "Conexiones de red establecidas"
# ------------------------------------------------------------
{
  if command -v ss >/dev/null 2>&1; then
    ss -tanp
  else
    netstat -tanp
  fi
} > "$OUTPUT_DIR/network_connections.txt"

# ------------------------------------------------------------
section "Interfaces de red"
# ------------------------------------------------------------
{
  ip addr show
  echo
  ip route show
} > "$OUTPUT_DIR/network_interfaces.txt"

# ------------------------------------------------------------
section "Tareas programadas (cron)"
# ------------------------------------------------------------
{
  echo "[/etc/crontab]"
  [ -f /etc/crontab ] && cat /etc/crontab
  echo
  echo "[/etc/cron.d]"
  ls -la /etc/cron.d 2>/dev/null
  echo
  echo "[Cron por usuario]"
  for u in $(cut -f1 -d: /etc/passwd); do
    crontab -l -u "$u" 2>/dev/null && echo "--- $u ---"
  done
} > "$OUTPUT_DIR/cron_jobs.txt"

# ------------------------------------------------------------
section "Archivos SUID / SGID"
# ------------------------------------------------------------
{
  find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} \; 2>/dev/null
} > "$OUTPUT_DIR/suid_sgid_files.txt"

# ------------------------------------------------------------
section "Capacidades Linux (setcap)"
# ------------------------------------------------------------
{
  if command -v getcap >/dev/null 2>&1; then
    getcap -r / 2>/dev/null
  else
    echo "getcap no disponible"
  fi
} > "$OUTPUT_DIR/capabilities.txt"

# ------------------------------------------------------------
section "Archivos modificados recientemente (24h)"
# ------------------------------------------------------------
{
  find /etc /usr /bin /sbin -type f -mtime -1 2>/dev/null
} > "$OUTPUT_DIR/recent_files.txt"

# ------------------------------------------------------------
section "Variables de entorno"
# ------------------------------------------------------------
{
  env
} > "$OUTPUT_DIR/environment.txt"

# ------------------------------------------------------------
section "Resumen"
# ------------------------------------------------------------
{
  echo "Enumeración local completada correctamente."
  echo "Directorio de salida: $OUTPUT_DIR"
} > "$OUTPUT_DIR/summary.txt"

log "Enumeración finalizada. Resultados almacenados en: $OUTPUT_DIR"
