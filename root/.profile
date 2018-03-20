# /root/.profile - main EZ-Wifibroadcast script
# (c) 2017 by Rodizio. Licensed under GPL2
#

#
# functions
#

function tmessage {
	if [ "$OSD" == "Y" ]; then
		echo $1 "$2"
	fi
}

function collect_errorlog {
	sleep 3
	echo
	if nice dmesg | nice grep -q over-current; then
		echo "ERROR: Over-current detected - potential power supply problems!"
	fi

	# check for USB disconnects (due to power-supply problems)
	if nice dmesg | nice grep -q disconnect; then
		echo "ERROR: USB disconnect detected - potential power supply problems!"
	fi

	nice mount -o remount,rw /boot

	# check if over-temp or under-voltage occured
	if vcgencmd get_throttled | nice grep -q -v "0x0"; then
		TEMP=`cat /sys/class/thermal/thermal_zone0/temp`
		TEMP_C=$(($TEMP/1000))
		if [ "$TEMP_C" -lt 75 ]; then # it must be under-voltage
			echo
			echo "	---------------------------------------------------------------------------------------------------"
			echo "	| ERROR: Under-Voltage detected on the TX Pi. Your Pi is not supplied with stable 5 Volts.		  |"
			echo "	| Either your power-supply or wiring is not sufficent, check the wiring instructions in the Wiki. |"
			echo "	| Video Bitrate will be reduced to 1000kbit to reduce current consumption!						  |"
			echo "	---------------------------------------------------------------------------------------------------"
			echo
			echo "	---------------------------------------------------------------------------------------------------" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
			echo "	| ERROR: Under-Voltage detected on the TX Pi. Your Pi is not supplied with stable 5 Volts.		  |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
			echo "	| Either your power-supply or wiring is not sufficent, check the wiring instructions in the Wiki. |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
			echo "	| Video Bitrate will be reduced to 1000kbit to reduce current consumption!						  |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
			echo "	| When you have fixed wiring/power-supply, delete this file and make sure it doesn't re-appear!	  |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
			echo "	---------------------------------------------------------------------------------------------------" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
		fi
	fi

	mv /boot/errorlog.txt /boot/errorlog-old.txt > /dev/null 2>&1
	mv /boot/errorlog.png /boot/errorlog-old.png > /dev/null 2>&1
	echo -n "Camera: "
	nice /usr/bin/vcgencmd get_camera
	uptime >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt
	echo -n "Camera: " >>/boot/errorlog.txt
	nice /usr/bin/vcgencmd get_camera >>/boot/errorlog.txt
	echo
	nice dmesg | nice grep disconnect
	nice dmesg | nice grep over-current
	nice dmesg | nice grep disconnect >>/boot/errorlog.txt
	nice dmesg | nice grep over-current >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt
	echo

	NICS=`ls /sys/class/net/ | nice grep -v eth | nice grep -v lo | nice grep -v usb`

	for NIC in $NICS
	do
	   iwconfig $NIC | grep $NIC
	done
	echo
	echo "Detected USB devices:"
	lsusb

	nice iwconfig >>/boot/errorlog.txt > /dev/null 2>&1
	echo >>/boot/errorlog.txt
	nice ifconfig >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt

	nice iw reg get >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt

	nice iw list >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt


	nice ps ax >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt

	nice df -h >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt

	nice mount >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt

	nice fdisk -l /dev/mmcblk0 >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt

	nice lsmod >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt

	nice lsusb >>/boot/errorlog.txt
	nice lsusb -v >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt
	nice ls -la /dev >>/boot/errorlog.txt
	nice ls -la /dev/input >>/boot/errorlog.txt
	echo
	nice vcgencmd measure_temp
	nice vcgencmd get_throttled
	echo >>/boot/errorlog.txt
	nice vcgencmd measure_volts >>/boot/errorlog.txt
	nice vcgencmd measure_temp >>/boot/errorlog.txt
	nice vcgencmd get_throttled >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt
	nice vcgencmd get_config int >>/boot/errorlog.txt

	nice /root/wifibroadcast_misc/raspi2png -p /boot/errorlog.png
	echo >>/boot/errorlog.txt
	nice dmesg >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt

	nice cat /etc/modprobe.d/rt2800usb.conf >> /boot/errorlog.txt
	nice cat /etc/modprobe.d/ath9k_htc.conf >> /boot/errorlog.txt
	nice cat /etc/modprobe.d/ath9k_hw.conf >> /boot/errorlog.txt
	nice cat /etc/modprobe.d/rtl8812au.conf >> /boot/errorlog.txt
	nice cat /etc/modprobe.d/rtl88XXau.conf >> /boot/errorlog.txt

	echo >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt
	nice cat /boot/wifibroadcast-1.txt | egrep -v "^(#|$)" >> /boot/errorlog.txt
	echo >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt
	nice cat /boot/osdconfig.txt | egrep -v "^(//|$)" >> /boot/errorlog.txt
	echo >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt
	nice cat /boot/joyconfig.txt | egrep -v "^(//|$)" >> /boot/errorlog.txt
	echo >>/boot/errorlog.txt
	echo >>/boot/errorlog.txt
	nice cat /boot/apconfig.txt | egrep -v "^(#|$)" >> /boot/errorlog.txt

	sync
	nice mount -o remount,ro /boot
}

function collect_debug {
	sleep 25

	DEBUGPATH=$1
	if [ "$DEBUGPATH" == "/boot" ]; then # if debugpath is boot partition, make it writeable first and move old logs
		nice mount -o remount,rw /boot
		mv /boot/debug.txt /boot/debug-old.txt > /dev/null 2>&1
	fi

	uptime >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	echo -n "Camera: " >>$DEBUGPATH/debug.txt
	nice /usr/bin/vcgencmd get_camera >>$DEBUGPATH/debug.txt
	nice dmesg | nice grep disconnect >>$DEBUGPATH/debug.txt
	nice dmesg | nice grep over-current >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt

	nice tvservice -s >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	nice tvservice -m CEA >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	nice tvservice -m DMT >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt

	nice iwconfig >>$DEBUGPATH/debug.txt > /dev/null 2>&1
	echo >>$DEBUGPATH/debug.txt
	nice ifconfig >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt

	nice iw reg get >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt

	nice iw list >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt

	nice ps ax >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt

	nice df -h >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt

	nice mount >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt

	nice fdisk -l /dev/mmcblk0 >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt

	nice lsmod >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt

	nice lsusb >>$DEBUGPATH/debug.txt
	nice lsusb -v >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	nice ls -la /dev >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	nice ls -la /dev/input >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	nice vcgencmd measure_temp >>$DEBUGPATH/debug.txt
	nice vcgencmd get_throttled >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	nice vcgencmd get_config int >>$DEBUGPATH/debug.txt

	echo >>$DEBUGPATH/debug.txt
	nice dmesg >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt

	nice cat /etc/modprobe.d/rt2800usb.conf >> $DEBUGPATH/debug.txt
	nice cat /etc/modprobe.d/ath9k_htc.conf >> $DEBUGPATH/debug.txt
	nice cat /etc/modprobe.d/ath9k_hw.conf >> $DEBUGPATH/debug.txt
	nice cat /etc/modprobe.d/rtl8812au.conf >> $DEBUGPATH/debug.txt
	nice cat /etc/modprobe.d/rtl88XXau.conf >> $DEBUGPATH/debug.txt

	echo >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	nice cat /tmp/settings.sh | egrep -v "^(#|$)" >> $DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	nice cat /boot/osdconfig.txt | egrep -v "^(//|$)" >> $DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	nice cat /boot/joyconfig.txt | egrep -v "^(//|$)" >> $DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	echo >>$DEBUGPATH/debug.txt
	nice cat /boot/apconfig.txt | egrep -v "^(#|$)" >> $DEBUGPATH/debug.txt

	nice top -n 3 -b -d 2 >>$DEBUGPATH/debug.txt

	if [ "$DEBUGPATH" == "/boot" ]; then # if debugpath is boot partition, sync and remount ro
		sync
		nice mount -o remount,ro /boot
	fi

}


function prepare_nic {
	DRIVER=`cat /sys/class/net/$1/device/uevent | nice grep DRIVER | sed 's/DRIVER=//'`
	case $DRIVER in
	*881[24]au)
		DRIVER=rtl88xxau
		;;
	esac
	if [ "$DRIVER" != "rt2800usb" ] && [ "$DRIVER" != "mt7601u" ] && [ "$DRIVER" != "ath9k_htc" ] && [ "$DRIVER" != "rtl88xxau" ]; then
		tmessage "WARNING: Unsupported or experimental wifi card: $DRIVER"	
		iw dev $1 set txpower fixed $((500*$txpower))
	fi
	tmessage -n "Setting up $1: "
	if [ "$DRIVER" == "ath9k_htc" ]; then # set bitrates for Atheros via iw
		temprate=$3
		ifconfig $1 up || {
			echo
			echo "ERROR: Bringing up interface $1 failed!"
			collect_errorlog
			sleep 365d
		}
		sleep 0.2
		if [ "$2" -gt 3000 ]; then
			if [ "$temprate" == "11" ]; then # set back to 12 to make sure ar7010 works (supports only 802.11g datarates on 5G)
				temprate=12
			fi
			tmessage -n "set 5G bitrate $temprate Mbit"
			iw dev $1 set bitrates legacy-5 $temprate || {
				echo
				echo "ERROR: Setting bitrate on $1 failed!"
				collect_errorlog
				sleep 365d
			}
		else
			tmessage -n "set 2.4G bitrate $temprate Mbit"
			iw dev $1 set bitrates legacy-2.4 $temprate || {
				echo
				echo "ERROR: Setting bitrate on $1 failed!"
				collect_errorlog
				sleep 365d
			}
		fi
		sleep 0.2
		tmessage -n " done. "
		ifconfig $1 down || {
			echo
			echo "ERROR: Bringing down interface $1 failed!"
			collect_errorlog
			sleep 365d
		}
		sleep 0.2
	fi

	tmessage -n "monitor mode.. "
	iw dev $1 set monitor none || {
		echo
		echo "ERROR: Setting monitor mode on $1 failed!"
		collect_errorlog
		sleep 365d
	}
	sleep 0.2
	tmessage -n "done. "

	ifconfig $1 up || {
		echo
		echo "ERROR: Bringing up interface $1 failed!"
		collect_errorlog
		sleep 365d
	}
	sleep 0.2

	if [ "$2" != "0" ]; then
		tmessage -n "frequency $2 MHz.. "
		iw dev $1 set freq $2 || {
		echo
		echo "ERROR: Setting frequency $2 MHz on $1 failed!"
		collect_errorlog
		sleep 365d
		}
		tmessage "done!"
	else
		echo
	fi

}


