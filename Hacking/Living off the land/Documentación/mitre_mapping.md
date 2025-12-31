# mitre_mapping.md  
## Mapeo MITRE ATT&CK – Living off the Land (LotL / LOLBins)

---

## Objetivo del documento

Este documento proporciona el **mapeo explícito entre técnicas Living off the Land (LotL)** utilizadas en este repositorio y el **framework MITRE ATT&CK**, con un enfoque **defensivo, operativo y docente**.

Está diseñado para:
- Blue Team
- Threat Hunting
- DFIR
- Purple Team
- Formación avanzada (FP, Universidad, Máster)

---

## Enfoque metodológico

El mapeo se realiza desde:
- **Táctica**
- **Técnica**
- **Uso real del binario**
- **Script del repositorio**
- **Indicadores defensivos**

No se basa en malware, sino en **abuso de funcionalidad legítima**.

---

## Visión general por tácticas

| Táctica | Objetivo del atacante |
|-------|----------------------|
| Discovery | Conocer el sistema y la red |
| Execution | Ejecutar comandos sin levantar alertas |
| Persistence | Mantener acceso |
| Credential Access | Obtener secretos |
| Defense Evasion | Evadir detección |
| Command and Control | Mantener comunicación |
| Impact | Borrar rastros |

---

## Discovery (TA0007)

### T1082 – System Information Discovery

**Descripción**  
Recopilación de información del sistema operativo, hardware y configuración.

**LOLBins usados**
- Linux/macOS: `uname`, `id`, `ps`, `system_profiler`
- Windows: `Get-ComputerInfo`, `systeminfo`

**Scripts del repositorio**
- `enum_local.sh`
- `enum_local.ps1`

**Indicadores defensivos**
- Ejecución masiva de comandos de enumeración
- Actividad fuera de contexto o de horario
- Usuarios no administrativos enumerando el sistema

---

### T1016 – Network Configuration Discovery

**Descripción**  
Obtención de información sobre interfaces, IPs y rutas.

**LOLBins usados**
- Linux/macOS: `ip`, `ifconfig`, `netstat`
- Windows: `ipconfig`, `Get-NetIPAddress`

**Scripts**
- `network_recon.sh`
- `network_recon.ps1`

**Detección**
- Enumeración de red sin cambios operativos
- Uso reiterado de comandos de red

---

### T1046 – Network Service Discovery

**Descripción**  
Identificación de servicios accesibles localmente.

**LOLBins**
- `ss`, `netstat`, `lsof`

**Scripts**
- `network_recon.sh`
- `network_recon.ps1`

**Detección**
- Consulta frecuente de puertos en escucha
- Correlación proceso ↔ puerto

---

## Execution (TA0002)

### T1059 – Command and Scripting Interpreter

**Descripción**  
Ejecución de comandos mediante intérpretes legítimos.

**Subtécnicas relevantes**
- T1059.001 – PowerShell
- T1059.003 – Windows Command Shell
- T1059.004 – Unix Shell

**LOLBins**
- `bash`, `sh`, `zsh`
- `powershell.exe`, `cmd.exe`

**Scripts**
- Todos los scripts LotL del repositorio

**Indicadores**
- Líneas de comandos largas
- Encadenamiento de comandos
- Uso de ofuscación

---

## Persistence (TA0003)

### T1053 – Scheduled Task / Job

**Descripción**  
Persistencia mediante tareas programadas.

**Subtécnicas**
- T1053.003 – Cron
- T1053.005 – Scheduled Task (Windows)

**LOLBins**
- `crontab`
- `schtasks.exe`

**Scripts**
- `persistence_audit.sh`
- `persistence_audit.ps1`

**Detección**
- Nuevas tareas sin justificación
- Tareas creadas por usuarios no esperados

---

### T1547 – Boot or Logon Autostart Execution

**Descripción**  
Ejecución automática al inicio del sistema o sesión.

**Subtécnicas**
- T1547.001 – Registry Run Keys
- T1547.002 – Login Items
- T1547.006 – Kernel Modules

**LOLBins**
- `reg.exe`
- `launchctl`
- Modificación de perfiles de shell

**Scripts**
- `persistence_audit.ps1`
- `enum_local.sh` (macOS)

**Detección**
- Cambios en claves Run
- LaunchAgents no firmados o inesperados

---

## Credential Access (TA0006)

### T1552 – Unsecured Credentials

**Descripción**  
Acceso a credenciales almacenadas de forma insegura.

**LOLBins**
- `grep`, `find`, `awk`
- `security` (macOS Keychain)

**Scripts**
- `cred_hunting.sh`
- `unified_logs_hunting.sh`

**Detección**
- Accesos masivos a archivos `.env`
- Búsquedas por palabras clave sensibles

---

### T1555 – Credentials from Password Stores

**Descripción**  
Acceso a almacenes de credenciales legítimos.

**LOLBins**
- `security` (macOS)
- APIs de Windows Credential Manager

**Scripts**
- `unified_logs_hunting.sh`

**Detección**
- Accesos inusuales a Keychain
- Consultas repetidas sin aplicación asociada

---

## Defense Evasion (TA0005)

### T1070 – Indicator Removal on Host

**Descripción**  
Eliminación o manipulación de rastros.

**LOLBins**
- `log`
- `wevtutil`

**Scripts**
- `unified_logs_hunting.sh`

**Detección**
- Borrado selectivo de logs
- Limpieza tras actividad sospechosa

---

## Command and Control (TA0011)

### T1105 – Ingress Tool Transfer

**Descripción**  
Descarga de contenido utilizando herramientas legítimas.

**LOLBins**
- `curl`, `wget`
- `certutil`, `bitsadmin`

**Scripts**
- Detectable desde `network_recon.*`
- Correlación con logs

**Detección**
- Conexiones salientes desde intérpretes
- Descargas fuera de proxy corporativo

---

## Relación scripts ↔ MITRE

| Script | Técnicas MITRE |
|------|----------------|
| enum_local.sh | T1082, T1057 |
| enum_local.ps1 | T1082, T1057 |
| network_recon.sh | T1016, T1046 |
| network_recon.ps1 | T1016, T1046 |
| cred_hunting.sh | T1552 |
| persistence_audit.sh | T1053, T1547 |
| persistence_audit.ps1 | T1053, T1547 |
| unified_logs_hunting.sh | T1070, T1059, T1555 |

---

## Uso recomendado (Purple Team)

1. Ejecutar scripts LotL legítimos
2. Registrar telemetría
3. Mapear detecciones a MITRE
4. Ajustar reglas
5. Repetir hasta reducir falsos positivos

---

## Conclusión

Living off the Land **encaja perfectamente en MITRE ATT&CK**.  
El problema no es el framework.  
El problema es **no usarlo con profundidad operativa**.

Este documento permite:
- Hablar el mismo idioma entre equipos
- Diseñar detecciones reales
- Enseñar ciberseguridad moderna

---
