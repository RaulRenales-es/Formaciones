#!/bin/bash
#
# usuarios-anomalos.sh (macOS)
#
# Descripción:
#   Script DFIR para detección de usuarios y configuraciones anómalas
#   en sistemas macOS. Orientado a persistencia basada en cuentas,
#   abuso de privilegios y backdoors locales.
#
# Autor: Raul Renales
# Uso: SOLO LECTURA
#

############################
# CONFIGURACIÓN GENERAL
############################

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="macos_usuarios_anomalos_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/resultados.txt"

mkdir -p "${OUTPUT_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[+] macOS DFIR - Análisis de usuarios"
echo "[+] Fecha: $(date)"
echo "[+] Host: ${HOSTNAME}"
echo "[+] Usuario que ejecuta: $(whoami)"
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
# LISTADO DE USUARIOS LOCALES
############################

section "USUARIOS LOCALES"

dscl . list /Users | grep -v "^_"

############################
# INFORMACIÓN DETALLADA DE USUARIOS
############################

section "DETALLE DE USUARIOS (UID, SHELL, HOME)"

for user in $(dscl . list /Users | grep -v "^_"); do
    echo "[+] Usuario: $user"
    dscl . -read /Users/"$user" UniqueID UserShell NFSHomeDirectory 2>/dev/null
    echo
done

############################
# USUARIOS CON UID 0 (ROOT ADICIONALES)
############################

section "USUARIOS CON UID 0 (ROOT ADICIONALES)"

for user in $(dscl . list /Users | grep -v "^_"); do
    UID=$(dscl . -read /Users/"$user" UniqueID 2>/dev/null | awk '{print $2}')
    if [ "$UID" = "0" ]; then
        echo "[!] Usuario con UID 0: $user"
    fi
done

############################
# USUARIOS OCULTOS
############################

section "USUARIOS OCULTOS (IsHidden)"

for user in $(dscl . list /Users | grep -v "^_"); do
    HIDDEN=$(dscl . -read /Users/"$user" IsHidden 2>/dev/null | awk '{print $2}')
    if [ "$HIDDEN" = "1" ]; then
        echo "[!] Usuario oculto: $user"
    fi
done

############################
# USUARIOS SIN HOME O HOME INEXISTENTE
############################

section "USUARIOS SIN HOME O HOME INEXISTENTE"

for user in $(dscl . list /Users | grep -v "^_"); do
    HOME_DIR=$(dscl . -read /Users/"$user" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    if [ -n "$HOME_DIR" ] && [ ! -d "$HOME_DIR" ]; then
        echo "[!] Usuario: $user | Home inexistente: $HOME_DIR"
    fi
done

############################
# USUARIOS CON SHELL SOSPECHOSA
############################

section "USUARIOS CON SHELL SOSPECHOSA"

VALID_SHELLS=$(cat /etc/shells 2>/dev/null)

for user in $(dscl . list /Users | grep -v "^_"); do
    SHELL=$(dscl . -read /Users/"$user" UserShell 2>/dev/null | awk '{print $2}')
    if [ -n "$SHELL" ] && ! echo "$VALID_SHELLS" | grep -qx "$SHELL"; then
        echo "[!] Usuario: $user | Shell no estándar: $SHELL"
    fi
done

############################
# USUARIOS EN GRUPOS PRIVILEGIADOS
############################

section "USUARIOS EN GRUPOS PRIVILEGIADOS"

PRIV_GROUPS=("admin" "wheel")

for group in "${PRIV_GROUPS[@]}"; do
    echo "[+] Grupo: $group"
    dscl . -read /Groups/"$group" GroupMembership 2>/dev/null
    echo
done

############################
# USUARIOS CON SUDO
############################

section "USUARIOS CON PRIVILEGIOS SUDO"

grep -E "^[^#].*ALL" /etc/sudoers 2>/dev/null
ls -la /etc/sudoers.d 2>/dev/null
cat /etc/sudoers.d/* 2>/dev/null

############################
# ÚLTIMOS INICIOS DE SESIÓN
############################

section "ÚLTIMOS INICIOS DE SESIÓN"

last -20

############################
# CAMBIOS RECIENTES EN BASE DE USUARIOS
############################

section "TIMESTAMPS DE BASES DE USUARIOS"

ls -la /var/db/dslocal/nodes/Default/users 2>/dev/null

############################
# DIRECTORIOS HOME RECIENTES
############################

section "DIRECTORIOS HOME MODIFICADOS RECIENTEMENTE"

find /Users -maxdepth 1 -type d -mtime -7 2>/dev/null

############################
# RESUMEN FINAL
############################

section "RESUMEN FINAL"

echo "[+] Directorio de evidencias: ${OUTPUT_DIR}"
echo "[+] Script finalizado"

exit 0
