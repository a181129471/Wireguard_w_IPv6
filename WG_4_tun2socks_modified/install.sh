#!/bin/bash

#下载安装tun2socks

wget https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-linux-amd64.zip
unzip tun2socks-linux-amd64.zip
mv tun2socks-linux-amd64 /usr/bin/tun2socks

#下载安装魔改wireguard
curl -sSL https://raw.githubusercontent.com/andy72630/Wireguard_w_IPv6/main/WG_4_tun2socks_modified/wg_tun2socks_installer.sh | bash
curl -sSL https://raw.githubusercontent.com/andy72630/Wireguard_w_IPv6/main/WG_4_tun2socks_modified/monitor.sh | bash
wget https://raw.githubusercontent.com/andy72630/Wireguard_w_IPv6/main/WG_4_tun2socks_modified/tunnel_setup.sh -O tunnel_setup.sh && bash tunnel_setup.sh start
echo "结束时请手动运行bash tunnel_setup.sh stop"
