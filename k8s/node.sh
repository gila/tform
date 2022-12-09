#!/bin/bash
set -ex

function add_kernel_modules() {
    for module in "$@"; do
        sudo modprobe "$module"
        if ! grep -q "^$module$" /etc/modules-load.d/kvm.conf; then
            echo "$module" | sudo tee -a /etc/modules-load.d/kvm.conf
        fi
    done
}

function enable_ip_forwarding() {
    sudo sysctl -w net.ipv4.ip_forward=1
    if ! grep -q "^net.ipv4.ip_forward\s*=\s*1$" /etc/sysctl.d/10-kubeadm.conf; then
        echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.d/10-kubeadm.conf
    fi
}

function set_huge_pages() {
    local nr_hugepages="$1"
    echo "$nr_hugepages" | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
    if ! grep -q "^vm.nr_hugepages\s*=\s*$nr_hugepages$" /etc/sysctl.d/10-kubeadm.conf; then
        echo "vm.nr_hugepages = $nr_hugepages" | sudo tee -a /etc/sysctl.d/10-kubeadm.conf
    fi
}

function wait_for_api_server() {
    local master_ip="$1"
    local token="$2"
    until nc -z "$master_ip" 6443; do
        echo "Waiting for API server to respond"
        sleep 5
    done
    sudo kubeadm join --token="$token" "$master_ip":6443 \
        --discovery-token-unsafe-skip-ca-verification \
        --ignore-preflight-errors=Swap,SystemVerification
}

if ! grep -qa container=lxc /proc/1/environ; then
    enable_ip_forwarding
    set_huge_pages "${nr_hugepages}"
    sudo apt-get -y install linux-modules-extra-$(uname -r)
    add_kernel_modules nvme-tcp nvmet
fi

wait_for_api_server "${master_ip}" "${token}"

