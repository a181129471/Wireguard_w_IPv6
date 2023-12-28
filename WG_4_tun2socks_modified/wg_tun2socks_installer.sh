#!/bin/bash

rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')
    echo $(($num%$max+$min))  
}

wireguard_install(){
    version=$(cat /etc/os-release | awk -F '[".]' '$1=="VERSION="{print $2}')
    if [ $version >= 18 ]
    then
        apt-get update -y
        apt-get install software-properties-common -y
    #else
     #   apt-get update -y
      #  apt-get install -y software-properties-common
    fi
    apt-get update -y
    apt-get install -y wireguard curl
    apt install resolvconf

    echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
    echo net.ipv6.conf.lo.disable_ipv6 = 1 >> /etc/sysctl.conf
    echo net.ipv6.conf.default.disable_ipv6 = 1 >> /etc/sysctl.conf
    echo net.ipv6.conf.all.disable_ipv6 = 1 >> /etc/sysctl.conf
    sysctl -p
    
    mkdir /etc/wireguard
    cd /etc/wireguard
    wg genkey | tee sprivatekey | wg pubkey > spublickey
    wg genkey | tee cprivatekey | wg pubkey > cpublickey
    s1=$(cat sprivatekey)
    s2=$(cat spublickey)
    c1=$(cat cprivatekey)
    c2=$(cat cpublickey)
    serverip=$(curl ipv4.icanhazip.com)
    port=$(rand 20000 50000)
    eth=$(ls /sys/class/net | awk '/^e/{print}')
    random_number=$(( RANDOM % 255 ))



cat > /etc/wireguard/wg0.conf <<-EOF
[Interface]
PrivateKey = $s1
Address = 10.100.$random_number.1/24
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT;
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT;
ListenPort = $port
DNS = 8.8.8.8
MTU = 1420

[Peer]
PublicKey = $c2
AllowedIPs = 10.100.$random_number.2/32
EOF


cat > /etc/wireguard/client.conf <<-EOF
[Interface]
PrivateKey = $c1
Address = 10.100.$random_number.2/24
DNS = 8.8.8.8
MTU = 1420

[Peer]
PublicKey = $s2
Endpoint = $serverip:$port
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 21
EOF

    apt-get install -y qrencode

cat > /etc/init.d/wgstart <<-EOF
#! /bin/bash
### BEGIN INIT INFO
# Provides:		wgstart
# Required-Start:	$remote_fs $syslog
# Required-Stop:    $remote_fs $syslog
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	wgstart
### END INIT INFO
wg-quick up wg0
EOF

    chmod +x /etc/init.d/wgstart
    cd /etc/init.d
    if [ $version == 14 ]
    then
        update-rc.d wgstart defaults 90
    else
        update-rc.d wgstart defaults
    fi
    
    wg-quick up wg0
    clear
    content=$(cat /etc/wireguard/client.conf)
    echo -e "\033[37;41m电脑端请下载/etc/wireguard/client.conf，手机端可直接使用软件扫码\033[0m"
    echo "${content}" | qrencode -o - -t UTF8
}



if ! command -v wg &> /dev/null; then
    # WireGuard is not installed, update and install net-tools
    apt update -y
    apt install net-tools -y
fi
clear
wireguard_install