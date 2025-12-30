# DFIR – Forense en Windows

Esta sección del repositorio contiene **scripts de Digital Forensics & Incident Response (DFIR)** orientados a **sistemas Microsoft Windows**, desarrollados en **PowerShell** y diseñados para:

- Respuesta a incidentes en vivo (Live Response)
- Triage forense
- Detección de persistencia y compromiso
- Análisis post-intrusión
- Formación técnica avanzada en DFIR

Todos los scripts siguen principios forenses de:
- **Solo lectura** (salvo adquisición explícita)
- **Trazabilidad**
- **Reproducibilidad**
- **Uso de artefactos nativos de Windows**

---

## ⚠️ Advertencia legal y forense

Estas herramientas deben utilizarse **únicamente** en:

- Sistemas bajo tu responsabilidad
- Investigaciones autorizadas
- Entornos de laboratorio o formación

Algunos scripts (adquisición de memoria o clonado de disco) **impactan el sistema** y deben ejecutarse con pleno conocimiento forense.

El autor **no se responsabiliza del uso indebido** de estas herramientas.

---

## 🧭 Metodología DFIR recomendada

Orden lógico de ejecución en un incidente real:

1. `windows_triage.ps1`
2. `buscar-persistencia.ps1`
3. `usuarios-anomalos.ps1`
4. `analizar-eventlog.ps1`
5. `procesos-sospechosos.ps1`
6. `timeline.ps1`
7. `acquire_memory.ps1` *(si procede)*
8. `clone_disk_bitwise.ps1` *(entorno controlado / WinPE)*

---

## 📂 Scripts incluidos

### 1️⃣ `windows_triage.ps1`
**Propósito:**  
Obtención de una **visión inicial del sistema**.

**Recopila:**
- Información del sistema operativo
- Uptime
- Usuarios conectados
- Procesos activos
- Servicios
- Conexiones de red
- Discos y volúmenes
- AV / EDR detectado

**Uso típico:**  
Primer script a ejecutar ante cualquier incidente en Windows.

---

### 2️⃣ `buscar-persistencia.ps1`
**Propósito:**  
Detección de **mecanismos de persistencia** utilizados por atacantes.

**Analiza:**
- Claves Run / RunOnce
- Servicios sospechosos
- Tareas programadas
- WMI Event Consumers
- Carpetas de inicio
- PowerShell Profiles
- DLL hijacking (rutas comunes)

**Uso típico:**  
Identificar backdoors persistentes tras una intrusión.

---

### 3️⃣ `usuarios-anomalos.ps1`
**Propósito:**  
Detección de **anomalías en cuentas y privilegios**.

**Analiza:**
- Usuarios locales
- Grupos privilegiados (Administrators, RDP Users)
- Cuentas ocultas o deshabilitadas
- Últimos inicios de sesión
- Creación y eliminación de usuarios
- Acceso remoto (RDP)

**Uso típico:**  
Detectar persistencia basada en cuentas o escaladas de privilegios.

---

### 4️⃣ `analizar-eventlog.ps1`
**Propósito:**  
Análisis forense de **registros de eventos de Windows**.

**Analiza:**
- Security.evtx (4624, 4625, 4688, 1102…)
- System.evtx
- PowerShell Operational (4103, 4104)
- Windows PowerShell clásico
- Eventos RDP (Terminal Services)

**Uso típico:**  
Reconstrucción de accesos, ejecución de comandos y actividad post-explotación.

---

### 5️⃣ `procesos-sospechosos.ps1`
**Propósito:**  
Identificación de **procesos anómalos o maliciosos**.

**Detecta:**
- Ejecución desde rutas no estándar (AppData, Temp, ProgramData)
- Procesos sin firma digital
- LOLBins (PowerShell, rundll32, mshta, etc.)
- Procesos huérfanos
- Relaciones padre-hijo sospechosas

**Uso típico:**  
Detección de malware fileless y living-off-the-land.

---

### 6️⃣ `timeline.ps1`
**Propósito:**  
Construcción de una **línea temporal forense unificada**.

**Incluye:**
- Event Logs (Security, System, PowerShell)
- Prefetch
- Timestamps del filesystem (MAC times)
- Cambios en claves de persistencia del registro

**Salida:**  
CSV ordenado cronológicamente para análisis y correlación.

---

### 7️⃣ `acquire_memory.ps1`
**Propósito:**  
Adquisición de **memoria RAM** mediante herramientas externas (si están disponibles).

**Soporta:**
- winpmem
- DumpIt
- Magnet RAM Capture

**Incluye:**
- Snapshot previo (procesos, red)
- Hash SHA256 de herramienta y evidencias
- Registro completo de ejecución

⚠️ **Este script impacta el sistema.**

---

### 8️⃣ `clone_disk_bitwise.ps1`
**Propósito:**  
Clonado **bit a bit (sector a sector)** de un disco físico en Windows.

**Características:**
- Acceso RAW a `\\.\PhysicalDriveX`
- Imagen RAW (`.img`)
- Hash SHA256
- Progreso controlado

⚠️ **Script de alto riesgo.**
- No ejecutar sobre el disco del sistema activo
- Recomendado solo en WinPE o entornos controlados

---

## 🧪 Modo de uso general

```powershell
# Ejecución típica (como Administrador)
.\windows_triage.ps1
.\buscar-persistencia.ps1
.\usuarios-anomalos.ps1
.\analizar-eventlog.ps1
.\procesos-sospechosos.ps1
.\timeline.ps1 -DaysBack 14
