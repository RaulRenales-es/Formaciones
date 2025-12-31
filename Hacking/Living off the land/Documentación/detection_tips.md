# detection_tips.md  
## Detección de ataques Living off the Land (LotL / LOLBins)

---

## Objetivo del documento

Este documento proporciona **criterios prácticos, técnicos y accionables** para la **detección de ataques basados en Living off the Land (LotL)**.  

Está orientado a:
- Blue Team
- Threat Hunting
- DFIR
- Purple Team
- Docencia avanzada en ciberseguridad

El enfoque es **detección por comportamiento**, no por herramientas.

---

## Principio fundamental

> **En ataques Living off the Land, el binario no es malicioso.  
El comportamiento sí lo es.**

Bloquear binarios nativos **no es viable**.  
Detectar **cómo, cuándo y por quién se usan**, sí lo es.

---

## 1. Cambiar el modelo mental de detección

### ❌ Lo que NO funciona
- Listas negras de binarios (`powershell.exe`, `bash`, `curl`)
- IOC estáticos
- Firma de herramientas externas

### ✅ Lo que SÍ funciona
- Contexto
- Secuencia de acciones
- Correlación temporal
- Desviaciones del baseline

---

## 2. Indicadores clave de Living off the Land

### 2.1 Uso anómalo de binarios legítimos

Detectar:
- Binarios ejecutados **fuera de su contexto habitual**
- Uso por **usuarios no administrativos**
- Ejecuciones **fuera de horario laboral**

Ejemplos:
- `powershell.exe` lanzado por un proceso Office
- `curl` ejecutado en un servidor que nunca descarga contenido
- `bash` ejecutando comandos complejos en sistemas appliance

---

## 3. Línea de comandos: el indicador más crítico

### 3.1 Argumentos sospechosos

La **línea de comandos** es uno de los mejores indicadores LotL.

Buscar:
- Encadenamiento de comandos (`|`, `&&`, `;`)
- Redirecciones (`>`, `2>/dev/null`)
- Uso de Base64
- Comandos largos u ofuscados

Ejemplos:
- PowerShell con `-EncodedCommand`
- Bash con múltiples pipes y subshells
- `certutil -urlcache -split`

---

## 4. Frecuencia y repetición

### 4.1 Ejecución repetitiva

Indicadores claros:
- Mismo binario ejecutado cada X minutos
- Ejecuciones periódicas sin tarea programada conocida
- Actividad constante de red asociada al mismo proceso

Esto suele indicar:
- Beaconing
- Persistencia encubierta
- C2 basado en LOLBins

---

## 5. Relación proceso ↔ red

### 5.1 Correlación obligatoria

Siempre correlacionar:
- Proceso
- Puerto
- IP remota
- Usuario
- Hora

Ejemplos sospechosos:
- `powershell.exe` con conexiones salientes
- `bash` o `sh` manteniendo sockets persistentes
- `curl` comunicándose con IPs externas sin proxy corporativo

---

## 6. Persistencia Living off the Land

### 6.1 Persistencia sin malware

Mecanismos comunes:
- Cron / tareas programadas
- Servicios
- LaunchAgents / LaunchDaemons
- Claves Run / RunOnce
- Modificación de perfiles de shell

Indicadores:
- Persistencia creada por binarios legítimos
- Persistencia sin binarios nuevos en disco
- Cambios realizados por usuarios no esperados

---

## 7. Uso de ubicaciones sospechosas

Detectar ejecuciones desde:
- `/tmp`, `/var/tmp`, `/private/tmp`
- `C:\Users\Public`
- `AppData\Local\Temp`
- `/Users/Shared`

Un binario legítimo **ejecutado desde una ruta anómala** es una señal fuerte.

---

## 8. Acceso indebido a credenciales

Indicadores:
- Acceso masivo a archivos `.env`
- Uso de `grep` / `find` buscando palabras clave
- Acceso frecuente a Keychain (macOS)
- Consultas repetidas al registro de Windows

Especial atención a:
- Credenciales en texto plano
- Variables de entorno

---

## 9. Anti-forense Living off the Land

### 9.1 Limpieza con binarios legítimos

Buscar:
- Uso de `log erase`, `wevtutil`, `Clear-EventLog`
- Manipulación selectiva de logs
- Borrado justo después de actividad sospechosa

Esto suele indicar **etapas finales del ataque**.

---

## 10. Secuencias típicas de ataque LotL

Un ataque real suele seguir este orden:

1. Enumeración local  
2. Reconocimiento de red  
3. Búsqueda de credenciales  
4. Persistencia  
5. Comunicación encubierta  
6. Limpieza de rastros  

Detectar **una sola acción aislada** no siempre es suficiente.  
Detectar **la secuencia**, sí.

---

## 11. Baseline: la defensa más poderosa

Sin baseline:
- Todo parece sospechoso
- O nada lo parece

Recomendaciones:
- Baseline por rol (usuario, servidor, DC)
- Baseline por sistema operativo
- Baseline por franja horaria

Living off the Land **rompe el baseline**, no la firma.

---

## 12. MITRE ATT&CK más relevante

Técnicas clave a monitorizar:
- T1059 – Command and Scripting Interpreter
- T1082 – System Information Discovery
- T1016 – Network Configuration Discovery
- T1046 – Network Service Discovery
- T1547 – Boot or Logon Autostart Execution
- T1552 – Unsecured Credentials
- T1070 – Indicator Removal on Host

---

## 13. Reglas prácticas de oro

- No bloquees binarios, **monitoriza comportamiento**
- La línea de comandos importa más que el nombre del proceso
- Correlaciona siempre proceso + red + tiempo
- La persistencia es el punto crítico
- Living off the Land **siempre deja rastro**, pero no donde se busca tradicionalmente

---

## 14. Uso docente recomendado

Ejercicio práctico:
1. Ejecutar scripts LotL legítimos
2. Registrar logs y telemetría
3. Diseñar detecciones
4. Comparar con actividad real
5. Ajustar reglas

Este enfoque entrena **analistas reales**, no usuarios de herramientas.

---

## Aviso final

Living off the Land **no es una técnica avanzada**.  
Es la técnica **por defecto** en ataques modernos.

No detectarla implica **ceguera defensiva**.

---
