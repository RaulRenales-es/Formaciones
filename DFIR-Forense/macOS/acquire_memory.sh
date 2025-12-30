#!/bin/bash
#
# acquire_memory.sh (macOS)
#
# Descripción:
#   Script DFIR para adquisición de artefactos de memoria en macOS.
#   Debido a las limitaciones de macOS (SIP, Apple Silicon),
#   este script:
#     - Detecta arquitectura y versión
#     - Advierte de limitaciones forenses
#     - Captura artefactos relacionados con memoria
#     - Usa herramientas externas SOLO si están disponibles
#     - Genera hashes y trazabilidad
#
# Autor: Raul Renales
# Uso DFIR - IMPACTO CONTROLADO
#

############################
# CONFIGURACIÓN GENERAL
############################

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="macos_memory_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/resultados.txt"

mkdir -p "${OUTPUT_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[+] macOS DFIR - Memory Acquisition"
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

hash_file() {
    local f="$1"
    if [ -f "$f" ]; then
        shasum -a 256 "$f" >> "${OUTPUT_DIR}/hashes.sha256"
    fi
}

############################
# DETECCIÓN DEL ENTORNO
############################

section "DETECCIÓN DEL ENTORNO"

OS_VERSION="$(sw_vers -productVersion)"
BUILD="$(sw_vers -buildVersion)"
ARCH="$(uname -m)"

echo "[+] macOS version : $OS_VERSION ($BUILD)"
echo "[+] Arquitectura : $ARCH"

csrutil status 2>/dev/null || echo "[!] No se pudo consultar SIP"

############################
# ADVERTENCIAS DFIR
############################

section "ADVERTENCIAS IMPORTANTES"

cat << EOF
[!] macOS impone fuertes restricciones a la adquisición de memoria:
    - SIP bloquea acceso a /dev/mem
    - Apple Silicon no permite volcados completos
    - No existe método nativo soportado para full RAM dump

[+] Este script captura:
    - Snapshots de procesos
    - Mapas de memoria accesibles
    - Estadísticas de VM
    - Core dumps controlados (si procede)
    - Uso de herramientas externas SI están presentes

[+] Para adquisición completa:
    - Se requiere hardware especializado
    - O sistemas Intel antiguos con SIP deshabilitado
EOF

############################
# SNAPSHOT DE PROCESOS
############################

section "SNAPSHOT DE PROCESOS"

ps auxww > "${OUTPUT_DIR}/procesos.txt"
hash_file "${OUTPUT_DIR}/procesos.txt"

############################
# MAPAS DE MEMORIA (vmmap)
############################

section "MAPAS DE MEMORIA (vmmap)"

for pid in $(ps -axo pid | tail -n +2 | head -20); do
    echo "[+] vmmap PID $pid"
    vmmap "$pid" > "${OUTPUT_DIR}/vmmap_${pid}.txt" 2>/dev/null
    hash_file "${OUTPUT_DIR}/vmmap_${pid}.txt"
done

############################
# ESTADÍSTICAS DE MEMORIA
############################

section "ESTADÍSTICAS DE MEMORIA"

vm_stat > "${OUTPUT_DIR}/vm_stat.txt"
hash_file "${OUTPUT_DIR}/vm_stat.txt"

top -l 1 -o mem > "${OUTPUT_DIR}/top_mem.txt"
hash_file "${OUTPUT_DIR}/top_mem.txt"

############################
# COREDUMPS (SI ESTÁN HABILITADOS)
############################

section "COREDUMPS (SI ESTÁN DISPONIBLES)"

COREDUMP_DIR="/cores"

if [ -d "$COREDUMP_DIR" ]; then
    ls -la "$COREDUMP_DIR" > "${OUTPUT_DIR}/coredumps.txt"
    hash_file "${OUTPUT_DIR}/coredumps.txt"
else
    echo "[+] Directorio /cores no disponible"
fi

############################
# HERRAMIENTAS EXTERNAS (VOLATILITY / REKALL)
############################

section "HERRAMIENTAS EXTERNAS DISPONIBLES"

for tool in volatility vol Rekall rekall; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "[+] Herramienta detectada: $tool"
        "$tool" --help > "${OUTPUT_DIR}/${tool}_help.txt" 2>/dev/null
        hash_file "${OUTPUT_DIR}/${tool}_help.txt"
    fi
done

############################
# LLDB (INSPECCIÓN CONTROLADA)
############################

section "LLDB (INSPECCIÓN CONTROLADA)"

if command -v lldb >/dev/null 2>&1; then
    echo "[+] lldb disponible"
    lldb --version > "${OUTPUT_DIR}/lldb_version.txt"
    hash_file "${OUTPUT_DIR}/lldb_version.txt"
else
    echo "[+] lldb no disponible"
fi

############################
# RESUMEN EJECUTIVO
############################

section "RESUMEN EJECUTIVO"

echo "[+] Arquitectura  : $ARCH"
echo "[+] macOS         : $OS_VERSION"
echo "[+] Evidencias    : $(ls "${OUTPUT_DIR}" | wc -l) ficheros"
echo "[+] Hashes SHA256 : ${OUTPUT_DIR}/hashes.sha256"

############################
# RESUMEN FINAL
############################

section "RESUMEN FINAL"

echo "[+] Evidencias almacenadas en: ${OUTPUT_DIR}"
echo "[+] Script finalizado"

exit 0