function detect_nics {
	tmessage "Setting up wifi cards ... "
	echo

	# set reg domain to DE to allow channel 12 and 13 for hotspot
	iw reg set DE

	NUM_CARDS=-1
	NICSWL=`ls /sys/class/net | nice grep wlan`

	for NIC in $NICSWL
	do
		# set MTU to 2304
		ifconfig $NIC mtu 2304
		# re-name wifi interface to MAC address
		NAME=`cat /sys/class/net/$NIC/address`
		ip link set $NIC name ${NAME//:}
		let "NUM_CARDS++"
		#sleep 0.1
	done

	if [ "$NUM_CARDS" == "-1" ]; then
		echo "ERROR: No wifi cards detected"
		collect_errorlog
		sleep 365d
	fi
	if [ "$CAM" == "0" ]; then # only do relay/hotspot stuff if RX
		# get wifi hotspot card out of the way
		if [ "$WIFI_HOTSPOT" == "Y" ]; then
			if [ "$WIFI_HOTSPOT_NIC" != "internal" ]; then
				# only configure it if it's there
				if ls /sys/class/net/ | grep -q $WIFI_HOTSPOT_NIC; then
					tmessage -n "Setting up $WIFI_HOTSPOT_NIC for Wifi Hotspot operation.. "
					ip link set $WIFI_HOTSPOT_NIC name wifihotspot0
					ifconfig wifihotspot0 192.168.2.1 up
					echo  "Y" > /tmp/wifihotspot
					tmessage "done!"
					let "NUM_CARDS--"
				else
					tmessage "Wifi Hotspot card $WIFI_HOTSPOT_NIC not found!"
					echo  "N" > /tmp/wifihotspot
					sleep 0.5
				fi
			else
				# only configure it if it's there
				if ls /sys/class/net/ | grep -q intwifi0; then
					tmessage -n "Setting up intwifi0 for Wifi Hotspot operation.. "
					ip link set intwifi0 name wifihotspot0
					ifconfig wifihotspot0 192.168.2.1 up
					echo  "Y" > /tmp/wifihotspot
					tmessage "done!"
				else
					tmessage "Pi Onboard Wifi Hotspot card not found!"
					echo  "N" > /tmp/wifihotspot
					sleep 0.5
				fi
			fi
		fi
		# get relay card out of the way
		if [ "$RELAY" == "Y" ]; then
			# only configure it if it's there
			if ls /sys/class/net/ | grep -q $RELAY_NIC; then
				ip link set $RELAY_NIC name relay0
				prepare_nic relay0 $RELAY_FREQ $VIDEO_WIFI_BITRATE
				let "NUM_CARDS--"
			else
				tmessage "Relay card $RELAY_NIC not found!"
				sleep 0.5
			fi
		fi
	else
		if [ "$TELEMETRY_TRANSMISSION" == "wbc" ]; then
			if [ -e "$FC_TELEMETRY_SERIALPORT" ]; then
				echo "Configured serial port $FC_TELEMETRY_SERIALPORT found ..."
				# setup TELEMETRY serial port
				stty -F $FC_TELEMETRY_SERIALPORT $FC_TELEMETRY_STTY_OPTIONS $TELEMETRY_BAUDRATE
			else
				echo "ERROR: $FC_TELEMETRY_SERIALPORT not found!"
				collect_errorlog
				sleep 365d
			fi
			if [ "$FC_TELEMETRY_SERIALPORT" != "$FC_RC_SERIALPORT" ] && [ "$RC" != "disabled" ]; then
				# setup RC serial port
				if [ ! -e "$FC_RC_SERIALPORT" ]; then
					echo "ERROR: $FC_RC_SERIALPORT not found!"
					collect_errorlog
					sleep 365d
				fi
				stty -F $FC_RC_SERIALPORT $FC_RC_STTY_OPTIONS $FC_RC_BAUDRATE
			fi
		else
			if [ "$RC" != "disabled" ]; then
				# setup RC serial port
				if [ ! -e "$FC_RC_SERIALPORT" ]; then
					echo "ERROR: $FC_RC_SERIALPORT not found!"
					collect_errorlog
					sleep 365d
				fi
				stty -F $FC_RC_SERIALPORT $FC_RC_STTY_OPTIONS $FC_RC_BAUDRATE
			fi
		fi
	fi

	NICS=`ls /sys/class/net/ | nice grep -v eth | nice grep -v lo | nice grep -v usb | nice grep -v intwifi | nice grep -v relay | nice grep -v wifihotspot`
#	echo "NICS: $NICS"
	echo "$NUM_CARDS" > /tmp/numcards
	if [ "$TXMODE" != "single" ]; then
		if [ "$TXMODE" == "auto" ]; then
			NUM_NIC=0
			for NIC in $NICS
			do
				if [ "$CAM" == "0" ]; then
					MAC_RX[$NUM_NIC]=$NIC
				else
					MAC_TX[$NUM_NIC]=$NIC
				fi
				let "NUM_NIC++"
			done
			FREQ_RX[0]=${FREQ_TX[0]}
			FREQ_RX[1]=${FREQ_TX[1]}
			FREQ_RX[2]=${FREQ_TX[0]}
			FREQ_RX[3]=${FREQ_TX[1]}
		fi
		for i in $(eval echo {0..$NUM_CARDS})
		do
			if [ "$CAM" == "0" ]; then
				prepare_nic ${MAC_RX[$i]} ${FREQ_RX[$i]} $UPLINK_WIFI_BITRATE
			else
				prepare_nic ${MAC_TX[$i]} ${FREQ_TX[$i]} $VIDEO_WIFI_BITRATE
			fi
			sleep 0.1
		done
	else
		# check if auto scan is enabled, if yes, set freq to 0 to let prepare_nic know not to set channel
		if [ "$FREQSCAN" == "Y" ] && [ "$CAM" == "0" ]; then
			G_RN=Y
			S_RN=Y
			L_RN=Y
			for NIC in $NICS
			do
				prepare_nic $NIC 2412 $UPLINK_WIFI_BITRATE
				sleep 0.1
#				if iwlist $NIC frequency | grep -q 5.18; then # cards support 5G
				if iw dev $NIC set freq 5180 > /dev/null 2>&1; then # cards support 5G
					echo -n "$NIC support 5G"
					sleep 0.1
					if iw dev $NIC set freq 5745 > /dev/null 2>&1; then # cards support 5.8G
						echo -n " and support 5.8G"
					else
						echo -n " not support 5.8G"
						S_RN=N
					fi
				else
					echo -n "$NIC not support 5G"
					G_RN=N
					S_RN=N
				fi
				sleep 0.1
#				if iwlist $NIC frequency | nice grep -q 2.312; then # cards support 2.3G and 2.4G
				if iw dev $NIC set freq 2312 > /dev/null 2>&1; then # cards support 2.3G and 2.4G
					echo " and support 2.3G"
				else # cards support only 2.4G and 5G
					echo " not support 2.3G"
					L_RN=N
				fi
				sleep 0.1
			done
			
			# make sure check_alive function doesnt restart hello_video while we are still scanning for channel
			touch /tmp/pausewhile
			ionice -c 1 -n 3 wfb_rx -u 5621 -p 23 -c 127.0.0.1 -n $VIDEO_NUM -k $VIDEO_BLOCKS -l 200 $NICS >/dev/null 2>/dev/null &
			ionice -c 1 -n 3 /root/wifibroadcast/rx -p 0 -d 1 -b $VIDEO_BLOCKS -r $VIDEO_FECS -f $VIDEO_BLOCKLENGTH $NICS >/dev/null &
			sleep 0.5
			echo
			FREQ=0
			echo "The frequency shared by all cards:2.3G:$L_RN 5.2G:$G_RN 5.8G:$S_RN Please wait, scanning for TX"
			while [ $FREQ -eq 0 ]; do
				if [ "$G_RN" == "Y" ]; then
					freq_scan 5180 5320 20
					if [ $S_RN == "Y" ]; then
						freq_scan 5745 5825 20
						freq_scan 5500 5700 20
					fi
				fi
				if [ $L_RN == "Y" ]; then
					freq_scan 2312 2407 10
				fi
				freq_scan 2412 2472 10
			done
			echo
			echo "found on $FREQ MHz"
			echo
			ps -ef | nice grep "rx -p 0" | nice grep -v grep | awk '{print $2}' | xargs kill -9
			ps -ef | nice grep "wfb_rx -u" | nice grep -v grep | awk '{print $2}' | xargs kill -9

			# all done

		else
			for NIC in $NICS
			do
				if [ "$CAM" == "0" ]; then
					prepare_nic $NIC $FREQ $UPLINK_WIFI_BITRATE
				else
					prepare_nic $NIC $FREQ $VIDEO_WIFI_BITRATE
				fi
				sleep 0.1
			done
		fi
		
		if [ "$AIRODUMP" == "Y" ] && [ "$CAM" == "0" ]; then
			killall wbc_status > /dev/null 2>&1
			touch /tmp/pausewhile # make sure check_alive doesn't do it's stuff ...
			echo "AiroDump is enabled, running airodump-ng for $AIRODUMP_SECONDS seconds ..."
			# strip newlines
			NICS_COMMA=`echo $NICS | tr '\n' ' '`
			# strip space at end
			NICS_COMMA=`echo $NICS_COMMA | sed 's/ *$//g'`
			# replace spaces by comma
			NICS_COMMA=${NICS_COMMA// /,}
			if [ "$FREQ" -gt 3000 ]; then
				AIRODUMP_CHANNELS="5180,5200,5220,5240,5260,5280,5300,5320,5500,5520,5540,5560,5580,5600,5620,5640,5660,5680,5700,5745,5765,5785,5805,5825"
			else
				AIRODUMP_CHANNELS="2412,2417,2422,2427,2432,2437,2442,2447,2452,2457,2462,2467,2472"
			fi
			airodump-ng --showack -h --berlin 60 --ignore-negative-one --manufacturer --output-format pcap --write /wbc_tmp/wifiscan --write-interval 2 -C $AIRODUMP_CHANNELS  $NICS_COMMA &
			sleep $AIRODUMP_SECONDS
			ionice -c 3 nice -n 19 /root/wifibroadcast_misc/raspi2png -p /wbc_tmp/airodump.png >> /dev/null
			killall airodump-ng
			sleep 1
			printf "\033c"
			for NIC in $NICS
			do
				iw dev $NIC set freq $FREQ
				sleep 0.1
			done
			sleep 1
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
			echo
		fi
	fi
	touch /tmp/nics_configured # let other processes know nics are setup and ready
}

## runs on RX (ground pi)
function freq_scan {
	if [ $FREQ -eq 0 ]; then
		for((i=$1; i<=$2;i+=$3));
		do
			for NIC in $NICS
			do				
				if iw dev $NIC set freq ${i} > /dev/null 2>&1; then
					echo -n "+"
				else # cards support only 2.4G and 5G
					echo -n "-"
				fi
				sleep 0.1
			done
			echo -n "${i}"
			SCANCHAN=`nice /root/wifibroadcast/channelscan`
			if [ $SCANCHAN == "0" ]; then
				echo -n ":"
				FREQ=0
			else
				FREQ=${i}
				break
			fi	
		done
	fi
}


## runs on RX (ground pi)
function check_alive_function {
	SINGLECORE=`cat /tmp/SINGLECORE`
	source /tmp/videofile
	echo "Waiting until nics are configured ..."
	while [ ! -f /tmp/nics_configured ]; do
		sleep 0.5
		#echo -n "."
	done
	sleep 2
	# function to check if packets coming in, if not, re-start hello_video to clear frozen display
	while true; do
	# pause while saving is in progress
		pause_while
		ALIVE=`nice /root/wifibroadcast/check_alive`
		PIP=`cat /tmp/pip`
		FX1=`cat /tmp/FX1`
		FX2=`cat /tmp/FX2`
		FX3=`cat /tmp/FX3`
		if [ "$FX1" == "N" ] && [ "$FX2" == "N" ] && [ "$FX3" == "N" ]; then
			FXIP=N
		else
			FXIP=Y
		fi
		if [ $ALIVE == "0" ]; then
			if [ "$FXIP" == "N" ] || [ "$SINGLECORE" == "N" ]; then
				echo "no new packets, restarting hello_video and sleeping for 5s ..."
				ps -ef | nice grep "cat /root/steamfifo1" | nice grep -v grep | awk '{print $2}' | xargs kill -9
				ps -ef | nice grep "cat /root/videofifo1" | nice grep -v grep | awk '{print $2}' | xargs kill -9
				ps -ef | nice grep "$DISPLAY_PROGRAM" | nice grep -v grep | awk '{print $2}' | xargs kill -9
				if [ "$PIP" == "S" ]; then
					ionice -c 1 -n 4 nice -n -10 cat /root/steamfifo1 | ionice -c 1 -n 4 nice -n -10 $DISPLAY_PROGRAM > /dev/null 2>&1 &
				else
					ionice -c 1 -n 4 nice -n -10 cat /root/videofifo1 | ionice -c 1 -n 4 nice -n -10 $DISPLAY_PROGRAM > /dev/null 2>&1 &
				fi
			fi
		else
			if [ "$PIP" == "S" ]; then
				echo "R" > /tmp/pip
				if [ "$SINGLECORE" == "N" ]; then
					ps -ef | nice grep "cat /root/steamfifo1" | nice grep -v grep | awk '{print $2}' | xargs kill -9
					ps -ef | nice grep "cat /root/steamfifo3" | nice grep -v grep | awk '{print $2}' | xargs kill -9
					ps -ef | nice grep "$DISPLAY_PROGRAM" | nice grep -v grep | awk '{print $2}' | xargs kill -9
					ionice -c 1 -n 4 nice -n -10 cat /root/videofifo1 | ionice -c 1 -n 4 nice -n -10 $DISPLAY_PROGRAM > /dev/null 2>&1 &
					if [ "$VIDEO_TMP" != "disabled" ]; then
						ionice -c 3 nice cat /root/videofifo3 >> $VIDEOFILE &
					fi
				elif [ -f "/tmp/single" ]; then
					ps -ef | nice grep "gst-launch-1.0 udpsrc" | nice grep -v grep | awk '{print $2}' | xargs kill -9
				fi
				UDP_PORT1=$VIDEO_UDP_PORT2
				UDP_PORT2=$VIDEO_UDP_PORT1
			else
				echo "S" > /tmp/pip
				if [ "$SINGLECORE" == "N" ]; then
					ps -ef | nice grep "cat /root/videofifo1" | nice grep -v grep | awk '{print $2}' | xargs kill -9
					ps -ef | nice grep "cat /root/videofifo3" | nice grep -v grep | awk '{print $2}' | xargs kill -9
					ps -ef | nice grep "$DISPLAY_PROGRAM" | nice grep -v grep | awk '{print $2}' | xargs kill -9
					ionice -c 1 -n 4 nice -n -10 cat /root/steamfifo1 | ionice -c 1 -n 4 nice -n -10 $DISPLAY_PROGRAM > /dev/null 2>&1 &
					if [ "$VIDEO_TMP" != "disabled" ]; then
							ionice -c 3 nice cat /root/steamfifo3 >> $VIDEOFILE &
					fi
				elif [ -f "/tmp/single" ]; then
					ps -ef | nice grep "rx -p 0" | nice grep -v grep | awk '{print $2}' | xargs kill -9
				fi
				UDP_PORT1=$VIDEO_UDP_PORT1
				UDP_PORT2=$VIDEO_UDP_PORT2
			fi
			if [ "$FXIP" != "N" ]; then
				ps -ef | nice grep "UDPSplitter" | nice grep -v grep | awk '{print $2}' | xargs kill -9
				nice -n -10 $SPLIT_PROGRAM 9120 5612 $UDP_PORT1 &
				sleep 1
				nice -n -10 $SPLIT_PROGRAM 9220 5512 $UDP_PORT2 &
				sleep 1
				if [ "$FX1" != "N" ]; then
					echo "add $FX1" > /dev/udp/127.0.0.1/9120
					echo "add $FX1" > /dev/udp/127.0.0.1/9220
				fi
				if [ "$FX2" != "N" ]; then
					echo "add $FX2" > /dev/udp/127.0.0.1/9120
					echo "add $FX2" > /dev/udp/127.0.0.1/9220							
				fi
				if [ "$FX3" != "N" ]; then
					echo "add $FX3" > /dev/udp/127.0.0.1/9120
					echo "add $FX3" > /dev/udp/127.0.0.1/9220								
				fi
			fi
		fi
		sleep 2
	done
}


function check_exitstatus {
	STATUS=$1
	case $STATUS in
	9)
	# rx returned with exit code 9 = the interface went down
	# wifi card must've been removed during running
	# check if wifi card is really gone
	NICS2=`ls /sys/class/net/ | nice grep -v eth | nice grep -v lo | nice grep -v usb | nice grep -v intwifi | nice grep -v relay | nice grep -v wifihotspot`
	if [ "$NICS" == "$NICS2" ]; then
		# wifi card has not been removed, something else must've gone wrong
		echo "ERROR: RX stopped, wifi card _not_ removed!			  "
	else
		# wifi card has been removed
		echo "ERROR: Wifi card removed!								  "
	fi
	;;
	2)
	# something else that is fatal happened during running
	echo "ERROR: RX chain stopped wifi card _not_ removed!			   "
	;;
	1)
	# something that is fatal went wrong at rx startup
	echo "ERROR: could not start RX							  "
	#echo "ERROR: could not start RX						   "
	;;
	*)
	if [  $RX_EXITSTATUS -lt 128 ]; then
		# whatever it was ...
		#echo "RX exited with status: $RX_EXITSTATUS						"
		echo -n ""
	fi
	;;
	esac
}

function veyecam_cmd {
	if ./cs_mipi_i2c.sh -r -f productmodel | grep -q CS-MIPI-IMX307; then
		./cs_mipi_i2c.sh -w -f videofmt -p1 $WIDTH -p2 $HEIGHT -p4 $FPS -b $1 >> /tmp/imx290log
#		./cs_mipi_i2c.sh -w -f streammode -p1 0 -b $1 >> /tmp/imx290log
#		./cs_mipi_i2c.sh -w -f expmode -p1 0 -b $1 >> /tmp/imx290log
#		./cs_mipi_i2c.sh -w -f awbmode -p1 0 -b $1 >> /tmp/imx290log
		./cs_mipi_i2c.sh -w -f powerhz -p1 $IMX307_videoformat -b $1 >> /tmp/imx290log
		./cs_mipi_i2c.sh -w -f imagedir -p1 $IMX307_mirrormode -b $1 >> /tmp/imx290log
		./cs_mipi_i2c.sh -w -f daynightmode -p1 $IMX307_daynightmode -b $1 >> /tmp/imx290log
		./cs_mipi_i2c.sh -w -f satu -p1 $IMX307_saturation -b $1 >> /tmp/imx290log
		./cs_mipi_i2c.sh -w -f aetarget -p1 $IMX307_aetarget -b $1 >> /tmp/imx290log
		./cs_mipi_i2c.sh -w -f hue -p1 $IMX307_hue -b $1 >> /tmp/imx290log
		./cs_mipi_i2c.sh -w -f contrast -p1 $IMX307_contrast -b $1 >> /tmp/imx290log
#		./cs_mipi_i2c.sh -w -f paramsave >> /tmp/imx290log
#		./cs_mipi_i2c.sh -w -f sysreboot -p1 1
	else
		./veye_mipi_i2c.sh -w -f cameramode -p1 0x0 -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f videoformat -p1 $IMX327_videoformat -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f wdrmode -p1 $IMX327_wdrmode -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f mirrormode -p1 $IMX327_mirrormode -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f denoise -p1 $IMX327_denoise -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f daynightmode -p1 $IMX327_daynightmode -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f saturation -p1 $IMX327_saturation -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f agc -p1 $IMX327_agc -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f aespeed  -p1 $IMX327_aespeed1 -p2 $VEYE_aespeed2 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f brightness -p1 $IMX327_brightness -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f contrast -p1 $IMX327_contrast -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f wdrtargetbr -p1 $IMX327_wdrtargetbr -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f wdrbtargetbr -p1 $IMX327_wdrbtargetbr -b $1 >> /tmp/imx290log
		./veye_mipi_i2c.sh -w -f sharppen -p1 $IMX327_sharppen1 -p2 $VEYE_sharppen2 >> /tmp/imx290log
	fi
}

## runs on TX (air pi)
function tx_function {
	killall wbc_status > /dev/null 2>&1

	/root/wifibroadcast/sharedmem_init_tx

	if [ "$TXMODE" == "single" ]; then
		echo -n "Waiting for wifi card to become ready ..."
		COUNTER=0
		# loop until card is initialized
		while [ $COUNTER -lt 10 ]; do
			sleep 0.5
			echo -n "."
			let "COUNTER++"
			if [ -d "/sys/class/net/wlan0" ]; then
				echo -n "card ready"
				break
			fi
		done
	else
		# just wait some time
		echo -n "Waiting for wifi cards to become ready ..."
		sleep 3
	fi

	echo
	echo
	dmesg -c >/dev/null 2>/dev/null

	if [ "$CAM" == "6" ] || [ "$CAM" == "7" ] || [ "$CAM" == "8" ] || [ "$CAM" == "9" ] || [ "$CAM" == "10" ] || [ "$CAM" == "11" ] || [ "$CAM" == "12" ]; then
		cams=Y
	fi
	if [ "$cams" == "Y" ]; then
		case $VIDEO_WIFI_BITRATE in
			6)
			VIDEO_WIFI_BITRATE=12
			MCS=1
			SGI=1
			;;
			11)
			VIDEO_WIFI_BITRATE=18
			MCS=2
			SGI=1
			;;
			12)
			VIDEO_WIFI_BITRATE=24
			MCS=3
			;;
			18)
			VIDEO_WIFI_BITRATE=36
			MCS=4
			SGI=1
			;;
			24)
			VIDEO_WIFI_BITRATE=48
			MCS=5
			;;
			36)
			VIDEO_WIFI_BITRATE=54
			MCS=5
			SGI=1
			;;
		esac
	fi

	detect_nics

	sleep 1
	echo

	if [ $FRAMETYPE -eq 1 ]; then
		echo "1" > /tmp/cts
	else
		echo "0" > /tmp/cts
	fi

