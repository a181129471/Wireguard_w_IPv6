#!/bin/bash
apt install tmux -y

if [ "$1" != "run_in_tmux" ]; then
    # Ask user for IP addresses
    read -p "输入正在ssh的ip（ipv4）: " static_route_ip1
    read -p "输入wireguard客户端的公网IP（ipv4）: " static_route_ip2

    # Save the input to temporary files
    echo "$static_route_ip1" > /tmp/static_route_ip1.txt
    echo "$static_route_ip2" > /tmp/static_route_ip2.txt

    # Start or attach to a tmux session and run the rest of the script
    tmux new-session -d -s monitor_session "bash $(realpath $0) run_in_tmux"
    echo "你的检测程序已于后台运行中，若需要查看输入 tmux attach -t monitor_session 即可"
    exit 0
fi

# The following will run in the tmux session

# Read the IP addresses from temporary files
static_route_ip1=$(cat /tmp/static_route_ip1.txt)
static_route_ip2=$(cat /tmp/static_route_ip2.txt)

# Clean up the temporary files
rm /tmp/static_route_ip1.txt /tmp/static_route_ip2.txt

# Retrieve the default gateway
static_route_gateway=$(ip route list | grep default | cut -d' ' -f 3)
check_interval=5  # How often to check, in seconds.

# Function to check static route
check_static_route() {
    if ip route show | grep -q "$static_route_ip1 via $static_route_gateway"; then
        echo "Static route for $static_route_ip1 is present."
    else
        echo "Static route for $static_route_ip1 is missing!"
        ip route add "$static_route_ip1" via "$static_route_gateway" dev enp1s0
    fi
    if ip route show | grep -q "$static_route_ip2 via $static_route_gateway"; then
        echo "Static route for $static_route_ip2 is present."
    else
        echo "Static route for $static_route_ip2 is missing!"
        ip route add "$static_route_ip2" via "$static_route_gateway" dev enp1s0
    fi
}

# Main monitoring loop
while true; do
    echo "Checking tunnel status..."
    check_static_route
    sleep "$check_interval"
done
