#!/bin/bash
#
# usuarios-anomalos.sh
# Autor: Raul Renales
# Descripción:
#   Script DFIR para detección de usuarios anómalos y posibles backdoors
#   en sistemas Linux.
#
# Advertencia:
#   Script de solo lectura. No modifica el sistema.
#

############################
# CONFIGURACIÓN GENERAL
############################

OUTPUT_DIR="usuarios_anomalos_$(hostname)_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$OUTPUT_DIR/resultados.txt"

mkdir -p "$OUTPUT_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[+] Iniciando análisis de usuarios"
echo "[+] Fecha: $(date)"
echo "[+] Hostname: $(hostname)"
echo "[+] Usuario que ejecuta: $(whoami)"
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
# USUARIOS UID 0
############################

seccion "USUARIOS CON UID 0 (ROOT ADICIONALES)"

awk -F: '($3 == 0) { print $1 ":" $3 ":" $7 }' /etc/passwd

############################
# USUARIOS SIN CONTRASEÑA
############################

seccion "USUARIOS SIN CONTRASEÑA O BLOQUEADOS"

if [ -r /etc/shadow ]; then
    awk -F: '($2 == "" || $2 == "!" || $2 == "*") { print $1 ":" $2 }' /etc/shadow
else
    echo "[!] No se puede leer /etc/shadow (permisos insuficientes)"
fi

############################
# CUENTAS SIN HOME O HOME ANÓMALO
############################

seccion "USUARIOS SIN HOME O HOME INEXISTENTE"

while IFS=: read -r user pass uid gid desc home shell; do
    if [ "$uid" -ge 1000 ] && [ ! -d "$home" ]; then
        echo "[!] Usuario: $user | UID: $uid | Home inexistente: $home"
    fi
done < /etc/passwd

############################
# SHELLS SOSPECHOSAS
############################

seccion "USUARIOS CON SHELL SOSPECHOSA"

VALID_SHELLS=$(cat /etc/shells 2>/dev/null)

while IFS=: read -r user pass uid gid desc home shell; do
    if ! echo "$VALID_SHELLS" | grep -qx "$shell"; then
        echo "[!] Usuario: $user | Shell no estándar: $shell"
    fi
done < /etc/passwd

############################
# USUARIOS DE SISTEMA CON SHELL INTERACTIVA
############################

seccion "USUARIOS DE SISTEMA CON SHELL INTERACTIVA"

while IFS=: read -r user pass uid gid desc home shell; do
    if [ "$uid" -lt 1000 ] && [[ "$shell" != *"nologin"* ]] && [[ "$shell" != *"false"* ]]; then
        echo "[!] Usuario sistema interactivo: $user | UID: $uid | Shell: $shell"
    fi
done < /etc/passwd

############################
# CAMBIOS RECIENTES EN ARCHIVOS CRÍTICOS
############################

seccion "CAMBIOS RECIENTES EN /etc/passwd Y /etc/shadow"

ls -la /etc/passwd
ls -la /etc/shadow 2>/dev/null

stat /etc/passwd
stat /etc/shadow 2>/dev/null

############################
# ACTIVIDAD DE LOGIN RECIENTE
############################

seccion "ACTIVIDAD DE LOGIN (LASTLOG)"

lastlog | grep -v "Never logged in"

############################
# USUARIOS CON SUDO
############################

seccion "USUARIOS CON PRIVILEGIOS SUDO"

if [ -d /etc/sudoers.d ]; then
    echo "[+] Contenido de /etc/sudoers.d"
    ls -la /etc/sudoers.d
    cat /etc/sudoers.d/* 2>/dev/null
fi

grep -E "^[^#].*ALL=\(ALL\)" /etc/sudoers 2>/dev/null

############################
# RESUMEN FINAL
############################

seccion "RESUMEN"

echo "[+] Resultados almacenados en: $OUTPUT_DIR"
echo "[+] Script finalizado"

exit 0