#	 if [ "$VIDEO_WIFI_BITRATE" == "11" ] || [ "$VIDEO_WIFI_BITRATE" == "5" ]; then # 11mbit and 5mbit bitrates don't support CTS, so set to 0
#		echo "0" > /tmp/cts
#	 else
#		echo "1" > /tmp/cts
#	 fi
#	 if [ "$VIDEO_WIFI_BITRATE" == "19.5" ]; then # set back to 18 to make sure -d parameter works (supports only 802.11b/g datarates)
#		VIDEO_WIFI_BITRATE=18
#	 fi
#	 if [ "$VIDEO_WIFI_BITRATE" == "5.5" ]; then # set back to 5 to make sure -d parameter works (supports only 802.11b/g datarates)
#		VIDEO_WIFI_BITRATE=5
#	 fi

	# check if over-temp or under-voltage occured before bitrate measuring
	if vcgencmd get_throttled | nice grep -q -v "0x0"; then
		TEMP=`cat /sys/class/thermal/thermal_zone0/temp`
		TEMP_C=$(($TEMP/1024))
		if [ "$TEMP_C" -lt 75 ]; then # it must be under-voltage
			echo
			echo "	---------------------------------------------------------------------------------------------------"
			echo "	| ERROR: Under-Voltage detected on the TX Pi. Your Pi is not supplied with stable 5 Volts.		  |"
			echo "	| Either your power-supply or wiring is not sufficent, check the wiring instructions in the Wiki. |"
			echo "	| Video Bitrate will be reduced to 1000kbit to reduce current consumption!						  |"
			echo "	---------------------------------------------------------------------------------------------------"
			echo
			mount -o remount,rw /boot
			echo "	---------------------------------------------------------------------------------------------------" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
			echo "	| ERROR: Under-Voltage detected on the TX Pi. Your Pi is not supplied with stable 5 Volts.		  |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
			echo "	| Either your power-supply or wiring is not sufficent, check the wiring instructions in the Wiki. |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
			echo "	| Video Bitrate will be reduced to 1000kbit to reduce current consumption!						  |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
			echo "	| When you have fixed wiring/power-supply, delete this file and make sure it doesn't re-appear!	  |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
			echo "	---------------------------------------------------------------------------------------------------" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
			mount -o remount,ro /boot
			UNDERVOLT=1
			echo "1" > /tmp/undervolt
		else # it was either over-temp or both undervolt and over-temp, we set undervolt to 0 anyway, since overtemp can be seen at the temp display on the rx
			UNDERVOLT=0
			echo "0" > /tmp/undervolt
		fi
	else
		UNDERVOLT=0
		echo "0" > /tmp/undervolt
	fi

	# if yes, we don't do the bitrate measuring to increase chances we "survive"
	if [ "$UNDERVOLT" == "0" ]; then
		if [ "$VIDEO_BITRATE" == "auto" ]; then
			echo -n "Measuring max. available bitrate .. "
			BITRATE_MEASURED=$(cat /dev/zero | /root/wifibroadcast/tx_rawsock -z 1 -p 77 -b $VIDEO_BLOCKS -r $VIDEO_FECS -f $VIDEO_BLOCKLENGTH -t $FRAMETYPE -d $MCS -G $SGI -S $STBC -L $LDPC -y 0 $NICS)
			BITRATE=$((BITRATE_MEASURED*$VIDEO_BLOCKS/$VIDEO_NUM))
			BITRATE_KBIT=$((BITRATE/1024))
			BITRATE_MEASURED_KBIT=$((BITRATE_MEASURED/1024))
			echo "$BITRATE_MEASURED_KBIT kBit/s * $VIDEO_BLOCKS/$VIDEO_NUM = $BITRATE_KBIT kBit/s video bitrate"
			if [ "$cams" == "Y" ]; then
				BITRATE=$((BITRATE/2))
			fi
		else
			if [ "$VIDEO_BITRATE" -le 100 ]; then
				echo -n "Measuring max. available bitrate .. "
				BITRATE_MEASURED=$(cat /dev/zero | /root/wifibroadcast/tx_rawsock -z 1 -p 77 -b $VIDEO_BLOCKS -r $VIDEO_FECS -f $VIDEO_BLOCKLENGTH -t $FRAMETYPE -d $MCS -G $SGI -S $STBC -L $LDPC -y 0 $NICS)
				BITRATE=$((BITRATE_MEASURED*$VIDEO_BITRATE/100))
				BITRATE_KBIT=$((BITRATE/1024))
				BITRATE_MEASURED_KBIT=$((BITRATE_MEASURED/1024))
				echo "$BITRATE_MEASURED_KBIT kBit/s * $VIDEO_BITRATE% = $BITRATE_KBIT kBit/s video bitrate"
				if [ "$cams" == "Y" ]; then
					BITRATE=$((BITRATE/2))
				fi
			else
				BITRATE=$(($VIDEO_BITRATE*1024))
				BITRATE_KBIT=$VIDEO_BITRATE
				BITRATE_MEASURED_KBIT=$VIDEO_BITRATE
				echo "Using fixed bitrate: $VIDEO_BITRATE kBit"
			fi
		fi
	else
		BITRATE=$((1024*1024))
		BITRATE_KBIT=1024
		BITRATE_MEASURED_KBIT=2048
		echo "Using reduced bitrate: 1024 kBit due to undervoltage!"
	fi

	# check again if over-temp or under-voltage occured after bitrate measuring (but only if it didn't occur before yet)
	if [ "$UNDERVOLT" == "0" ]; then
		if vcgencmd get_throttled | nice grep -q -v "0x0"; then
			TEMP=`cat /sys/class/thermal/thermal_zone0/temp`
			TEMP_C=$(($TEMP/1024))
			if [ "$TEMP_C" -lt 75 ]; then # it must be under-voltage
				echo
				echo "	---------------------------------------------------------------------------------------------------"
				echo "	| ERROR: Under-Voltage detected on the TX Pi. Your Pi is not supplied with stable 5 Volts.		  |"
				echo "	| Either your power-supply or wiring is not sufficent, check the wiring instructions in the Wiki. |"
				echo "	| Video Bitrate will be reduced to 1000kbit to reduce current consumption!						  |"
				echo "	---------------------------------------------------------------------------------------------------"
				echo
				mount -o remount,rw /boot
				echo "	---------------------------------------------------------------------------------------------------" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
				echo "	| ERROR: Under-Voltage detected on the TX Pi. Your Pi is not supplied with stable 5 Volts.		  |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
				echo "	| Either your power-supply or wiring is not sufficent, check the wiring instructions in the Wiki. |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
				echo "	| Video Bitrate will be reduced to 1000kbit to reduce current consumption!						  |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
				echo "	| When you have fixed wiring/power-supply, delete this file and make sure it doesn't re-appear!	  |" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
				echo "	---------------------------------------------------------------------------------------------------" >> /boot/UNDERVOLTAGE-ERROR!!!.txt
				mount -o remount,ro /boot
				UNDERVOLT=1
				echo "1" > /tmp/undervolt
				BITRATE=$((1024*1024))
				BITRATE_KBIT=1024
				BITRATE_MEASURED_KBIT=2048
			else # it was either over-temp or both undervolt and over-temp, we set undervolt to 0 anyway, since overtemp can be seen at the temp display on the rx
				UNDERVOLT=0
				echo "0" > /tmp/undervolt
			fi
		else
			UNDERVOLT=0
			echo "0" > /tmp/undervolt
		fi
	fi

	# check for over-current on USB bus (due to card being powered via usb instead directly)
	if nice dmesg | nice grep -q over-current; then
		echo "ERROR: Over-current detected - potential power supply problems!"
		collect_errorlog
		sleep 365d
	fi

	# check for USB disconnects (due to power-supply problems)
	if nice dmesg | nice grep -q disconnect; then
		echo "ERROR: USB disconnect detected - potential power supply problems!"
		collect_errorlog
		sleep 365d
	fi

	echo $BITRATE_KBIT > /tmp/bitrate_kbit
	echo $BITRATE_MEASURED_KBIT > /tmp/bitrate_measured_kbit

	if [ "$DEBUG" == "Y" ]; then
		collect_debug /boot &
	fi

	/root/wifibroadcast/rssitx -c $FRAMETYPE -d $STBC $NICS &

	echo "Wifi bitrate: $VIDEO_WIFI_BITRATE, Video frametype: $FRAMETYPE"
#	if [ "$CAM" == "4" ] || [ "$CAM" == "9"  ] || [ "$CAM" == "10" ] || [ "$CAM" == "11" ] || [ "$CAM" == "12" ]; then
#	    USBCAMWIDTH=`echo $USBCAM | nice grep width | sed -n 's/^.*width=//p' | cut -d ' ' -f 1 | cut -d ',' -f 1`
#		echo "USBCAMWIDTH:$USBCAMWIDTH"
#		USBCAMHEIGHT=`echo $USBCAM | nice grep height | sed -n 's/^.*height=//p' | cut -d ' ' -f 1 | cut -d ',' -f 1`
#		echo "USBCAMHEIGHT:$USBCAMHEIGHT"
#		USBCAMFPS=`echo $USBCAM | nice grep framerate | sed -n 's/^.*framerate=//p' | cut -d '/' -f 1`
#		echo "USBCAMFPS:$USBCAMFPS"
#		if [ "$USBCAMHEIGHT" == "960" ]; then
#			echo "Note: This is an Insta 360 AIR special resolution!"
#			v4l2-ctl -V
#		else
#			v4l2-ctl --list-formats
#			v4l2-ctl -p $USBCAMFPS
#			v4l2-ctl -v width=$USBCAMWIDTH,height=$USBCAMHEIGHT,pixelformat=H264
#			v4l2-ctl --set-fmt-video=width=$USBCAMWIDTH,height=$USBCAMHEIGHT,pixelformat=H264
#			v4l2-ctl -v width=$USBCAMWIDTH,height=$USBCAMHEIGHT
#			v4l2-ctl --set-fmt-video=width=$USBCAMWIDTH,height=$USBCAMHEIGHT,pixelformat=MJPG
#			v4l2-ctl --set-ctrl h264_i_frame_period=$KEYFRAMERATE
#			v4l2-ctl --set-ctrl video_bitrate=$BITRATE
#			v4l2-ctl --set-ctrl repeat_sequence_header=1
#			v4l2-ctl --set-ctrl video_bitrate=$BITRATE,repeat_sequence_header=1,h264_i_frame_period=$KEYFRAMERATE,white_balance_auto_preset=5
#			v4l2-ctl -P
#			v4l2-ctl --list-framesizes=H264
#			rmmod uvcvideo
#			modprobe uvcvideo nodrop=1 timeout=5000
#		fi
#	fi

	if [ "$CAM" == "1" ] || [ "$CAM" == "6" ] || [ "$CAM" == "10" ]; then
		if [ "$CSI" == "2" ]; then	
			raspi-gpio set 2 op pn dh
			raspi-gpio set 3 op pn dh
			raspi-gpio set 30 op pn dh
			raspi-gpio set 31 op pn dh
		fi
		# if a tc358743 is detected,FIX bug framerate.
		i2cdetect -y 0 | grep "00:			-- -- -- -- -- -- -- -- -- -- -- -- 0f"
		grepRet=$?
		if [ $grepRet -eq 0 ]; then
			echo "HDMI to CSI via tc358743"
			EFFECT="-awb off -ex off"
#			FPS=59.9
		fi
	fi
	USBCAM=${USBCAM//VIDEOBITRATE/$BITRATE}
	CSI_CMD="nice -n -9 raspivid -w $WIDTH -h $HEIGHT -fps $FPS -b $BITRATE -g $KEYFRAMERATE -t 0 $EXTRAPARAMS $EFFECT"
	RAW_CMD="nice -n -9 /root/wifibroadcast/tx_rawsock -p 0 -b $VIDEO_BLOCKS -r $VIDEO_FECS -f $VIDEO_BLOCKLENGTH -t $FRAMETYPE -d $MCS -G $SGI -S $STBC -L $LDPC -y 0 $NICS"
	VEYE_CMD="nice -n -9 /root/veyecam/bin/veye_raspivid -w $WIDTH -h $HEIGHT -fps $FPS -b $BITRATE -g $KEYFRAMERATE -t 0 $EXTRAPARAMS"
	CSI_SVP_CMD="gst-launch-1.0 fdsrc ! h264parse ! rtph264pay mtu=1400 ! udpsink host=127.0.0.1 port=5600"
	IPC_SVP_CMD="nice -n -9 gst-launch-1.0 $IPCAM ! udpsink host=127.0.0.1 port=5600"
#	USB_SVP_CMD="nice -n -9 gst-launch-1.0 $USBCAM ! h264parse config-interval=1 ! rtph264pay ! udpsink host=127.0.0.1 port=5600"
	USB_SVP_CMD="nice -n -9 gst-launch-1.0 $USBCAM ! h264parse disable-passthrough=true ! rtph264pay mtu=1400 ! udpsink host=127.0.0.1 port=5600"

	case $CAM in
		"1")
			if [ "$STREAM" == "svpcom" ]; then
				echo "$CSI_CMD -o - | $CSI_SVP_CMD"
				$CSI_CMD -o - | $CSI_SVP_CMD > /dev/null 2>&1 &
			else
				echo "$CSI_CMD -o - | $RAW_CMD"
				$CSI_CMD -o - | $RAW_CMD
			fi
		;;
		"2")
			echo "Dualcam"
			vcdbg set awb_mode 0
			if [ "$STREAM" == "svpcom" ]; then
				echo "$CSI_CMD -3d sbs -o - | $CSI_SVP_CMD"
				$CSI_CMD -3d sbs -o - | $CSI_SVP_CMD > /dev/null 2>&1 &
			else
				echo "$CSI_CMD -3d sbs -o - | $RAW_CMD"
				$CSI_CMD -3d sbs -o - | $RAW_CMD
			fi
		;;
		"3")
			echo "VEYECAM"
			if [ "$STREAM" == "svpcom" ]; then
				echo "$VEYE_CMD -o - | $CSI_SVP_CMD"
				$VEYE_CMD -o - | $CSI_SVP_CMD > /dev/null 2>&1 &
			else
				echo "$VEYE_CMD -o - | $RAW_CMD"
				$VEYE_CMD -o - | $RAW_CMD
			fi
		;;
		"4")
			echo "USB camera"
			if [ "$STREAM" == "svpcom" ]; then
				echo "$USB_SVP_CMD"
				$USB_SVP_CMD > /dev/null 2>&1 &
			else
				echo "nice -n -9 gst-launch-1.0 $USBCAM ! fdsink fd=1 | $RAW_CMD"
				nice -n -9 gst-launch-1.0 $USBCAM ! fdsink fd=1 | $RAW_CMD
			fi
		;;
		"5")
			echo "IP camera"
			if [ "$STREAM" == "svpcom" ]; then
				echo "$IPC_SVP_CMD"
				$IPC_SVP_CMD > /dev/null 2>&1 &
			else
				echo "Starting transmission in $TXMODE mode, FEC: $VIDEO_BLOCKS/$VIDEO_FECS/$VIDEO_BLOCKLENGTH, $IPCAM, video bitrate: $BITRATE_KBIT kBit/s, Keyframerate: $KEYFRAMERATE"
				nice -n -9 gst-launch-1.0 $IPCAM ! "application/x-rtp,media=video" ! rtph264depay ! video/x-h264, stream-format="byte-stream" ! fdsink fd=1 | $RAW_CMD
			fi
		;;
		"6")
			echo "IP camera+CSI camera"
			echo "$CSI_CMD -o - | $RAW_CMD"
			$CSI_CMD -o - | $RAW_CMD > /dev/null 2>&1 &
			echo "$IPC_SVP_CMD"
			$IPC_SVP_CMD > /dev/null 2>&1 &
		;;
		"7")
			echo "IP camera+Dualcam"
			vcdbg set awb_mode 0
			echo "$CSI_CMD -3d sbs -o - | $RAW_CMD"
			$CSI_CMD -3d sbs -o - | $RAW_CMD > /dev/null 2>&1 &
			echo "$IPC_SVP_CMD"
			$IPC_SVP_CMD > /dev/null 2>&1 &
		;;
		"8")
			echo "IP camera+VEYECAM"
			echo "$VEYE_CMD -o - | $RAW_CMD"
			$VEYE_CMD -o - | $RAW_CMD > /dev/null 2>&1 &
			echo "$IPC_SVP_CMD"
			$IPC_SVP_CMD > /dev/null 2>&1 &
		;;
		"9")
			echo "IP camera+USB camera"
			echo "nice -n -9 gst-launch-1.0 $USBCAM ! fdsink fd=1 | $RAW_CMD"
			nice -n -9 gst-launch-1.0 $USBCAM ! fdsink fd=1 | $RAW_CMD &
			echo "$IPC_SVP_CMD"
			$IPC_SVP_CMD > /dev/null 2>&1 &
		;;
		"10")
			echo "USB camera+CSI camera"
			echo "$USB_SVP_CMD"
			$USB_SVP_CMD > /dev/null 2>&1 &
			echo "$CSI_CMD -o - | $RAW_CMD"
			$CSI_CMD -o - | $RAW_CMD > /dev/null 2>&1 &
		;;
		"11")
			echo "USB camera+Dualcam"
			vcdbg set awb_mode 0
			echo "$USB_SVP_CMD"
			$USB_SVP_CMD > /dev/null 2>&1 &
			echo "$CSI_CMD -3d sbs -o - | $RAW_CMD"
			$CSI_CMD -3d sbs -o - | $RAW_CMD > /dev/null 2>&1 &
		;;
		"12")
			echo "USB camera+VEYECAM"
			echo "$USB_SVP_CMD"
			$USB_SVP_CMD > /dev/null 2>&1 &
			echo "$VEYE_CMD -o - | $RAW_CMD"
			$VEYE_CMD -o - | $RAW_CMD > /dev/null 2>&1 &
		;;
	esac

	if [ "$STREAM" == "svpcom" ] || [ "$cams" == "Y" ]; then
		echo "start wfb_tx -u 5600 -t $FRAMETYPE -p 23 -B 20 -G $SGI -S $STBC -L $LDPC -M $MCS -n $VIDEO_NUM -k $VIDEO_BLOCKS $NICS"
		while true; do
			nice -n -9 wfb_tx -u 5600 -t $FRAMETYPE -p 23 -B 20 -G $SGI -S $STBC -L $LDPC -M $MCS -n $VIDEO_NUM -k $VIDEO_BLOCKS $NICS &
			sleep 1800
			ps -ef | nice grep "wfb_tx -u 5600" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		done
	fi

	TX_EXITSTATUS=${PIPESTATUS[1]}
	# if we arrive here, either raspivid or tx did not start, or were terminated later
	# check if NIC has been removed
	NICS2=`ls /sys/class/net/ | nice grep -v eth | nice grep -v lo | nice grep -v usb | nice grep -v intwifi | nice grep -v relay | nice grep -v wifihotspot`
	if [ "$NICS" == "$NICS2" ]; then
		# wifi card has not been removed
		if [ "$TX_EXITSTATUS" != "0" ]; then
			echo "ERROR: could not start tx or tx terminated!"
		fi
		collect_errorlog
		sleep 365d
	else
		# wifi card has been removed
		echo "ERROR: Wifi card removed!"
		collect_errorlog
		sleep 365d
	fi
}

