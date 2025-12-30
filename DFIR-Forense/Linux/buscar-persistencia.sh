#!/bin/bash
#
# buscar-persistencia.sh
# Autor: Raul Renales
# Descripción:
#   Script DFIR para la detección de mecanismos de persistencia en sistemas Linux.
#   Diseñado para respuesta a incidentes y análisis forense en vivo.
#
# Advertencia:
#   Ejecutar preferiblemente en modo solo lectura.
#   El script NO modifica el sistema.
#

############################
# CONFIGURACIÓN GENERAL
############################

OUTPUT_DIR="persistencia_$(hostname)_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$OUTPUT_DIR/resultados.txt"

mkdir -p "$OUTPUT_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "[+] Iniciando búsqueda de persistencia"
echo "[+] Fecha: $(date)"
echo "[+] Hostname: $(hostname)"
echo "[+] Usuario: $(whoami)"
echo "========================================"

############################
# FUNCIONES AUXILIARES
############################

seccion() {
    echo
    echo "========================================"
    echo "[*] $1"
    echo "========================================"
}

############################
# CRON - SISTEMA
############################

seccion "CRON DEL SISTEMA"

CRON_PATHS=(
    "/etc/crontab"
    "/etc/cron.d"
    "/etc/cron.daily"
    "/etc/cron.hourly"
    "/etc/cron.weekly"
    "/etc/cron.monthly"
)

for path in "${CRON_PATHS[@]}"; do
    if [ -e "$path" ]; then
        echo "[+] Contenido de $path"
        ls -la "$path"
        echo
        cat "$path" 2>/dev/null
        echo
    fi
done

############################
# CRON - USUARIOS
############################

seccion "CRON DE USUARIOS"

for user in $(cut -d: -f1 /etc/passwd); do
    CRON_USER="/var/spool/cron/crontabs/$user"
    if [ -f "$CRON_USER" ]; then
        echo "[+] Cron del usuario: $user"
        ls -la "$CRON_USER"
        cat "$CRON_USER"
        echo
    fi
done

############################
# SYSTEMD
############################

seccion "SERVICIOS SYSTEMD SOSPECHOSOS"

SYSTEMD_DIRS=(
    "/etc/systemd/system"
    "/lib/systemd/system"
    "/usr/lib/systemd/system"
)

for dir in "${SYSTEMD_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "[+] Analizando $dir"
        find "$dir" -type f -name "*.service" -exec ls -la {} \;
    fi
done

echo
echo "[*] Servicios habilitados"
systemctl list-unit-files --type=service --state=enabled 2>/dev/null

############################
# INIT / RC
############################

seccion "INIT / RC.LOCAL"

RC_FILES=(
    "/etc/rc.local"
    "/etc/init.d"
)

for rc in "${RC_FILES[@]}"; do
    if [ -e "$rc" ]; then
        echo "[+] Contenido de $rc"
        ls -la "$rc"
        cat "$rc" 2>/dev/null
        echo
    fi
done

############################
# SSH PERSISTENCIA
############################

seccion "CLAVES SSH (authorized_keys)"

find /home /root -type f -name "authorized_keys" 2>/dev/null | while read file; do
    echo "[+] Archivo: $file"
    ls -la "$file"
    cat "$file"
    echo
done

############################
# VARIABLES DE ENTORNO PELIGROSAS
############################

seccion "VARIABLES DE ENTORNO PELIGROSAS"

ENV_FILES=(
    "/etc/profile"
    "/etc/bash.bashrc"
    "/etc/environment"
    "/etc/profile.d"
)

for env in "${ENV_FILES[@]}"; do
    if [ -e "$env" ]; then
        echo "[+] Revisando $env"
        ls -la "$env"
        grep -Ei "LD_PRELOAD|LD_LIBRARY_PATH|PATH=" "$env" 2>/dev/null
        echo
    fi
done

############################
# BINARIOS EN RUTAS ANÓMALAS
############################

seccion "BINARIOS EN RUTAS ANÓMALAS"

SUSPICIOUS_DIRS=(
    "/tmp"
    "/var/tmp"
    "/dev/shm"
)

for sdir in "${SUSPICIOUS_DIRS[@]}"; do
    if [ -d "$sdir" ]; then
        echo "[+] Ejecutables en $sdir"
        find "$sdir" -type f -executable -exec ls -la {} \;
        echo
    fi
done

############################
# PATH MANIPULADO
############################

seccion "PATH DEL SISTEMA"

echo "$PATH" | tr ':' '\n'

############################
# RESUMEN FINAL
############################

seccion "RESUMEN"

echo "[+] Resultados almacenados en: $OUTPUT_DIR"
echo "[+] Script finalizado"

exit 0
