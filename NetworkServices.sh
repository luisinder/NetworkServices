#! /bin/bash
#https://github.com/luisinder
clear
echo "######################"
echo "#INSTALADOR SERVICIOS#"
echo "######################"

interfaz()
{
	echo
	echo "Interfaces de red:"
	ifconfig -a | egrep eth | cut -c 1-5
}


confinterfaz()
{
	echo "#Modificado por el script#" > /etc/network/interfaces
	echo "auto lo" >> /etc/network/interfaces
	echo "iface lo inet loopback" >> /etc/network/interfaces
	r=0
	while [ $r -eq 0 ]
	do
		clear
		echo "Introduce el nombre de la interfaz:"
		read temp
		echo "auto" $temp >> /etc/network/interfaces
		echo "iface" $temp "inet static" >> /etc/network/interfaces
		echo "Introduce la direccion Ip"
		read temp
		echo "address" $temp >> /etc/network/interfaces
		echo "Introduce la mascara de red"
		read temp
		echo "netmask" $temp >> /etc/network/interfaces
		echo "Introduce la red"
		read temp
		echo "network" $temp >> /etc/network/interfaces
		echo "Introduce el broadcast"
		read temp
		echo "broadcast" $temp >> /etc/network/interfaces
		echo "Introduce la puerta de enlace"
		read temp
		echo "gateway" $temp >> /etc/network/interfaces
		echo "Introduce los servidores DNS"
		echo "Primer Servidor DNS"
		read temp
		echo "Segundo Servidor DNS"
		read temp2
		echo "dns-nameservers" $temp $temp2 >> /etc/network/interfaces

		echo "------------------------------"
		echo "¿Quieres introducir otra interfaz?"
		echo "[0]SI"
		echo "[1]NO"
		read r

	done
	/etc/init.d/networking restart

}


instDHCP()
{
	echo "Actualizando repositorios..."
	apt-get update > /dev/null 2>/dev/null
	apt-get install isc-dhcp-server
	service isc-dhcp-server status 2>/dev/null
}


instDNS()
{
	echo "Actualizando repositorios..."
	apt-get update > /dev/null 2>/dev/null
	apt-get install bind9
	service bind9 status 2>/dev/null
	cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
}


interfDHCP()
{
	echo "Introduce separados por un espacio"
	echo "Las interfaces por las que quieres"
	echo "que el servidor DHCP escuche/sirva"
	read int
	echo 'INTERFACES="'$int'"' > /etc/default/isc-dhcp-server
}


addAmbito()
{
	echo "" >> /etc/dhcp/dhcpd.conf	
	echo "Introduce nombre ambito"
	read temp
	echo "#" $temp >> /etc/dhcp/dhcpd.conf
	echo "Introduce la subred"
	read temp
	echo "Introduce la mascara"
	read temp2
	echo "subnet" $temp "netmask" $temp2 >> /etc/dhcp/dhcpd.conf
	echo "{" >> /etc/dhcp/dhcpd.conf
	echo "Introduce el rango separado por un espacio"
	read temp
	echo "	range " $temp";">> /etc/dhcp/dhcpd.conf
	echo "Introduce la puerta de enlace"
	read temp
	echo "	option routers" $temp";">> /etc/dhcp/dhcpd.conf
	echo "Introduce nombre de Dominio"
	read temp
	echo "	option domain-name" $temp";">> /etc/dhcp/dhcpd.conf
	echo "Introduce IP del servidor DNS"
	read temp
	echo "	option domain-name-servers" $temp";">> /etc/dhcp/dhcpd.conf
	echo "Introduce el tiempo por defecto de la concesion"
	read temp
	echo "	default-lease-time" $temp";">> /etc/dhcp/dhcpd.conf
	echo "Introduce el tiempo maximo de concesion"
	read temp
	echo "	max-lease-time" $temp";">> /etc/dhcp/dhcpd.conf
	echo "}" >> /etc/dhcp/dhcpd.conf

	dhcpd -t
	service isc-dhcp-server restart
}

