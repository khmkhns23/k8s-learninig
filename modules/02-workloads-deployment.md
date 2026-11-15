# Module 2: Workloads — Pod, ReplicaSet & Deployment

## 1. ลำดับชั้นของ Workload ใน Kubernetes

ใน K8s เรามักไม่สร้าง Pod โดดๆ ในระบบจริง แต่จะให้ **Deployment** เป็นตัวจัดการ:

```text
Deployment (จัดการเวอร์ชัน, Rolling Update, Rollback)
    └── ReplicaSet (คุมจำนวน Pod ให้ครบตาม replicas ที่ตั้งไว้)
            ├── Pod 1 (หน่วยเล็กสุดที่รัน 1 หรือหลาย Container)
            ├── Pod 2
            └── Pod 3
```

### ทำไมไม่สร้าง Pod เปล่าๆ?
- ถ้า Pod เปล่าๆ ตาย หรือ Node ล่ม -> Pod หายไปเลย ไม่ถูกสร้างใหม่
- **ReplicaSet** จะคอยเฝ้าดูผ่าน `selector` (`matchLabels`) ถ้า Pod หายไป 1 ตัว จะสั่งสร้างใหม่ทันที
- **Deployment** ครอบ ReplicaSet อีกชั้น เพื่อรองรับการอัปเดตเวอร์ชันแบบ **Rolling Update** (ทยอยเปลี่ยนทีละตัว ไม่ให้เว็บล่ม) และ **Rollback** ย้อนกลับได้

---

## 2. โครงสร้างไฟล์ YAML มาตรฐาน

ไฟล์ Manifest ของ K8s ทุกไฟล์มี 4 คีย์หลักเสมอ:

```yaml
apiVersion: apps/v1          # 1. เวอร์ชันของ API (Pod/Service ใช้ v1, Deployment ใช้ apps/v1)
kind: Deployment             # 2. ชนิดของ Resource
metadata:                    # 3. ข้อมูลระบุตัวตน (ชื่อ, namespace, labels)
  name: web-app
  labels:
    app: web
spec:                        # 4. สเปกที่ต้องการ (Desired State)
  replicas: 3
  selector:
    matchLabels:
      app: web               # ต้องตรงกับ template.metadata.labels!
  template:                  # แม่พิมพ์ของ Pod ที่จะถูกสร้าง
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
```

> **ข้อควรระวังยอดฮิต:** `spec.selector.matchLabels` ของ Deployment **ต้องตรงกับ** `spec.template.metadata.labels` ของ Pod เสมอ ไม่เช่นนั้น API Server จะปฏิเสธการสร้าง!

---

## 3. การจัดการ Deployment (Scaling, Update, Rollback)

| งานที่ต้องการทำ | คำสั่ง |
| :--- | :--- |
| สร้าง / อัปเดตจากไฟล์ | `kubectl apply -f webapp-deploy.yaml` |
| ปรับจำนวน Pod ทันที | `kubectl scale deployment web-app --replicas=5` |
| อัปเดต Image เวอร์ชันใหม่ | `kubectl set image deployment/web-app nginx=nginx:1.27-alpine` |
| ดูสถานะการ Rolling Update | `kubectl rollout status deployment/web-app` |
| ดูประวัติเวอร์ชันทั้งหมด | `kubectl rollout history deployment/web-app` |
| ย้อนกลับเวอร์ชันก่อนหน้า | `kubectl rollout undo deployment/web-app` |

---

## 4. ลงมือปฏิบัติ (Workshop 2)
ไปทำแบบฝึกหัด Deploy, Scale, Rolling Update และ Rollback ได้ที่: [ws02-deployment-scaling](../../workshops/ws02-deployment-scaling/README.md)

---

## 5. แบบทดสอบท้ายบท (Quiz 2)

**ข้อ 1.** หน่วยประมวลผลที่เล็กที่สุดใน Kubernetes ที่สามารถสร้างและจัดการได้คืออะไร?
- A. Container
- B. Pod
- C. ReplicaSet
- D. Node

**ข้อ 2.** หากคุณสร้าง `Pod` เดี่ยวๆ (`kind: Pod`) โดยไม่ใช้ Deployment แล้ว Pod นั้นเกิด Crash จนลบตัวเอง หรือ Worker Node พัง จะเกิดอะไรขึ้น?
- A. K8s จะสร้าง Pod ใหม่บน Node อื่นให้อัตโนมัติ
- B. Pod นั้นจะหายไปเลย ไม่ถูกสร้างใหม่
- C. `kube-proxy` จะสร้าง Pod ใหม่แทน
- D. Deployment Controller จะเข้ามาดูแลแทน