## runs on RX (ground pi)
function rx_function {
	/root/wifibroadcast/sharedmem_init_rx
	python /root/wifibroadcast_misc/gpio-IsAir.py
	echo "18" > /sys/class/gpio/export
	echo "in" > /sys/class/gpio/gpio18/direction
	SCANSTATUS=`cat /sys/class/gpio/gpio18/value`
	if [ "$FREQSCAN" != "Y" ] && [ "$SCANSTATUS" == "0" ]; then
		FREQSCAN=Y
		echo "Frequency scanning is manually activated!"
	fi
	echo "18" > /sys/class/gpio/unexport
	
	# start virtual serial port for cmavnode and ser2net
	ionice -c 3 nice socat -lf /wbc_tmp/socat1.log -d -d pty,raw,echo=0 pty,raw,echo=0 & > /dev/null 2>&1
	sleep 1
	ionice -c 3 nice socat -lf /wbc_tmp/socat2.log -d -d pty,raw,echo=0 pty,raw,echo=0 & > /dev/null 2>&1
	sleep 1
	ionice -c 3 nice socat -lf /wbc_tmp/socat3.log -d -d pty,raw,echo=0 pty,raw,echo=0 & > /dev/null 2>&1
	sleep 1
	ionice -c 3 nice socat -lf /wbc_tmp/socat4.log -d -d pty,raw,echo=0 pty,raw,echo=0 & > /dev/null 2>&1
	sleep 1
	# setup virtual serial ports
	stty -F /dev/pts/0 -icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon $TELEMETRY_BAUDRATE
	stty -F /dev/pts/1 -icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon $TELEMETRY_BAUDRATE
	stty -F /dev/pts/2 -icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon $TELEMETRY_BAUDRATE
	stty -F /dev/pts/3 -icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon $TELEMETRY_BAUDRATE
	stty -F /dev/pts/4 -icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon $TELEMETRY_BAUDRATE
	stty -F /dev/pts/5 -icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon $TELEMETRY_BAUDRATE
	stty -F /dev/pts/6 -icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon $TELEMETRY_BAUDRATE
	stty -F /dev/pts/7 -icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon $TELEMETRY_BAUDRATE
	echo

	# if USB memory stick is already connected during startup, notify user
	# and pause as long as stick is not removed
	# some sticks show up as sda1, others as sda, check for both
	if [ -e "/dev/sda1" ]; then
		USBDEV="/dev/sda1"
	else
		USBDEV="/dev/sda"
	fi

	if [ -e $USBDEV ]; then
		touch /tmp/donotsave
		STICKGONE=0
		while [ $STICKGONE -ne 1 ]; do
			killall wbc_status > /dev/null 2>&1
			nice /root/wifibroadcast_status/wbc_status "USB memory stick detected - please remove and re-plug after flight" 7 65 0 &
			if [ "$AIRODUMP" == "N" ]; then
				AIRODUMP=Y
			fi
			sleep 4
			if [ ! -e $USBDEV ]; then
				STICKGONE=1
				rm /tmp/donotsave
			fi
		done
	fi

	killall wbc_status > /dev/null 2>&1

	sleep 1
	detect_nics
	echo

	sleep 0.5

	# videofifo1: local display, hello_video.bin
	# videofifo2: Wifi_hotspot
	# videofifo3: recording
	# videofifo4: wbc relay/usb-tethering
	# videofifo5: Ethernet_hotspot

	SINGLECORE=`cat /tmp/SINGLECORE`

	if [ "$SINGLECORE" == "N" ]; then
		if [ "$VIDEO_TMP" == "sdcard" ]; then
			touch /tmp/pausewhile # make sure check_alive doesn't do it's stuff ...
			tmessage "Saving to SDCARD enabled, preparing video storage ..."
			if cat /proc/partitions | nice grep -q mmcblk0p3; then # partition has not been created yet
				echo
				echo "SD card video partion detected.."
			else
				echo
				echo "SD card video partion NOT detected.."
				echo -e "n\np\n3\n3674112\n\nw" | fdisk /dev/mmcblk0 > /dev/null 2>&1
				partprobe > /dev/null 2>&1
				mkfs.ext4 /dev/mmcblk0p3 -L myvideo -F > /dev/null 2>&1 || {
#				mkfs.ext4 /dev/mmcblk0p3 -F > /dev/null 2>&1 || {
					tmessage "ERROR: Could not format video storage on SDCARD!"
					collect_errorlog
					sleep 365d
				}
			fi
			e2fsck -p /dev/mmcblk0p3 > /dev/null 2>&1
			mkdir -p /video_tmp > /dev/null 2>&1
			mount -t ext4 -o noatime /dev/mmcblk0p3 /video_tmp > /dev/null 2>&1 || {
				tmessage "ERROR: Could not mount video storage on SDCARD!"
				collect_errorlog
				sleep 365d
			}
			VIDEOFILE=/video_tmp/videotmp.raw
			echo "VIDEOFILE=/video_tmp/videotmp.raw" > /tmp/videofile
			rm $VIDEOFILE > /dev/null 2>&1
		else
			VIDEOFILE=/wbc_tmp/videotmp.raw
			echo "VIDEOFILE=/wbc_tmp/videotmp.raw" > /tmp/videofile
		fi
	fi

	#/root/wifibroadcast/tracker /wifibroadcast_rx_status_0 >> /wbc_tmp/tracker.txt &
	#sleep 1

	killall wbc_status > /dev/null 2>&1

	if [ "$DEBUG" == "Y" ]; then
		collect_debug /wbc_tmp &
	fi

	if [ "$SINGLECORE" == "N" ]; then
		wbclogger_function &
	fi

	if vcgencmd get_throttled | nice grep -q -v "0x0"; then
		TEMP=`cat /sys/class/thermal/thermal_zone0/temp`
		TEMP_C=$(($TEMP/1000))
		if [ "$TEMP_C" -lt 75 ]; then
			echo "	---------------------------------------------------------------------------------------------------"
			echo "	| ERROR: Under-Voltage detected on the RX Pi. Your Pi is not supplied with stable 5 Volts.		  |"
			echo "	|																								  |"
			echo "	| Either your power-supply or wiring is not sufficent, check the wiring instructions in the Wiki! |"
			echo "	---------------------------------------------------------------------------------------------------"
			echo "1" > /tmp/undervolt
			sleep 5
		else
			echo "0" > /tmp/undervolt
		fi
	else
		echo "0" > /tmp/undervolt
	fi

	echo "N" > /tmp/FX1
	echo "N" > /tmp/FX2
	echo "N" > /tmp/FX3

	if [ -e "/tmp/pausewhile" ]; then
		rm /tmp/pausewhile # remove pausewhile file to make sure check_alive and everything runs again
	fi

	while true; do
		pause_while
		PIP=`cat /tmp/pip`
		FX1=`cat /tmp/FX1`
		FX2=`cat /tmp/FX2`
		FX3=`cat /tmp/FX3`
		if [ "$FX1" == "N" ] && [ "$FX2" == "N" ] && [ "$FX3" == "N" ]; then
			FXIP=N
		else
			FXIP=Y
		fi
		if [ "$FXIP" == "N" ] || [ "$SINGLECORE" == "N" ]; then
			if [ "$PIP" == "S" ]; then
				ionice -c 1 -n 4 nice -n -10 cat /root/steamfifo1 | ionice -c 1 -n 4 nice -n -10 $DISPLAY_PROGRAM > /dev/null 2>&1 &
			else
				ionice -c 1 -n 4 nice -n -10 cat /root/videofifo1 | ionice -c 1 -n 4 nice -n -10 $DISPLAY_PROGRAM > /dev/null 2>&1 &
			fi
		fi
		
		if [ "$VIDEO_TMP" != "disabled" ] && [ "$SINGLECORE" == "N" ]; then
			if [ "$PIP" == "S" ]; then
				ionice -c 3 nice cat /root/steamfifo3 >> $VIDEOFILE &
			else
				ionice -c 3 nice cat /root/videofifo3 >> $VIDEOFILE &
			fi
		fi
		
		if [ "$RELAY" == "Y" ]; then
			echo "Starting RELAY"
			/root/wifibroadcast/sharedmem_init_tx
			ionice -c 1 -n 4 nice -n -10 cat /root/videofifo4 | /root/wifibroadcast/tx_rawsock -p 0 -b $RELAY_VIDEO_BLOCKS -r $RELAY_VIDEO_FECS -f $RELAY_VIDEO_BLOCKLENGTH -t 1 -d $MCS -G 0 -S 0 -L 0 -y 0 relay0 > /dev/null 2>&1 &
		fi
		# update NICS variable in case a NIC has been removed (exclude devices with wlanx)
		NICS=`ls /sys/class/net/ | nice grep -v eth | nice grep -v lo | nice grep -v usb | nice grep -v intwifi | nice grep -v wlan | nice grep -v relay | nice grep -v wifihotspot`
		if [ "$SINGLECORE" == "N" ]; then
			tmessage "start wfb_rx -u 5621 -p 23 -c 127.0.0.1 -n $VIDEO_NUM -k $VIDEO_BLOCKS -l 200 $NICS \n"
			ionice -c 1 -n 3 wfb_rx -u 5621 -p 23 -c 127.0.0.1 -n $VIDEO_NUM -k $VIDEO_BLOCKS -l 200 $NICS >/dev/null 2>/dev/null &
			if [ "$FORWARD_STREAM" == "rtp" ]; then
				tmessage "Starting SVPCOM RX ... (FEC: $VIDEO_BLOCKS/$VIDEO_FECS)"
				nice -n -5 gst-launch-1.0 udpsrc port=5621 ! tee name=t ! queue ! udpsink host=127.0.0.1 port=5612 t. ! queue ! "application/x-rtp,media=video" ! rtph264depay ! video/x-h264, stream-format="byte-stream" ! fdsink fd=1 | ionice -c 1 -n 4 nice -n -10 tee >(ionice -c 3 nice /root/wifibroadcast_misc/ftee /root/steamfifo3 > /dev/null 2>&1) | ionice -c 1 -n 4 nice -n -10 /root/wifibroadcast_misc/ftee /root/steamfifo1 > /dev/null 2>&1 &
				tmessage "Starting RAWSOCK RX ... (FEC: $VIDEO_BLOCKS/$VIDEO_FECS/$VIDEO_BLOCKLENGTH)"
#				ionice -c 1 -n 3 /root/wifibroadcast/rx -p 0 -d 1 -b $VIDEO_BLOCKS -r $VIDEO_FECS -f $VIDEO_BLOCKLENGTH $NICS | ionice -c 1 -n 4 nice -n -10 tee >(ionice -c 1 -n 4 nice -n -10 /root/wifibroadcast_misc/ftee /root/videofifo3 > /dev/null 2>&1) >(ionice -c 1 nice -n -10 /root/wifibroadcast_misc/ftee /root/videofifo1 > /dev/null 2>&1) | nice -n -5 gst-launch-1.0 fdsrc ! h264parse ! rtph264pay mtu=$VIDEO_UDP_BLOCKSIZE ! udpsink host=127.0.0.1 port=5512 > /dev/null 2>&1
				ionice -c 1 -n 3 /root/wifibroadcast/rx -p 0 -d 1 -b $VIDEO_BLOCKS -r $VIDEO_FECS -f $VIDEO_BLOCKLENGTH $NICS | ionice -c 1 -n 4 nice -n -10 tee >(ionice -c 1 -n 4 nice -n -10 /root/wifibroadcast_misc/ftee /root/videofifo3 > /dev/null 2>&1) >(ionice -c 1 nice -n -10 /root/wifibroadcast_misc/ftee /root/videofifo1 > /dev/null 2>&1) | nice -n -5 gst-launch-1.0 fdsrc ! h264parse disable-passthrough=true ! rtph264pay ! udpsink host=127.0.0.1 port=5512 > /dev/null 2>&1
			else
				tmessage "Starting SVPCOM RX ... (FEC: $VIDEO_BLOCKS/$VIDEO_FECS)"				
				nice -n -5 gst-launch-1.0 udpsrc port=5621 ! "application/x-rtp,media=video" ! rtph264depay	 ! video/x-h264, stream-format="byte-stream" ! fdsink fd=1 | ionice -c 1 -n 4 nice -n -10 tee >(ionice -c 3 nice /root/wifibroadcast_misc/ftee /root/steamfifo3 > /dev/null 2>&1) >(ionice -c 3 nice /root/wifibroadcast_misc/ftee /root/steamfifo1 > /dev/null 2>&1) | ionice -c 1 -n 4 nice -n -10 socat -b $VIDEO_UDP_BLOCKSIZE - UDP4-SENDTO:127.0.0.1:5612 > /dev/null 2>&1 &
				tmessage "Starting RAWSOCK RX ... (FEC: $VIDEO_BLOCKS/$VIDEO_FECS/$VIDEO_BLOCKLENGTH)"				
				ionice -c 1 -n 3 /root/wifibroadcast/rx -p 0 -d 1 -b $VIDEO_BLOCKS -r $VIDEO_FECS -f $VIDEO_BLOCKLENGTH $NICS | ionice -c 1 -n 4 nice -n -10 tee >(ionice -c 1 -n 4 nice -n -10 /root/wifibroadcast_misc/ftee /root/videofifo3 > /dev/null 2>&1) >(ionice -c 1 nice -n -10 /root/wifibroadcast_misc/ftee /root/videofifo1 > /dev/null 2>&1) | ionice -c 1 -n 4 nice -n -10 socat -b $VIDEO_UDP_BLOCKSIZE - UDP4-SENDTO:127.0.0.1:5512 > /dev/null 2>&1
			fi
			RX_EXITSTATUS=${PIPESTATUS[0]}
			check_exitstatus $RX_EXITSTATUS
		elif [ "$FXIP" == "N" ]; then
			touch /tmp/single
			if [ "$PIP" == "S" ]; then
				tmessage "start wfb_rx -u 5612 -p 23 -c 127.0.0.1 -n $VIDEO_NUM -k $VIDEO_BLOCKS -l 200 $NICS \n"
				ionice -c 1 -n 3 wfb_rx -u 5612 -p 23 -c 127.0.0.1 -n $VIDEO_NUM -k $VIDEO_BLOCKS -l 200 $NICS >/dev/null 2>/dev/null &
				tmessage "Starting SVPCOM RX ... (FEC: $VIDEO_BLOCKS/$VIDEO_FECS)"
				nice -n -5 gst-launch-1.0 udpsrc port=5612 ! "application/x-rtp,media=video" ! rtph264depay	 ! video/x-h264, stream-format="byte-stream" ! fdsink fd=1 | ionice -c 1 -n 4 nice -n -10 /root/wifibroadcast_misc/ftee /root/steamfifo1 > /dev/null 2>&1
			else
				tmessage "Starting RAWSOCK RX ... (FEC: $VIDEO_BLOCKS/$VIDEO_FECS/$VIDEO_BLOCKLENGTH)"				
				ionice -c 1 -n 3 /root/wifibroadcast/rx -p 0 -d 1 -b $VIDEO_BLOCKS -r $VIDEO_FECS -f $VIDEO_BLOCKLENGTH $NICS | ionice -c 1 -n 4 nice -n -10 /root/wifibroadcast_misc/ftee /root/videofifo1 > /dev/null 2>&1
			fi
		else
			if [ "$FORWARD_STREAM" == "rtp" ]; then
				tmessage "start wfb_rx -u 5612 -p 23 -c 127.0.0.1 -n $VIDEO_NUM -k $VIDEO_BLOCKS -l 200 $NICS \n"
				ionice -c 1 -n 3 wfb_rx -u 5612 -p 23 -c 127.0.0.1 -n $VIDEO_NUM -k $VIDEO_BLOCKS -l 200 $NICS >/dev/null 2>/dev/null &
				tmessage "Starting RAWSOCK RX ... (FEC: $VIDEO_BLOCKS/$VIDEO_FECS/$VIDEO_BLOCKLENGTH)"				
#				ionice -c 1 -n 3 /root/wifibroadcast/rx -p 0 -d 1 -b $VIDEO_BLOCKS -r $VIDEO_FECS -f $VIDEO_BLOCKLENGTH $NICS | nice -n -5 gst-launch-1.0 fdsrc ! h264parse ! rtph264pay mtu=$VIDEO_UDP_BLOCKSIZE ! udpsink host=127.0.0.1 port=5512 > /dev/null 2>&1
				ionice -c 1 -n 3 /root/wifibroadcast/rx -p 0 -d 1 -b $VIDEO_BLOCKS -r $VIDEO_FECS -f $VIDEO_BLOCKLENGTH $NICS | nice -n -5 gst-launch-1.0 fdsrc ! h264parse disable-passthrough=true ! rtph264pay ! udpsink host=127.0.0.1 port=5512 > /dev/null 2>&1
			else
				tmessage "start wfb_rx -u 5621 -p 23 -c 127.0.0.1 -n $VIDEO_NUM -k $VIDEO_BLOCKS -l 200 $NICS \n"
				ionice -c 1 -n 3 wfb_rx -u 5621 -p 23 -c 127.0.0.1 -n $VIDEO_NUM -k $VIDEO_BLOCKS -l 200 $NICS >/dev/null 2>/dev/null &
				tmessage "Starting SVPCOM RX ... (FEC: $VIDEO_BLOCKS/$VIDEO_FECS)"				
				nice -n -5 gst-launch-1.0 udpsrc port=5621 ! "application/x-rtp,media=video" ! rtph264depay	 ! video/x-h264, stream-format="byte-stream" ! fdsink fd=1 | ionice -c 1 -n 4 nice -n -10 socat -b $VIDEO_UDP_BLOCKSIZE - UDP4-SENDTO:127.0.0.1:5612 > /dev/null 2>&1 &
				tmessage "Starting RAWSOCK RX ... (FEC: $VIDEO_BLOCKS/$VIDEO_FECS/$VIDEO_BLOCKLENGTH)"				
				ionice -c 1 -n 3 /root/wifibroadcast/rx -p 0 -d 1 -b $VIDEO_BLOCKS -r $VIDEO_FECS -f $VIDEO_BLOCKLENGTH $NICS | ionice -c 1 -n 4 nice -n -10 socat -b $VIDEO_UDP_BLOCKSIZE - UDP4-SENDTO:127.0.0.1:5512 > /dev/null 2>&1
			fi
		fi
		ps -ef | nice grep "$DISPLAY_PROGRAM" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "gst-launch-1.0" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "wfb_rx -u" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "ftee /root/videofifo" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "ftee /root/steamfifo" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "cat /root/videofifo" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "cat /root/steamfifo" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "rx -p 0" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "socat -b $VIDEO_UDP_BLOCKSIZE" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	done
	
}