addEstatico()
{
	echo "" >> /etc/dhcp/dhcpd.conf
	echo "Introduce nombre dispositivo"
	read temp
	echo "host" $temp "{" >> /etc/dhcp/dhcpd.conf
	echo "Introduce MAC"
	read temp
	echo "	hardware ethernet" $temp";" >> /etc/dhcp/dhcpd.conf
	echo "Introduce IP para disp."
	read temp
	echo "	fixed-address" $temp";" >> /etc/dhcp/dhcpd.conf
	echo "}" >> /etc/dhcp/dhcpd.conf

	dhcpd -t
	service isc-dhcp-server restart
}

forw()
{
	
	cp /etc/bind/named.conf.options.bak /etc/bind/named.conf.options
	echo "Introduce los reenviadores con un ';' al final de cada uno"
	echo "(seguidos y sin espacios)"
	echo "+info: https://help.ubuntu.com/community/BIND9ServerHowto"
	read cad
	
	#/bin/sh on Ubuntu is dash, not bash
	
	sed -e "s/\/\/ forwarders {/forwarders {/g" /etc/bind/named.conf.options > /tmp/volcado.temp
	cp /tmp/volcado.temp /etc/bind/named.conf.options
	sed -e "s/\/\/ 	0.0.0.0;/$cad/g" /etc/bind/named.conf.options > /tmp/volcado.temp
	cp /tmp/volcado.temp /etc/bind/named.conf.options
	sed -e "s/\/\/ };/};/g" /etc/bind/named.conf.options > /tmp/volcado.temp
	cp /tmp/volcado.temp /etc/bind/named.conf.options
	rm -f /temp/volcado.temp 2>/dev/null
}




