#!/bin/bash

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "请用root权限运行"
    exit 1
fi

#下载安装tun2socks
wget https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-linux-amd64.zip
unzip tun2socks-linux-amd64.zip
mv tun2socks-linux-amd64 /usr/bin/tun2socks

#下载安装魔改wireguard
curl -sSL https://raw.githubusercontent.com/andy72630/Wireguard_w_IPv6/main/WG_4_tun2socks_modified/wg_tun2socks_installer.sh | bash
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null
wget https://raw.githubusercontent.com/andy72630/Wireguard_w_IPv6/main/WG_4_tun2socks_modified/monitor.sh
echo "请手动运行一次 bash monitor.sh"
wget https://raw.githubusercontent.com/andy72630/Wireguard_w_IPv6/main/WG_4_tun2socks_modified/tunnel_setup.sh
echo "之后请手动运行 bash tunnel_setup.sh start 开启转发 或者 bash tunnel_setup.sh stop停止转发"
