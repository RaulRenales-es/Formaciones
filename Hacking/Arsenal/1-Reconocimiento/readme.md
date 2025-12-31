# Reconnaissance Scripts – Network & Cloud

## Autor
**Raul Renales**  
Formación y cursos especializados: https://raulrenales.es

---

## Descripción general

Este conjunto de scripts cubre la **fase de reconocimiento** dentro de escenarios de **hacking ético, pentesting interno y red team**, siguiendo la filosofía **Living off the Land (LotL)**.

El objetivo principal es **enseñar al alumno cómo un atacante real obtiene contexto** desde un sistema ya comprometido, **minimizando ruido**, **sin herramientas externas** y **aprovechando recursos nativos del sistema operativo**.

---

## Filosofía Living off the Land (LotL)

Todos los scripts:

- Utilizan **binarios y comandos nativos**
- Evitan escaneos agresivos
- Son **difíciles de diferenciar** de actividad legítima
- Reflejan técnicas usadas en ataques reales

Esto permite trabajar tanto la **parte ofensiva** como la **detección defensiva**.

---

## Scripts incluidos

```text
recon/
├── network_recon.sh
├── network_recon.ps1
├── dns_enum.sh
├── web_fingerprint.sh
└── cloud_metadata_enum.sh
```


##network_recon.sh
Objetivo
Obtener una visión general de la red local desde un sistema Linux comprometido.

Qué hace
Enumera interfaces y direcciones IP
Obtiene rutas y gateways
Lista conexiones activas y puertos en escucha
Extrae la tabla ARP
Realiza un ping sweep controlado de la red local

Qué aprende el alumno
Identificar otros activos en la red

Detectar servicios expuestos

Evitar herramientas ruidosas como nmap

Detección defensiva
Tráfico ICMP anómalo

Consultas ARP inusuales

Uso de ss / netstat

##network_recon.ps1
Objetivo
Realizar reconocimiento de red en entornos Windows usando únicamente cmdlets nativos.

Qué hace
Enumera configuración IP y rutas

Extrae conexiones TCP activas

Detecta puertos en escucha

Identifica dominio y contexto del host

Ejecuta un ping sweep de bajo impacto

Qué aprende el alumno
Reconocimiento interno sin herramientas externas

Correlación con eventos de firewall y Sysmon

Detección defensiva
Eventos ICMP

Uso anómalo de Get-NetTCPConnection

Tráfico lateral temprano

##dns_enum.sh
Objetivo
Enumerar información DNS interna y externa de forma pasiva.

Qué hace
Analiza la configuración DNS local

Detecta dominio

Enumera servidores DNS

Resuelve registros comunes (A, MX, SRV)

Identifica posibles Domain Controllers

Realiza reverse DNS desde la tabla ARP

Qué aprende el alumno
Descubrimiento de dominios internos

Identificación temprana de Active Directory

Relación DNS ↔ infraestructura crítica

Detección defensiva
Consultas DNS SRV

Resoluciones repetidas de nombres internos

##web_fingerprint.sh
Objetivo
Identificar tecnologías web y configuraciones expuestas sin realizar escaneos agresivos.

Qué hace
Obtiene cabeceras HTTP y HTTPS

Detecta tecnologías comunes (PHP, ASP.NET, CMS)

Comprueba métodos HTTP permitidos

Busca ficheros sensibles comunes

Qué aprende el alumno
Fingerprinting web realista

Identificación de superficie de ataque web

Riesgos de filtrado de información en cabeceras

Detección defensiva
Logs de servidor web

Peticiones HTTP OPTIONS

Accesos a rutas sensibles

cloud_metadata_enum.sh
Objetivo
Detectar entornos cloud y exposición de metadatos desde una máquina comprometida.

Qué hace
Comprueba acceso al servicio de metadatos

Identifica proveedor cloud (AWS, Azure, GCP)

Enumera información básica de la instancia

Detecta posibles roles e identidades

Qué aprende el alumno
Ataques mediante SSRF

Riesgos del metadata service

Impacto de malas configuraciones cloud

Detección defensiva
Tráfico hacia 169.254.169.254

Alertas de IMDS

Análisis de flujo de red

##Uso responsable
Estos scripts están diseñados exclusivamente para:

Formación
Laboratorios
Entornos controlados y autorizados

❌ No deben utilizarse en sistemas sin consentimiento explícito.

##Relación con el ciclo de ataque
Estos scripts cubren principalmente:

Reconnaissance
Discovery
Initial Targeting

Sirven como base para las siguientes fases:

Credential Access
Lateral Movement
Persistence
Siguiente paso recomendado



© Raul Renales – https://raulrenales.es