defDNS()
{
	noms=$(hostname)	

	echo ""> /etc/bind/named.conf.local
	rm -rf /etc/bind/zonas
	
	mkdir /etc/bind/zonas
		
	echo "Introduce el nombre de las zonas"
	read nomzon

	echo "zone" '"'$nomzon'"' "{" >> /etc/bind/named.conf.local
	echo "type master;" >> /etc/bind/named.conf.local
	echo 'file "/etc/bind/zonas/db.'$nomzon'";' >> /etc/bind/named.conf.local
	echo "};" >> /etc/bind/named.conf.local

	echo "Introduce IP zona inversa"
	echo "Recuerda introducirla al reves"
	echo "Ej: 168.192"
	read resp
	echo "zone" '"'$resp'.in-addr.arpa"' "{" >> /etc/bind/named.conf.local
	echo "type master;" >> /etc/bind/named.conf.local
	echo 'file "/etc/bind/zonas/db.'$resp'";' >> /etc/bind/named.conf.local
	echo "};" >> /etc/bind/named.conf.local
	
	echo ";" > /etc/bind/zonas/db.$nomzon
	echo "; BIND9 Zona directa" >> /etc/bind/zonas/db.$nomzon
	echo ";" >> /etc/bind/zonas/db.$nomzon
	echo "@ IN SOA" $nomzon". root@"$nomzon". (" >> /etc/bind/zonas/db.$nomzon
	echo "1 ; Serial" >> /etc/bind/zonas/db.$nomzon
	echo "604800 ; Refresh" >> /etc/bind/zonas/db.$nomzon
	echo "86400 ; Retry" >> /etc/bind/zonas/db.$nomzon
	echo "2419200 ; Expire" >> /etc/bind/zonas/db.$nomzon
	echo "604800 ) ; Default TTL" >> /etc/bind/zonas/db.$nomzon
	
	echo "Introduce IP del servidor (DNS)"
	read ipservidor

	echo "@ IN NS" $noms.$nomzon"." >> /etc/bind/zonas/db.$nomzon
	echo "@ IN A" $ipservidor >> /etc/bind/zonas/db.$nomzon
	echo $noms "IN A" $ipservidor >> /etc/bind/zonas/db.$nomzon

	
	echo ";" > /etc/bind/zonas/db.$resp
	echo "; BIND9 Zona inversa" >> /etc/bind/zonas/db.$resp
	echo ";" >> /etc/bind/zonas/db.$resp
	echo "@ IN SOA" $nomzon". root@"$nomzon". (" >> /etc/bind/zonas/db.$resp
	echo "1 ; Serial" >> /etc/bind/zonas/db.$resp
	echo "604800 ; Refresh" >> /etc/bind/zonas/db.$resp
	echo "86400 ; Retry" >> /etc/bind/zonas/db.$resp
	echo "2419200 ; Expire" >> /etc/bind/zonas/db.$resp
	echo "604800 ) ; Default TTL" >> /etc/bind/zonas/db.$resp
	echo "@ IN NS" $noms.$nomzon"." >> /etc/bind/zonas/db.$resp
	
	echo "Introduce el PTR del servidor"
	read ipservPTR
	echo $ipservPTR "IN PTR" $noms.$nomzon"." >> /etc/bind/zonas/db.$resp


	tmpzd=9
	while [ $tmpzd -ne 0 ]
	do
		echo "Registros a agregar"
		echo "[1]Servidor de Correo(MX)"
		echo "[2]Alias (CNAME)"
		echo "[3]Direcion(A)"
		echo "[0]Salir"
		read tmpzd
		case $tmpzd in 
	   		1)
				echo "Introduce nombre servidor"
				read aux
				echo "Introduce nombre servidor correo"
				read aux2
				echo $aux "IN MX 10" $aux2.$nomzon"." >> /etc/bind/zonas/db.$nomzon;;				
	    		2)
				echo "Introduce el nombre"
				echo "(El YA registrado)"
				read aux
				echo "Introduce el Alias"
				read aux2
				echo $aux2 "IN CNAME" $aux >> /etc/bind/zonas/db.$nomzon;;				 
	    		3)
				echo "Introduce la IP"
				read aux
				echo "Introduce el nombre"
				read aux2
				echo $aux2 "IN A" $aux >> /etc/bind/zonas/db.$nomzon
				echo "Introduce PTR"

				read aux3
				echo $aux3 "IN PTR" $aux2.$nomzon"." >> /etc/bind/zonas/db.$resp;;				
		esac
		
	done	
	service bind9 restart

	if [ $? -ne 0 ]; then
		echo "El servicio Bind9 no se ha reiniciado"
		echo "Prueba archivo named.conf.local"
		named-checkconf /etc/bind/named.conf.local
		echo
		echo "Prueba fichero resolucion directa"
		named-checkzone $nomzon /etc/bind/zonas/db.$nomzon
		echo
		echo "Prueba fichero resolucion inversa"
		named-checkzone $resp.in-addr.arpa /etc/bind/zonas/db.$resp
		
	else
		echo "El servicio se ha reiniciado con normalidad"
	fi

}

showDNS()
{
	clear
	bp=100
	while [ $bp -ne 0 ]
	do
		echo "--DNS FILES--"
		echo "[1]-Visualizar fichero reenviadores"
		echo "[2]-Visualizar los ficheros de zona"
		echo "[0]-Salir"
		read bp

		case $bp in
			1) clear
				if [ ! -f /etc/bind/named.conf.options ]
					then
						echo "No existe el fichero"
						echo "¿Has instalado el servicio DNS?"
					else						
						echo "--------------------------------------"
						echo "Fichero: /etc/bind/named.conf.options"
						echo "--------------------------------------"
						cat /etc/bind/named.conf.options | more
						echo "--------------------------------------"
				fi;;
			2) clear
				if [ ! -d /etc/bind/zonas ]
				then
					echo "No existe el directorio de zonas"
					echo "¿Has instalado el servicio DNS?"
					echo "En caso de haberlo hecho..."
					echo "¿Has utilizado este script para configurarlo?"					
				else
					for f in `ls /etc/bind/zonas`; do
  						echo "--------------------------------------------"
  						echo "Fichero: /etc/bind/zonas/$f"
  						echo "--------------------------------------------"
  						cat /etc/bind/zonas/$f | more
  						echo "--------------------------------------------"
					done
				fi;;
			*) 
				echo "OPC no válida";;
		esac
	done
}