## runs on RX (ground pi)
function rssirx_function {
	echo
	echo "Waiting until nics are configured ..."
	while [ ! -f /tmp/nics_configured ]; do
		sleep 0.5
		#echo -n "."
	done
	sleep 1
	# get NICS (exclude devices with wlanx)
	NICS=`ls /sys/class/net/ | nice grep -v eth | nice grep -v lo | nice grep -v usb | nice grep -v intwifi | nice grep -v wlan | nice grep -v relay | nice grep -v wifihotspot`
	echo "Starting RSSI RX ..."
	nice /root/wifibroadcast/rssirx $NICS
}


## runs on RX (ground pi)
function downlinkrx_function {
	echo
	SINGLECORE=`cat /tmp/SINGLECORE`
	if [ "$SINGLECORE" == "N" ]; then
		# Convert osdconfig from DOS format to UNIX format
		ionice -c 3 nice dos2unix -n /boot/osdconfig.txt /tmp/osdconfig.txt
		if [ "$TELEMETRY_OSD" ]; then
			tosd=`echo $TELEMETRY_OSD | tr '[:lower:]' '[:upper:]'`
			sed	 -i '1 i\#define '$tosd''  /tmp/osdconfig.txt
		fi
		echo
		cd /root/wifibroadcast_osd
		echo Building OSD:
		ionice -c 3 nice make -j2 || {
			echo
			echo "ERROR: Could not build OSD, check osdconfig.txt!"
			sleep 5
			nice /root/wifibroadcast_status/wbc_status "ERROR: Could not build OSD, check osdconfig.txt for errors." 7 55 0
			sleep 5
		}
	fi
	echo
	echo "Waiting until nics are configured ..."
	while [ ! -f /tmp/nics_configured ]; do
		sleep 0.5
		#echo -n "."
	done
	sleep 1

	while true; do
		killall wbc_status > /dev/null 2>&1
		if [ "$TELEMETRY_TRANSMISSION" == "wbc" ]; then
			echo "Telemetry transmission WBC chosen, using wbc rx"
			TELEMETRY_RX_CMD="/root/wifibroadcast/rx_rc_telemetry_buf -p 1"
		else
			if [ "$TELEMETRY_UPLINK" == "Y" ] && [ "$ENABLE_SERIAL_TELEMETRY_OUTPUT" == "Y" ]; then
				if [ "$TELEMETRY_OUTPUT_SERIALPORT_GROUND" == "$EXTERNAL_TELEMETRY_SERIALPORT_GROUND" ]; then
					echo "Telemetry transmission external and uplink chosen, disabled TELEMETRY GROUND output on same serialport"
					ENABLE_SERIAL_TELEMETRY_OUTPUT == N
				fi
			fi
			echo "Telemetry transmission external chosen, using cat from serialport"
			if [ "$EXTERNAL_TELEMETRY_SERIALPORT_GROUND" == "/dev/ttyUSB0" ]; then
				while [ ! -e "/dev/ttyUSB0" ]; do
					killall wbc_status > /dev/null 2>&1
					nice /root/wifibroadcast_status/wbc_status "Waiting for USB-to-serial adapter to be plugged in ..." 7 65 0 &
					sleep 4
				done
			fi
			nice stty -F $EXTERNAL_TELEMETRY_SERIALPORT_GROUND $EXTERNAL_TELEMETRY_SERIALPORT_GROUND_STTY_OPTIONS $TELEMETRY_BAUDRATE
			#nice /root/wifibroadcast/setupuart -d 0 -s $EXTERNAL_TELEMETRY_SERIALPORT_GROUND -b $TELEMETRY_BAUDRATE
			TELEMETRY_RX_CMD="cat $EXTERNAL_TELEMETRY_SERIALPORT_GROUND"
		fi
		if [ "$ENABLE_SERIAL_TELEMETRY_OUTPUT" == "Y" ]; then
			touch /tmp/telemetryout
			if [ "$TELEMETRY_OUTPUT_SERIALPORT_GROUND" == "/dev/ttyUSB0" ]; then
				while [ ! -e "/dev/ttyUSB0" ]; do
					killall wbc_status > /dev/null 2>&1
					nice /root/wifibroadcast_status/wbc_status "Waiting for USB-to-serial adapter to be plugged in ..." 7 65 0 &
					sleep 4
				done
			fi
			echo "enable_serial_telemetry_output is Y, sending telemetry stream to $TELEMETRY_OUTPUT_SERIALPORT_GROUND"
			nice stty -F $TELEMETRY_OUTPUT_SERIALPORT_GROUND $TELEMETRY_OUTPUT_SERIALPORT_GROUND_STTY_OPTIONS $TELEMETRY_BAUDRATE
			#nice /root/wifibroadcast/setupuart -d 1 -s $TELEMETRY_OUTPUT_SERIALPORT_GROUND -b $TELEMETRY_BAUDRATE
			nice cat /root/telemetryfifo6 > $TELEMETRY_OUTPUT_SERIALPORT_GROUND &
		fi
		touch /tmp/downlinkrx
		# telemetryfifo1: local display, osd
		# telemetryfifo2: Wifi_hotspot
		# telemetryfifo3: recording
		# telemetryfifo4: wbc relay/usb-tethering
		# telemetryfifo5: Ethernet_hotspot
		# telemetryfifo6: serial downlink
		pause_while
		if [ "$SINGLECORE" == "N" ]; then
			ionice -c 3 nice cat /root/telemetryfifo3 >> /wbc_tmp/telemetrydowntmp.raw &
			/tmp/osd >> /wbc_tmp/telemetrydowntmp.txt &
		fi
		if [ "$RELAY" == "Y" ]; then
			ionice -c 1 -n 4 nice -n -9 cat /root/telemetryfifo4 | nice /root/wifibroadcast/tx_telemetry -p 1 -c 1 -r 2 -x $TELEMETRY_TYPE -d 0 -y 0 relay0 > /dev/null 2>&1 &
		fi

		if [ "$TELEMETRY_TRANSMISSION" == "wbc" ]; then
			# update NICS variable in case a NIC has been removed (exclude devices with wlanx)
			NICS=`ls /sys/class/net/ | nice grep -v eth | nice grep -v lo | nice grep -v usb | nice grep -v intwifi | nice grep -v wlan | nice grep -v relay | nice grep -v wifihotspot`
			if [ "$DEBUG" == "Y" ]; then
				$TELEMETRY_RX_CMD -d 1 $NICS 2>/wbc_tmp/telemetrydowndebug.txt | tee >(/root/wifibroadcast_misc/ftee /root/telemetryfifo2 > /dev/null 2>&1) >(/root/wifibroadcast_misc/ftee /root/telemetryfifo3 > /dev/null 2>&1) >(ionice -c 1 nice -n -9 /root/wifibroadcast_misc/ftee /root/telemetryfifo4 > /dev/null 2>&1) >(ionice nice /root/wifibroadcast_misc/ftee /root/telemetryfifo5 > /dev/null 2>&1) >(ionice nice /root/wifibroadcast_misc/ftee /root/telemetryfifo6 > /dev/null 2>&1) | /root/wifibroadcast_misc/ftee /root/telemetryfifo1 > /dev/null 2>&1
			else
				$TELEMETRY_RX_CMD $NICS | tee >(/root/wifibroadcast_misc/ftee /root/telemetryfifo2 > /dev/null 2>&1) >(/root/wifibroadcast_misc/ftee /root/telemetryfifo3 > /dev/null 2>&1) >(ionice -c 1 nice -n -9 /root/wifibroadcast_misc/ftee /root/telemetryfifo4 > /dev/null 2>&1) >(ionice nice /root/wifibroadcast_misc/ftee /root/telemetryfifo5 > /dev/null 2>&1) >(ionice nice /root/wifibroadcast_misc/ftee /root/telemetryfifo6 > /dev/null 2>&1) | /root/wifibroadcast_misc/ftee /root/telemetryfifo1 > /dev/null 2>&1
			fi
		else
			$TELEMETRY_RX_CMD | tee >(/root/wifibroadcast_misc/ftee /root/telemetryfifo2 > /dev/null 2>&1) >(/root/wifibroadcast_misc/ftee /root/telemetryfifo3 > /dev/null 2>&1) >(ionice -c 1 nice -n -9 /root/wifibroadcast_misc/ftee /root/telemetryfifo4 > /dev/null 2>&1) >(ionice nice /root/wifibroadcast_misc/ftee /root/telemetryfifo5 > /dev/null 2>&1) >(ionice nice /root/wifibroadcast_misc/ftee /root/telemetryfifo6 > /dev/null 2>&1) | /root/wifibroadcast_misc/ftee /root/telemetryfifo1 > /dev/null 2>&1
		fi
		echo "ERROR: Telemetry RX has been stopped - restarting RX and OSD ..."
		ps -ef | nice grep "$TELEMETRY_RX_CMD" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "ftee /root/telemetryfifo" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "/tmp/osd" | nice grep -v grep | awk '{print $2}' | xargs kill -9
#		ps -ef | nice grep "stty -F" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "cat /root/telemetryfifo3" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "cat /root/telemetryfifo4" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "cat /root/telemetryfifo6" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "tx_telemetry -p 1" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		rm /tmp/downlinkrx
		sleep 1
	done
}

## runs on RX (ground pi)
function uplinktx_function {
	while true; do
		pause_while
		echo -n "Waiting until downlinkrx are configured ..."
		while [ ! -f /tmp/downlinkrx ]; do
			sleep 1
			#echo -n "."
		done
		echo
		if [ -f /tmp/telemetryout ]; then
			nice cat $TELEMETRY_OUTPUT_SERIALPORT_GROUND > /dev/pts/7 &
		fi
		echo "Starting uplink telemetry transmission"
		if [ "$TELEMETRY_TRANSMISSION" == "wbc" ]; then
			echo "telemetry transmission = wbc, starting tx_telemetry ..."
			NICS=`ls /sys/class/net/ | nice grep -v eth | nice grep -v lo | nice grep -v usb | nice grep -v intwifi | nice grep -v relay | nice grep -v wifihotspot`
			echo -n "NICS:"
			echo $NICS
			UPLINK_TX_CMD="nice /root/wifibroadcast/tx_telemetry -p $TELEMETRY_UPLINK_PORT -c $FRAMETYPE -r 2 -x $TELEMETRY_TYPE -d $STBC -y 0"
			if [ "$DEBUG" == "Y" ]; then
				nice cat /dev/pts/6 | $UPLINK_TX_CMD -z 1 $NICS 2>/wbc_tmp/telemetryupdebug.txt
			else
				nice cat /dev/pts/6 | $UPLINK_TX_CMD $NICS
			fi
		else
			echo "telemetry transmission = external, sending data to $EXTERNAL_TELEMETRY_SERIALPORT_GROUND ..."
			nice cat /dev/pts/6 > $EXTERNAL_TELEMETRY_SERIALPORT_GROUND
		fi
		ps -ef | nice grep "cat $TELEMETRY_OUTPUT_SERIALPORT_GROUND" | nice grep -v grep | awk '{print $2}' | xargs kill -9
    	ps -ef | nice grep "cat /dev/pts/6" | nice grep -v grep | awk '{print $2}' | xargs kill -9
    	ps -ef | nice grep "tx_telemetry -p $TELEMETRY_UPLINK_PORT" | nice grep -v grep | awk '{print $2}' | xargs kill -9
    done
}

## runs on TX (air pi)
function downlinktx_function {
	echo "Waiting until nics are configured ..."
	while [ ! -f /tmp/nics_configured ]; do
		sleep 0.5
	#echo -n "."
	done
	sleep 1
	echo
	echo "nics configured, starting Downlink telemetry TX processes ..."
	echo "telemetry packets: $FRAMETYPE"
	echo
	while true; do
		echo "Starting downlink telemetry transmission in $TXMODE mode (FC Serialport: $FC_TELEMETRY_SERIALPORT)"
		NICS=`ls /sys/class/net/ | nice grep -v eth | nice grep -v lo | nice grep -v usb | nice grep -v intwifi`
		nice cat $FC_TELEMETRY_SERIALPORT | nice /root/wifibroadcast/tx_telemetry -p 1 -c $FRAMETYPE -r 2 -x $TELEMETRY_TYPE -d $STBC -y 0 $NICS
		ps -ef | nice grep "cat $FC_TELEMETRY_SERIALPORT" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		ps -ef | nice grep "tx_telemetry -p 1" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		echo "Downlink Telemetry TX exited - restarting ..."
		sleep 1
	done
}

# runs on RX (ground pi)
function rctx_function {
	ionice -c 3 nice dos2unix -n /boot/joyconfig.txt /tmp/rctx.h > /dev/null 2>&1
	# Convert joystick config from DOS format to UNIX format
	echo
	echo Building RC ...
	cd /root/wifibroadcast_rc
	ionice -c 3 nice gcc -lrt -lpcap rctx.c -o /tmp/rctx `sdl-config --libs` `sdl-config --cflags` || {
	echo "ERROR: Could not build RC, check joyconfig.txt!"
	}
	# wait until video is running to make sure NICS are configured and wifibroadcast_rx_status shmem is available

	echo
	echo "Waiting until nics are configured ..."
	while [ ! -f /tmp/nics_configured ]; do
		sleep 0.5
	#echo -n "."
	done
	sleep 1
	echo
	echo "Starting R/C TX ..."
	while true; do
		if [ "$RC_NIC" ]; then
			NICS=$RC_NIC
		else
			NICS=`ls /sys/class/net/ | nice grep -v eth | nice grep -v lo | nice grep -v usb | nice grep -v intwifi | nice grep -v relay | nice grep -v wifihotspot`
			#echo "NICS: $NICS"
		fi
		pause_while
		nice -n -5 /tmp/rctx -p $TELEMETRY_UPLINK_PORT -d $STBC $NICS
	done
}

## runs on TX (air pi)
function uplinkrx_and_rcrx_function {
	echo "Waiting until nics are configured ..."
	while [ ! -f /tmp/nics_configured ]; do
		sleep 0.5
		#echo -n "."
	done
	sleep 1
	NICS=`ls /sys/class/net/ | nice grep -v eth | nice grep -v lo | nice grep -v usb | nice grep -v intwifi | nice grep -v relay | nice grep -v wifihotspot`
	echo -n "NICS:"
	echo $NICS
	echo
	case $RC in
		"msp")
		RC_PROTOCOL=0
		;;
		"mavlink")
		RC_PROTOCOL=1
		;;
		"sumd")
		RC_PROTOCOL=2
		;;
		"ibus")
		RC_PROTOCOL=3
		;;
		"srxl")
		RC_PROTOCOL=4
		;;
	esac
	if [ "$TELEMETRY_TRANSMISSION" == "wbc" ]; then
		if [ "$RC" != "disabled" ]; then # with R/C
			echo "Starting Uplink telemetry and R/C RX ..."
			echo "FC_TELEMETRY_SERIALPORT: $FC_TELEMETRY_SERIALPORT"
			echo "FC_RC_SERIALPORT: $FC_RC_SERIALPORT"
			echo
			if [ "$FC_TELEMETRY_SERIALPORT" == "$FC_RC_SERIALPORT" ]; then # TODO: check if this logic works in all cases
				/root/wifibroadcast/rx_rc_telemetry -p $TELEMETRY_UPLINK_PORT -o 0 -b $TELEMETRY_BAUDRATE -s $FC_TELEMETRY_SERIALPORT -r $RC_PROTOCOL $NICS
			else # use the telemetry serialport and baudrate as it's the same anyway
