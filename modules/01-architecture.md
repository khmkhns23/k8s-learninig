# Module 1: Kubernetes Architecture & `kubectl` Basics

## 1. ภาพรวมสถาปัตยกรรม Kubernetes (K8s)

Kubernetes แบ่งเครื่องในคลัสเตอร์ออกเป็น 2 กลุ่มหลัก ได้แก่ **Control Plane** (สมองสั่งการ) และ **Worker Nodes** (ผู้รันงานจริง)

```text
+-------------------------------------------------------------------+
| Control Plane (k8s-control: 192.168.1.10)                         |
|  [kube-apiserver] <---> [etcd]                                    |
|        ^                                                          |
|        +---> [kube-scheduler]                                     |
|        +---> [kube-controller-manager]                            |
+-------------------------------------------------------------------+
         | (สื่อสารผ่าน API Server พอร์ต 6443)
         +-----------------------------+
         v                             v
+---------------------------+ +---------------------------+
| Worker 1 (192.168.1.11)   | | Worker 2 (192.168.1.12)   |
|  - kubelet                | |  - kubelet                |
|  - kube-proxy             | |  - kube-proxy             |
|  - containerd (Runtime)   | |  - containerd (Runtime)   |
|  - [Pods...]              | |  - [Pods...]              |
+---------------------------+ +---------------------------+
```

### 1.1 องค์ประกอบของ Control Plane
1. **`kube-apiserver`**: ประตูหน้าบ้านของคลัสเตอร์ ทุกคำสั่ง `kubectl` และการสื่อสารภายในต้องผ่านตัวนี้ (พอร์ต `6443`)
2. **`etcd`**: ฐานข้อมูลแบบ Key-Value ที่เก็บสถานะทั้งหมดของคลัสเตอร์ (เปรียบเสมือนหน่วยความจำถาวรของ K8s)
3. **`kube-scheduler`**: คอยดูว่ามี Pod ใหม่ที่ยังไม่มี Node อยู่หรือไม่ แล้วตัดสินใจเลือก Worker Node ที่เหมาะสมที่สุดให้ (ดูจาก CPU/RAM ที่เหลือ, Affinity ฯลฯ)
4. **`kube-controller-manager`**: คอยเฝ้าดูสถานะจริงเทียบกับสถานะที่ต้องการ (Desired State) เช่น ต้องการ 3 Pods แต่ตายไป 1 ตัว ก็จะสั่งสร้างเพิ่มให้ครบ 3

### 1.2 องค์ประกอบของ Worker Node
1. **`kubelet`**: ตัวแทน (Agent) บนแต่ละ Node คอยรับคำสั่งจาก API Server เพื่อสร้าง/ดูแล Container ให้ทำงานตาม Spec
2. **`kube-proxy`**: จัดการกฎ Network (iptables/IPVS) บนแต่ละ Node เพื่อให้ Service และ NodePort ส่งต่อทราฟฟิกไปยัง Pod ได้ถูกต้อง
3. **`Container Runtime` (`containerd`)**: โปรแกรมที่รัน Container จริงๆ ตามมาตรฐาน CRI

---

## 2. แนวคิดพื้นฐาน: Declarative vs Imperative & Namespace

- **Imperative (สั่งเป็นขั้นตอน):** เช่น `kubectl run web --image=nginx` — เหมาะกับการทดสอบเร็วๆ
- **Declarative (ประกาศผลลัพธ์ที่ต้องการด้วย YAML):** เช่น `kubectl apply -f app.yaml` — เหมาะกับงานจริงเพราะเก็บเข้า Git และทำซ้ำได้
- **Namespace:** คือการแบ่งพื้นที่เสมือน (Virtual Cluster) ภายในคลัสเตอร์เดียวกัน
  - `default`: พื้นที่เริ่มต้นหากไม่ระบุ `-n`
  - `kube-system`: เก็บ Pod ระบบของ K8s เอง (เช่น `coredns`, `etcd`, `kube-apiserver`, `flannel`)

---

## 3. คำสั่ง `kubectl` พื้นฐานที่ต้องใช้บ่อย

| คำสั่ง | ความหมาย |
| :--- | :--- |
| `kubectl get nodes -o wide` | ดูรายชื่อ Node, สถานะ (`Ready`), IP และ OS |
| `kubectl get pods -A` | ดู Pod ทั้งหมดในทุก Namespace |
| `kubectl describe pod <name>` | ดูรายละเอียดเชิงลึกและ **Events** (ใช้หาสาเหตุเวลา Pod มีปัญหา) |
| `kubectl logs <pod-name>` | ดู Log ที่แอปพ่นออกมาทาง stdout/stderr |
| `kubectl exec -it <pod> -- sh` | เข้าไปรัน shell ข้างใน Container เพื่อ Debug |
| `kubectl api-resources` | ดูรายการ Resource ทั้งหมดที่คลัสเตอร์รองรับ พร้อมชื่อย่อ (เช่น `po`, `svc`, `deploy`) |

