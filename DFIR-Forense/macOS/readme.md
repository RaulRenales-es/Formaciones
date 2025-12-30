# DFIR / Forense – macOS

Este directorio contiene un **conjunto de scripts DFIR (Digital Forensics & Incident Response) para sistemas macOS**, orientados a la **adquisición y análisis forense** en escenarios de:

- Respuesta a incidentes
- Análisis post-compromiso
- Laboratorios y prácticas forenses
- Formación técnica avanzada en DFIR

Los scripts están desarrollados utilizando **herramientas nativas de macOS** y siguen una **metodología forense realista**, alineada con las limitaciones y particularidades del sistema operativo de Apple.

---

## 🎯 Objetivo del repositorio macOS

- Proporcionar **herramientas forenses reales** para macOS
- Permitir la realización de **prácticas DFIR** en cursos y formaciones
- Enseñar **qué artefactos analizar y por qué**
- Trabajar con **evidencia real**, no simulada
- Adaptarse a las **restricciones técnicas de macOS moderno (SIP, Apple Silicon)**

---

## ⚠️ Advertencia legal y técnica

Estas herramientas deben utilizarse **únicamente** en:

- Sistemas bajo tu responsabilidad
- Investigaciones debidamente autorizadas
- Entornos de laboratorio y formación

macOS impone **limitaciones reales** a la adquisición forense (especialmente en memoria y disco).  
Los scripts **no intentan eludir protecciones del sistema**, sino trabajar **dentro de lo técnicamente y legalmente viable**.

El autor no se responsabiliza del uso indebido de este repositorio.

---

## 📂 Scripts incluidos

### 1️⃣ `macos_triage.sh`
**Propósito:**  
Triage forense inicial del sistema.

**Recopila:**
- Versión de macOS y build
- Estado de SIP y Gatekeeper
- Uptime
- Usuarios conectados
- Procesos activos
- Servicios launchd
- Conexiones de red
- Discos y volúmenes
- Actividad reciente básica

**Uso típico:**  
Primer script a ejecutar ante cualquier incidente en macOS.

---

### 2️⃣ `buscar-persistencia.sh`
**Propósito:**  
Detección de **mecanismos de persistencia** utilizados por malware en macOS.

**Analiza:**
- LaunchAgents y LaunchDaemons (sistema y usuario)
- Login Items
- Cron / periodic
- Profiles y MDM
- Kernel Extensions (kexts)
- TCC (accesos sensibles)
- Variables de entorno peligrosas
- Binarios y plist en rutas anómalas

---

### 3️⃣ `usuarios-anomalos.sh`
**Propósito:**  
Identificación de **anomalías en cuentas locales**.

**Analiza:**
- Usuarios locales
- UID 0 adicionales (root oculto)
- Cuentas ocultas
- Usuarios sin home válido
- Shells no estándar
- Grupos privilegiados (admin, wheel)
- Configuración sudo
- Últimos inicios de sesión

---

### 4️⃣ `procesos-sospechosos.sh`
**Propósito:**  
Detección de **procesos potencialmente maliciosos**.

**Detecta:**
- Procesos sin binario asociado
- Ejecución desde rutas anómalas
- LOLBins (osascript, curl, python, bash, etc.)
- Procesos sin firma válida
- Relaciones padre-hijo sospechosas
- Procesos con conexiones de red activas
- Procesos root ejecutados desde rutas no estándar

---

### 5️⃣ `network_live.sh`
**Propósito:**  
Análisis de **estado de red en vivo**.

**Recopila:**
- Interfaces de red
- Tabla de rutas
- Conexiones TCP/UDP activas
- Procesos asociados a red
- Puertos en escucha
- DNS y proxy configurado
- Información Wi-Fi
- Conexiones en puertos típicos de C2

---

### 6️⃣ `filesystem_triage.sh`
**Propósito:**  
Análisis forense del **sistema de ficheros**.

**Analiza:**
- Modificaciones recientes (MAC times)
- Descargas recientes
- Atributos extendidos (quarantine)
- Base de datos LSQuarantine
- Aplicaciones instaladas/modificadas
- Ejecutables en rutas anómalas
- LaunchAgents/Daemons recientes
- Historial de comandos
- Ficheros ocultos sospechosos

---

### 7️⃣ `analizar-unified-logs.sh`
**Propósito:**  
Análisis forense de **Unified Logs** de macOS.

**Extrae eventos de:**
- Autenticación (loginwindow, securityd)
- Uso de sudo
- Acceso remoto (SSH)
- launchd (servicios y persistencia)
- Ejecución de procesos
- LOLBins
- Descargas y cuarentena
- Errores y alertas de seguridad

---

### 8️⃣ `timeline.sh`
**Propósito:**  
Construcción de una **línea temporal forense unificada**.

**Combina:**
- Unified Logs
- MAC times del filesystem
- LaunchAgents/Daemons
- Quarantine events
- Descargas
- Historial de comandos

**Salida:**  
`timeline.csv`, ordenado cronológicamente y listo para correlación.

---

### 9️⃣ `acquire_memory.sh`
**Propósito:**  
Adquisición de **artefactos relacionados con memoria** en macOS.

**Incluye:**
- Detección de versión y arquitectura
- Advertencias claras sobre limitaciones
- Snapshot de procesos
- Mapas de memoria (vmmap)
- Estadísticas de memoria (vm_stat, top)
- Detección de herramientas externas (Volatility, Rekall)
- Hashes SHA256 y trazabilidad

⚠️ **macOS no permite full RAM dump en la mayoría de versiones modernas.**

---

### 🔟 `clone_disk_bitwise.sh`
**Propósito:**  
Clonado **bit a bit (sector a sector)** de discos en macOS.

**Soporta:**
- Adquisición a imagen RAW (recomendado)
- Clonado disco a disco (muy peligroso)
- `dd` con `conv=noerror,sync`
- Progreso en tiempo real
- Hash SHA256 de la imagen
- Registro completo de ejecución

⚠️ Script de **alto riesgo operativo**. Usar solo en entornos controlados.

---

## 🧭 Metodología DFIR recomendada en macOS

Orden típico de ejecución:

1. `macos_triage.sh`
2. `buscar-persistencia.sh`
3. `usuarios-anomalos.sh`
4. `procesos-sospechosos.sh`
5. `network_live.sh`
6. `filesystem_triage.sh`
7. `analizar-unified-logs.sh`
8. `timeline.sh`
9. `acquire_memory.sh` *(si procede)*
10. `clone_disk_bitwise.sh` *(entorno controlado)*

---

## 🧪 Uso en formación

Este repositorio está diseñado para:

- Prácticas DFIR reales
- Simulación de incidentes en macOS
- Análisis guiado en cursos
- Comprensión profunda de artefactos forenses macOS

Los scripts **no son simulaciones** y trabajan con **datos reales del sistema**.

---

## ✍️ Autor

**Raul Renales**  
Especialista en Ciberseguridad, DFIR e Infraestructuras Críticas

---

## 📄 Licencia

Consulta el archivo `LICENSE` del repositorio para conocer los términos de uso.
