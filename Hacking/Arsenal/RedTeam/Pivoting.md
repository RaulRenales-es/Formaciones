# Comprobacion de IPS

ifconfig

netdiscover -i eth*

find pepito -exec "/usr/sbin/netdiscover -i eth1" \;

# Escaneo de puertos

nc -v -w 1 127.0.0.1 -z 1-1000

for var in $(seq 1 254); do nc -vv -n -w 1 192.168.7.$var 25-139 -z; done

# Ping chuli
for var in $(seq 1 254); do ping -c 2 172.0.2.$var; done

# Tuneling

desde kali ssh -L 0.0.0.0:25:192.168.7.4:445 sistemas@192.168.1.38(IP VICTIMA)

desde victima sudo ssh -L 0.0.0.0:53:192.168.1.42:53 sistemas@127.0.0.1

Continuamos en windows.



for IP in 172.0.1.{1..254}; do if ping $IP -c 1 > /dev/null; then echo $IP alive; else echo $IP dead; fi; done