#				/root/wifibroadcast/setupuart -d 1 -s $FC_TELEMETRY_SERIALPORT -b $TELEMETRY_BAUDRATE
				/root/wifibroadcast/rx_rc_telemetry -p $TELEMETRY_UPLINK_PORT -o 1 -b $FC_RC_BAUDRATE -s $FC_RC_SERIALPORT -r $RC_PROTOCOL $NICS > $FC_TELEMETRY_SERIALPORT
			fi
		else # without R/C
			echo "Starting Uplink telemetry RX ..."
			echo "FC_TELEMETRY_SERIALPORT: $FC_TELEMETRY_SERIALPORT"
			echo
			nice /root/wifibroadcast/rx_rc_telemetry -p $TELEMETRY_UPLINK_PORT -o 1 $NICS > $FC_TELEMETRY_SERIALPORT
		fi
	else
		echo "Starting Uplink R/C RX ..."
		echo "FC_RC_SERIALPORT: $FC_RC_SERIALPORT"
		echo
		# use the configured r/c serialport and baudrate
		/root/wifibroadcast/rx_rc_telemetry -p $TELEMETRY_UPLINK_PORT -o 0 -b $FC_RC_BAUDRATE -s $FC_RC_SERIALPORT -r $RC_PROTOCOL $NICS
	fi
}

## runs on RX (ground pi)
function screenshot_function {
	while true; do
	# pause loop while saving is in progress
	pause_while
	SCALIVE=`nice /root/wifibroadcast/check_alive`
	# do nothing if no video being received (so we don't take unnecessary screeshots)
	LIMITFREE=3000 # 3 mbyte
	if [ "$SCALIVE" == "1" ]; then
		# check if tmp disk is full, if yes, do not save screenshot
		FREETMPSPACE=`df -P /wbc_tmp/ | awk 'NR==2 {print $4}'`
		if [ $FREETMPSPACE -gt $LIMITFREE ]; then
			PNG_NAME=/wbc_tmp/screenshot`ls /wbc_tmp/screenshot* | wc -l`.png
			echo "Taking screenshot: $PNG_NAME"
			ionice -c 3 nice -n 19 /root/wifibroadcast_misc/raspi2png -p $PNG_NAME
		else
			echo "RAM disk full - no screenshot taken ..."
		fi
	else
		echo "Video not running - no screenshot taken ..."
	fi
	sleep 5
	done
}

