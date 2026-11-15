# Module 3: Networking, Services & External Load Balancing

## 1. ทำไมต้องมี Service?

ใน Kubernetes **IP ของ Pod ไม่ถาวร (Ephemeral)** ทุกครั้งที่ Pod ตายแล้วเกิดใหม่ หรือถูก Scale จะได้ IP ใหม่เสมอ ทำให้แอปหนึ่งไม่สามารถเรียกอีกแอปด้วย Pod IP ตรงๆ ได้

**Service** จึงทำหน้าที่เป็น **IP ถาวร + DNS Name + Internal Load Balancer** คอยรับทราฟฟิกแล้วกระจายไปยัง Pod ที่มี Label ตรงกัน (ดูรายชื่อ Pod ปลายทางได้จาก `Endpoints`)

---

## 2. ประเภทของ Service (Service Types)

| ประเภท | เข้าถึงได้จากที่ไหน | การทำงาน |
| :--- | :--- | :--- |
| **`ClusterIP`** *(ค่าเริ่มต้น)* | ภายในคลัสเตอร์เท่านั้น | สร้าง Virtual IP ภายใน เช่น `10.96.x.x` และชื่อ DNS เพื่อให้ Pod คุยกันเอง (เช่น Frontend -> Backend/DB) |
| **`NodePort`** | ภายนอกคลัสเตอร์ได้ | เปิดพอร์ตช่วง `30000-32767` บน **ทุก Node** (ทั้ง Control และ Worker) แล้วส่งต่อเข้า `ClusterIP` -> `Pod` |
| **`LoadBalancer`** | ภายนอกคลัสเตอร์ได้ | บน Cloud (AWS/GCP) จะสร้าง Cloud LB ให้อัตโนมัติ แต่บน On-Premise (VMware ของเรา) เราใช้ **External Nginx LB (`192.168.1.20`)** ยิงเข้า `NodePort` แทน |

---

## 3. เส้นทางทราฟฟิกใน Lab ของคุณ

```text
[Browser / Client: 192.168.1.1]
         |  HTTP Port 80
         v
[External LB (k8s-lb): 192.168.1.20]  <-- Nginx Proxy Pass (Round-Robin)
         |  HTTP Port 30080 (NodePort)
         +-----------------------------+
         v                             v
[Worker1: 192.168.1.11:30080]   [Worker2: 192.168.1.12:30080]
         |                             |  kube-proxy (iptables)
         +--------------+--------------+
                        v
            [K8s Service (ClusterIP)]
                        |
          +-------------+-------------+
          v             v             v
       [Pod 1]       [Pod 2]       [Pod 3]
```

### พอร์ต 3 ตัวใน Service YAML (อย่าสับสน!)
```yaml
ports:
  - port: 80          # พอร์ตของตัว Service เอง (ClusterIP:80)
    targetPort: 8080  # พอร์ตที่แอปกำลังฟังอยู่จริงใน Container
    nodePort: 30081   # พอร์ตที่เปิดบน IP ของเครื่อง Node (30000-32767)
```

---

## 4. Internal DNS (CoreDNS)

เมื่อคุณสร้าง Service ชื่อ `backend-svc` ใน Namespace `k8s-lab` Pod อื่นๆ สามารถเรียกใช้ผ่านชื่อ DNS ได้เลย:
- **ใน Namespace เดียวกัน:** `http://backend-svc`
- **ข้าม Namespace:** `http://backend-svc.k8s-lab.svc.cluster.local`

---

## 5. ลงมือปฏิบัติ (Workshop 3)
ไปสร้างระบบ 2-Tier (Frontend คุยกับ Backend ผ่าน DNS `ClusterIP` และออกสู่ภายนอกผ่าน `NodePort`) ได้ที่: [ws03-services-networking](../../workshops/ws03-services-networking/README.md)

---

## 6. แบบทดสอบท้ายบท (Quiz 3)

**ข้อ 1.** เหตุใดจึงไม่ควรให้ Frontend Pod เรียกใช้ Backend Pod ผ่าน Pod IP โดยตรง?
- A. Pod IP มีความเร็วช้ากว่า Service IP
- B. Pod IP เปลี่ยนแปลงได้เสมอเมื่อ Pod ถูกสร้างใหม่หรือย้าย Node
- C. Pod ในคนละ Node ไม่สามารถ ping Pod IP หากันได้
- D. Pod IP ใช้ได้เฉพาะพอร์ต 80 เท่านั้น

**ข้อ 2.** Service ประเภทใดเหมาะที่สุดสำหรับฐานข้อมูล (Database) ที่ต้องการให้เฉพาะ Backend Pod ภายในคลัสเตอร์เรียกใช้ ห้ามเข้าถึงจากอินเทอร์เน็ต?
- A. `NodePort`
- B. `LoadBalancer`
- C. `ClusterIP`
- D. `ExternalName`

