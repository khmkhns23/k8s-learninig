# Module 0: การสร้าง Kubernetes Cluster ตั้งแต่เริ่มต้น (From Scratch)

หากคุณยังไม่มี Kubernetes Cluster ใช้งานมาก่อน บทนี้จะแนะนำแนวทางการสร้างคลัสเตอร์ตั้งแต่ศูนย์ ตั้งแต่ระดับ **ทดลองเร็วบนเครื่องเดียว** ไปจนถึงระดับ **Multi-Node เต็มรูปแบบด้วย `kubeadm`**

---

## 1. เลือกวิธีสร้าง Cluster แบบไหนดี?

| เครื่องมือ | ลักษณะการทำงาน | ข้อดี | ข้อจำกัด |
| :--- | :--- | :--- | :--- |
| **Docker Desktop (K8s)** | เปิด K8s 1 Node มากับ Docker บน Windows/Mac | กดติ๊กถูกปุ่มเดียว ใช้งานได้ทันที | ได้แค่ 1 Node, ใช้ทดสอบ Multi-Node ไม่ได้ |
| **Minikube** | รัน Single/Multi-Node ใน Docker หรือ VM | มี Add-ons สำเร็จรูปเยอะ (เช่น Ingress, Dashboard) | กินทรัพยากรมากกว่า Kind เล็กน้อย |
| **Kind (Kubernetes in Docker)** | รัน K8s Node เป็น **Docker Container** | **เร็วมาก (< 1 นาที)** จำลอง 3 Nodes ได้สบาย, กิน RAM น้อย | ต้องมี Docker ติดตั้งอยู่แล้ว |
| **`kubeadm` บน VM / Server** | ติดตั้ง Component จริงทีละตัวบน Linux | เข้าใจโครงสร้างลึกเหมือน Production จริง | ขั้นตอนเยอะ, ต้องเตรียม VM 3 เครื่อง (RAM 6-8 GB+) |

> **คำแนะนำ:**
> - อยากเริ่มเรียนเขียน YAML / Workshop 1-6 ทันทีบน Notebook เครื่องเดียว -> ใช้ **Kind** (หรือ Minikube)
> - อยากฝึกเป็น Infra / System Admin และเข้าใจระบบเครือข่าย K8s จริงๆ -> ใช้ **`kubeadm`**

---

## 2. แนวทางที่ 1: แบบรวดเร็วด้วย Kind (3 Nodes ในเครื่องเดียว)

**Kind** ย่อมาจาก *Kubernetes in Docker* สามารถจำลองคลัสเตอร์แบบ 1 Control Plane + 2 Workers ได้ด้วยคำสั่งเดียว:

1. **ติดตั้ง Docker Desktop** และ **Kind** (`winget install Kubernetes.kind` บน Windows)
2. **สร้างไฟล์ Config (`kind-3node-config.yaml`)** เพื่อกำหนดจำนวน Node และเปิดพอร์ต `30080-30085` (เพื่อให้เข้าถึง NodePort จากเบราว์เซอร์ได้เหมือนคลัสเตอร์จริง)
3. **สร้างคลัสเตอร์:**
   ```bash
   kind create cluster --name k8s-lab --config kind-3node-config.yaml
   ```
4. **ตรวจสอบ:**
   ```bash
   kubectl get nodes
   ```
   คุณจะได้ `k8s-lab-control-plane`, `k8s-lab-worker`, `k8s-lab-worker2` พร้อมใช้งานใน 1 นาที!

---

## 3. แนวทางที่ 2: แบบเต็มรูปแบบด้วย `kubeadm` (Ubuntu 24.04)

เป็นการสร้างคลัสเตอร์มาตรฐานของ Kubernetes เอง โดยแบ่งเป็น 7 ขั้นตอนหลัก:

### ขั้นตอนที่ 1: เตรียม OS และ Network (ทำบนทุกเครื่อง)
- ตั้ง Hostname ให้ต่างกัน (`k8s-control`, `k8s-worker1`, `k8s-worker2`)
- ตั้ง Static IP และใส่รายชื่อใน `/etc/hosts` ให้ทุกเครื่องรู้จักกัน