## runs on RX (ground pi)
function save_function {
	touch /tmp/pausewhile
	# let screenshot and check_alive function know that saving is in progrss
	# kill OSD so we can safeley start wbc_status
	ps -ef | nice grep "osd" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	# kill video and telemetry recording and also local video display
	ps -ef | nice grep "cat /root/videofifo3" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "cat /root/steamfifo3" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "cat /root/telemetryfifo3" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "$DISPLAY_PROGRAM" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "gst-launch-1.0" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "cat /root/videofifo1" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "cat /root/steamfifo1" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	# kill video rx
	ps -ef | nice grep "rx -p 0" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "ftee /root/videofifo" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "ftee /root/steamfifo" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "wfb_rx -u" | nice grep -v grep | awk '{print $2}' | xargs kill -9

	killall wbc_status > /dev/null 2>&1
	nice /root/wifibroadcast_status/wbc_status "Saving to USB. This may take some time ..." 7 55 0 &

	echo -n "Accessing file system.. "

#	if [ -e "/dev/sda1" ]; then
#		USBDEV="/dev/sda1"
#	else
#		USBDEV="/dev/sda"
#	fi

	echo "USBDEV: $USBDEV"

	if mount $USBDEV /media/usb; then
		TELEMETRY_SAVE_PATH="/telemetry"
		SCREENSHOT_SAVE_PATH="/screenshot"
		VIDEO_SAVE_PATH="/video"
		RSSI_SAVE_PATH="/rssi"

		if [ -d "/media/usb$RSSI_SAVE_PATH" ]; then
			echo "RSSI save path $RSSI_SAVE_PATH found"
			DIR_NAME_RSSI=/media/usb$RSSI_SAVE_PATH/`ls -l /media/usb$RSSI_SAVE_PATH | grep "^d" | wc -l`
			mkdir $DIR_NAME_RSSI
			mv /media/usb$RSSI_SAVE_PATH/*.png $DIR_NAME_RSSI > /dev/null 2>&1
			mv /media/usb$RSSI_SAVE_PATH/*.csv $DIR_NAME_RSSI > /dev/null 2>&1
		else
			echo "Creating RSSI save path $RSSI_SAVE_PATH.. "
			mkdir /media/usb$RSSI_SAVE_PATH
		fi

		if [ -d "/media/usb$TELEMETRY_SAVE_PATH" ]; then
			echo "Telemetry save path $TELEMETRY_SAVE_PATH found"
		else
			echo "Creating Telemetry save path $TELEMETRY_SAVE_PATH.. "
			mkdir /media/usb$TELEMETRY_SAVE_PATH
		fi

		killall rssilogger
		killall syslogger
		if [ "$DEBUG" == "Y" ]; then
			killall wifibackgroundscan
			gnuplot -e "load '/root/gnuplot/wifibackgroundscan.gp'"
			killall tshark

			killall wbc_status > /dev/null 2>&1
			nice /root/wifibroadcast_status/wbc_status "Saving debuglogger - please wait ..." 7 65 0 &

			cp /wbc_tmp/*.pcap /media/usb
			cp /wbc_tmp/*.cap /media/usb
			cp /wbc_tmp/debug.txt /media/usb/
			cp /wbc_tmp/telemetrydowndebug.txt /media/usb$TELEMETRY_SAVE_PATH/
			cp /wbc_tmp/telemetryupdebug.txt /media/usb$TELEMETRY_SAVE_PATH/
		fi

		killall wbc_status > /dev/null 2>&1
		nice /root/wifibroadcast_status/wbc_status "Saving rssilogger - please wait ..." 7 65 0 &

		gnuplot -e "load '/root/gnuplot/videorssi.gp'"
		gnuplot -e "load '/root/gnuplot/videopackets.gp'"

		CARDS=`cat /tmp/numcards`
		echo "CARDS:$CARDS"
		gnuplot -e "load '/root/gnuplot/videopacketrssi0.gp'"
		if [ "$CARDS" -ge 1 ]; then
			gnuplot -e "load '/root/gnuplot/videopacketrssi1.gp'"
			if [ "$CARDS" -ge 2 ]; then
				gnuplot -e "load '/root/gnuplot/videopacketrssi2.gp'"
				if [ "$CARDS" -ge 3 ]; then
					gnuplot -e "load '/root/gnuplot/videopacketrssi3.gp'"
				fi
			fi
		fi

		killall wbc_status > /dev/null 2>&1
		nice /root/wifibroadcast_status/wbc_status "Saving syslogger - please wait ..." 7 65 0 &

		gnuplot -e "load '/root/gnuplot/link_rssi_dist.gp'"
		gnuplot -e "load '/root/gnuplot/link_efficiency.gp'"

		if [ "$TELEMETRY_TRANSMISSION" == "wbc" ]; then
#		   gnuplot -e "load '/root/gnuplot/telemetrydownrssi.gp'" &
		   gnuplot -e "load '/root/gnuplot/telemetrydownpackets.gp'"
		fi

		if [ "$TELEMETRY_UPLINK" == "Y" ]; then
#			gnuplot -e "load '/root/gnuplot/telemetryuprssi.gp'" &
			gnuplot -e "load '/root/gnuplot/telemetryuppackets.gp'"
		fi

		if [ "$RC" != "disabled" ]; then
			gnuplot -e "load '/root/gnuplot/rcrssi.gp'"
			gnuplot -e "load '/root/gnuplot/rcpackets.gp'"
		fi

		killall wbc_status > /dev/null 2>&1
		nice /root/wifibroadcast_status/wbc_status "Saving telemetrylogger - please wait ..." 7 65 0 &

		cp /wbc_tmp/*.csv /media/usb$RSSI_SAVE_PATH/
		cp /tmp/imx290log /media/usb

		if [ -s "/wbc_tmp/telemetrydowntmp.raw" ]; then
			cp /wbc_tmp/telemetrydowntmp.raw /media/usb$TELEMETRY_SAVE_PATH/telemetrydown`ls /media/usb$TELEMETRY_SAVE_PATH/*.raw | wc -l`.raw
		fi

		if [ -s "/wbc_tmp/telemetrydowntmp.txt" ]; then
			cp /wbc_tmp/telemetrydowntmp.txt /media/usb$TELEMETRY_SAVE_PATH/telemetrydown`ls /media/usb$TELEMETRY_SAVE_PATH/*.txt | wc -l`.txt
		fi

		if [ "$AIRODUMP" == "Y" ]; then
			cp /wbc_tmp/airodump.png /media/usb
		fi

		if [ "$ENABLE_SCREENSHOTS" == "Y" ]; then
			if [ -d "/media/usb$SCREENSHOT_SAVE_PATH" ]; then
				echo "Screenshots save path $SCREENSHOT_SAVE_PATH found"
			else
				echo "Creating screenshots save path $SCREENSHOT_SAVE_PATH.. "
				mkdir /media/usb$SCREENSHOT_SAVE_PATH
			fi

			killall wbc_status > /dev/null 2>&1
			nice /root/wifibroadcast_status/wbc_status "Saving creenshots - please wait ..." 7 65 0 &

			DIR_NAME_SCREENSHOT=/media/usb$SCREENSHOT_SAVE_PATH/`ls /media/usb$SCREENSHOT_SAVE_PATH | wc -l`
			mkdir $DIR_NAME_SCREENSHOT
			cp /wbc_tmp/screenshot* $DIR_NAME_SCREENSHOT > /dev/null 2>&1
		fi

#		cp /wbc_tmp/tracker.txt /media/usb/
		# find out if video is on ramdisk or sd
		source /tmp/videofile
		echo "VIDEOFILE: $VIDEOFILE"
		if [ -s "$VIDEOFILE" ]; then
			# start re-play of recorded video ....
			nice /opt/vc/src/hello_pi/hello_video/hello_video.bin.player $VIDEOFILE $FPS &
			if [ -d "/media/usb$VIDEO_SAVE_PATH" ]; then
				echo "Video save path $VIDEO_SAVE_PATH found"
			else
				echo "Creating video save path $VIDEO_SAVE_PATH.. "
				mkdir /media/usb$VIDEO_SAVE_PATH
			fi
			FILE_NAME_AVI=/media/usb$VIDEO_SAVE_PATH/video`ls /media/usb$VIDEO_SAVE_PATH | wc -l`.avi
			echo "FILE_NAME_AVI: $FILE_NAME_AVI"
			nice avconv -framerate $FPS -i $VIDEOFILE -vcodec copy $FILE_NAME_AVI > /dev/null 2>&1 &
			AVCONVRUNNING=1
			while [ $AVCONVRUNNING -eq 1 ]; do
				AVCONVRUNNING=`pidof avconv | wc -w`
				#echo "AVCONVRUNNING: $AVCONVRUNNING"
				sleep 4
				killall wbc_status > /dev/null 2>&1
				nice /root/wifibroadcast_status/wbc_status "Saving video - please wait ..." 7 65 0 &
			done
		fi

		nice umount /media/usb
		STICKGONE=0
		while [ $STICKGONE -ne 1 ]; do
			killall wbc_status > /dev/null 2>&1
			nice /root/wifibroadcast_status/wbc_status "Done - USB memory stick can be removed now" 7 65 0 &
			sleep 4
			if [ ! -e $USBDEV ]; then
				STICKGONE=1
			fi
		done
		killall wbc_status > /dev/null 2>&1
		killall hello_video.bin.player > /dev/null 2>&1
		rm /wbc_tmp/* > /dev/null 2>&1
		rm /video_tmp/* > /dev/null 2>&1
		sync
	else
		STICKGONE=0
		while [ $STICKGONE -ne 1 ]; do
			killall wbc_status > /dev/null 2>&1
			nice /root/wifibroadcast_status/wbc_status "ERROR: Could not access USB memory stick!" 7 65 0 &
			sleep 4
			if [ ! -e $USBDEV ]; then
				STICKGONE=1
			fi
		done
		killall wbc_status > /dev/null 2>&1
		killall hello_video.bin.player > /dev/null 2>&1
	fi

	#killall tracker
	# re-start video/telemetry recording
#	if [ "$VIDEO_TMP" != "disabled" ]; then
#		ionice -c 3 nice cat /root/videofifo3 >> $VIDEOFILE &
#	fi
	ionice -c 3 nice cat /root/telemetryfifo3 >> /wbc_tmp/telemetrydowntmp.raw &
	killall wbc_status > /dev/null 2>&1
	OSDRUNNING=`pidof /tmp/osd | wc -w`
	if [ $OSDRUNNING  -ge 1 ]; then
		echo "OSD already running!"
	else
		killall wbc_status > /dev/null 2>&1
		/tmp/osd >> /wbc_tmp/telemetrydowntmp.txt &
	fi

	# let screenshot function know that it can continue taking screenshots
	wbclogger_function &
	rm /tmp/pausewhile
}

## runs on RX (ground pi)
function wbclogger_function {
	echo
	echo "Waiting until nics are configured ..."
	while [ ! -f /tmp/nics_configured ]; do
		sleep 0.5
		#echo -n "."
	done
	sleep 5

	nice /root/wifibroadcast/rssilogger /wifibroadcast_rx_status_0 >> /wbc_tmp/videorssi.csv &
	nice /root/wifibroadcast/syslogger /wifibroadcast_rx_status_sysair >> /wbc_tmp/system.csv &

	if [ "$TELEMETRY_TRANSMISSION" == "wbc" ]; then
		nice /root/wifibroadcast/rssilogger /wifibroadcast_rx_status_1 >> /wbc_tmp/telemetrydownrssi.csv &
	fi

	if [ "$TELEMETRY_UPLINK" == "Y" ]; then
		nice /root/wifibroadcast/rssilogger /wifibroadcast_rx_status_uplink >> /wbc_tmp/telemetryuprssi.csv &
	fi
	if [ "$RC" != "disabled" ]; then
		nice /root/wifibroadcast/rssilogger /wifibroadcast_rx_status_rc >> /wbc_tmp/rcrssi.csv &
	fi
	if [ "$DEBUG" == "Y" ]; then
		nice /root/wifibroadcast/wifibackgroundscan $NICS >> /wbc_tmp/wifibackgroundscan.csv &
	fi
	sleep 365d
}

function pause_while {
	if [ -f "/tmp/pausewhile" ]; then
		PAUSE=1
		while [ $PAUSE -ne 0 ]; do
			if [ ! -f "/tmp/pausewhile" ]; then
				PAUSE=0
			fi
			sleep 1
		done
	fi
}

## runs on TX (air pi)
function auto_sync {
	ssid=`sed -n 's/\bssid=\b//p' "/tmp/apconfig.txt" | cut -d ' ' -f 1`
	echo "Air unit configfile sync form ssid:$ssid,channel:$channel"
	iwconfig $1 essid "$ssid"
	iwconfig $1 channel $channel
#	iwconfig $1 key off
	ifconfig $1 192.168.2.3 netmask 255.255.255.0 broadcast 192.168.2.255
	ifconfig $1 up || {
		echo
		echo "ERROR: Bringing up interface $1 failed!"
		collect_errorlog
		sleep 365d
	}
#	iw $1 connect $ssid  
	COUNTER=0
	# loop until connect the ground wifihotspot!
	while [ $COUNTER -lt 3 ]; do
		if nice ping -I $1 -c 2 -W 1 -n -q 192.168.2.1 > /dev/null 2>&1; then
			CONNECT=Y
			file0=/tmp/tmp.txt
			file1=/tmp/settings.sh
			nice socat -u TCP4:192.168.2.1:991 open:$file0,create
			if [ -e "$file0" ]; then
				if diff $file1 $file0 > /dev/null 2>&1; then
					tmessage "Air and Ground configfile are same."
					rm $file0
				else
					filex=/boot/$CONFIGFILE
					nice mount -o remount,rw /boot
					rm $filex
					mv $file0 $filex
					syncpower=`sed -n 's/^.*txpower=//p' "$filex" | cut -d ' ' -f 1`
					echo "syncpower: $syncpower"
					nice /usr/local/bin/txpower_atheros $syncpower
					nice /usr/local/bin/txpower_ralink $syncpower
					sync
					nice mount -o remount,ro /boot
					reboot
				fi
			else
				tmessage "Sync configfile not found,need restart ground unit!"
			fi
			break
		else
			CONNECT=N
		fi
		let "COUNTER++"
	done
	if [ "$CONNECT" == "N" ]; then
		tmessage "Sync configfile can't connect the ground wifihotspot!"
	fi
#	iw $1 disconnect
	ifconfig $1 down || {
		echo
		echo "ERROR: Bringing down interface $1 failed!"
		collect_errorlog
		sleep 365d
	}
	sleep 0.2
	drv=`cat /sys/class/net/$1/device/uevent | nice grep DRIVER | sed 's/DRIVER=//'`
	if [ "$drv" == "ath9k_htc" ]; then
		rmmod ath9k_htc
		modprobe ath9k_htc
	fi
}

## runs on RX (ground pi)
function telemetry_forward {
	nice /root/wifibroadcast/rssi_forward $2 $RSSI_UDP_PORT &
	nice /root/wifibroadcast/rssi_forward $2 $RSSI_QGC_UDP_PORT &
	case $1 in
	"telemetryfifo4")
		VSERIALUP=/dev/pts/0
		VSERIALDWON=/dev/pts/1
		;;
	"telemetryfifo2")
		VSERIALUP=/dev/pts/2
		VSERIALDWON=/dev/pts/3
		;;
	"telemetryfifo5")
		VSERIALUP=/dev/pts/4
		VSERIALDWON=/dev/pts/5
	;;
	esac
	case $TELEMETRY_OSD in
	"mavlink")
		cat /root/$1 > $VSERIALUP &
		ionice -c 3 nice /root/mavlink-router/mavlink-routerd -e $2:14550 $VSERIALDWON:$TELEMETRY_BAUDRATE &
		if [ "$DEBUG" == "Y" ]; then
			tshark -i usb0 -f "udp and port 14550" -w /wbc_tmp/mavlink`date +%s`.pcap &
		fi
	;;
	"msp")
		cat /root/$1 > $VSERIALUP &
		socat $VSERIALDWON tcp-listen:23 &
		#ser2net
	;;
	*)
		nice socat -b $TELEMETRY_UDP_BLOCKSIZE GOPEN:/root/$1 UDP4-SENDTO:$2:$TELEMETRY_UDP_PORT &
	;;
	esac
	if [ "$TELEMETRY_UPLINK" == "Y" ]; then
		nice cat $VSERIALUP > /dev/pts/7 &
	fi
}

## runs on RX (ground pi)
function stream_forward {
	PIP=`cat /tmp/pip`
	if [ -f "/tmp/single" ]; then
		rm /tmp/single
		if [ "$PIP" == "S" ]; then
			ps -ef | nice grep "gst-launch-1.0 udpsrc" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		else
			ps -ef | nice grep "rx -p 0" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		fi
		sleep 1
	fi
	if [ ! -f "/tmp/splitting" ]; then
		if [ "$PIP" == "S" ]; then
			UDP_PORT1=$VIDEO_UDP_PORT1
			UDP_PORT2=$VIDEO_UDP_PORT2
		else
			UDP_PORT1=$VIDEO_UDP_PORT2
			UDP_PORT2=$VIDEO_UDP_PORT1
		fi	
		nice -n -10 $SPLIT_PROGRAM 9120 5612 $UDP_PORT1 &
		sleep 1
		nice -n -10 $SPLIT_PROGRAM 9220 5512 $UDP_PORT2 &
		sleep 1
		touch /tmp/splitting
	fi
	echo "add $1" > /dev/udp/127.0.0.1/9120
	echo "add $1" > /dev/udp/127.0.0.1/9220
}

## runs on RX (ground pi)
function kill_forward {
	FX1=`cat /tmp/FX1`
	FX2=`cat /tmp/FX2`
	FX3=`cat /tmp/FX3`
	if [ "$FX1" == "N" ] && [ "$FX2" == "N" ] && [ "$FX3" == "N" ]; then
		FXIP=N
	else
		FXIP=Y
	fi
	case $1 in
	"telemetryfifo4")
		VSERIALUP=/dev/pts/0
		;;
	"telemetryfifo2")
		VSERIALUP=/dev/pts/2
		;;
	"telemetryfifo5")
		VSERIALUP=/dev/pts/4
		;;
	esac	
	echo "del $2" > /dev/udp/127.0.0.1/9120
	echo "del $2" > /dev/udp/127.0.0.1/9220
	SINGLECORE=`cat /tmp/SINGLECORE`
	ps -ef | nice grep "cat /root/$1" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "UDP4-SENDTO:$2" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "rssi_forward $2" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "mavlink-routerd -e $2" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "cmavnode --file /tmp/cmavnode$1.conf" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "tshark" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	ps -ef | nice grep "cat $VSERIALUP" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	if [ "$FXIP" == "N" ]; then
		rm /tmp/splitting
		ps -ef | nice grep "UDPSplitter" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		if [ "$SINGLECORE" != "N" ]; then
			ps -ef | nice grep "rx -p 0" | nice grep -v grep | awk '{print $2}' | xargs kill -9
		fi
	fi
	# kill msp processes
#	ps -ef | nice grep "cat /root/mspfifo" | nice grep -v grep | awk '{print $2}' | xargs kill -9
	#ps -ef | nice grep "socat /dev/pts/3" | nice grep -v grep | awk '{print $2}' | xargs kill -9
#	ps -ef | nice grep "ser2net" | nice grep -v grep | awk '{print $2}' | xargs kill -9
}

## runs on RX (ground pi)
function tether_check_function {
	SINGLECORE=`cat /tmp/SINGLECORE`
	echo "Waiting until nics are configured ..."
	while [ ! -f /tmp/nics_configured ]; do
		sleep 0.5
		#echo -n "."
	done
	sleep 1
	while true; do
		# pause loop while saving is in progress
		pause_while
		if [ -d "/sys/class/net/usb0" ]; then
			echo
			echo "USB tethering device detected. Configuring IP ..."
			nice pump -h wifibrdcast -i usb0 --no-dns --keep-up --no-resolvconf --no-ntp || {
				echo "ERROR: Could not configure IP for USB tethering device!"
				nice killall wbc_status > /dev/null 2>&1
				nice /root/wifibroadcast_status/wbc_status "ERROR: Could not configure IP for USB tethering device!" 7 55 0
				collect_errorlog
				sleep 365d
			}
			# find out smartphone IP to send video stream to
			PHONE_IP=`ip route show 0.0.0.0/0 dev usb0 | cut -d\  -f3`
			echo "Android IP: $PHONE_IP"
			echo "$PHONE_IP" > /tmp/FX1
			stream_forward $PHONE_IP
			telemetry_forward telemetryfifo4 $PHONE_IP
			# check if smartphone has been disconnected
			PHONETHERE=1
			while [ $PHONETHERE -eq 1 ]; do
				if [ -d "/sys/class/net/usb0" ]; then
					PHONETHERE=1
				else
					echo "Android device gone"
					echo "N" > /tmp/FX1
					PHONETHERE=0
					# kill forwarding of video and osd to secondary display
					kill_forward telemetryfifo4 $PHONE_IP
					ps -ef | nice grep "pump -h wifibrdcast" | nice grep -v grep | awk '{print $2}' | xargs kill -9
				fi
				sleep 2
			done
		else
			echo "Android device not detected ..."
		fi
		sleep 2
	done
}

## runs on RX (ground pi)
function wifi_hotspot_function {
	echo
	echo "Waiting until nics are configured ..."
	while [ ! -f /tmp/nics_configured ]; do
		sleep 0.5
		#echo -n "."
	done
	sleep 2
	WIFIHOTSPOT=`cat /tmp/wifihotspot`
	if [ "$WIFIHOTSPOT" == "Y" ]; then
		# Convert hostap config from DOS format to UNIX format
		ionice -c 3 nice dos2unix -n /boot/apconfig.txt /tmp/apconfig.txt
		nice udhcpd -I 192.168.2.1 /etc/udhcpd-wifi.conf
		nice -n 5 hostapd -B -d /tmp/apconfig.txt
		if cat /tmp/apconfig.txt | grep -q "^#wpa_passphrase="; then
			tmessage "Wifihotspot havn't passphrase,configfile sync enabled"
			nice socat -u open:/tmp/settings.sh TCP4-LISTEN:991,bind=192.168.2.1,reuseaddr &
		else
			tmessage "Wifihotspot have passphrase,configfile sync disabled"
		fi
		SINGLECORE=`cat /tmp/SINGLECORE`
		while true; do
			# pause loop while saving is in progress
			pause_while
			if nice ping -I wifihotspot0 -c 2 -W 1 -n -q 192.168.2.2 > /dev/null 2>&1; then
				WIFIIP="192.168.2.2"
				echo "Wifi device detected. WIFIIP: $WIFIIP"
				echo "$WIFIIP" > /tmp/FX2
				stream_forward $WIFIIP
				telemetry_forward telemetryfifo2 $WIFIIP
				WIFIIPTHERE=1
				while [ $WIFIIPTHERE -eq 1 ]; do
					if ping -c 2 -W 1 -n -q $WIFIIP > /dev/null 2>&1; then
						WIFIIPTHERE=1
					else
						echo "WIFIIP $WIFIIP gone"
						echo "N" > /tmp/FX2
						WIFIIPTHERE=0
						# kill forwarding of video and telemetry to secondary display
						kill_forward telemetryfifo2 $WIFIIP
					fi
					sleep 2
				done
			fi
			sleep 2
		done
	else
		echo "wifi Hotspot card not found!"
	fi
}

## runs on RX (ground pi)
function ethernet_hotspot_function {
	echo
	echo "Waiting until nics are configured ..."
	while [ ! -f /tmp/nics_configured ]; do
		sleep 0.5
		#echo -n "."
	done
	sleep 3
	if ls /sys/class/net | grep -q eth0; then
		# setup hotspot on internal ethernet chip
		nice ifconfig eth0 down
		sleep 1
		nice ifconfig eth0 192.168.1.1 up
		nice udhcpd -I 192.168.1.1 /etc/udhcpd-eth.conf
		SINGLECORE=`cat /tmp/SINGLECORE`
		while true; do
			# pause loop while saving is in progress
			pause_while
			if nice ping -I eth0 -c 1 -W 1 -n -q 192.168.1.2 > /dev/null 2>&1; then
				NETIP="192.168.1.2"
				echo "Ethernet device detected. NETIP: $NETIP"
				echo "$NETIP" > /tmp/FX3
				stream_forward $NETIP
				telemetry_forward telemetryfifo5 $NETIP
				NETIPTHERE=1
				while [ $NETIPTHERE -eq 1 ]; do
					if ping -c 2 -W 1 -n -q $NETIP > /dev/null 2>&1; then
						NETIPTHERE=1
					else
						echo "NETIP $NETIP gone"
						echo "N" > /tmp/FX3
						NETIPTHERE=0
						# kill forwarding of video and telemetry to secondary display
						kill_forward telemetryfifo5 $NETIP
					fi
					sleep 2
				done
			fi
			sleep 2
		done
	else
		echo "Pi Onboard ethernet Hotspot card not found!"
	fi
}

#
# Start of script
#

#setcolors /boot/console-color.txt

printf "\033c"

TTY=`tty`

# check if cam is detected to determine if we're going to be RX or TX
# only do this on one tty so that we don't run vcgencmd multiple times (which may make it hang)
if [ -e "/tmp/settings.sh" ]; then
	OK=`bash -n /tmp/settings.sh`
	if [ "$?" == "0" ]; then
		source /tmp/settings.sh
		LSCPU=`lscpu`
		CPU_THREADS=`echo "$LSCPU" | grep "^CPU(s):" | cut -d':' -f2 | sed "s/^[ \t]*//"`
		tmessage "CPU_THREADS:$CPU_THREADS"
		if [ "$CPU_THREADS" != "1" ] && [ "$OSD" == "Y" ]; then
			SINGLECORE=N
		else
			SINGLECORE=Y
		fi
		echo "$SINGLECORE" > /tmp/SINGLECORE
		if [ "$STREAM" == "svpcom" ]; then
			echo "S" > /tmp/pip
		else
			echo "R" > /tmp/pip
		fi
	else
		echo "ERROR: wifobroadcast config file contains syntax error(s)!"
		collect_errorlog
		sleep 365d
	fi
else
	echo "ERROR: wifobroadcast config file not found!"
	collect_errorlog
	sleep 365d
fi

if [ "$TTY" == "/dev/tty1" ]; then
	count=0
	IPHERE=N
	if [ "$IPCAM" ]; then
		if ls /sys/class/net | grep -q eth1; then
			ip link set eth0 name eth2
			ip link set eth1 name eth0
			ip link set eth2 name eth1
		fi
		if ls /sys/class/net | grep -q eth0; then
			CAMIP=`echo $IPCAM | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"`
			AIRIP=`echo $CAMIP | awk 'BEGIN{FS=OFS="."}{$NF=1;print}'`
			#IP Camera don`t have DHCP, so air pi fixed IP.
			nice ifconfig eth0 $AIRIP netmask 255.255.255.0 up
			sleep 2
			if cat /sys/class/net/eth0/carrier | nice grep -q 1; then
				tmessage "Ethernet connection detected"
				while [ $count -lt 7 ]; do
					if ping -c 2 -W 1 -n -q $CAMIP > /dev/null 2>&1; then
						IPHERE=Y
						tmessage "IPCAM:$CAMIP have connected ..."
						break
					fi
					let "count++"
				done
			else
				nice ifconfig eth0 down
			fi
		fi
	fi

	CAM=`vcgencmd get_camera | nice grep detected | sed -n 's/^.*detected=//p'`
	CSI=`vcgencmd get_camera | nice grep supported | sed -n 's/^.*supported=//p' | cut -d ' ' -f 1`
	echo  "$CSI" > /tmp/csi
	if [ "$CAM" == "0" ]; then
		pushd /root/veyecam/i2c_cmd
		./camera_i2c_config
		if [ "$CSI" == "2" ]; then	
			echo "supported CSI:$CSI"
			echo "detected CAM:$CAM"
			i2cdetect -y 1 | grep "30: -- -- -- -- -- -- -- -- -- -- -- 3b -- -- -- --"
			grepRet=$?
			if [ $grepRet -eq 0 ] ; then
				VEYE=Y
				veyecam_cmd 1
			else
				i2cdetect -y 0 | grep "30: -- -- -- -- -- -- -- -- -- -- -- 3b -- -- -- --"
				grepRet=$?
				if [ $grepRet -eq 0 ] ; then
					VEYE=Y
					veyecam_cmd 0
				else
					VEYE=N
				fi
			fi
		else
			i2cdetect -y 0 | grep "30: -- -- -- -- -- -- -- -- -- -- -- 3b -- -- -- --"
			grepRet=$?
			if [ $grepRet -eq 0 ] ; then
				VEYE=Y
				veyecam_cmd 0
			else
				VEYE=N
			fi
		fi
		popd
	fi
	
	if [ "$IPHERE" == "Y" ]; then
		if [ "$CPU_THREADS" != "1" ]; then
			sleep 3
		fi
		if [ "$CAM" == "0" ]; then
			if [ "$VEYE" == "Y" ]; then
				CAM="8"
				echo  "8" > /tmp/cam
			else
				if [ -e /dev/video0 ]; then
					CAM="9"
					echo  "9" > /tmp/cam
				else
					CAM="5"
					echo  "5" > /tmp/cam
				fi
			fi
		else
			if [ "$CAM" == "2" ]; then
				CAM="7"
				echo  "7" > /tmp/cam
			else
				CAM="6"
				echo  "6" > /tmp/cam
			fi
		fi
	else
		if [ "$CAM" == "0" ]; then
			if [ "$VEYE" == "Y" ]; then
				if [ -e /dev/video0 ]; then
					CAM="12"
					echo  "12" > /tmp/cam
				else
					CAM="3"
					echo  "3" > /tmp/cam
				fi
			else
				if [ -e /dev/video0 ]; then
					CAM="4"
					echo  "4" > /tmp/cam
				else
					echo  "0" > /tmp/cam
				fi
			fi
		else
			if [ -e /dev/video0 ]; then
				if [ "$CAM" == "2" ]; then
					CAM="11"
					echo  "11" > /tmp/cam
				else
					CAM="10"
					echo  "10" > /tmp/cam
				fi
			else
				echo  "$CAM" > /tmp/cam
			fi
		fi
	fi
else
	#echo -n "Waiting until TX/RX has been determined"
	while [ ! -f /tmp/cam ]; do
		sleep 0.5
		#echo -n "."
	done
	CAM=`cat /tmp/cam`
	CSI=`cat /tmp/csi`
fi

if [ "$CAM" == "0" ]; then # if we are RX ...
	# if local TTY, set font according to display resolution
	if [ "$TTY" = "/dev/tty1" ] || [ "$TTY" = "/dev/tty2" ] || [ "$TTY" = "/dev/tty3" ] || [ "$TTY" = "/dev/tty4" ] || [ "$TTY" = "/dev/tty5" ] || [ "$TTY" = "/dev/tty6" ] || [ "$TTY" = "/dev/tty7" ] || [ "$TTY" = "/dev/tty8" ] || [ "$TTY" = "/dev/tty9" ] || [ "$TTY" = "/dev/tty10" ] || [ "$TTY" = "/dev/tty11" ] || [ "$TTY" = "/dev/tty12" ]; then
	H_RES=`tvservice -s | cut -f 2 -d "," | cut -f 2 -d " " | cut -f 1 -d "x"`
	if [ "$H_RES" -ge "1680" ]; then
		setfont /usr/share/consolefonts/Lat15-TerminusBold24x12.psf.gz
	else
		if [ "$H_RES" -ge "1280" ]; then
			setfont /usr/share/consolefonts/Lat15-TerminusBold20x10.psf.gz
		else
			if [ "$H_RES" -ge "800" ]; then
				setfont /usr/share/consolefonts/Lat15-TerminusBold14.psf.gz
			fi
		fi
	fi
	fi
fi



# enable jit compiler for BPF filter (may improve bpf filter performance?)
#echo 1 > /proc/sys/net/core/bpf_jit_enable

case $DATARATE in
	1)
	UPLINK_WIFI_BITRATE=6
	VIDEO_WIFI_BITRATE=6
	MCS=0
	SGI=0
	;;
	2)
	UPLINK_WIFI_BITRATE=6
	VIDEO_WIFI_BITRATE=11
	MCS=1
	SGI=0
	;;
	3)
	UPLINK_WIFI_BITRATE=11
	VIDEO_WIFI_BITRATE=12
	MCS=1
	SGI=1
	;;
	4)
	UPLINK_WIFI_BITRATE=12
	VIDEO_WIFI_BITRATE=18
	MCS=2
	SGI=0
	;;
	5)
	UPLINK_WIFI_BITRATE=12
	VIDEO_WIFI_BITRATE=24
	MCS=3
	SGI=0
	;;
	6)
	UPLINK_WIFI_BITRATE=12
	VIDEO_WIFI_BITRATE=36
	MCS=4
	SGI=0
	;;
