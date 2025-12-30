#!/bin/bash
#
# clone_disk_bitwise.sh (macOS)
#
# Descripción:
#   Clonado forense bit a bit (sector a sector) en macOS.
#   Soporta:
#     - Imagen RAW a fichero (recomendado)
#     - Clonado a disco destino (opcional y peligroso)
#   Incluye:
#     - Inventario de discos
#     - Validación básica de origen
#     - dd con conv=noerror,sync y status=progress
#     - Hash SHA256 de la imagen resultante
#     - Logging completo
#
# Autor: Raul Renales
# Uso DFIR - ALTO RIESGO si se clona a disco destino
#

############################
# CONFIGURACIÓN
############################

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="macos_disk_clone_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/resultados.txt"

mkdir -p "${OUTPUT_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

section() {
  echo
  echo "========================================"
  echo "[*] $1"
  echo "========================================"
}

die() {
  echo "[!] ERROR: $1"
  exit 1
}

usage() {
  cat << 'EOF'
Uso:
  sudo ./clone_disk_bitwise.sh --source /dev/diskXsY --out /ruta/imagen.img [--bs 4m]

Opcional (MUY PELIGROSO):
  sudo ./clone_disk_bitwise.sh --source /dev/diskX --dest /dev/diskY [--bs 4m]

Parámetros:
  --source   Disco/partición origen (ej: /dev/disk2 o /dev/disk2s1)
  --out      Fichero imagen RAW destino (recomendado)
  --dest     Disco destino para clonado directo (PELIGROSO)
  --bs       Block size para dd (default: 4m)
  --list     Muestra diskutil list y sale

Ejemplos:
  # Imagen a fichero (recomendado)
  sudo ./clone_disk_bitwise.sh --source /dev/disk2 --out /Volumes/DFIR/EVIDENCIAS/disk2.img --bs 4m

  # Clonado disco a disco (solo si sabes exactamente lo que haces)
  sudo ./clone_disk_bitwise.sh --source /dev/disk2 --dest /dev/disk3 --bs 4m
EOF
}

############################
# PARSE ARGUMENTOS
############################

SOURCE=""
OUT_IMG=""
DEST_DISK=""
BS="4m"
LIST_ONLY="0"

while [ $# -gt 0 ]; do
  case "$1" in
    --source) SOURCE="$2"; shift 2;;
    --out) OUT_IMG="$2"; shift 2;;
    --dest) DEST_DISK="$2"; shift 2;;
    --bs) BS="$2"; shift 2;;
    --list) LIST_ONLY="1"; shift;;
    -h|--help) usage; exit 0;;
    *) die "Parámetro no reconocido: $1";;
  esac
done

############################
# PRECHECKS
############################

echo "[+] macOS DFIR - Clonado bit a bit"
echo "[+] Fecha: $(date)"
echo "[+] Host: ${HOSTNAME}"
echo "[+] Usuario: $(whoami)"
echo "========================================"

section "INVENTARIO DE DISCOS"
diskutil list

if [ "$LIST_ONLY" = "1" ]; then
  echo "[+] Modo listado finalizado."
  exit 0
fi

[ -z "$SOURCE" ] && die "Debe indicar --source"
if [ -n "$OUT_IMG" ] && [ -n "$DEST_DISK" ]; then
  die "Use SOLO uno: --out (imagen) o --dest (clonado directo), no ambos."
fi
if [ -z "$OUT_IMG" ] && [ -z "$DEST_DISK" ]; then
  die "Debe indicar --out (recomendado) o --dest (peligroso)."
fi

# Requiere root
if [ "$(id -u)" -ne 0 ]; then
  die "Ejecute como root: sudo ./clone_disk_bitwise.sh ..."
fi

# Validar que source existe
[ ! -e "$SOURCE" ] && die "No existe el origen: $SOURCE"

# Resolver a raw device para mejor rendimiento (/dev/rdiskX...)
RAW_SOURCE="$(echo "$SOURCE" | sed 's|/dev/disk|/dev/rdisk|')"
[ ! -e "$RAW_SOURCE" ] && RAW_SOURCE="$SOURCE"

############################
# INFO DE ORIGEN
############################

