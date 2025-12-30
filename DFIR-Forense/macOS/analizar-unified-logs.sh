#!/bin/bash
#
# analizar-unified-logs.sh (macOS)
#
# Descripción:
#   Script DFIR para análisis forense de Unified Logs en macOS.
#   Extrae eventos relevantes de autenticación, sudo, ssh, launchd,
#   ejecución de procesos y eventos de seguridad.
#
# Autor: Raul Renales
# Uso: SOLO LECTURA
#

############################
# CONFIGURACIÓN
############################

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="macos_unified_logs_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/resultados.txt"

# Ventana temporal (ajustable)
TIME_WINDOW="24h"

mkdir -p "${OUTPUT_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[+] macOS DFIR - Análisis de Unified Logs"
echo "[+] Fecha: $(date)"
echo "[+] Host: ${HOSTNAME}"
echo "[+] Ventana temporal: ${TIME_WINDOW}"
echo "========================================"

############################
# FUNCIÓN AUXILIAR
############################

section() {
    echo
    echo "========================================"
    echo "[*] $1"
    echo "========================================"
}

############################
# INFORMACIÓN GENERAL
############################

section "INFORMACIÓN GENERAL DEL LOG"

log config --status 2>/dev/null
log config --mode 2>/dev/null

############################
# AUTENTICACIÓN (loginwindow / securityd)
############################

section "AUTENTICACIÓN (login / securityd)"

log show --style syslog --last "${TIME_WINDOW}" \
  --predicate '(process == "loginwindow" OR process == "securityd")' \
  2>/dev/null | tee "${OUTPUT_DIR}/auth.log"

############################
# SUDO / PRIVILEGIOS
############################

section "USO DE SUDO"

log show --style syslog --last "${TIME_WINDOW}" \
  --predicate 'process == "sudo"' \
  2>/dev/null | tee "${OUTPUT_DIR}/sudo.log"

############################
# SSH (REMOTO)
############################

section "SSH (ACCESO REMOTO)"

log show --style syslog --last "${TIME_WINDOW}" \
  --predicate '(process == "sshd")' \
  2>/dev/null | tee "${OUTPUT_DIR}/ssh.log"

############################
# LAUNCHD (SERVICIOS / PERSISTENCIA)
############################

section "LAUNCHD (SERVICIOS Y AGENTES)"

log show --style syslog --last "${TIME_WINDOW}" \
  --predicate '(process == "launchd")' \
  2>/dev/null | tee "${OUTPUT_DIR}/launchd.log"

############################
# EJECUCIÓN DE PROCESOS
############################

section "EJECUCIÓN DE PROCESOS (exec)"

log show --style syslog --last "${TIME_WINDOW}" \
  --predicate 'eventMessage CONTAINS[c] "exec"' \
  2>/dev/null | tee "${OUTPUT_DIR}/exec.log"

############################
# LOLBINS / BINARIOS COMUNES
############################

section "LOLBINS / BINARIOS COMUNES"

log show --style syslog --last "${TIME_WINDOW}" \
  --predicate 'eventMessage MATCHES "(?i)(osascript|curl|wget|python|perl|ruby|bash|sh|zsh)"' \
  2>/dev/null | tee "${OUTPUT_DIR}/lolbins.log"

############################
# DESCARGAS / QUARANTINE
############################

section "DESCARGAS / QUARANTINE EVENTS"

log show --style syslog --last "${TIME_WINDOW}" \
  --predicate '(process == "syspolicyd" OR process == "trustd")' \
  2>/dev/null | tee "${OUTPUT_DIR}/quarantine.log"

############################
# ERRORES DE SEGURIDAD
############################

section "ERRORES Y ALERTAS DE SEGURIDAD"

log show --style syslog --last "${TIME_WINDOW}" \
  --predicate 'eventType == logEvent AND (eventMessage CONTAINS[c] "denied" OR eventMessage CONTAINS[c] "failed")' \
  2>/dev/null | tee "${OUTPUT_DIR}/security_errors.log"

############################
# RESUMEN RÁPIDO (CONTADORES)
############################

section "RESUMEN RÁPIDO (CONTADORES)"

echo "[+] Autenticación:"
wc -l "${OUTPUT_DIR}/auth.log" 2>/dev/null

echo "[+] Sudo:"
wc -l "${OUTPUT_DIR}/sudo.log" 2>/dev/null

echo "[+] SSH:"
wc -l "${OUTPUT_DIR}/ssh.log" 2>/dev/null

echo "[+] Launchd:"
wc -l "${OUTPUT_DIR}/launchd.log" 2>/dev/null

echo "[+] Exec:"
wc -l "${OUTPUT_DIR}/exec.log" 2>/dev/null

echo "[+] LOLBins:"
wc -l "${OUTPUT_DIR}/lolbins.log" 2>/dev/null

############################
# ÚLTIMOS EVENTOS (VISIÓN RÁPIDA)
############################

section "ÚLTIMOS EVENTOS (VISIÓN RÁPIDA)"

log show --style syslog --last "1h" 2>/dev/null | head -200

############################
# RESUMEN FINAL
############################

section "RESUMEN FINAL"

echo "[+] Evidencias almacenadas en: ${OUTPUT_DIR}"
echo "[+] Script finalizado"

exit 0
