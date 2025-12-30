#!/bin/bash
#
# analizar-authlog.sh
# Autor: Raul Renales
# Descripción:
#   Script DFIR para análisis forense de logs de autenticación en Linux.
#   Compatible con Debian/Ubuntu (/var/log/auth.log)
#   y RedHat/CentOS (/var/log/secure).
#
# Advertencia:
#   Script de solo lectura. No modifica el sistema.
#

############################
# CONFIGURACIÓN GENERAL
############################

OUTPUT_DIR="authlog_$(hostname)_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$OUTPUT_DIR/resultados.txt"

AUTH_LOG=""

mkdir -p "$OUTPUT_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

############################
# DETECCIÓN DE LOG
############################

if [ -f /var/log/auth.log ]; then
    AUTH_LOG="/var/log/auth.log"
elif [ -f /var/log/secure ]; then
    AUTH_LOG="/var/log/secure"
else
    echo "[!] No se encontró auth.log ni secure"
    exit 1
fi

echo "[+] Analizando log: $AUTH_LOG"
echo "[+] Fecha: $(date)"
echo "[+] Hostname: $(hostname)"
echo "========================================"

############################
# FUNCIÓN AUXILIAR
############################

seccion() {
    echo
    echo "========================================"
    echo "[*] $1"
    echo "========================================"
}

############################
# RESUMEN GENERAL
############################

seccion "RESUMEN GENERAL"

echo "[+] Total de eventos:"
wc -l "$AUTH_LOG"

############################
# LOGINS SSH FALLIDOS
############################

seccion "INTENTOS FALLIDOS SSH"

grep -Ei "Failed password|authentication failure" "$AUTH_LOG" | tee "$OUTPUT_DIR/ssh_fallidos.txt"

############################
# FUERZA BRUTA (TOP IPs)
############################

seccion "TOP IPs CON INTENTOS FALLIDOS"

grep -Ei "Failed password" "$AUTH_LOG" \
| awk '{print $(NF-3)}' \
| sort | uniq -c | sort -nr | head -20

############################
# LOGINS SSH EXITOSOS
############################

seccion "LOGINS SSH EXITOSOS"

grep -Ei "Accepted password|Accepted publickey" "$AUTH_LOG" | tee "$OUTPUT_DIR/ssh_exitosos.txt"

############################
# LOGINS DE ROOT
############################

seccion "LOGINS DE ROOT"

grep -Ei "Accepted.*root" "$AUTH_LOG"

############################
# USO DE SUDO
############################

seccion "USO DE SUDO"

grep -Ei "sudo:" "$AUTH_LOG" | tee "$OUTPUT_DIR/sudo.txt"

############################
# INTENTOS FALLIDOS DE SUDO
############################

seccion "
