#!/bin/bash

set -x

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg --yes
curl -fsSl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/goole.gpg --yes

sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" --yes
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" --yes

sudo apt-get update -y
sudo apt-get install -y \
  containerd.io \
  kubelet \
  kubeadm \
  kubectl

sudo apt-mark hold kubelet kubeadm kubectl

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF


# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Setup required sysctl params, these persist across reboots.
sudo sysctl --system

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml


# add registry
#
cat << EOF | sudo tee -a /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.1.4:5000"]
endpoint = ["http://192.168.1.4:5000"]
[plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.1.4:5000"]
insecure = true
EOF

# ensure reboot does not take forever
sudo mkdir -p /etc/systemd/system/containerd.service.d
sudo tee /etc/systemd/system/containerd.service.d/override.conf >/dev/null <<EOF
[Service]
KillMode=mixed
EOF

sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl restart containerd
