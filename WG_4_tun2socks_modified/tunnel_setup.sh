#!/bin/bash

# Declare tun_proxies as a global array
declare -a tun_proxies

default_gateway=$(ip route show default | awk '/default/ {print $3}')
INTERFACE=$(ip route | grep default | awk '{print $5}')
function ask_for_proxies() {
    while true; do
        read -p "输入SOCKS5的IP:端口 格式：x.y.z.n:m (留空回车代表结束): " proxy_input
        if [[ -z "$proxy_input" ]]; then
            if [[ ${#tun_proxies[@]} -gt 0 ]]; then
                break
            else
                echo "输入至少一个socks5代理地址或者按ctrl+c退出即可"
                continue
            fi
        fi
        tun_proxies+=("$proxy_input")
    done
}

function start_tunnel() {
    for i in "${!tun_proxies[@]}"; do
        ip tuntap add mode tun dev "tun$i"
        ip addr add "192.168.2$(expr $i + 0).1/24" dev "tun$i"
        ip link set dev "tun$i" up
        nohup tun2socks -device "tun$i" -proxy socks5://Attention:NoNeedPassword@${tun_proxies[$i]} -interface $INTERFACE -tcp-auto-tuning &
    done

    #ip route add 45.86.228.229 via $default_gateway dev $INTERFACE monitor看着的
    nohup wg-quick up wg0 &

    echo "请在10秒内连接wireguard"
    sleep 10
    wireguardClient_ip=$(wg | grep endpoint | awk '{print $2}' | cut -d ':' -f1)
    #ip route add $wireguardClient_ip via $default_gateway dev $INTERFACE monitor看着的
    ip route del default
    ip route add default via 192.168.20.1 dev tun0 metric 1
    ip route add default via $default_gateway dev $INTERFACE metric 10

    nexthops=""
    for i in "${!tun_proxies[@]}"; do
        nexthops+="nexthop via 192.168.2$(expr $i + 0).1 dev tun$i weight 1 "
    done
    ip route replace default scope global $nexthops

    for i in "${!tun_proxies[@]}"; do
        iptables -t nat -A POSTROUTING -o "tun$i" -j MASQUERADE
    done
}

function stop_tunnel() {
    wg-quick down wg0
    ip route del default via 192.168.20.1 dev tun0 metric 1
    pkill tun2socks
    readarray -t tun_interfaces < <(ip link show | grep -oP '(?<=\d: )tun\w+')

# Iterate over each 'tun' interface and perform operations
    for tun_if in "${tun_interfaces[@]}"; do
        echo "Operating on interface $tun_if..."

    # Bring the interface down
        ip link set dev "$tun_if" down

    # Delete the 'tun' interface
        ip tuntap del mode tun dev "$tun_if"

    # Delete the corresponding NAT rule in iptables
        iptables -t nat -D POSTROUTING -o "$tun_if" -j MASQUERADE
    done
}

case "$1" in
    start)
        ask_for_proxies
        start_tunnel
    ;;
    stop)
        stop_tunnel
    ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
    ;;
esac
