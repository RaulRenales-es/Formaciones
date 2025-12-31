# ISO & MOTW – Explicación Educativa

## Autor
**Raul Renales**  
Formación y cursos especializados: https://raulrenales.es

---

## ¿Qué es MOTW (Mark of the Web)?

MOTW es una marca que Windows añade a archivos descargados desde Internet
(Alternate Data Stream: `Zone.Identifier`).
Esta marca permite a Windows y a soluciones de seguridad
aplicar advertencias y restricciones.

---

## Contenedores y MOTW

Históricamente, ciertos contenedores (ZIP, ISO) han tenido
comportamientos que podían **propagar o perder** la marca MOTW
según versión y configuración.

⚠️ Este documento **no proporciona técnicas operativas**,
solo describe el **riesgo** y la **detección**.

---

## Riesgos habituales

- El usuario no ve advertencias al abrir archivos
- Accesos directos o scripts parecen “confiables”
- Mayor probabilidad de ingeniería social

---

## Detección y mitigación

### Detección
- Inspeccionar `Zone.Identifier`
- Alertar ejecuciones desde contenedores montados
- Logs de SmartScreen y AMSI

### Mitigación
- Mantener Windows actualizado
- Bloquear ejecución desde ubicaciones temporales
- Concienciación del usuario
- Políticas ASR y AppLocker

---

## Uso responsable

Este contenido es **exclusivamente educativo** y para
entornos **autorizados y controlados**.

---

© Raul Renales – https://raulrenales.es
