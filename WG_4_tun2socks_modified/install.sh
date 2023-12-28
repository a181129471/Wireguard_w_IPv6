#!/bin/bash

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "请用root权限运行"
    exit 1
fi
apt update
apt install unzip -y

#下载安装tun2socks
wget https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-linux-amd64.zip
unzip tun2socks-linux-amd64.zip
mv tun2socks-linux-amd64 /usr/bin/tun2socks

#下载安装魔改wireguard
wget https://raw.githubusercontent.com/andy72630/Wireguard_w_IPv6/main/WG_4_tun2socks_modified/monitor.sh
wget https://raw.githubusercontent.com/andy72630/Wireguard_w_IPv6/main/WG_4_tun2socks_modified/tunnel_setup.sh
curl -sSL https://raw.githubusercontent.com/andy72630/Wireguard_w_IPv6/main/WG_4_tun2socks_modified/wg_tun2socks_installer.sh | bash
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null
echo -e "\033[0;31m需要手动运行 bash monitor.sh\033[0m"
echo -e "\033[0;31m之后请手动运行 bash tunnel_setup.sh start 开启转发 或者 bash tunnel_setup.sh stop停止转发\033[0m"