**ข้อ 3.** Deployment ใช้กลไกใดในการจับคู่ว่า Pod ไหนอยู่ภายใต้การดูแลของตน?
- A. ชื่อของ Pod (`metadata.name`)
- B. IP Address ของ Pod
- C. Labels และ `selector.matchLabels`
- D. ชื่อของ Docker/Container Image

**ข้อ 4.** เมื่อคุณอัปเดต Image ของ Deployment จาก `v1` เป็น `v2` เบื้องหลัง Kubernetes ทำอะไร?
- A. ลบ Deployment เก่าทิ้งแล้วสร้างใหม่ทั้งหมดพร้อมกัน
- B. สร้าง ReplicaSet ใหม่สำหรับ `v2` แล้วค่อยๆ เพิ่ม Pod `v2` พร้อมกับลด Pod `v1` ใน ReplicaSet เดิม
- C. เข้าไปแก้ไฟล์ภายใน Container ที่กำลังรันอยู่
- D. รีบูต Worker Node ทีละเครื่อง

**ข้อ 5.** หากอัปเดตเวอร์ชันใหม่แล้วแอปพัง ต้องการย้อนกลับไปเวอร์ชันก่อนหน้าทันที ควรใช้คำสั่งใด?
- A. `kubectl rollback deployment/<name>`
- B. `kubectl rollout undo deployment/<name>`
- C. `kubectl revert deployment/<name>`
- D. `kubectl delete pod --all`

**ข้อ 6.** `apiVersion` ที่ถูกต้องสำหรับ `kind: Deployment` ใน K8s ปัจจุบันคือข้อใด?
- A. `v1`
- B. `extensions/v1beta1`
- C. `apps/v1`
- D. `batch/v1`

**ข้อ 7.** หากตั้งค่า `replicas: 3` แล้วคุณใช้คำสั่ง `kubectl delete pod <pod-1-name>` ด้วยมือ จะเกิดอะไรขึ้น?
- A. จำนวน Pod จะลดเหลือ 2 ตลอดไป
- B. ReplicaSet จะตรวจพบว่ามี Pod เหลือ 2 ซึ่งน้อยกว่า Desired State (3) จึงสร้าง Pod ใหม่ขึ้นมาทดแทนทันที
- C. Deployment จะเปลี่ยนค่า `replicas` ใน YAML เป็น 2
- D. Pod ทั้ง 3 ตัวจะถูกลบทั้งหมด

**ข้อ 8.** คำสั่งใดใช้สำหรับเพิ่มจำนวน Pod ของ Deployment ชื่อ `api` เป็น 4 ตัวอย่างรวดเร็ว?
- A. `kubectl resize deployment api --count=4`
- B. `kubectl scale deployment api --replicas=4`
- C. `kubectl set replicas deployment/api 4`
- D. `kubectl rollout scale api=4`

---

<details>
<summary>คลิกเพื่อดูเฉลย Quiz 2</summary>

1. **B (`Pod`)** — Pod คือหน่วยเล็กที่สุดที่ K8s สร้างและ Schedule ลง Node (1 Pod ห่อหุ้ม 1 หรือหลาย Container)
2. **B (Pod นั้นจะหายไปเลย ไม่ถูกสร้างใหม่)** — Pod เดี่ยวๆ ไม่มี Controller คอยรักษาจำนวน replicas
3. **C (Labels และ `selector.matchLabels`)** — K8s ใช้ Label Selector ในการเชื่อมโยง Deployment/ReplicaSet/Service เข้ากับ Pod
4. **B (สร้าง ReplicaSet ใหม่สำหรับ `v2`...)** — นี่คือกลไก Rolling Update ที่ทำให้ระบบไม่มี Downtime และเก็บ ReplicaSet เก่าไว้เผื่อ Rollback
5. **B (`kubectl rollout undo deployment/<name>`)** — คำสั่งมาตรฐานสำหรับย้อนกลับ revision ก่อนหน้า
6. **C (`apps/v1`)** — Deployment, ReplicaSet, StatefulSet, DaemonSet อยู่ในกลุ่ม API `apps/v1`
7. **B (ReplicaSet จะสร้าง Pod ใหม่ขึ้นมาทดแทนทันที)** — ตามหลัก Reconciliation Loop ที่พยายามปรับ Actual State ให้ตรงกับ Desired State
8. **B (`kubectl scale deployment api --replicas=4`)** — คำสั่ง scale ใช้ปรับจำนวน replicas แบบ imperative

</details>
