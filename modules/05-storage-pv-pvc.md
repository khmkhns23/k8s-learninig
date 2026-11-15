# Module 5: Storage & Persistence — Volume, PV & PVC

## 1. ปัญหาของ Container Storage แบบปกติ

โดยปกติไฟล์ที่ถูกสร้างขึ้นใน Container (เช่น ไฟล์อัปโหลด, ข้อมูลฐานข้อมูล, Log) เป็นแบบ **Ephemeral (ชั่วคราว)** หาก Container พัง หรือ Pod ถูกลบแล้วสร้างใหม่ **ข้อมูลทั้งหมดจะหายไปทันที**

Kubernetes แก้ปัญหานี้ด้วยระบบ **Volumes** และ **Persistent Storage**

---

## 2. ประเภทของ Volume พื้นฐาน

| ประเภท | อายุของข้อมูล | การใช้งาน |
| :--- | :--- | :--- |
| **`emptyDir`** | อยู่เท่าอายุของ **Pod** (ถ้ารีสตาร์ท Container ใน Pod เดิมข้อมูลยังอยู่ แต่ถ้าลบ Pod ข้อมูลหาย) | ใช้แชร์ไฟล์ระหว่าง Container ใน Pod เดียวกัน หรือทำ Cache ชั่วคราว |
| **`hostPath`** | เก็บบน Disk ของ **Worker Node** เครื่องนั้นๆ | ใช้ใน Lab หรือ DaemonSet ที่ต้องเข้าถึงไฟล์บน Host (ข้อเสีย: ถ้า Pod ย้ายไปอีก Node ข้อมูลจะไม่ตามไปด้วย) |
| **`PV` + `PVC`** | แยกอายุออกจาก Pod โดยสิ้นเชิง (ลบ Pod ข้อมูลยังอยู่) | มาตรฐานสำหรับระบบ Production เช่น Database, File Server |

---

## 3. สถาปัตยกรรม PersistentVolume (PV) และ PersistentVolumeClaim (PVC)

K8s แยกหน้าที่ออกเป็น 2 ส่วน เพื่อให้นักพัฒนาไม่ต้องรู้รายละเอียดของ Hardware Storage:

```text
[Admin / StorageClass] ---> สร้าง PersistentVolume (PV) : ก้อนพื้นที่จริง (เช่น 1Gi บน NFS/Disk)
                                  ^
                                  |  (Bound จับคู่กัน)
                                  |
[Developer] --------------> สร้าง PersistentVolumeClaim (PVC) : ใบขอเบิกพื้นที่ (เช่น ขอ 500Mi, ReadWriteOnce)
                                  ^
                                  |  (อ้างอิงใน volumes)
                                  |
[Pod] --------------------> mount PVC เข้าไปใช้งานที่ /data
```

### Access Modes ที่พบบ่อย
- **`ReadWriteOnce` (`RWO`)**: อ่าน-เขียนได้จาก **Node เดียว** ในเวลาเดียวกัน (นิยมใช้กับ Disk/Block Storage)
- **`ReadOnlyMany` (`ROX`)**: อ่านได้อย่างเดียวจากหลาย Node
- **`ReadWriteMany` (`RWX`)**: อ่าน-เขียนพร้อมกันได้จาก **หลาย Node** (เช่น NFS, CephFS)

### Reclaim Policy (เมื่อลบ PVC จะเกิดอะไรกับ PV?)
- **`Retain`**: เก็บข้อมูลและ PV ไว้ (ต้องเคลียร์เอง)
- **`Delete`**: ลบ PV และข้อมูลทิ้งทันที

---

## 4. ลงมือปฏิบัติ (Workshop 5)
ไปสร้าง PV/PVC และทดสอบเขียนข้อมูลลง Storage แล้วลบ Pod ทิ้งเพื่อพิสูจน์ว่าข้อมูลไม่หาย ได้ที่: [ws05-persistent-storage](../../workshops/ws05-persistent-storage/README.md)

---

## 5. แบบทดสอบท้ายบท (Quiz 5)

**ข้อ 1.** หากต้องการแชร์ไฟล์ชั่วคราวระหว่าง 2 Container ที่อยู่ภายใน **Pod เดียวกัน** โดยไม่สนใจว่าข้อมูลจะหายเมื่อ Pod ถูกลบ ควรใช้ Volume ชนิดใด?
- A. `PersistentVolumeClaim`
- B. `emptyDir`
- C. `ConfigMap`
- D. `Secret`

**ข้อ 2.** ข้อใดอธิบายความแตกต่างระหว่าง `PV` และ `PVC` ได้ถูกต้องที่สุด?
- A. `PV` ใช้กับ Nginx ส่วน `PVC` ใช้กับ Database
- B. `PV` คือทรัพยากรพื้นที่จัดเก็บจริงในคลัสเตอร์ ส่วน `PVC` คือคำร้องขอเบิกพื้นที่จากผู้ใช้/Pod
- C. `PV` เป็นพื้นที่ชั่วคราว ส่วน `PVC` เป็นพื้นที่ถาวร
- D. ไม่มีข้อแตกต่าง ใช้แทนกันได้

