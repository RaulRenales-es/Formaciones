# LOLBins Map – Living off the Land Binaries

## Descripción

Este documento identifica **binarios nativos del sistema operativo** que, aunque tienen un uso legítimo administrativo, **son comúnmente abusados en ataques reales** bajo la filosofía **Living off the Land (LotL / LOLBins)**.

El objetivo es **defensivo y docente**:
- Comprender **TTPs reales**
- Facilitar **Threat Hunting**
- Mejorar **detección basada en comportamiento**
- Apoyar **DFIR, Blue Team y Purple Team**

---

## Principios Living off the Land

- Uso exclusivo de binarios nativos
- Sin herramientas externas
- Huella forense reducida
- Evasión de controles basados en firmas
- Abuso del contexto, no del exploit

---

## Linux LOLBins

| Binario | Uso legítimo | Abuso habitual | MITRE ATT&CK | Detección recomendada |
|-------|--------------|----------------|--------------|----------------------|
| bash | Shell | Control remoto | T1059.004 | Línea de comandos |
| sh | Shell | Scripts encubiertos | T1059 | Procesos anómalos |
| curl | Transferencias | Descarga C2 | T1105 | Proxy / DNS |
| wget | Descargas | Payload | T1105 | IDS / FW |
| find | Búsqueda | Discovery | T1083 | Uso masivo |
| grep | Filtrado | Cred hunting | T1552 | Accesos repetidos |
| awk | Procesado | Ofuscación | T1059 | Pipelines largos |
| sed | Edición | Ofuscación | T1059 | Comandos encadenados |
| crontab | Automatización | Persistencia | T1053.003 | Cambios no autorizados |
| systemctl | Servicios | Backdoor | T1543.002 | Servicios nuevos |
| ss | Red | Recon | T1046 | Ejecución frecuente |
| ip | Red | Discovery | T1016 | Uso reiterado |

---

## Windows LOLBins

| Binario | Uso legítimo | Abuso habitual | MITRE ATT&CK | Detección recomendada |
|-------|--------------|----------------|--------------|----------------------|
| powershell.exe | Automatización | Payload | T1059.001 | Script Block Logging |
| cmd.exe | Shell | Control | T1059.003 | Cmdline |
| certutil.exe | Certificados | Descarga | T1105 | Uso de -urlcache |
| bitsadmin.exe | Transferencias | C2 | T1197 | Jobs sospechosos |
| reg.exe | Registro | Persistencia | T1547 | Run Keys |
| schtasks.exe | Tareas | Autostart | T1053.005 | Evento 4698 |
| wmic.exe | Gestión | Recon | T1047 | Uso interactivo |
| mshta.exe | HTML Apps | Payload | T1218.005 | Ejecución remota |
| rundll32.exe | DLL | Inyección | T1218.011 | DLL no estándar |
| net.exe | Red | Movimiento lateral | T1021 | Uso fuera de horario |

---

## macOS LOLBins

| Binario | Uso legítimo | Abuso habitual | MITRE ATT&CK | Detección recomendada |
|-------|--------------|----------------|--------------|----------------------|
| bash | Shell | Control | T1059 | Historial |
| zsh | Shell | Persistencia | T1059 | Cmdline |
| curl | Descargas | C2 | T1105 | Proxy |
| launchctl | Servicios | Autostart | T1543.001 | Unified Logs |
| defaults | Preferencias | Persistencia | T1547 | Cambios plist |
| osascript | AppleScript | Payload | T1059.002 | Script execution |
| log | Logs | Anti-forense | T1070 | Limpieza de logs |
| sqlite3 | Base de datos | Robo de datos | T1005 | Accesos anómalos |
| dscl | Directorio | Gestión usuarios | T1087 | Nuevas cuentas |
| security | Keychain | Acceso credenciales | T1555 | Accesos a Keychain |

---

## Relación con scripts del repositorio

| Script | LOLBins implicados |
|------|-------------------|
| enum_local.sh | bash, ps, ip, ss, find |
| enum_local.ps1 | powershell, netstat, reg |
| cred_hunting.sh | grep, awk, find |
| network_recon.sh | ss, ip |
| network_recon.ps1 | netstat, arp |
| persistence_audit.sh | crontab, systemctl |
| persistence_audit.ps1 | schtasks, reg |
| unified_logs_hunting.sh | log |

---

## Enfoque defensivo recomendado

- No bloquear binarios nativos
- Monitorizar:
  - argumentos
  - frecuencia de ejecución
  - contexto del usuario
- Correlacionar:
  - procesos
  - red
  - persistencia
- Detectar **comportamiento**, no herramientas

---

## Uso docente

Este mapa permite:
- Simular ataques reales sin malware
- Diseñar reglas Sigma
- Entrenar Threat Hunters
- Comprender evasión moderna

---

## Aviso legal

Este material está destinado **exclusivamente** a:
- Formación
- Laboratorios controlados
- Auditorías con autorización expresa
- Mejora de la seguridad defensiva

El uso no autorizado de estas técnicas es ilegal y contrario a la ética profesional.
