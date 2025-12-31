# Living off the Land (LotL) – Ethical Hacking Toolkit

## Descripción

Esta sección del repositorio está dedicada al estudio y uso **ético y controlado** de la filosofía **Living off the Land (LotL)**, que consiste en **aprovechar binarios, utilidades y funcionalidades nativas del sistema operativo** para realizar tareas de reconocimiento, auditoría y análisis de seguridad **sin introducir herramientas externas**.

El objetivo principal **no es la explotación**, sino:

- Comprender **TTPs reales** usados por atacantes modernos
- Mejorar **detección basada en comportamiento**
- Facilitar **Threat Hunting, DFIR y hardening**
- Proporcionar **material docente realista** para cursos y laboratorios

---

## ¿Qué es Living off the Land?

Living off the Land es una técnica ampliamente utilizada en ataques reales donde el adversario:

- Evita malware tradicional
- Usa binarios firmados y confiables del sistema
- Reduce la huella forense
- Elude controles basados en firmas

Desde el punto de vista defensivo, **entender LotL es imprescindible** para detectar amenazas modernas.

---

## Alcance de esta sección

✔ Enumeración local  
✔ Reconocimiento de red pasivo  
✔ Hunting de credenciales en texto plano (pasivo)  
✔ Análisis de persistencia  
✔ Documentación de LOLBins  

✘ Sin exploits  
✘ Sin escalada de privilegios  
✘ Sin payloads  
✘ Sin bypass de controles de seguridad  

---

## Estructura

```text
├── linux/
│   ├── enum_local.sh
│   ├── persistence_audit.sh
│   ├── cred_hunting.sh
│   ├── network_recon.sh
│   └── lolbins_map.md
├── windows/
│   ├── enum_local.ps1
│   ├── persistence_audit.ps1
│   ├── eventlog_hunting.ps1
│   ├── network_recon.ps1
│   └── lolbins_map.md
├── macos/
│   ├── enum_local.sh
│   ├── persistence_audit.sh
│   ├── unified_logs_hunting.sh
│   └── lolbins_map.md
└── docs/
    ├── detection_tips.md
    ├── mitre_mapping.md
