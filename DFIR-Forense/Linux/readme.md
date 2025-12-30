# DFIR – Forense en Linux

Esta sección del repositorio contiene **scripts de Digital Forensics & Incident Response (DFIR)** orientados a **sistemas Linux**, diseñados para:

- Respuesta a incidentes en vivo (Live Response)
- Triage forense rápido
- Recolección de evidencias
- Análisis inicial de compromiso
- Formación técnica en DFIR

Todos los scripts siguen los principios de:
- **No intrusión** (solo lectura)
- **Auditoría y trazabilidad**
- **Uso de herramientas estándar del sistema**
- **Reproducibilidad forense**



## ⚠️ Advertencia Legal y Forense

Estos scripts están destinados a:
- Entornos controlados
- Sistemas bajo tu responsabilidad
- Investigaciones autorizadas

El uso indebido puede tener **implicaciones legales**.  
Ejecuta siempre con **criterio forense** y preservando la **cadena de custodia**.



## 📂 Scripts incluidos

### 1️⃣ `linux_triage.sh`
**Propósito:**  
Script maestro de **triage forense** para una visión rápida del estado del sistema.

**Funcionalidad principal:**
- Información del sistema (kernel, uptime, hostname)
- Procesos activos
- Conexiones de red
- Usuarios conectados
- Servicios activos
- Montajes y discos

**Uso típico:**  
Primer script a ejecutar ante un incidente para obtener una **foto inicial** del sistema.



### 2️⃣ `buscar-persistencia.sh`
**Propósito:**  
Detección de **mecanismos de persistencia** utilizados por atacantes.

**Analiza:**
- Cron (sistema y usuarios)
- Servicios `systemd`
- Init scripts / `rc.local`
- Claves SSH (`authorized_keys`)
- Variables de entorno peligrosas (`LD_PRELOAD`, `PATH`)
- Binarios ejecutables en rutas anómalas (`/tmp`, `/dev/shm`)

**Uso típico:**  
Identificar **backdoors persistentes** tras una intrusión.



### 3️⃣ `usuarios-anomalos.sh`
**Propósito:**  
Detección de **usuarios sospechosos o manipulaciones de cuentas**.

**Analiza:**
- Usuarios con UID 0 adicionales
- Cuentas sin contraseña o bloqueadas
- Usuarios sin directorio HOME
- Shells no estándar
- Usuarios de sistema con shells interactivas
- Uso de sudo
- Actividad de login reciente

**Uso típico:**  
Detectar **persistencia basada en cuentas** o escaladas de privilegios.



### 4️⃣ `analizar-authlog.sh`
**Propósito:**  
Análisis forense de **logs de autenticación**.

**Compatible con:**
- Debian / Ubuntu (`/var/log/auth.log`)
- RedHat / CentOS (`/var/log/secure`)

**Detecta:**
- Fuerza bruta SSH
- Logins exitosos
- Accesos de root
- Uso y abuso de `sudo`
- Cambios de usuario (`su`)
- Actividad fuera de horario
- IPs sospechosas

**Uso típico:**  
Reconstrucción de accesos y **línea temporal de autenticación**.



### 5️⃣ `timeline.sh`
**Propósito:**  
Construcción de una **línea temporal forense básica**.

**Funcionalidad:**
- Recopila tiempos MAC (Modified, Accessed, Changed)
- Ordena eventos cronológicamente
- Facilita correlación con logs y accesos

**Uso típico:**  
Entender **qué ocurrió y cuándo** durante un incidente.



### 6️⃣ `acquire_disk_memory.sh`
**Propósito:**  
Guía y automatización básica para **adquisición de disco y memoria**.

**Incluye:**
- Advertencias forenses
- Preparación del sistema
- Soporte para adquisición controlada
- Enfoque educativo y práctico

**Uso típico:**  
Preservación de evidencias en fases tempranas o laboratorios DFIR.



## 🧪 Metodología recomendada de uso

Orden lógico en un incidente real:

1. `linux_triage.sh`
2. `buscar-persistencia.sh`
3. `usuarios-anomalos.sh`
4. `analizar-authlog.sh`
5. `timeline.sh`
6. `acquire_disk_memory.sh` (si procede)



## 📌 Requisitos

- Bash
- Permisos de root (recomendado)
- Entorno Linux estándar
- Ejecución preferible desde:
  - Live CD forense
  - Sistema montado en solo lectura
  - Entorno controlado



## 📚 Uso educativo

Estos scripts están diseñados para:
- Formación DFIR
- Laboratorios prácticos
- Análisis guiado
- Comprensión de técnicas reales de ataque y defensa

Cada script puede utilizarse **de forma independiente** o integrada en flujos DFIR completos.



## Autor

**Raul Renales**  
Especialista en Ciberseguridad, DFIR e Infraestructuras Críticas



## 📄 Licencia

Revisa el archivo `LICENSE` del repositorio para conocer los términos de uso.
