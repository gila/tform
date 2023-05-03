#!/bin/bash
set -e

# Initialize the Kubernetes cluster with the provided configuration file
sudo kubeadm init --config /tmp/kubeadm_config.yaml
# Configure kubectl to use the newly created cluster
[ -d "$HOME"/.kube ] || mkdir -p "$HOME"/.kube
sudo cp /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown $(id -u):$(id -g) "$HOME"/.kube/config

# Wait for the Kubernetes API server to become available
until kubectl cluster-info > /dev/null 2>&1; do
  echo "Waiting for Kubernetes API server to become available"
  sleep 5
done

# Apply the latest version of Flannel networking
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

