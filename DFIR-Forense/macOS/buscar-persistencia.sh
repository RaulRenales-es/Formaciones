#!/bin/bash
#
# buscar-persistencia.sh (macOS)
#
# Descripción:
#   Script DFIR para detección de mecanismos de persistencia en macOS.
#   Analiza launchd, login items, cron, profiles, kexts, variables de entorno
#   y artefactos comunes usados por malware en macOS.
#
# Autor: Raul Renales
# Uso: SOLO LECTURA
#

############################
# CONFIGURACIÓN GENERAL
############################

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="macos_persistencia_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/resultados.txt"

mkdir -p "${OUTPUT_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[+] macOS DFIR - Búsqueda de persistencia"
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
# LAUNCHAGENTS / LAUNCHDAEMONS
############################

section "LAUNCHAGENTS / LAUNCHDAEMONS"

LAUNCH_PATHS=(
    "/Library/LaunchDaemons"
    "/Library/LaunchAgents"
    "/System/Library/LaunchDaemons"
    "/System/Library/LaunchAgents"
)

for path in "${LAUNCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "[+] Contenido de $path"
        ls -la "$path"
        echo
    fi
done

############################
# LAUNCHAGENTS POR USUARIO
############################

section "LAUNCHAGENTS POR USUARIO"

for home in /Users/*; do
    if [ -d "$home/Library/LaunchAgents" ]; then
        echo "[+] $home/Library/LaunchAgents"
        ls -la "$home/Library/LaunchAgents"
        echo
    fi
done

############################
# LOGIN ITEMS (USUARIOS)
############################

section "LOGIN ITEMS (LoginWindow)"

for user in $(dscl . list /Users | grep -v "^_"); do
    USER_HOME=$(dscl . -read /Users/"$user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    if [ -d "$USER_HOME" ]; then
        echo "[+] Login Items para usuario: $user"
        defaults read "$USER_HOME/Library/Preferences/com.apple.loginitems.plist" 2>/dev/null
        echo
    fi
done

############################
# CRON / AT / PERIODIC
############################

section "CRON / AT / PERIODIC"

echo "[+] /etc/crontab"
cat /etc/crontab 2>/dev/null
echo

echo "[+] Cron por usuario"
for user in $(dscl . list /Users | grep -v "^_"); do
    crontab -u "$user" -l 2>/dev/null && echo
done

echo "[+] Periodic"
ls -la /etc/periodic 2>/dev/null

############################
# PROFILES / MDM
############################

section "PROFILES / MDM"

profiles list 2>/dev/null
profiles status -type enrollment 2>/dev/null

############################
# KEXTS (EXTENSIONES DE KERNEL)
############################

section "KERNEL EXTENSIONS (KEXTS)"

kextstat 2>/dev/null | grep -v com.apple

############################
# TCC (PRIVACIDAD / FULL DISK ACCESS)
############################

section "TCC DATABASE (ACCESOS SENSIBLES)"

for home in /Users/*; do
    TCC_DB="$home/Library/Application Support/com.apple.TCC/TCC.db"
    if [ -f "$TCC_DB" ]; then
        echo "[+] $TCC_DB"
        sqlite3 "$TCC_DB" "select service, client, auth_value from access;" 2>/dev/null
        echo
    fi
done

############################
# VARIABLES DE ENTORNO PELIGROSAS
############################

section "VARIABLES DE ENTORNO PELIGROSAS"

ENV_FILES=(
    "/etc/profile"
    "/etc/zshrc"
    "/etc/bashrc"
    "/etc/launchd.conf"
)

for env in "${ENV_FILES[@]}"; do
    if [ -f "$env" ]; then
        echo "[+] $env"
        grep -Ei "DYLD_|PATH=|LD_" "$env"
        echo
    fi
done

############################
# PLIST SOSPECHOSOS (RUTAS COMUNES)
############################

section "PLIST SOSPECHOSOS (RUTAS NO ESTÁNDAR)"

find /Users /Library /private/var -name "*.plist" 2>/dev/null | \
grep -Ei "tmp|cache|update|agent|daemon" | head -100

############################
# BINARIOS EN RUTAS ANÓMALAS
############################

section "BINARIOS EN RUTAS ANÓMALAS"

SUSPICIOUS_DIRS=(
    "/tmp"
    "/private/var/tmp"
    "/Users/Shared"
)

for dir in "${SUSPICIOUS_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "[+] Ejecutables en $dir"
        find "$dir" -type f -perm +111 -exec ls -la {} \; 2>/dev/null
        echo
    fi
done

############################
# SERVICIOS LAUNCHD ACTIVOS
############################

section "SERVICIOS LAUNCHD ACTIVOS"

launchctl list

############################
# RESUMEN FINAL
############################

section "RESUMEN FINAL"

echo "[+] Directorio de evidencias: ${OUTPUT_DIR}"
echo "[+] Script finalizado"

exit 0
