# Workshop 0: สร้าง Kubernetes Cluster ตั้งแต่เริ่มต้น

เลือกทำตาม **แนวทาง A** (เร็ว 5 นาทีบนเครื่องเดียวด้วย Kind) หรือ **แนวทาง B** (สร้าง 3 VMs เต็มรูปแบบด้วย `kubeadm`)

---

## แนวทาง A: สร้างคลัสเตอร์ 3 Nodes ใน 1 นาทีด้วย Kind (Windows / Mac / Linux)

เหมาะสำหรับผู้ที่ยังไม่มี VM และมี **Docker Desktop** ติดตั้งอยู่ในเครื่อง

### ขั้นตอนที่ 1: ติดตั้ง Kind (ทำครั้งเดียว)
บน Windows (PowerShell):
```powershell
winget install Kubernetes.kind
winget install Kubernetes.kubectl
```

### ขั้นตอนที่ 2: สร้างคลัสเตอร์ 3 Nodes พร้อมเปิดพอร์ต `30080-30085`
ใช้ไฟล์ [kind-3node-config.yaml](./kind-3node-config.yaml) ที่เตรียมไว้ให้ (มี 1 Control Plane + 2 Workers):
```powershell
kind create cluster --name k8s-lab --config kind-3node-config.yaml
```

### ขั้นตอนที่ 3: ตรวจสอบผลลัพธ์
```powershell
kubectl get nodes -o wide
```
จะเห็น 3 Nodes (`k8s-lab-control-plane`, `k8s-lab-worker`, `k8s-lab-worker2`) สถานะ **`Ready`** พร้อมเรียน Workshop 1-6 ต่อได้ทันที!
*(หมายเหตุ: เมื่อใช้ Kind หาก Workshop สั่งให้เข้า `http://192.168.1.11:30081` ให้เปลี่ยนมาเข้า `http://localhost:30081` แทน)*

### ลบคลัสเตอร์เมื่อเลิกใช้งาน (Cleanup)
```powershell
kind delete cluster --name k8s-lab
```

---

## แนวทาง B: สร้างคลัสเตอร์ด้วย `kubeadm` บน Ubuntu 24.04 (3 VMs)

เหมาะสำหรับผู้ที่ต้องการฝึกสร้างคลัสเตอร์จริงตั้งแต่ศูนย์บน VMware / VirtualBox / Cloud

### ขั้นตอนที่ 1: เตรียม OS และติดตั้ง Package พื้นฐาน (ทำบนทุกเครื่อง: Control, Worker1, Worker2)
1. ตั้ง Hostname ของแต่ละเครื่องให้ตรงกัน (`sudo hostnamectl set-hostname k8s-control` ฯลฯ)
2. คัดลอกไฟล์ [kubeadm-prereq.sh](./kubeadm-prereq.sh) ไปรันบน **ทุกเครื่อง**:
   ```bash
   sudo bash kubeadm-prereq.sh
   ```
   *(สคริปต์นี้จะปิด Swap, ตั้งค่า Kernel/Sysctl, ติดตั้ง `containerd` พร้อมเปิด `SystemdCgroup = true` และติดตั้ง `kubelet`, `kubeadm`, `kubectl` v1.31)*

### ขั้นตอนที่ 2: สร้าง Control Plane (ทำเฉพาะเครื่อง `k8s-control`)
เปลี่ยน `192.168.1.10` เป็น IP ของเครื่อง Control Plane ของคุณ:
```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.1.10
```
ตั้งค่า `kubeconfig` ให้ user ปกติใช้งาน `kubectl` ได้:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### ขั้นตอนที่ 3: ติดตั้ง Flannel CNI (ทำเฉพาะเครื่อง `k8s-control`)
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### ขั้นตอนที่ 4: Join Worker Nodes (ทำบน `worker1` และ `worker2`)
1. บน `k8s-control` รันเพื่อขอคำสั่ง Join:
   ```bash
   kubeadm token create --print-join-command
   ```
2. นำคำสั่งที่ได้ (ขึ้นต้นด้วย `sudo kubeadm join ...`) ไปวางรันบน `worker1` และ `worker2`

### ขั้นตอนที่ 5: ตรวจสอบคลัสเตอร์ (บน `k8s-control`)
```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system
```
เมื่อทุก Node ขึ้น **`Ready`** ก็พร้อมเริ่ม **Workshop 1** ได้เลยครับ!