**ข้อ 3.** หากคุณสร้าง `PVC` ขนาด `5Gi` แต่ในคลัสเตอร์มี `PV` ว่างอยู่เพียงก้อนเดียวขนาด `2Gi` สถานะของ `PVC` จะเป็นอย่างไร?
- A. `Bound` (ใช้งานได้แค่ 2Gi)
- B. `Pending` (รอจนกว่าจะมี PV ที่ใหญ่พอ >= 5Gi)
- C. `Error`
- D. `Terminating`

**ข้อ 4.** Access Mode ใดที่อนุญาตให้หลาย Pod บน **คนละ Worker Node** สามารถ Mount เพื่ออ่านและเขียนพร้อมกันได้?
- A. `ReadWriteOnce` (`RWO`)
- B. `ReadOnlyMany` (`ROX`)
- C. `ReadWriteMany` (`RWX`)
- D. `ReadWritePod` (`RWP`)

**ข้อ 5.** ในคลัสเตอร์ Lab (VMware 2 Worker Nodes) หากใช้ `PV` แบบ `hostPath` ที่ชี้ไปยัง `/mnt/data` บน `k8s-worker1` ต่อมา Pod ถูกลบแล้ว Scheduler ส่ง Pod ใหม่ไปรันที่ `k8s-worker2` จะเกิดอะไรขึ้น?
- A. ข้อมูลจาก `worker1` จะถูกคัดลอกไป `worker2` อัตโนมัติ
- B. Pod บน `worker2` จะไม่เห็นไฟล์เดิมที่เคยเขียนไว้บน `worker1`
- C. K8s จะปฏิเสธการสร้าง Pod
- D. ระบบจะรวม Disk ของทั้ง 2 เครื่องเข้าด้วยกัน

**ข้อ 6.** ใน `Pod` YAML เราต้องระบุอะไรในส่วน `spec.volumes` เพื่อเชื่อมกับพื้นที่แบบ Persistent?
- A. ระบุชื่อของ `PersistentVolume` (`pv-name`) โดยตรง
- B. ระบุชื่อของ `PersistentVolumeClaim` (`persistentVolumeClaim.claimName`)
- C. ระบุ IP ของ Storage Server โดยตรง
- D. ระบุ `StorageClass`

**ข้อ 7.** เมื่อไม่ใช้งานแล้ว หากต้องการลบทั้ง Pod และข้อมููลที่ค้างอยู่ ควรลบตามลำดับใดเพื่อไม่ให้ PVC ค้างสถานะ `Terminating`?
- A. ลบ `PV` ก่อน แล้วค่อยลบ `PVC` และ `Pod`
- B. ลบ `Pod` ก่อน -> ลบ `PVC` -> ลบ `PV`
- C. ลบ `PVC` ก่อน แล้ว Pod จะถูกลบตามเอง
- D. ลบ `Namespace` ทิ้งทันทีทุกครั้ง

**ข้อ 8.** `StorageClass` มีหน้าที่หลักอะไรในระบบ Production?
- A. บีบอัดไฟล์ใน Pod ให้เล็กลง
- B. ทำ **Dynamic Provisioning** (สร้าง `PV` ให้อัตโนมัติเมื่อมีคนสร้าง `PVC` โดย Admin ไม่ต้องสร้าง PV รอไว้)
- C. สำรองข้อมูลเข้า GitHub
- D. จำกัดความเร็วอินเทอร์เน็ตของ Pod

---

<details>
<summary>คลิกเพื่อดูเฉลย Quiz 5</summary>

1. **B (`emptyDir`)** — `emptyDir` สร้างโฟลเดอร์ว่างผูกกับอายุของ Pod เหมาะสำหรับแชร์ไฟล์ระหว่าง container ใน Pod เดียวกัน
2. **B (`PV` คือพื้นที่จริง, `PVC` คือใบคำขอเบิก)** — แนวคิดเดียวกับ Node (ทรัพยากรจริง) กับ Pod (ผู้ขอใช้)
3. **B (`Pending`)** — PVC จะจับคู่ (`Bound`) ได้ก็ต่อเมื่อมี PV ที่มีขนาด **มากกว่าหรือเท่ากับ** ที่ขอ และ AccessMode/StorageClass ตรงกัน
4. **C (`ReadWriteMany` / `RWX`)** — `RWO` จำกัดเฉพาะ 1 Node, `ROX` อ่านอย่างเดียว, ส่วน `RWX` เขียนพร้อมกันได้หลาย Node
5. **B (ไม่เห็นไฟล์เดิม)** — `hostPath` ผูกติดกับ Local Disk ของเครื่อง Node นั้นๆ ไม่ได้แชร์ข้ามเครือข่าย (จึงเหมาะกับ Single-Node Lab หรือใช้ `nodeSelector` ล็อก Node ไว้)
6. **B (`persistentVolumeClaim.claimName`)** — Pod เชื่อมต่อผ่าน `PVC` เสมอ ไม่ได้ชี้ไปที่ `PV` โดยตรง
7. **B (ลบ `Pod` -> `PVC` -> `PV`)** — K8s มีระบบป้องกัน (`storage-protection` finalizer) จะไม่ยอมให้ลบ PVC/PV ที่ยังมี Pod ใช้งานอยู่
8. **B (Dynamic Provisioning)** — ช่วยสร้าง PV ให้อัตโนมัติบน Cloud หรือ Storage Provider (เช่น CSI Driver) ทันทีที่มี PVC เข้ามา

</details>
