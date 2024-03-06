#!/bin/sh

START () {
	if [ -e /home/root/.initdone ]
	then
	  FLOW=flows_`hostname`.json
	  echo "updating Flow for: $(hostname)"
	else
	  FLOW=flows_*.json
	fi
	NEWFLOW=''
	testpath="/media/card $(ls -d /media/usb-* 2>/dev/null)"
	logfile="/media/card/backup/install-flow.log"
	usbinstall=false

	mountpoint -q  /media/card || {
	  echo "SDcard not mounted, mounting to /tmp/sdcard !!!"
	  mkdir /tmp/sdcard
	  mount --bind /media/card/ /tmp/sdcard
	}

	mkdir -p /media/card/backup

	###Helperfunctions
	# Übergebenen Wert aus json auslesen
	readjson() {
	  ret_val=$(grep -o "\"$1\": .*" $NEWFLOW | gawk -F'[,:]' '{gsub(/ /,"");gsub(/"/,"");print$2}')
	}

	get_hostname() {
	  tr -d " \t\n\r" < /etc/hostname
	}

	#Pruefen ob neuer Flow existiert
	for i in ${testpath}; do
		echo "testing for new Flow in ${i}"
	  if [ -e ${i}/${FLOW} ]; then NEWFLOW=$(ls ${i}/${FLOW});
	  fi
	done

	if [ -z "$NEWFLOW" ]
	then
	  tput setaf 3
	  echo "*** $(date +%F" "%T) Kein neuer Flow vorhanden...Exit ***" | tee -a ${logfile}
	  tput setaf 7
	  exit 0
	else
	  if [[ "$NEWFLOW" =~ \/media\/usb-sd[a-z][0-9]\/.*\.json ]]
	  then
		usbinstall=true
	  fi
	  echo "Neuen Flow gefunden: ${NEWFLOW}"
	  INSTALL | tee -a ${logfile}
	fi
}

PASSWD () {
### Password für Node-Red erzeugen ###
	# # PW=hostname, default PW:UDOCODE
	# # Passwordhash erzeugen
	pw=$(cd /usr/lib/node/node-red/ && node -e "console.log(require('bcrypt').hashSync(process.argv[1],8));" $(hostname))
	settings='/home/root/.node-red/settings.js'

	if ! [ -e ${settings} ]
      then cp /usr/lib/node/node-red/settings.js ${settings}
	fi

	# aktuelles admin-Password auslesen
	oldpwd=$(grep -A5 "adminAuth" $settings | grep -A1 "username: \"admin\"" | grep password)

    # neues admin-Password für den Node-Red Editor in die settings.js setzen
	# default Einstellungen sichern
	if ! [ -e $settings.bak ]
	then
	  cp $settings $settings.bak
	fi
	sed -i "s|${oldpwd}|            password: \"${pw}\",|" $settings
}

INSTALL () {
	### Neuen Flow Importieren und Geraete Netzwerk Einstellungen setzen ####

	#Start install/update 
	echo "*** $(date +%F" "%T) Installation/Update gestartet ***"

	# Hostnamen aus dem Flow auslesen
	readjson Hostname
	Hostname=${ret_val}
	echo "Hostname: ${Hostname}"

	# Geraete-IP aus dem Flow auslesen
	readjson Geraete-IP
	IP_address=${ret_val}
	echo "Geraete-IP: ${IP_address}"

	# Netmask aus dem Flow auslesen
	readjson Netmask
	Netmask=${ret_val}
	echo "Netmask: ${Netmask}"

	# Gateway-IP aus dem Flow auslesen
	readjson Gateway
	Gateway_address=${ret_val}
	echo "Gateway: ${Gateway_address}"

	# DNS1 aus dem Flow auslesen
	readjson DNS-Server1
	DNS1_IP=${ret_val}
	echo "DNS1: ${DNS1_IP}"

	# DNS2 aus dem Flow auslesen
	readjson DNS-Server2
	DNS2_IP=${ret_val}
	echo "DNS2: ${DNS2_IP}"

	# NTP-Server aus dem Flow auslesen
	readjson NTP-Server
	NTP_Server=${ret_val}
	echo "NTP-Server: ${NTP_Server}"

	# Geraete-IP und Gateway-IP konfigurieren
	sed -i "s/address.*/address ${IP_address}/" /etc/network/interfaces
	sed -i "s/netmask.*/netmask ${Netmask}/" /etc/network/interfaces
	sed -i "s/gateway.*/gateway ${Gateway_address}/" /etc/network/interfaces

	#create new resolv.conf file
	rm -f /etc/resolv.conf
	echo "resolv.conf wird neu erstellt"
	stty -echo
	echo -e  "search example.com \nnameserver ${DNS1_IP} \nnameserver ${DNS2_IP}" > /etc/resolv.conf
	stty echo

	#Neuen NTP-Server aktivieren
	sed -i "1d" /etc/ntp.conf
	sed -i '1s/^/'$NTP_Server'\n/' /etc/ntp.conf

	#Neuen Hostnamen setzen
	if [ $Hostname != $(get_hostname) ]
	then
	  echo "changing hostname..."
	  echo -e $Hostname > /etc/hostname
	  sed -i "s/127\.0\.1\.1.*/127.0.1.1 $Hostname/g" /etc/hosts
	  hostname $Hostname
	  echo "new hostname: $(hostname)"
	fi

	# Netzwerkservices neu starten um die neue Konfiguration zu übernehmen
	/etc/init.d/networking restart
	/etc/init.d/ntpd.busybox restart

	# aktuellen Flow sichern
	if [ -e /home/root/.node-red/flows_`hostname`.json ]
	  then cp /home/root/.node-red/flows_`hostname`.json /media/card/backup/flows_`hostname`_`date +"%F_%H%M"`.json
	fi

	# Neuen Flow in das Node-Red-Verzeichnis kopieren
	mv "${NEWFLOW}" /home/root/.node-red/flows_`hostname`.json

	echo "setting password for node-red"
	PASSWD

	if [ -e /var/run/node-red.pid ]
	then
	  /etc/init.d/node-red restart
	fi

	echo "install/update finished"

	# Erstinstallation erfolgreich
	if [ -e /home/root/.node-red/flows_`hostname`.json ]
	then
	  touch -a /home/root/.initdone
	fi

	if [ "$usbinstall" = true ]; then
	  dest=$(echo $NEWFLOW | rev | cut -d'/' -f2- | rev)
	  mkdir -p $dest/log $dest/backup
	  cp ${logfile} $dest/log/`hostname`_install-flow.log
	  cp $(ls -tr /media/card/backup/*.json | tail -n1) $dest/backup
	fi

	exit 0

}

case "$1" in
    start)
        echo "Starting installFlow script ... "
        HOME=/home/root
        START
        ;;
    stop)
        echo "not supported"
        ;;
    status)
        echo "not supported"
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac

exit 0