esac

FC_TELEMETRY_STTY_OPTIONS="-icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon"
FC_RC_STTY_OPTIONS="-icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon"

# mmormota's stutter-free hello_video.bin: "hello_video.bin.30-mm" (for 30fps) or "hello_video.bin.48-mm" (for 48 and 59.9fps)
# befinitiv's hello_video.bin: "hello_video.bin.240-befi" (for any fps, use this for higher than 59.9fps)

#	if [ "$STREAM" == "svpcom" ] || [ "$FPS" -ge 60 ]; then
		DISPLAY_PROGRAM=/opt/vc/src/hello_pi/hello_video/hello_video.bin.240-befi
#	else
#		if [ "$FPS" -eq 30 ]; then
#			DISPLAY_PROGRAM=/opt/vc/src/hello_pi/hello_video/hello_video.bin.30-mm
#		else
#			DISPLAY_PROGRAM=/opt/vc/src/hello_pi/hello_video/hello_video.bin.48-mm
#		fi
#	fi

SPLIT_PROGRAM=/root/wifibroadcast_misc/UDPSplitter

VIDEO_UDP_BLOCKSIZE=1024
TELEMETRY_UDP_BLOCKSIZE=128

VIDEO_NUM=$((VIDEO_BLOCKS+VIDEO_FECS))

RELAY_VIDEO_BLOCKS=6
RELAY_VIDEO_FECS=2
RELAY_VIDEO_BLOCKLENGTH=1536

EXTERNAL_TELEMETRY_SERIALPORT_GROUND_STTY_OPTIONS="-icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon"
TELEMETRY_OUTPUT_SERIALPORT_GROUND_STTY_OPTIONS="-icrnl -ocrnl -imaxbel -opost -isig -icanon -echo -echoe -ixoff -ixon"

if [ "$TELEMETRY_TRANSMISSION" == "wbc" ]; then
	TELEMETRY_BAUDRATE=$FC_TELEMETRY_BAUDRATE
else
	TELEMETRY_BAUDRATE=$EXTERNAL_TELEMETRY_SERIALPORT_GROUND_BAUDRATE
fi
RSSI_UDP_PORT=5003
RSSI_QGC_UDP_PORT=5154

if [ "$TELEMETRY_OSD" == "mavlink" ]; then
	TELEMETRY_TYPE=0
else
	TELEMETRY_TYPE=1
fi

case $TELEMETRY_OSD in
	"ltm")
		TELEMETRY_UDP_PORT=5001
	;;
	"frsky")
		TELEMETRY_UDP_PORT=5002
	;;
	"smartport")
		TELEMETRY_UDP_PORT=5010
	;;
	"vot")
		TELEMETRY_UDP_PORT=5011
	;;
	*)
		TELEMETRY_UDP_PORT=5004
	;;
esac

if [ "$RC" != "disabled" ]; then
	FRAMETYPE=0 # use RTS frames
else
	FRAMETYPE=1 # use DATA frames
fi

if [ "$STBC_LDPC" == "Y" ]; then
	STBC=1 # enabled STBC
	LDPC=1 # enabled LDPC
else
	STBC=0 # Disabled STBC
	LDPC=0 # Disabled LDPC
fi

if [ "$LINK_RC_KEY" ]; then
	TELEMETRY_UPLINK_PORT=$((LINK_RC_KEY+10))
else
	TELEMETRY_UPLINK_PORT=3
fi

case $TTY in
	/dev/tty1) # video stuff and general stuff like wifi card setup etc.
	printf "\033[12;0H"
	echo
	tmessage "Display: `tvservice -s | cut -f 3-20 -d " "`"
	echo
	TxPowerConfigFilePath="/etc/modprobe.d/ath9k_hw.conf"
	tagpower=`sed -n 's/^.*txpower=//p' $TxPowerConfigFilePath | cut -d ' ' -f 1`
	CONFIGFILE=`/root/wifibroadcast_misc/gpio-config.py`
	tmessage "GPIO chose configfile:$CONFIGFILE,tagpower: $tagpower"
	if [ "$CAM" == "0" ]; then
		if [ "$txpower" ]; then
			if [ "$TELEMETRY_UPLINK" == "Y" ] || [ "$RC" != "disabled" ]; then
				if [ "$tagpower" != "$txpower" ]; then
				   nice /usr/local/bin/txpower_atheros $txpower
				   nice /usr/local/bin/txpower_ralink $txpower
				   reboot
				fi
			else
				if [ "$tagpower" != "1" ]; then
				   nice /usr/local/bin/txpower_atheros 1
				   nice /usr/local/bin/txpower_ralink 1
				   reboot
				fi
			fi
		fi
		rx_function
	else
		if [ "$txpower" ]; then
			if [ "$tagpower" != "$txpower" ]; then
				nice /usr/local/bin/txpower_atheros $txpower
				nice /usr/local/bin/txpower_ralink $txpower
				reboot
			fi
		fi
		if [ "$WIFI_HOTSPOT" == "Y" ]; then
			# Convert hostap config from DOS format to UNIX format
			ionice -c 3 nice dos2unix -n /boot/apconfig.txt /tmp/apconfig.txt > /dev/null 2>&1
			channel=`sed -n 's/\bchannel=\b//p' "/tmp/apconfig.txt" | cut -d ' ' -f 1`
			if ls /sys/class/net/ | grep -q intwifi0; then
				if iwlist intwifi0 channel | grep -q $channel; then
					tmessage "Air unit Onboard Wifi card found! Sync configfile operation via intwifi0. "
					SYNCWIFI=1
				else
					tmessage "Air unit Onboard Wifi card doesn't support the channels of ground unit WiFihotspot"
					SYNCWIFI=0
				fi
			else
				tmessage "Air unit Onboard Wifi card not found!"
				SYNCWIFI=2
			fi
			if [ "$SYNCWIFI" == "1" ]; then
				auto_sync intwifi0 &
			else
				SYNCCARD=0
				ALL_CARDS=-1
				NICCARDS=`ls /sys/class/net | nice grep wlan`
				for NIC in $NICCARDS
				do
					let "ALL_CARDS++"
					if iwlist $NIC channel | grep -q $channel; then
						SYNCCARD=$NIC
						break
					fi
				done
				if [ "$ALL_CARDS" == "-1" ]; then
					echo "ERROR: No wifi cards detected"
					collect_errorlog
					sleep 365d
				else
					if [ "$SYNCCARD" == "0" ]; then
						tmessage "Air unit have not WiFi card support the channels of ground unit WiFihotspot!"
					else
						tmessage "Sync configfile operation via $SYNCCARD."
						auto_sync $SYNCCARD
					fi
				fi
			fi
		fi
		tx_function
	fi
	;;
	/dev/tty2) # osd stuff
	echo "================== OSD (tty2) ==========================="
	# only run osdrx if no cam found
	if [ "$CAM" == "0" ]; then
		downlinkrx_function
	else
		# only run osdtx if cam found, osd enabled and telemetry input is the tx
		if [ "$TELEMETRY_TRANSMISSION" == "wbc" ]; then
			downlinktx_function
		fi
	fi
	echo "OSD not enabled in configfile"
	sleep 365d
	;;
	/dev/tty3) # r/c stuff
	echo "================== R/C TX (tty3) ==========================="
	# only run rctx if no cam found and rc is not disabled
	if [ "$CAM" == "0" ] && [ "$RC" != "disabled" ]; then
		echo "R/C enabled ... we are R/C TX (Ground Pi)"
		rctx_function
	fi
	echo "R/C not enabled in configfile or we are R/C RX (Air Pi)"
	sleep 365d
	;;
	/dev/tty4) # unused
	echo "================== RSSIRX (tty4) ==========================="
	if [ "$CAM" == "0" ]; then
		rssirx_function
	else
		echo "We are TX - rssirx not started"
	fi
	sleep 365d
	;;
	/dev/tty5) # screenshot stuff
	echo "================== SCREENSHOT (tty5) ==========================="
	echo
	# only run screenshot function if cam found and screenshots are enabled
	if [ "$CAM" == "0" ]; then
		SINGLECORE=`cat /tmp/SINGLECORE`
		if [ "$SINGLECORE" == "N" ] && [ "$ENABLE_SCREENSHOTS" == "Y" ]; then
			echo "Waiting some time until everything else is running ..."
			sleep 20
			echo "Screenshots enabled - starting screenshot function ..."
			screenshot_function
		fi
	fi
	echo "Screenshots not enabled in configfile or we are TX"
	sleep 365d
	;;
	/dev/tty6)
	echo "================== SAVE FUNCTION (tty6) ==========================="
	echo
	# only run save function if we are RX
	if [ "$CAM" == "0" ]; then
		SINGLECORE=`cat /tmp/SINGLECORE`
		if [ "$SINGLECORE" == "N" ]; then
			echo "Waiting some time until everything else is running ..."
			sleep 30
			echo "Waiting for USB stick to be plugged in ..."
			KILLED=0
			LIMITFREE=3000 # 3 mbyte
			while true; do
				if [ ! -f "/tmp/donotsave" ]; then
		# some sticks show up as sda1, others as sda, check for both
					if [ -e "/dev/sda1" ]; then
						USBDEV="/dev/sda1"
					else
						USBDEV="/dev/sda"
					fi
					if [ -e $USBDEV ]; then
						echo "USB Memory stick detected"
						save_function
					fi
				fi
		# check if tmp disk is full, if yes, kill cat process
				if [ "$KILLED" != "1" ]; then
					FREETMPSPACE=`nice df -P /wbc_tmp/ | nice awk 'NR==2 {print $4}'`
					if [ $FREETMPSPACE -lt $LIMITFREE ]; then
						echo "RAM disk full, killing cat video file writing	 process ..."
						ps -ef | nice grep "cat /root/videofifo3" | nice grep -v grep | awk '{print $2}' | xargs kill -9
						ps -ef | nice grep "cat /root/steamfifo3" | nice grep -v grep | awk '{print $2}' | xargs kill -9
						KILLED=1
					fi
				fi
				sleep 1
			done
		fi
	fi
	echo "Save function not need or we are TX"
	sleep 365d
	;;
	/dev/tty7) # check tether
	echo "================== CHECK TETHER (tty7) ==========================="
	if [ "$CAM" == "0" ]; then
		echo "Waiting some time until everything else is running ..."
		tether_check_function
	else
		echo "Cam found, we are TX, Check tether function disabled"
		sleep 365d
	fi
	;;
	/dev/tty8) # wifi hotspot
	echo "================== CHECK HOTSPOT (tty8) ==========================="
	if [ "$CAM" == "0" ] && [ "$WIFI_HOTSPOT" == "Y" ]; then
		echo "Waiting some time until everything else is running ..."
		wifi_hotspot_function
	else
		echo "wifi hotspot function not enabled - we are TX (Air Pi)"
		sleep 365d
	fi
	;;
	/dev/tty9) # check alive
	echo "================== CHECK ALIVE (tty9) ==========================="
	if [ "$CAM" == "0" ]; then
		echo "Waiting some time until everything else is running ..."
		check_alive_function
		echo
	else
		echo "Cam found, we are TX, check alive function disabled"
		sleep 365d
	fi
	;;
	/dev/tty10) # uplink
	echo "================== uplink tx rx / rc rx / (tty10) ==========================="
	if [ "$CAM" == "0" ]; then # we are video RX and uplink TX
		if [ "$TELEMETRY_UPLINK" == "Y" ]; then
			echo "uplink  enabled ... we are uplink TX"
		    uplinktx_function
		else
			echo "uplink not enabled in config"
		fi
		sleep 365d
	else # we are video TX and uplink RX
		if [ "$TELEMETRY_TRANSMISSION" == "wbc" ]; then
			echo "Telemetry transmission WBC chosen"
			if [ "$TELEMETRY_UPLINK" == "Y" ] || [ "$RC" != "disabled" ]; then
				echo "Uplink and/or R/C enabled ... we are RX"
				uplinkrx_and_rcrx_function
			else
				echo "uplink and R/C not enabled in config"
			fi
		else
			echo "Telemetry transmission external"
			if [ "$RC" != "disabled" ]; then
				echo "R/C enabled ... we are RX"
				uplinkrx_and_rcrx_function
			else
				echo "R/C not enabled in config"
			fi
		fi
		sleep 365d
	fi
	;;
	/dev/tty11) # tty for dhcp and login
	echo "================== eth0 DHCP client (tty11) ==========================="
# sleep until everything else is loaded (atheros cards and usb flakyness ...)
	if [ "$CAM" == "0" ] && [ "$ETHERNET_HOTSPOT" == "Y" ]; then
		echo "We are RX and Ethernet Hotspot enabled"
		ethernet_hotspot_function
	else
# only configure ethernet network interface via DHCP if ethernet hotspot is disabled
		if [ "$CAM" == "0" ]; then
			EZHOSTNAME="wifibrdcast-rx"
		else
			EZHOSTNAME="wifibrdcast-tx"
		fi
		if [ "$CAM" != "5" ] && [ "$CAM" != "6" ] && [ "$CAM" != "7" ] && [ "$CAM" != "8" ] && [ "$CAM" != "9" ]; then
# disabled loop, as usual, everything is flaky on the Pi, gives kernel stall messages ...
			if ls /sys/class/net | grep -q eth0; then
				nice ifconfig eth0 down
				sleep 1
				nice ifconfig eth0 up
				sleep 2
				if cat /sys/class/net/eth0/carrier | nice grep -q 1; then
					echo "Ethernet connection detected"
					CARRIER=1
					if nice pump -i eth0 --no-ntp -h $EZHOSTNAME; then
#						ETHCLIENTIP=`ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1`
						ETHCLIENTIP=`ifconfig eth0 | grep 'inet ' | cut -d ':' -f 2 | awk '{print $2}'`
# kill and pause OSD so we can safeley start wbc_status
						ps -ef | nice grep "osd" | nice grep -v grep | awk '{print $2}' | xargs kill -9
						killall wbc_status > /dev/null 2>&1
						nice /root/wifibroadcast_status/wbc_status "Ethernet connected. IP: $ETHCLIENTIP" 7 55 0
						pause_while # make sure we don't restart osd while in pause state
						OSDRUNNING=`pidof /tmp/osd | wc -w`
						if [ $OSDRUNNING  -ge 1 ]; then
							echo "OSD already running!"
						else
							killall wbc_status > /dev/null 2>&1
							if [ "$CAM" == "0" ] && [ "$OSD" == "Y" ]; then # only (re-)start OSD if we are RX
								/tmp/osd >> /wbc_tmp/telemetrydowntmp.txt &
							fi
						fi
						ping -n -q -c 1 1.1.1.1
					else
						ps -ef | nice grep "pump -i eth0" | nice grep -v grep | awk '{print $2}' | xargs kill -9
						nice ifconfig eth0 down
						echo "Could not acquire IP via DHCP!"
					fi
				else
					nice ifconfig eth0 down
					echo "No ethernet connection detected"
				fi
			else
				echo "Pi Onboard ethernet card not found!"
			fi
		else
			echo "We are TX and IPCAM have connected, doing nothing"
		fi
	fi
	sleep 365d
	;;
	/dev/tty12) # tty for local interactive login
	echo
	if [ "$CAM" == "0" ]; then
		echo -n "Welcome to EZ-Wifibroadcast (RX) - "
		read -p "Press <enter> to login"
		killall osd
		rw
	else
		echo -n "Welcome to EZ-Wifibroadcast (TX) - "
		read -p "Press <enter> to login"
		rw
	fi
	;;
	*) # all other ttys used for interactive login
	if [ "$CAM" == "0" ]; then
		echo "Welcome to EZ-Wifibroadcast (RX) - type 'ro' to switch filesystems back to read-only"
		rw
	else
		echo "Welcome to EZ-Wifibroadcast (TX) - type 'ro' to switch filesystems back to read-only"
		rw
	fi
	;;
esac
