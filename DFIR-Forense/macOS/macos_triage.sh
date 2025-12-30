#!/bin/bash
#
# macos_triage.sh
#
# Descripción:
#   Script DFIR para triage forense inicial en sistemas macOS.
#   Obtiene una visión rápida del estado del sistema sin modificarlo.
#
# Autor: Raul Renales
# Uso: SOLO LECTURA
#

############################
# CONFIGURACIÓN GENERAL
############################

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="macos_triage_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/resultados.txt"

mkdir -p "${OUTPUT_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[+] macOS DFIR Triage iniciado"
echo "[+] Fecha: $(date)"
echo "[+] Host: ${HOSTNAME}"
echo "[+] Usuario: $(whoami)"
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
# INFORMACIÓN DEL SISTEMA
############################

section "INFORMACIÓN DEL SISTEMA"

sw_vers
uname -a
uptime
sysctl kern.boottime

############################
# SIP / GATEKEEPER
############################

section "SEGURIDAD DEL SISTEMA (SIP / GATEKEEPER)"

csrutil status 2>/dev/null
spctl --status 2>/dev/null

############################
# USUARIOS CONECTADOS
############################

section "USUARIOS CONECTADOS"

who
w

############################
# USUARIOS LOCALES
############################

section "USUARIOS LOCALES"

dscl . list /Users | grep -v "^_"

############################
# PROCESOS ACTIVOS
############################

section "PROCESOS ACTIVOS"

ps auxww

############################
# PROCESOS SOSPECHOSOS (RUTAS ANÓMALAS)
############################

section "PROCESOS EN RUTAS ANÓMALAS"

ps auxww | grep -E "/tmp/|/private/var/tmp/|/Users/.*/Library" | grep -v grep

############################
# SERVICIOS LAUNCHD
############################

section "SERVICIOS LAUNCHD (LOADED)"

launchctl list

############################
# CONEXIONES DE RED
############################

section "CONEXIONES DE RED"

netstat -anv
lsof -i -n -P

############################
# INTERFACES Y RUTAS
############################

section "INTERFACES Y RUTAS DE RED"

ifconfig
route -n get default 2>/dev/null

############################
# DNS Y PROXY
############################

section "DNS Y PROXY"

scutil --dns
scutil --proxy

############################
# VOLUMENES Y DISCOS
############################

section "DISCOS Y VOLUMENES"

diskutil list
mount

############################
# APLICACIONES RECIENTES
############################

section "APLICACIONES EJECUTADAS RECIENTEMENTE"

ls -lt /Applications 2>/dev/null | head -20

############################
# DESCARGAS RECIENTES
############################

section "DESCARGAS RECIENTES"

for home in /Users/*; do
    if [ -d "${home}/Downloads" ]; then
        echo "[+] ${home}/Downloads"
        ls -lt "${home}/Downloads" | head -20
        echo
    fi
done

############################
# HISTORIAL BÁSICO (bash/zsh)
############################

section "HISTORIAL DE COMANDOS (BÁSICO)"

for home in /Users/*; do
    if [ -f "${home}/.bash_history" ]; then
        echo "[+] ${home}/.bash_history"
        tail -50 "${home}/.bash_history"
        echo
    fi
    if [ -f "${home}/.zsh_history" ]; then
        echo "[+] ${home}/.zsh_history"
        tail -50 "${home}/.zsh_history"
        echo
    fi
done

############################
# LOGS UNIFICADOS (RESUMEN)
############################

section "UNIFIED LOGS (RESUMEN RECIENTE)"

log show --style syslog --last 1h --predicate 'eventType == logEvent' 2>/dev/null | head -200

############################
# RESUMEN FINAL
############################

section "RESUMEN FINAL"

echo "[+] Directorio de evidencias: ${OUTPUT_DIR}"
echo "[+] Script finalizado"

exit 0
