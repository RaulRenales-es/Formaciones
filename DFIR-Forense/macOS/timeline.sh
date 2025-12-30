#!/bin/bash
#
# timeline.sh (macOS)
#
# Descripción:
#   Script DFIR para construcción de una línea temporal forense en macOS.
#   Combina Unified Logs, filesystem (MAC times), LaunchAgents/Daemons,
#   Quarantine, descargas y artefactos de usuario.
#
# Autor: Raul Renales
# Uso: SOLO LECTURA
#

############################
# CONFIGURACIÓN
############################

HOSTNAME="$(hostname)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="macos_timeline_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${OUTPUT_DIR}/resultados.txt"

# Ventana temporal (ajustable)
DAYS_BACK=7
START_DATE="$(date -v -${DAYS_BACK}d '+%Y-%m-%d %H:%M:%S')"

mkdir -p "${OUTPUT_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[+] macOS DFIR - Timeline"
echo "[+] Fecha: $(date)"
echo "[+] Host: ${HOSTNAME}"
echo "[+] Ventana temporal: últimos ${DAYS_BACK} días"
echo "========================================"

TIMELINE_CSV="${OUTPUT_DIR}/timeline.csv"
echo "Time,Source,Category,Description,Details" > "${TIMELINE_CSV}"

############################
# FUNCIÓN AUXILIAR
############################

section() {
    echo
    echo "========================================"
    echo "[*] $1"
    echo "========================================"
}

add_timeline() {
    local time="$1"
    local source="$2"
    local category="$3"
    local desc="$4"
    local details="$5"
    echo "\"$time\",\"$source\",\"$category\",\"$desc\",\"$details\"" >> "${TIMELINE_CSV}"
}

############################
# UNIFIED LOGS
############################

section "UNIFIED LOGS (auth / exec / launchd / sudo)"

log show --style syslog --start "${START_DATE}" \
  --predicate '(process == "loginwindow" OR process == "securityd" OR process == "sudo" OR process == "launchd")' \
  2>/dev/null | while read -r line; do
    TS="$(echo "$line" | awk '{print $1" "$2}')"
    add_timeline "$TS" "UnifiedLog" "Auth/Privilege" "Security-related event" "$line"
done

log show --style syslog --start "${START_DATE}" \
  --predicate 'eventMessage CONTAINS[c] "exec"' \
  2>/dev/null | while read -r line; do
    TS="$(echo "$line" | awk '{print $1" "$2}')"
    add_timeline "$TS" "UnifiedLog" "Execution" "Process execution" "$line"
done

############################
# FILESYSTEM (MAC TIMES)
############################

section "FILESYSTEM (MAC TIMES)"

find /Users /Applications /Library /tmp /private/var/tmp \
     -type f \
     \( -mtime -${DAYS_BACK} -o -ctime -${DAYS_BACK} -o -atime -${DAYS_BACK} \) \
     2>/dev/null | while read -r f; do
        MTIME="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$f" 2>/dev/null)"
        CTIME="$(stat -f '%Sc' -t '%Y-%m-%d %H:%M:%S' "$f" 2>/dev/null)"
        ATIME="$(stat -f '%Sa' -t '%Y-%m-%d %H:%M:%S' "$f" 2>/dev/null)"
        [ -n "$MTIME" ] && add_timeline "$MTIME" "Filesystem" "Modified" "File modified" "$f"
        [ -n "$CTIME" ] && add_timeline "$CTIME" "Filesystem" "Created"  "File created"  "$f"
        [ -n "$ATIME" ] && add_timeline "$ATIME" "Filesystem" "Accessed" "File accessed" "$f"
done

############################
# LAUNCHAGENTS / LAUNCHDAEMONS
############################

section "LAUNCHAGENTS / LAUNCHDAEMONS (TIMESTAMPS)"

LAUNCH_PATHS=(
    "/Library/LaunchDaemons"
    "/Library/LaunchAgents"
    "/System/Library/LaunchDaemons"
    "/System/Library/LaunchAgents"
)

for path in "${LAUNCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        find "$path" -type f -name "*.plist" -mtime -${DAYS_BACK} 2>/dev/null | while read -r p; do
            TS="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$p")"
            add_timeline "$TS" "Launchd" "Persistence" "LaunchAgent/Daemon modified" "$p"
        done
    fi
done

############################
# QUARANTINE (DESCARGAS)
############################

section "QUARANTINE EVENTS"

for home in /Users/*; do
    DB="$home/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2"
    if [ -f "$DB" ]; then
        sqlite3 "$DB" \
          "select datetime(LSQuarantineTimeStamp + 978307200,'unixepoch'),
                  LSQuarantineAgentName,
                  LSQuarantineDataURLString
           from LSQuarantineEvent
           order by LSQuarantineTimeStamp desc
           limit 50;" 2>/dev/null | while IFS='|' read -r ts agent url; do
                add_timeline "$ts" "Quarantine" "Download" "File downloaded" "$agent $url"
        done
    fi
done

############################
# DESCARGAS RECIENTES
############################

section "DESCARGAS RECIENTES (Downloads)"

for home in /Users/*; do
    if [ -d "$home/Downloads" ]; then
        find "$home/Downloads" -type f -mtime -${DAYS_BACK} 2>/dev/null | while read -r f; do
            TS="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$f")"
            add_timeline "$TS" "Downloads" "UserActivity" "File in Downloads" "$f"
        done
    fi
done

############################
# HISTÓRICO DE COMANDOS
############################

section "HISTÓRICO DE COMANDOS (bash / zsh)"

for home in /Users/*; do
    if [ -f "$home/.bash_history" ]; then
        TS="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$home/.bash_history")"
        add_timeline "$TS" "Shell" "CommandHistory" "bash history modified" "$home/.bash_history"
    fi
    if [ -f "$home/.zsh_history" ]; then
        TS="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$home/.zsh_history")"
        add_timeline "$TS" "Shell" "CommandHistory" "zsh history modified" "$home/.zsh_history"
    fi
done

############################
# ORDENAR TIMELINE
############################

section "ORDENANDO TIMELINE"

sort -t',' -k1,1 "${TIMELINE_CSV}" -o "${TIMELINE_CSV}"

############################
# RESUMEN FINAL
############################

section "RESUMEN FINAL"

echo "[+] Timeline generada: ${TIMELINE_CSV}"
echo "[+] Script finalizado"

exit 0
