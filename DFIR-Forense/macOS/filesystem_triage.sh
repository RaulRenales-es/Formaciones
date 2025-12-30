#!/bin/bash
#
# filesystem_triage.sh (macOS)
#
# Descripción:
#   Script DFIR para análisis forense del sistema de ficheros en macOS.
#   Recopila artefactos clave: descargas, cuarentena, xattrs,
#   aplicaciones recientes, LaunchAgents timestamps, ficheros sospechosos
#   y modificaciones recientes.
#
# Autor: Raul Renales
# Uso: SOLO LECTURA
#

############################
# CONFIGURACIÓN GENERAL
############################

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="macos_filesystem_triage_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/resultados.txt"

mkdir -p "${OUTPUT_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[+] macOS DFIR - Filesystem Triage"
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
# INFORMACIÓN GENERAL DEL FS
############################

section "INFORMACIÓN GENERAL DEL SISTEMA DE FICHEROS"

df -h
mount

############################
# MODIFICACIONES RECIENTES (GLOBAL)
############################

section "FICHEROS MODIFICADOS RECIENTEMENTE (ÚLTIMOS 7 DÍAS)"

find / -xdev -mtime -7 2>/dev/null | head -200

############################
# DESCARGAS RECIENTES
############################

section "DESCARGAS RECIENTES"

for home in /Users/*; do
    if [ -d "$home/Downloads" ]; then
        echo "[+] $home/Downloads"
        ls -lt "$home/Downloads" | head -30
        echo
    fi
done

############################
# ATRIBUTOS EXTENDIDOS (QUARANTINE)
############################

section "ARCHIVOS CON ATRIBUTO QUARANTINE"

for home in /Users/*; do
    if [ -d "$home" ]; then
        xattr -rl "$home" 2>/dev/null | grep -B1 "com.apple.quarantine" | head -100
    fi
done

############################
# BASE DE DATOS QUARANTINE (LSQUARANTINE)
############################

section "BASE DE DATOS QUARANTINE (LSQuarantine)"

for home in /Users/*; do
    DB="$home/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2"
    if [ -f "$DB" ]; then
        echo "[+] $DB"
        sqlite3 "$DB" \
          "select datetime(LSQuarantineTimeStamp + 978307200,'unixepoch'),
                  LSQuarantineAgentName,
                  LSQuarantineDataURLString,
                  LSQuarantineOriginURLString
           from LSQuarantineEvent
           order by LSQuarantineTimeStamp desc
           limit 20;" 2>/dev/null
        echo
    fi
done

############################
# APLICACIONES INSTALADAS / MODIFICADAS
############################

section "APLICACIONES MODIFICADAS RECIENTEMENTE"

ls -lt /Applications 2>/dev/null | head -30

############################
# EJECUTABLES EN RUTAS ANÓMALAS
############################

section "EJECUTABLES EN RUTAS ANÓMALAS"

SUSPICIOUS_DIRS=(
    "/tmp"
    "/private/var/tmp"
    "/Users/Shared"
    "/Library/Caches"
)

for dir in "${SUSPICIOUS_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "[+] Ejecutables en $dir"
        find "$dir" -type f -perm +111 -exec ls -la {} \; 2>/dev/null | head -50
        echo
    fi
done

############################
# LAUNCHAGENTS / DAEMONS - TIMESTAMPS
############################

section "TIMESTAMPS DE LAUNCHAGENTS / LAUNCHDAEMONS"

LAUNCH_PATHS=(
    "/Library/LaunchDaemons"
    "/Library/LaunchAgents"
    "/System/Library/LaunchDaemons"
    "/System/Library/LaunchAgents"
)

for path in "${LAUNCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "[+] $path"
        ls -lt "$path" | head -30
        echo
    fi
done

############################
# HISTÓRICO DE COMANDOS
############################

section "HISTÓRICO DE COMANDOS (bash / zsh)"

for home in /Users/*; do
    if [ -f "$home/.bash_history" ]; then
        echo "[+] $home/.bash_history"
        tail -50 "$home/.bash_history"
        echo
    fi
    if [ -f "$home/.zsh_history" ]; then
        echo "[+] $home/.zsh_history"
        tail -50 "$home/.zsh_history"
        echo
    fi
done

############################
# FICHEROS OCULTOS SOSPECHOSOS
############################

section "FICHEROS OCULTOS SOSPECHOSOS EN HOME"

for home in /Users/*; do
    if [ -d "$home" ]; then
        find "$home" -maxdepth 2 -name ".*" -type f 2>/dev/null | head -50
        echo
    fi
done

############################
# RESUMEN EJECUTIVO
############################

section "RESUMEN EJECUTIVO"

echo "[+] Sistemas de ficheros:"
df -h | wc -l

echo "[+] Descargas recientes:"
find /Users -type d -name Downloads -exec ls -lt {} \; 2>/dev/null | wc -l

echo "[+] Ejecutables en rutas anómalas:"
find /tmp /private/var/tmp /Users/Shared -type f -perm +111 2>/dev/null | wc -l

############################
# RESUMEN FINAL
############################

section "RESUMEN FINAL"

echo "[+] Evidencias almacenadas en: ${OUTPUT_DIR}"
echo "[+] Script finalizado"

exit 0