**ข้อ 3.** ช่วงพอร์ตมาตรฐานสำหรับ `NodePort` ใน Kubernetes คือช่วงใด?
- A. `80 - 443`
- B. `1024 - 9999`
- C. `30000 - 32767`
- D. `49152 - 65535`

**ข้อ 4.** ใน Service YAML หาก Container รันเว็บแอปที่พอร์ต `8080` แต่ต้องการให้ Service รับทราฟฟิกที่พอร์ต `80` ค่าใดต้องตั้งเป็น `8080`?
- A. `port`
- B. `targetPort`
- C. `nodePort`
- D. `hostPort`

**ข้อ 5.** หาก Service มีค่า `Endpoints: <none>` (ว่างเปล่า) ทั้งที่มี Pod รันอยู่ สาเหตุที่พบบ่อยที่สุดคืออะไร?
- A. Worker Node แรมเต็ม
- B. `spec.selector` ของ Service ไม่ตรงกับ `metadata.labels` ของ Pod
- C. External Nginx LB ปิดอยู่
- D. CoreDNS ยังไม่ทำงาน

**ข้อ 6.** Pod ชื่อ `frontend` อยู่ใน Namespace `app-a` ต้องการเรียก Service ชื่อ `db-svc` ที่อยู่ใน Namespace `app-b` ต้องเรียกชื่อ DNS เต็มว่าอย่างไร?
- A. `db-svc`
- B. `db-svc.app-a`
- C. `db-svc.app-b.svc.cluster.local`
- D. `app-b.db-svc.cluster.local`

**ข้อ 7.** เมื่อใช้คำสั่ง `kubectl get endpoints <service-name>` ข้อมูลที่แสดงคืออะไร?
- A. รายชื่อ URL ภายนอกทั้งหมด
- B. รายการ IP และพอร์ตของ **Pod จริงๆ** ที่ Service กำลังส่งทราฟฟิกไปให้
- C. รายชื่อ Worker Node ทั้งหมดในคลัสเตอร์
- D. Log การเชื่อมต่อของ `kube-proxy`

**ข้อ 8.** ใน Lab ของเรา External Nginx (`192.168.1.20`) ส่งทราฟฟิกไปที่ `192.168.1.11:30080` แม้ว่าตอนนั้น Pod ทั้ง 3 ตัวจะบังเอิญรันอยู่บน `192.168.1.12` ทั้งหมด ทราฟฟิกจะยังไปถึง Pod ได้หรือไม่?
- A. ไม่ได้ จะเกิด Error 404 ทันที
- B. ได้ เพราะ `kube-proxy` บน Node1 (`192.168.1.11`) จะส่งต่อทราฟฟิกข้าม Node ไปหา Pod บน Node2 ให้เอง
- C. ไม่ได้ ต้องเปิด NodePort เฉพาะ Node ที่มี Pod เท่านั้น
- D. ได้เฉพาะเมื่อใช้ `ClusterIP` เป็น `None`

---

<details>
<summary>คลิกเพื่อดูเฉลย Quiz 3</summary>

1. **B (Pod IP เปลี่ยนแปลงได้เสมอ...)** — Service ช่วยให้มี Virtual IP และ DNS ที่คงที่แม้ Pod ข้างหลังจะเปลี่ยนไปเรื่อยๆ
2. **C (`ClusterIP`)** — เป็นค่าเริ่มต้นและเปิดให้เข้าถึงได้เฉพาะภายในคลัสเตอร์เท่านั้น ปลอดภัยที่สุดสำหรับ DB/Internal API
3. **C (`30000 - 32767`)** — เป็นช่วงพอร์ตมาตรฐานที่ K8s API Server อนุญาตให้ใช้สำหรับ NodePort
4. **B (`targetPort`)** — `port` คือพอร์ตขาเข้าของ Service ส่วน `targetPort` คือพอร์ตปลายทางภายใน Container
5. **B (`spec.selector` ไม่ตรงกับ `labels` ของ Pod)** — Service ค้นหา Pod ปลายทางผ่าน Label Selector เท่านั้น หากสะกดผิดแม้แต่ตัวเดียว Endpoints จะว่าง
6. **C (`db-svc.app-b.svc.cluster.local`)** — รูปแบบ FQDN ของ CoreDNS คือ `<service>.<namespace>.svc.cluster.local`
7. **B (รายการ IP และพอร์ตของ Pod จริงๆ)** — ใช้ตรวจสอบได้ดีที่สุดว่า Service มองเห็น Pod ครบหรือไม่
8. **B (ได้)** — NodePort เปิดบน **ทุก Node** และ `kube-proxy` จะ route ทราฟฟิกข้าม Node ผ่าน CNI (Flannel) ไปหา Pod ปลายทางให้เอง

</details>
