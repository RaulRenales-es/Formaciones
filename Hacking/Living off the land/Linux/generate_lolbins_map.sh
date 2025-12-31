#!/usr/bin/env bash
# ------------------------------------------------------------
# generate_lolbins_map.sh
# Generador de documentación LOLBins (Living off the Land)
# Autor: RaulRenales.es
# Uso: ./generate_lolbins_map.sh
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

OUTPUT_FILE="lolbins_map.md"

cat <<'EOF' > "$OUTPUT_FILE"
# LOLBins Map – Living off the Land Binaries

## Descripción

Este documento recoge los **binarios nativos del sistema operativo** que pueden ser utilizados legítimamente por administradores, pero que son **frecuentemente abusados por atacantes** bajo la filosofía **Living off the Land (LotL)**.

Objetivos:
- Formación técnica
- Threat Hunting
- Blue / Purple Team
- Hardening de sistemas

---

## Principios Living off the Land

- Uso exclusivo de binarios nativos
- Sin herramientas externas
- Baja huella forense
- Evasión basada en confianza del sistema

---

## Linux LOLBins

| Binario | Uso legítimo | Abuso habitual | MITRE ATT&CK | Detección |
|-------|--------------|----------------|--------------|-----------|
| bash | Shell | Control remoto | T1059.004 | Cmdline anómala |
| sh | Shell | Scripts ocultos | T1059 | Ejecución indirecta |
| curl | Transferencias | Descarga C2 | T1105 | Proxy / DNS |
| wget | Descargas | Payload | T1105 | IDS |
| find | Búsqueda | Discovery | T1083 | Uso masivo |
| grep | Filtrado | Cred hunting | T1552 | Accesos repetidos |
| awk | Procesado | Ofuscación | T1059 | Pipelines largos |
| sed | Edición | Ofuscación | T1059 | Comandos encadenados |
| crontab | Automatización | Persistencia | T1053.003 | Cambios no autorizados |
| systemctl | Servicios | Backdoor | T1543.002 | Nuevos servicios |
| ss | Red | Recon | T1046 | Ejecución frecuente |
| ip | Red | Discovery | T1016 | Uso reiterado |

---

## Windows LOLBins

| Binario | Uso legítimo | Abuso habitual | MITRE ATT&CK | Detección |
|-------|--------------|----------------|--------------|-----------|
| powershell.exe | Automatización | Payload | T1059.001 | Script Block Logging |
| cmd.exe | Shell | Control | T1059.003 | Cmdline |
| certutil.exe | Certificados | Descarga | T1105 | -urlcache |
| bitsadmin.exe | Transferencias | C2 | T1197 | Jobs anómalos |
| reg.exe | Registro | Persistencia | T1547 | Run Keys |
| schtasks.exe | Tareas | Autostart | T1053.005 | Evento 4698 |
| wmic.exe | Gestión | Recon | T1047 | Uso interactivo |
| mshta.exe | HTML Apps | Payload | T1218.005 | Ejecución remota |
| rundll32.exe | DLL | Inyección | T1218.011 | DLL externa |
| net.exe | Red | Lateral | T1021 | Uso fuera horario |

---

## macOS LOLBins

| Binario | Uso legítimo | Abuso habitual | MITRE ATT&CK | Detección |
|-------|--------------|----------------|--------------|-----------|
| bash | Shell | Control | T1059 | Historial |
| zsh | Shell | Persistencia | T1059 | Cmdline |
| curl | Descargas | C2 | T1105 | Proxy |
| launchctl | Servicios | Autostart | T1543.001 | Unified Logs |
| defaults | Preferencias | Persistencia | T1547 | Cambios plist |
| osascript | AppleScript | Payload | T1059.002 | Script exec |
| log | Logs | Anti-forense | T1070 | Limpieza |
| sqlite3 | BD | Robo datos | T1005 | Acceso anómalo |
| dscl | Directorio | Usuarios | T1087 | Nuevas cuentas |
| security | Keychain | Cred access | T1555 | Accesos keychain |

---

## Relación con scripts del repositorio

| Script | LOLBins usados |
|------|----------------|
| enum_local.sh | bash, ps, ip, ss, find |
| cred_hunting.sh | grep, awk, find |
| network_recon.sh | ss, ip, netstat |
| persistence_audit.sh | crontab, systemctl |
| unified_logs_hunting.sh | log |

---

## Enfoque defensivo

- No bloquear binarios
- Monitorizar argumentos y contexto
- Correlacionar procesos, red y persistencia
- Detectar comportamiento, no herramientas

---

## Aviso legal

Uso exclusivo para:
- Formación
- Auditorías autorizadas
- Mejora de la postura defensiva

El uso no autorizado es responsabilidad del usuario.
EOF

echo "[+] Archivo generado correctamente: $OUTPUT_FILE"
