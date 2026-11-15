#!/usr/bin/env bash
# ==========================================================
# Prerequisite Setup Script for Kubernetes v1.31 (Ubuntu 24.04)
# รันบนทุก Node (Control Plane + Workers): sudo bash kubeadm-prereq.sh
# ==========================================================

set -e

echo "[1/5] ปิด Swap ถาวร..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "[2/5] โหลด Kernel Modules และตั้งค่า Sysctl..."
cat << 'EOF' > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat << 'EOF' > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

echo "[3/5] ติดตั้งและตั้งค่า containerd (SystemdCgroup = true)..."
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg containerd

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

echo "[4/5] เพิ่ม Kubernetes v1.31 APT Repository..."
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

echo "[5/5] ติดตั้ง kubelet, kubeadm, kubectl..."
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "=========================================================="
echo " เตรียม Node เสร็จสมบูรณ์! ขั้นตอนถัดไป:"
echo " - บน Control Plane: รัน sudo kubeadm init --pod-network-cidr=10.244.0.0/16"
echo " - บน Worker Nodes: รอคำสั่ง kubeadm join จาก Control Plane"
echo "=========================================================="
