# Nmap – Guía rápida de escaneo

## Scanning básico

```bash
# Ping a toda una red de clase C
nmap -sP 192.168.1.*

# TCP Connect Scan
nmap -sT 192.168.1.179

# SYN Scan
nmap -sS 192.168.1.179

# FIN Scan
nmap -sF 192.168.1.179

# UDP Scan (puertos 0–100)
nmap -sU -p 0-100 192.168.1.179

# Nmap – Guía rápida de escaneo

## Scanning básico

```bash
# Ping a toda una red de clase C
nmap -sP 192.168.1.*

# TCP Connect Scan
nmap -sT 192.168.1.179

# SYN Scan
nmap -sS 192.168.1.179

# FIN Scan
nmap -sF 192.168.1.179

# UDP Scan (puertos 0–100)
nmap -sU -p 0-100 192.168.1.179

# Detección de protocolos soportados
nmap -sO 192.168.1.179

# Detección de versiones de servicios
nmap -sV 192.168.1.179

# Fingerprinting del sistema operativo
nmap -O 192.168.1.179

# Escaneo agresivo (timing alto)
nmap -sS -T insane 192.168.1.179

# Guardar resultados en fichero
nmap -sS -oN resultado.txt 192.168.1.179

# Uso de hosts señuelo (decoys)
nmap -n -D 192.168.1.5,10.5.1.2 192.168.1.179

# Mostrar ayuda de todos los scripts disponibles
nmap --script-help "*"

# Ejecutar scripts por defecto (auditoría básica)
nmap -sC 192.168.1.179

# Pruebas de vulnerabilidades HTTP
nmap --script "http-*" 192.168.1.179

# Comprobación de acceso FTP anónimo
nmap --script ftp-anon 192.168.1.179

# Captura de banners de servicios
nmap --script banner 192.168.1.179

# Auditoría no intrusiva
nmap --script "not intrusive" 192.168.1.179

# Auditoría intrusiva (agresiva)
nmap --script "intrusive" 192.168.1.179

# Ataque de fuerza bruta contra MySQL
nmap --script mysql-brute 192.168.1.179