---

## 4. ลงมือปฏิบัติ (Workshop 1)
ไปทำแบบฝึกหัดจริงบนคลัสเตอร์ของคุณได้ที่: [ws01-cluster-inspection](../../workshops/ws01-cluster-inspection/README.md)

---

## 5. แบบทดสอบท้ายบท (Quiz 1)

**ข้อ 1.** Component ใดของ Control Plane ที่ทำหน้าที่เก็บสถานะทั้งหมดของคลัสเตอร์?
- A. `kube-scheduler`
- B. `etcd`
- C. `kube-proxy`
- D. `kubelet`

**ข้อ 2.** เมื่อสั่ง `kubectl apply -f deploy.yaml` คำสั่งแรกจะถูกส่งไปที่ Component ใด?
- A. `kubelet` บน Worker Node โดยตรง
- B. `kube-apiserver` บน Control Plane
- C. `containerd`
- D. `etcd` โดยตรง

**ข้อ 3.** หาก Pod อยู่ในสถานะ `Pending` (ยังไม่ได้รับการจัดสรรลง Node) น่าจะเกิดจาก Component ใดไม่ทำงาน หรือทรัพยากรไม่พอ?
- A. `kube-scheduler`
- B. `kube-proxy`
- C. `coredns`
- D. `etcd`

**ข้อ 4.** Component ใดบน Worker Node ที่เป็นตัวจัดการกฎเครือข่ายเพื่อให้ NodePort (`30080`) ส่งต่อทราฟฟิกเข้า Pod ได้?
- A. `containerd`
- B. `kube-controller-manager`
- C. `kube-proxy`
- D. `kubelet`

**ข้อ 5.** หากต้องการดู Event ล่าสุดว่าทำไม Pod ถึงสร้างไม่สำเร็จ ควรใช้คำสั่งใด?
- A. `kubectl get pod <name>`
- B. `kubectl describe pod <name>`
- C. `kubectl exec <name> -- events`
- D. `kubectl cluster-info`

**ข้อ 6.** Namespace ใดที่ใช้เก็บระบบหลักของ Kubernetes เช่น `coredns` และ `kube-apiserver`?
- A. `default`
- B. `kube-public`
- C. `kube-system`
- D. `kube-node-lease`

**ข้อ 7.** คำสั่งใดใช้สำหรับเข้าไปเปิด Terminal (`sh`) ภายใน Pod ชื่อ `my-nginx` ที่อยู่ใน Namespace `k8s-lab`?
- A. `kubectl ssh my-nginx -n k8s-lab`
- B. `kubectl logs -it my-nginx -n k8s-lab -- sh`
- C. `kubectl exec -it my-nginx -n k8s-lab -- sh`
- D. `kubectl attach my-nginx --shell`

**ข้อ 8.** ในสถาปัตยกรรม K8s ตัวไหนเป็นคนรัน Container จริงๆ ตามมาตรฐาน CRI ในคลัสเตอร์ Ubuntu 24.04 ของเรา?
- A. `kubelet`
- B. `containerd`
- C. `kube-apiserver`
- D. `nginx`

---

<details>
<summary>คลิกเพื่อดูเฉลย Quiz 1</summary>

1. **B (`etcd`)** — `etcd` เป็น Distributed Key-Value Store ที่เก็บ state ทั้งหมดของคลัสเตอร์
2. **B (`kube-apiserver`)** — ทุกการติดต่อและคำสั่ง `kubectl` ต้องผ่าน API Server เท่านั้น
3. **A (`kube-scheduler`)** — Scheduler มีหน้าที่จับคู่ Pod กับ Node; หาก Node ทรัพยากรไม่พอ หรือ Scheduler หยุดทำงาน Pod จะค้างอยู่ที่ `Pending`
4. **C (`kube-proxy`)** — `kube-proxy` สร้างกฎ iptables/IPVS บนแต่ละ Node เพื่อ route ทราฟฟิกของ Service/NodePort ไปยัง Pod
5. **B (`kubectl describe pod <name>`)** — ส่วนท้ายของ `describe` จะแสดง `Events` ซึ่งบอกสาเหตุที่แท้จริง (เช่น image pull error, scheduling failed)
6. **C (`kube-system`)** — Control Plane static pods และ CoreDNS ทำงานอยู่ใน `kube-system`
7. **C (`kubectl exec -it my-nginx -n k8s-lab -- sh`)** — ใช้ `exec -it` เพื่อรันคำสั่งแบบ interactive ใน Container
8. **B (`containerd`)** — `kubelet` เป็นเพียง agent ที่สั่งการผ่าน CRI ไปยัง Container Runtime ซึ่งใน Lab นี้คือ `containerd`

</details>