show_config_files()
{
	clear
	ops=100
	while [ $ops -ne 0 ]
	do		
		echo "#VISUALIZAR FICH. CONF.#"
		echo "[1]-Ver fich. interfaces DHCP"
		echo "[2]-Ver fich. ámbitos DHCP"
		echo "[3]-Ver fich. interfaces red"
		echo "[4]-Ver fich. DNS"
		echo "[0]-Salir"
		echo -n "Introduce una opción:"
		read ops

		case $ops in
			1)	clear
				if [ ! -f /etc/default/isc-dhcp-server ]
					then
						echo "No existe el fichero"
						echo "¿Has instalado el servicio DHCP?"
					else						
						echo "--------------------------------------"
						echo "Fichero: /etc/default/isc-dhcp-server"
						echo "--------------------------------------"
						cat /etc/default/isc-dhcp-server | more
						echo "--------------------------------------"
				fi;;
			2)	clear
				if [ ! -f /etc/dhcp/dhcpd.conf ]
					then
						echo "No existe el fichero"
						echo "¿Has instalado el servicio DHCP?"
					else						
						echo "--------------------------------------"
						echo "Fichero: /etc/dhcp/dhcpd.conf"
						echo "--------------------------------------"
						cat /etc/dhcp/dhcpd.conf | more
						echo "--------------------------------------"
				fi;;
			3) 
				clear
				echo "---------------------------------"
				echo "Fichero: /etc/network/interfaces"
				echo "---------------------------------"
				cat /etc/network/interfaces | more
				echo "---------------------------------";;
			4) 
				showDNS;;
			*) 
				echo "OPC no válida";;
		esac
	done
}

m=10
while [ $m -ne 0 ]
do
	echo
	echo
	if [ $USER != 'root' ]
	then
		echo "*********************************************************"
		echo "* El script no esta siendo ejecutado como ADMINISTRADOR *"
		echo "*               EJECUTALO COMO ROOT                     *"
		echo "*********************************************************"
	fi
	
	echo "###############"
	echo "#   M E N U   #"
	echo "###############"
	echo "[1]-Ver interfaces de red"
	echo "[2]-Reiniciar nombre interfaces"
	echo "[3]-Configurar interfaces"
	echo "[4]-Instalar DHCP"
	echo "[5]-Desinstalar DHCP"
	echo "[6]-Configurar Interfaces DHCP"
	echo "[7]-Reiniciar Fichero Ambitos/Estaticos"
	echo "[8]-Agregar Ambito"
	echo "[9]-Agregar IP estatica"
	echo "[10]-Instalar DNS"
	echo "[11]-Desinstalar DNS"
	echo "[12]-Configurar reenviadores"
	echo "[13]-Definir Zonas DNS"
	echo "[14]-Visualizar ficheros configuración"
	echo "-----------------------------------------"
	echo "[0]-Salir"
	echo "-----------------------------------------"
	echo -n "Introduce una opción:"
	read m



	case $m in
		0)
			#Development use
			echo "PID:" $$
			echo "bye!";;
   		1) 
        	interfaz;;
    	2) 
        	rm -f /etc/udev/rules.d/70-persistent-net.rules 2>/dev/null
			reboot -f;; 
    	3) 
        	confinterfaz;;
		4)
			instDHCP;;
		5)
			apt-get purge --remove  isc-dhcp-server;;
		6)
			interfDHCP;;
		7)
			echo "" > /etc/dhcp/dhcpd.conf;;
		8)
			addAmbito;;
		9)
			addEstatico;;
		10)
			instDNS;;
		11)
			apt-get purge --remove  bind9;;
		12)
			forw;;
		13)
			defDNS;;
		14)
			show_config_files;;
		*)
			echo "OPC no válida";;
	esac
done