section "INFORMACIÓN DEL ORIGEN"
echo "[+] SOURCE: $SOURCE"
echo "[+] RAW_SOURCE: $RAW_SOURCE"
diskutil info "$SOURCE" 2>/dev/null || true

############################
# PREPARAR DESTINO
############################

if [ -n "$OUT_IMG" ]; then
  section "MODO: IMAGEN A FICHERO (RECOMENDADO)"
  echo "[+] OUT_IMG: $OUT_IMG"

  OUT_DIR="$(dirname "$OUT_IMG")"
  [ ! -d "$OUT_DIR" ] && die "El directorio destino no existe: $OUT_DIR"

  # Verificar espacio libre aproximado si es un volumen montado
  # (No todos los path permiten cálculo fiable; es una ayuda, no garantía)
  echo "[+] Espacio libre en destino:"
  df -h "$OUT_DIR" || true

  # Evitar sobrescrituras accidentales
  if [ -f "$OUT_IMG" ]; then
    die "El fichero de salida ya existe. Elimine/renombre antes: $OUT_IMG"
  fi

elif [ -n "$DEST_DISK" ]; then
  section "MODO: CLONADO A DISCO (MUY PELIGROSO)"
  echo "[+] DEST_DISK: $DEST_DISK"
  [ ! -e "$DEST_DISK" ] && die "No existe el disco destino: $DEST_DISK"

  # Evitar clonar sobre el mismo
  if [ "$DEST_DISK" = "$SOURCE" ]; then
    die "Origen y destino son el mismo dispositivo."
  fi

  echo "[!] AVISO: El destino será SOBRESCRITO COMPLETAMENTE."
  echo "[!] Recomendación DFIR: adquirir a fichero imagen y trabajar sobre copias."
  echo
  echo "[+] Intentando desmontar destino (si procede)..."
  diskutil unmountDisk force "$DEST_DISK" 2>/dev/null || true
fi

############################
# EJECUCIÓN DD
############################

section "INICIANDO CLONADO (dd)"

echo "[+] Block size: $BS"
echo "[+] Parámetros: conv=noerror,sync status=progress"

if [ -n "$OUT_IMG" ]; then
  dd if="$RAW_SOURCE" of="$OUT_IMG" bs="$BS" conv=noerror,sync status=progress
  DD_RC=$?
else
  RAW_DEST="$(echo "$DEST_DISK" | sed 's|/dev/disk|/dev/rdisk|')"
  [ ! -e "$RAW_DEST" ] && RAW_DEST="$DEST_DISK"
  dd if="$RAW_SOURCE" of="$RAW_DEST" bs="$BS" conv=noerror,sync status=progress
  DD_RC=$?
fi

if [ $DD_RC -ne 0 ]; then
  die "dd finalizó con error (exit code: $DD_RC)"
fi

sync

############################
# HASH Y EVIDENCIAS
############################

if [ -n "$OUT_IMG" ]; then
  section "HASH SHA256 (IMAGEN)"

  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$OUT_IMG" | tee "${OUT_IMG}.sha256.txt"
    cp -f "${OUT_IMG}.sha256.txt" "${OUTPUT_DIR}/" 2>/dev/null || true
  else
    echo "[!] shasum no disponible"
  fi

  section "METADATA DEL FICHERO"
  ls -la "$OUT_IMG"
  stat "$OUT_IMG" 2>/dev/null || true
else
  section "CLONADO A DISCO COMPLETADO"
  echo "[+] No se genera hash de un dispositivo de bloque en este modo por defecto."
  echo "[+] Recomendación: generar hash sobre una imagen o sobre la partición adquirida si aplica."
fi

############################
# RESUMEN FINAL
############################

section "RESUMEN FINAL"

echo "[+] Origen:  $SOURCE"
if [ -n "$OUT_IMG" ]; then
  echo "[+] Imagen:  $OUT_IMG"
  echo "[+] Hash:    ${OUT_IMG}.sha256.txt"
else
  echo "[+] Destino: $DEST_DISK"
fi
echo "[+] Evidencias de ejecución: ${OUTPUT_DIR}"
echo "[+] Script finalizado"

exit 0