### ขั้นตอนที่ 2: ปิด Swap และเปิด Kernel Modules (ทำบนทุกเครื่อง)
Kubernetes บังคับให้ **ปิด Swap** เพื่อให้ `kubelet` คำนวณและจัดสรร Memory ของ Node ได้แม่นยำ:
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```
และเปิดโมดูลสำหรับ Container Networking (`overlay`, `br_netfilter`) พร้อมเปิด `ip_forward = 1` ใน `sysctl`

### ขั้นตอนที่ 3: ติดตั้ง Container Runtime (`containerd`) (ทำบนทุกเครื่อง)
ติดตั้ง `containerd` แล้วตั้งค่าสำคัญที่สุดคือ **`SystemdCgroup = true`** ใน `/etc/containerd/config.toml` เพื่อให้ `containerd` ใช้ Cgroup driver ตัวเดียวกับ `kubelet` (ไม่เช่นนั้น `kubelet` จะ Crash)

### ขั้นตอนที่ 4: ติดตั้ง `kubeadm`, `kubelet`, `kubectl` (ทำบนทุกเครื่อง)
เพิ่ม Repository ของ Kubernetes (`pkgs.k8s.io`) แล้วติดตั้งทั้ง 3 ตัว พร้อมสั่ง `apt-mark hold` เพื่อป้องกันการอัปเดตข้ามเวอร์ชันโดยไม่ตั้งใจ

### ขั้นตอนที่ 5: สร้าง Control Plane (ทำเฉพาะบน `k8s-control`)
```bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.1.10
```
หลังรันสำเร็จ ต้องคัดลอกไฟล์ Admin Config มาให้ user ปกติใช้งาน `kubectl` ได้:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### ขั้นตอนที่ 6: ติดตั้ง CNI (Pod Network) (ทำเฉพาะบน `k8s-control`)
หลัง `kubeadm init` เสร็จใหม่ๆ Node จะขึ้นสถานะ **`NotReady`** เพราะยังไม่มีปลั๊กอินเครือข่ายสำหรับ Pod (CNI) ต้องติดตั้ง เช่น **Flannel** (ใช้คู่กับ CIDR `10.244.0.0/16`):
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### ขั้นตอนที่ 7: นำ Worker Nodes เข้าร่วมคลัสเตอร์ (ทำบน `worker1`, `worker2`)
นำคำสั่ง `kubeadm join ...` ที่ได้จากขั้นตอนที่ 5 (หรือสร้างใหม่ด้วย `kubeadm token create --print-join-command`) ไปรันบน Worker Node ทุกตัว จากนั้นตรวจด้วย `kubectl get nodes` จนขึ้น `Ready` ครบทุกเครื่อง

---

## 4. ลงมือปฏิบัติ (Workshop 0)
ดูคู่มือและไฟล์สำเร็จรูปทั้งแบบ **Kind** และ **`kubeadm`** ได้ที่: [ws00-build-cluster](../../workshops/ws00-build-cluster/README.md)

---

## 5. แบบทดสอบท้ายบท (Quiz 0)

**ข้อ 1.** เหตุใดการติดตั้ง Kubernetes ด้วย `kubeadm` จึงบังคับให้ปิด Swap (`swapoff -a`)?
- A. เพราะ Linux ไม่รองรับ Docker เมื่อเปิด Swap
- B. เพื่อให้ `kubelet` จัดสรรและคุมเพดาน Memory ของ Pod ได้แม่นยำตามที่กำหนดใน `requests`/`limits`
- C. เพื่อประหยัดพื้นที่ Hard Disk
- D. เพื่อเปิดพอร์ต 6443

**ข้อ 2.** หากเพิ่งรัน `kubeadm init` เสร็จใหม่ๆ แล้วสั่ง `kubectl get nodes` พบว่า `k8s-control` มีสถานะเป็น `NotReady` สาเหตุที่พบบ่อยที่สุดคืออะไร?
- A. ลืมติดตั้ง `kubectl`
- B. ยังไม่ได้ติดตั้ง CNI (Container Network Interface) เช่น Flannel หรือ Calico
- C. Worker Node ยังไม่ได้ Join
- D. ไฟร์วอลล์บล็อกพอร์ต 80

**ข้อ 3.** การตั้งค่า `SystemdCgroup = true` ในไฟล์ `/etc/containerd/config.toml` มีความสำคัญอย่างไร?
- A. ทำให้ดึง Image จาก Docker Hub เร็วขึ้น
- B. ทำให้ `containerd` และ `kubelet` ใช้ Cgroup Driver ตัวเดียวกัน (`systemd`) ป้องกันปัญหา kubelet ล่มหรือ Node ไม่เสถียร
- C. ทำให้ Container ใช้งาน GPU ได้
- D. เป็นการเปิด Firewall อัตโนมัติ

**ข้อ 4.** หลังรัน `kubeadm init` สำเร็จ หากพิมพ์ `kubectl get nodes` แล้วขึ้นข้อความ `The connection to the server localhost:8080 was refused` ต้องแก้ไขอย่างไร?
- A. รัน `kubeadm init` ใหม่อีกครั้ง
- B. คัดลอก `/etc/kubernetes/admin.conf` มาไว้ที่ `~/.kube/config` และตั้งสิทธิ์เจ้าของไฟล์ (`chown`)
- C. ติดตั้ง Nginx บนพอร์ต 8080
- D. รีบูตเครื่อง

**ข้อ 5.** หาก Token สำหรับ `kubeadm join` หมดอายุ (ปกติหมดอายุใน 24 ชั่วโมง) จะสร้างคำสั่ง Join ใหม่ได้จากเครื่อง Control Plane ด้วยคำสั่งใด?
- A. `kubeadm reset`
- B. `kubeadm token create --print-join-command`
- C. `kubectl get token`
- D. `kubeadm init --renew`

**ข้อ 6.** หากคุณใช้ Notebook เครื่องเดียว มี RAM จำกัดแต่อยากจำลองคลัสเตอร์แบบ 3 Nodes (`1 Control + 2 Workers`) เพื่อฝึก Workshop 1-6 ได้เร็วที่สุด ควรเลือกใช้เครื่องมือใด?
- A. `kubeadm` บน 3 VMs
- B. **Kind (Kubernetes in Docker)**
- C. `etcd` แบบ Standalone
- D. ติดตั้งบน Raspberry Pi 3 เครื่อง

---

<details>
<summary>คลิกเพื่อดูเฉลย Quiz 0</summary>

1. **B** — `kubelet` ออกแบบมาให้คุม Memory บน RAM จริง หากเปิด Swap จะทำให้การคำนวณ OOM และ Isolation ผิดพลาด (แม้ K8s รุ่นใหม่มี feature gate รองรับ swap บ้างแล้ว แต่มาตรฐาน Lab/Production ยังปิด Swap)
2. **B (ยังไม่ได้ติดตั้ง CNI)** — Kubelet จะรอจนกว่า CNI Plugin (เช่น Flannel/Calico) จะพร้อมใช้งานจึงจะเปลี่ยนสถานะ Node เป็น `Ready`
3. **B (`SystemdCgroup = true`)** — Ubuntu สมัยใหม่ใช้ `systemd` จัดการ cgroup หาก `containerd` ใช้ `cgroupfs` คนละตัวกับ `kubelet` จะเกิด conflict
4. **B (ตั้งค่า `~/.kube/config`)** — `kubectl` จะหาไฟล์ config ที่ `~/.kube/config` ถ้าไม่เจอจะเดาไปที่ `localhost:8080`
5. **B (`kubeadm token create --print-join-command`)** — สร้าง bootstrap token ใหม่พร้อมพิมพ์คำสั่ง join และ CA hash ออกมาให้คัดลอกทันที
6. **B (`Kind`)** — รัน Node เป็น Container เบาและเร็วที่สุดสำหรับการจำลอง Multi-Node ในเครื่องเดียว

</details>
