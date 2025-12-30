#!/bin/bash
#
# procesos-sospechosos.sh (macOS)
#
# Descripción:
#   Script DFIR para detección de procesos sospechosos en macOS.
#   Enfocado en malware fileless, LOLBins, rutas anómalas,
#   procesos sin binario y relaciones padre-hijo sospechosas.
#
# Autor: Raul Renales
# Uso: SOLO LECTURA
#

############################
# CONFIGURACIÓN GENERAL
############################

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="macos_procesos_sospechosos_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/resultados.txt"

mkdir -p "${OUTPUT_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[+] macOS DFIR - Análisis de procesos sospechosos"
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
# LISTADO COMPLETO DE PROCESOS
############################

section "LISTADO COMPLETO DE PROCESOS"

ps auxww > "${OUTPUT_DIR}/procesos_completos.txt"
wc -l "${OUTPUT_DIR}/procesos_completos.txt"

############################
# PROCESOS SIN BINARIO ASOCIADO
############################

section "PROCESOS SIN BINARIO (PATH VACÍO)"

ps -axo pid,comm | while read pid comm; do
    if [ "$pid" != "PID" ]; then
        BIN=$(lsof -p "$pid" 2>/dev/null | awk '/ txt / {print $NF; exit}')
        if [ -z "$BIN" ]; then
            echo "[!] PID $pid ($comm) sin binario asociado"
        fi
    fi
done

############################
# PROCESOS DESDE RUTAS ANÓMALAS
############################

section "PROCESOS EJECUTADOS DESDE RUTAS ANÓMALAS"

ps auxww | grep -E "/tmp/|/private/var/tmp/|/Users/Shared|/Library/Caches" | grep -v grep

############################
# LOLBINS EN EJECUCIÓN
############################

section "LOLBINS EN EJECUCIÓN"

LOLBINS_REGEX="osascript|curl|wget|python|python3|perl|ruby|bash|sh|zsh|nc|ncat|openssl"

ps auxww | grep -Ei "$LOLBINS_REGEX" | grep -v grep

############################
# PROCESOS NO FIRMADOS O CON FIRMA INVÁLIDA
############################

section "PROCESOS SIN FIRMA O FIRMA INVÁLIDA"

ps -axo pid,comm | while read pid comm; do
    if [ "$pid" != "PID" ]; then
        BIN=$(lsof -p "$pid" 2>/dev/null | awk '/ txt / {print $NF; exit}')
        if [ -n "$BIN" ] && [ -f "$BIN" ]; then
            codesign -v "$BIN" &>/dev/null
            if [ $? -ne 0 ]; then
                echo "[!] PID $pid ($comm) binario sin firma válida: $BIN"
            fi
        fi
    fi
done

############################
# PROCESOS EJECUTADOS DESDE DIRECTORIOS DE USUARIO
############################

section "PROCESOS EJECUTADOS DESDE HOME DE USUARIO"

ps auxww | grep "/Users/" | grep -v grep

############################
# RELACIONES PADRE-HIJO SOSPECHOSAS
############################

section "RELACIONES PADRE-HIJO SOSPECHOSAS"

# Apps comunes lanzando shells o LOLBins
SUSPICIOUS_PARENTS="Safari|Google Chrome|Firefox|Microsoft Word|Microsoft Excel|Preview"

ps -axo pid,ppid,comm | while read pid ppid comm; do
    if [ "$pid" != "PID" ]; then
        PARENT=$(ps -p "$ppid" -o comm= 2>/dev/null)
        if echo "$comm" | grep -Ei "$LOLBINS_REGEX" >/dev/null && \
           echo "$PARENT" | grep -Ei "$SUSPICIOUS_PARENTS" >/dev/null; then
            echo "[!] Parent-Child sospechoso: $PARENT ($ppid) -> $comm ($pid)"
        fi
    fi
done

############################
# PROCESOS CON CONEXIONES DE RED
############################

section "PROCESOS CON CONEXIONES DE RED ACTIVAS"

lsof -i -n -P | awk '{print $1,$2,$9}' | sort -u

############################
# PROCESOS EJECUTÁNDOSE COMO ROOT DESDE RUTAS NO ESTÁNDAR
############################

section "PROCESOS ROOT DESDE RUTAS NO ESTÁNDAR"

ps auxww | awk '$1=="root"' | grep -E "/Users/|/tmp/|/private/var/tmp"

############################
# RESUMEN EJECUTIVO
############################

section "RESUMEN EJECUTIVO"

echo "[+] Total de procesos:"
ps aux | wc -l

echo "[+] LOLBins detectados:"
ps auxww | grep -Ei "$LOLBINS_REGEX" | grep -v grep | wc -l

echo "[+] Procesos desde rutas anómalas:"
ps auxww | grep -E "/tmp/|/private/var/tmp|/Users/Shared" | grep -v grep | wc -l

############################
# RESUMEN FINAL
############################

section "RESUMEN FINAL"

echo "[+] Evidencias almacenadas en: ${OUTPUT_DIR}"
echo "[+] Script finalizado"

exit 0
