#!/bin/bash

create() {
    NUM_INTERFACES=3
    BASE_NETWORK="192.168."
    SUBNET_MASK="/24"
    PROXY_ADDRESSES=("x.x.x.x:1080" "y.y.y.y:1080" "z.z.z.z:1080")
    EXCLUDED_IPS=("8.8.8.8" "本机公网IP" "一号代理IP" "二号代理IP" "三号代理IP") #DNS/本机ssh/代理1，2，3 都需要用原有的gateway做直连。
    START_INDEX=0

    # 移除现有的pid记录文件（nohup 执行后的PID记录）
    rm -f tun2socks_pids.txt

    for IP in "${EXCLUDED_IPS[@]}"; do
        sudo iptables -t mangle -A OUTPUT -d "$IP" -j ACCEPT
    done

    for (( i=START_INDEX; i<START_INDEX+NUM_INTERFACES; i++ )); do
        sudo ip tuntap add mode tun dev "tun$i"
        NETWORK=$((22 + i))
        IP_ADDR="${BASE_NETWORK}${NETWORK}.1"
        sudo ip addr add "${IP_ADDR}${SUBNET_MASK}" dev "tun$i"
        sudo ip link set dev "tun$i" up
        
        nohup ./tun2socks-linux-amd64 -device tun://tun$i -proxy socks5://${PROXY_ADDRESSES[$i]} -interface ens3 -tcp-auto-tuning &
        echo $! >> tun2socks_pids.txt

        echo "$((100 + i)) tun$i" | sudo tee -a /etc/iproute2/rt_tables
        sudo ip rule add fwmark $((1 + i)) table $((100 + i))
        sudo ip route add default via $IP_ADDR dev "tun$i" metric 1 table $((100 + i)) #原有default via {gateway} 的metric 101 . 新default比原有的metric低，按理说会走新的default
    
    done

    for (( i=START_INDEX; i<START_INDEX+NUM_INTERFACES; i++ )); do
        sudo iptables -t mangle -A OUTPUT -m conntrack --ctstate NEW -m statistic --mode nth --every ${NUM_INTERFACES} --packet $i -j MARK --set-mark $((1 + i))
    done
    sudo iptables -t mangle -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark

    echo "$NUM_INTERFACES TUN interfaces created, configured with unique subnets, and load balancing set up."
}

delete() {
    NUM_INTERFACES=3
    START_INDEX=0



        # Kill tun2socks
    if [ -f tun2socks_pids.txt ]; then
        while read -r pid; do
            kill "$pid" 2>/dev/null
        done < tun2socks_pids.txt
        rm -f tun2socks_pids.txt
    fi
    for (( i=START_INDEX; i<START_INDEX+NUM_INTERFACES; i++ )); do
        sudo ip link set dev "tun$i" down
        sudo ip tuntap del mode tun dev "tun$i"
    done
    for (( i=START_INDEX; i<START_INDEX+NUM_INTERFACES; i++ )); do
        sudo ip rule del table $((100 + i))
        sudo sed -i '/tun'$i'$/d' /etc/iproute2/rt_tables
    done
    sudo iptables -t mangle -F
    echo "Reversed setup: Removed TUN interfaces and cleared related rules."
}

case "$1" in
    create)
        create
        ;;
    delete)
        delete
        ;;
    *)
        echo "Usage: $0 {create|delete}"
        exit 1
        ;;
esac
