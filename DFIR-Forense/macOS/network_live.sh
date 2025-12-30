#!/bin/bash
#
# network_live.sh (macOS)
#
# Descripción:
#   Script DFIR para análisis de red en vivo en macOS.
#   Recopila conexiones activas, procesos asociados, interfaces,
#   rutas, DNS, proxy, Wi-Fi y listeners locales.
#
# Autor: Raul Renales
# Uso: SOLO LECTURA
#

############################
# CONFIGURACIÓN GENERAL
############################

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="macos_network_live_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/resultados.txt"

mkdir -p "${OUTPUT_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[+] macOS DFIR - Network Live Analysis"
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
# INTERFACES DE RED
############################

section "INTERFACES DE RED"

ifconfig

############################
# RUTAS DE RED
############################

section "TABLA DE RUTAS"

netstat -rn

############################
# CONEXIONES ACTIVAS (TCP/UDP)
############################

section "CONEXIONES DE RED ACTIVAS"

netstat -anv

############################
# PROCESOS CON CONEXIONES DE RED
############################

section "PROCESOS CON CONEXIONES DE RED"

lsof -i -n -P > "${OUTPUT_DIR}/lsof_network.txt"
head -200 "${OUTPUT_DIR}/lsof_network.txt"

############################
# LISTENERS LOCALES
############################

section "PUERTOS EN ESCUCHA (LISTEN)"

lsof -iTCP -sTCP:LISTEN -n -P

############################
# CONEXIONES EXTERNAS ESTABLECIDAS
############################

section "CONEXIONES EXTERNAS ESTABLECIDAS"

netstat -an | grep ESTABLISHED

############################
# DNS CONFIGURADO
############################

section "CONFIGURACIÓN DNS"

scutil --dns

############################
# CACHÉ DNS (mDNSResponder)
############################

section "CACHÉ DNS (ESTADÍSTICAS)"

sudo killall -INFO mDNSResponder 2>/dev/null || echo "[!] No se pudo consultar mDNSResponder"

############################
# PROXY CONFIGURADO
############################

section "CONFIGURACIÓN DE PROXY"

scutil --proxy

############################
# WI-FI (SI EXISTE)
############################

section "INFORMACIÓN WI-FI"

AIRPORT="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"

if [ -x "$AIRPORT" ]; then
    $AIRPORT -I
else
    echo "[+] airport no disponible"
fi

############################
# CONEXIONES SOSPECHOSAS (PUERTOS COMUNES C2)
############################

section "CONEXIONES EN PUERTOS SOSPECHOSOS (C2 COMUNES)"

SUSPICIOUS_PORTS=":4444|:1337|:6666|:7777|:9001|:9050|:53"

netstat -an | grep -E "$SUSPICIOUS_PORTS"

############################
# PROCESOS CONECTADOS A IPs EXTERNAS
############################

section "PROCESOS CONECTADOS A IPs EXTERNAS"

lsof -i -n | grep -E "TCP|UDP" | grep -v "127.0.0.1" | grep -v "::1"

############################
# RESUMEN EJECUTIVO
############################

section "RESUMEN EJECUTIVO"

echo "[+] Total de conexiones:"
netstat -an | wc -l

echo "[+] Listeners locales:"
lsof -iTCP -sTCP:LISTEN -n -P | wc -l

echo "[+] Procesos con red:"
lsof -i -n -P | awk '{print $1}' | sort -u | wc -l

############################
# RESUMEN FINAL
############################

section "RESUMEN FINAL"

echo "[+] Evidencias almacenadas en: ${OUTPUT_DIR}"
echo "[+] Script finalizado"

exit 0
