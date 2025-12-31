
# Acceso Inicial – Webshells (Uso Educativo)

## Autor
**Raul Renales**  
Formación y cursos especializados: https://raulrenales.es

---

## Descripción general

Esta sección contiene **webshells educativas** y **herramientas de detección asociadas**, diseñadas para **enseñar el impacto real de una subida de archivos insegura o RCE**, así como su **detección desde el punto de vista defensivo**.

El objetivo es que el alumno comprenda:

- Cómo se obtiene **ejecución remota** vía web
- Qué **rastros deja un webshell**
- Cómo **detectar, analizar y responder** a este tipo de intrusiones

Todo el contenido está pensado **exclusivamente para formación y laboratorios autorizados**.

---

## Filosofía de la sección

- Webshells **simples y deliberadamente detectables**
- Código **claro, no ofuscado**
- Enfoque **ofensivo + defensivo**
- Ideal para:
  - Pentesting web
  - DFIR
  - Blue Team / Red Team

---

## Archivos incluidos

```text
webshells/
├── php_webshell.php
├── aspx_webshell.aspx
├── jsp_webshell_simulator.jsp
└── webshell_detector.sh
````

---

## php_webshell.php

### Descripción

Webshell **PHP** educativa que permite la ejecución de comandos del sistema tras una **autenticación básica**.

### Escenario típico

* Vulnerabilidad de **file upload**
* Inclusión de archivos
* RCE en aplicaciones PHP

### Uso en laboratorio

1. Subir el archivo a un servidor web vulnerable
2. Acceder vía navegador
3. Introducir la contraseña configurada
4. Ejecutar comandos básicos (`id`, `whoami`, `ls`)

### Qué se enseña

* Impacto real de una subida insegura
* Ejecución de comandos vía servidor web
* Rastros en logs y sistema de archivos

### Detección

* Uso de `system()`, `exec()`
* Parámetro `cmd`
* Archivos `.php` fuera de rutas esperadas

---

## aspx_webshell.aspx

### Descripción

Webshell **ASPX** para entornos **IIS / ASP.NET**, diseñada para demostrar ejecución de comandos mediante `cmd.exe`.

### Escenario típico

* Aplicaciones ASP.NET con subida de archivos
* IIS mal configurado
* Application Pools con permisos excesivos

### Uso en laboratorio

Comandos recomendados:

```text
whoami
hostname
ipconfig
dir
```

### Qué se enseña

* Contexto de ejecución del Application Pool
* Riesgo real en servidores Windows
* Trazas en logs IIS y EDR

### Detección

* Uso de `System.Diagnostics.Process`
* Ejecución de `cmd.exe`
* Parámetros sospechosos en peticiones POST

---

## jsp_webshell_simulator.jsp

### Descripción

**Simulador educativo de webshell JSP**.
⚠️ **No ejecuta comandos reales**.

### Propósito

* Enseñar **cómo luce una webshell JSP**
* Practicar **detección, logging y hardening**
* Evitar introducir código peligroso funcional

### Uso en laboratorio

* Subida del archivo a Tomcat / Jetty
* Envío de parámetros `password` y `cmd`
* Observación de:

  * logs de acceso
  * patrones de petición
  * detección por WAF

### Qué se enseña

* Indicadores típicos de webshells JSP
* Detección basada en patrones
* Seguridad en servidores Java

---

## webshell_detector.sh

### Descripción

Script **defensivo** para detectar webshells **PHP, ASPX y JSP** mediante **heurísticas comunes**.

### Qué analiza

* Patrones de ejecución de comandos
* Archivos web recientes
* Permisos inseguros
* Nombres de archivo sospechosos

### Uso recomendado

```bash
chmod +x webshell_detector.sh
sudo ./webshell_detector.sh /var/www
```

### Archivos generados

* `pattern_matches.txt`
* `recent_web_files.txt`
* `world_writable.txt`
* `suspicious_names.txt`
* `summary.txt`

### Qué se enseña

* Diferencia entre alerta y confirmación
* Triage web básico
* Inicio de un análisis DFIR

---

## Flujo didáctico recomendado

1. Explotar una subida insegura (webshell)
2. Ejecutar comandos controlados
3. Analizar logs y sistema
4. Ejecutar `webshell_detector.sh`
5. Correlacionar resultados
6. Aplicar mitigaciones

---

## Uso responsable

Estos archivos están diseñados **exclusivamente** para:

* Formación
* Laboratorios
* Entornos controlados y autorizados

❌ **No deben utilizarse en sistemas sin consentimiento explícito.**

---

## Relación con el ciclo de ataque

Esta sección cubre principalmente:

* Initial Access
* Execution
* Persistence (básica)

Sirve como base para avanzar hacia:

* Privilege Escalation
* Lateral Movement
* Detection & Response

---


© Raul Renales – [https://raulrenales.es](https://raulrenales.es)



Si quieres, el siguiente paso lógico y muy potente para el repositorio es:

- crear **`post_webshell_enum.sh`**
- o una **guía de hardening web tras detección**

Dime cuál y lo construimos con el mismo estándar profesional.
```
