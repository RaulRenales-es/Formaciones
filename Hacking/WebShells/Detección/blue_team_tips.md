Indicadores comunes de WebShells:

- Uso de system(), exec(), passthru(), eval()
- Parámetros sospechosos: cmd, exec, x, shell
- Archivos PHP/JSP pequeños en uploads/
- Tráfico POST anómalo sin formularios
- Base64 en parámetros HTTP

Controles defensivos:
- WAF con reglas de comportamiento
- File Integrity Monitoring
- Logs de procesos del servidor web
- Análisis de requests anómalos
