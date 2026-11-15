# Module 4: Configuration — ConfigMap & Secret

## 1. แนวคิด: แยก Config ออกจาก Container Image

ในการพัฒนาแอปสมัยใหม่ (12-Factor App) เราไม่ควรใส่ค่า Config (เช่น URL ของฐานข้อมูล, ไฟล์ `nginx.conf`, หน้า HTML) หรือข้อมูลลับ (Password, API Token) ฝังตายตัวใน Docker Image เพราะจะทำให้ต้อง Build Image ใหม่ทุกครั้งที่เปลี่ยน environment (Dev / Staging / Prod)

Kubernetes จึงมี 2 Resource สำหรับจัดการเรื่องนี้:
1. **`ConfigMap`**: เก็บค่า Config ทั่วไปที่ไม่เป็นความลับ (Plain text)
2. **`Secret`**: เก็บข้อมูลสำคัญ/รหัสผ่าน (เก็บแบบ Base64 encoded ใน YAML และสามารถจำกัดสิทธิ์การเข้าถึงได้)

---

## 2. วิธีการนำ ConfigMap / Secret ไปใช้ใน Pod

มี 2 วิธีหลัก:

### วิธีที่ 1: ส่งผ่าน Environment Variables (`env` หรือ `envFrom`)
```yaml
env:
  - name: APP_ENV
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: ENVIRONMENT
  - name: DB_PASS
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: PASSWORD
```
*(หรือใช้ `envFrom` เพื่อดึงทุก Key ใน ConfigMap/Secret เข้ามาเป็น Env ทั้งก้อน)*

### วิธีที่ 2: แปะเป็นไฟล์ผ่าน Volume Mount (`volumes` + `volumeMounts`)
เหมาะสำหรับไฟล์ขนาดใหญ่หรือไฟล์ตั้งค่า เช่น `nginx.conf`, `index.html`, `application.properties`
- **ข้อดีพิเศษ:** หากแก้ไข ConfigMap แล้วสั่ง `kubectl apply` ไฟล์ที่ Mount ไว้ใน Pod จะอัปเดตตามอัตโนมัติ (ภายใน ~1 นาที) โดยไม่ต้องลบ Pod (แต่สำหรับแอปเช่น Nginx อาจต้อง reload service)

---

## 3. ข้อควรรู้เรื่อง Secret (Base64 ไม่ใช่การเข้ารหัสที่ปลอดภัย!)
- ใน YAML ของ `Secret` ค่าในช่อง `data:` ต้องเข้ารหัสเป็น **Base64** (เช่น `echo -n "mysecret" | base64` -> `bXlzZWNyZXQ=`)
- หรือใช้คีย์ `stringData:` แทน `data:` เพื่อให้พิมพ์ข้อความปกติได้เลย แล้ว K8s จะแปลงเป็น Base64 ให้เอง
- **หมายเหตุ:** Base64 สามารถถอดกลับได้ง่ายๆ ด้วย `base64 -d` จึงควรใช้ร่วมกับ **RBAC** และ **Encryption at Rest** ในระบบ Production

---

## 4. ลงมือปฏิบัติ (Workshop 4)
ไปฝึกสร้าง ConfigMap (หน้าเว็บ + Nginx config) และ Secret (รหัสผ่าน) เพื่อฉีดเข้าไปใน Pod ได้ที่: [ws04-configmap-secret](../../workshops/ws04-configmap-secret/README.md)

---

## 5. แบบทดสอบท้ายบท (Quiz 4)

**ข้อ 1.** Resource ใดใน Kubernetes เหมาะสำหรับเก็บค่า `LOG_LEVEL=debug` หรือไฟล์ `nginx.conf`?
- A. `Secret`
- B. `ConfigMap`
- C. `PersistentVolume`
- D. `Ingress`

**ข้อ 2.** หากใช้คีย์ `data:` ในไฟล์ YAML ของ `kind: Secret` ค่าที่ใส่ลงไปต้องอยู่ในรูปแบบใด?
- A. Plain text ธรรมดา
- B. MD5 Hash
- C. Base64 Encoded
- D. SHA-256

**ข้อ 3.** หากไม่อยากแปลงข้อความเป็น Base64 เองในไฟล์ YAML ของ Secret สามารถใช้คีย์ใดแทน `data:` ได้?
- A. `plainData:`
- B. `stringData:`
- C. `rawData:`
- D. `textData:`

**ข้อ 4.** วิธีใดที่ช่วยให้สามารถส่งไฟล์คอนฟิกหลายบรรทัด (เช่น `default.conf`) เข้าไปให้ Container ใช้งานที่ path `/etc/nginx/conf.d/` ได้?
- A. ส่งผ่าน `envFrom`
- B. Mount `ConfigMap` เป็น `Volume` เข้าไปที่ `volumeMounts`
- C. ใส่ใน `metadata.annotations`
- D. ใช้คำสั่ง `kubectl cp` ทุกครั้งที่ Pod เกิดใหม่

**ข้อ 5.** ข้อความใดถูกต้องเกี่ยวกับการอัปเดต `ConfigMap` ที่ถูกใช้งานอยู่?
- A. หากใช้งานแบบ **Environment Variable** ค่าใน Pod ที่รันอยู่จะเปลี่ยนทันทีโดยอัตโนมัติ
- B. หากใช้งานแบบ **Environment Variable** ต้อง Restart/Recreate Pod ใหม่ ค่า Env จึงจะเปลี่ยน
- C. ConfigMap ไม่สามารถแก้ไขได้หลังสร้างแล้ว
- D. ต้องลบ Cluster แล้วสร้างใหม่

**ข้อ 6.** คำสั่งแบบ Imperative ใดใช้สร้าง Secret ชื่อ `my-pass` ที่มี key `password=1234` ได้ถูกต้อง?
- A. `kubectl create secret my-pass --from=password=1234`
- B. `kubectl create secret generic my-pass --from-literal=password=1234`
- C. `kubectl apply secret my-pass password=1234`
- D. `kubectl create configmap my-pass --secret=1234`

**ข้อ 7.** หาก Pod Mount ConfigMap ที่ `/usr/share/nginx/html` โดยใน ConfigMap มีเฉพาะไฟล์ `index.html` จะเกิดอะไรขึ้นกับไฟล์อื่นๆ ที่เคยอยู่ในโฟลเดอร์ `/usr/share/nginx/html` ของ Image เดิม?
- A. ไฟล์เดิมจะยังอยู่ครบ และเพิ่ม `index.html` เข้าไป
- B. โฟลเดอร์ `/usr/share/nginx/html` จะถูกทับ (Shadowed) ด้วยไฟล์จาก ConfigMap เท่านั้น (เว้นแต่ใช้ `subPath`)
- C. Pod จะเกิด Error `CrashLoopBackOff`
- D. ไฟล์จาก ConfigMap จะถูกลบทิ้ง

**ข้อ 8.** เหตุใดจึงไม่ควรนำ Password ไปเก็บไว้ใน `ConfigMap`?
- A. ConfigMap เก็บได้เฉพาะตัวเลข
- B. ConfigMap ถูกออกแบบให้เป็น Plain text และมักถูกเปิดสิทธิ์ให้อ่านได้กว้างกว่า Secret รวมถึงไม่รองรับ Secret Encryption
- C. ConfigMap มีขนาดจำกัดแค่ 100 Bytes
- D. Pod ไม่สามารถอ่าน ConfigMap เป็น Env ได้

---

<details>
<summary>คลิกเพื่อดูเฉลย Quiz 4</summary>

1. **B (`ConfigMap`)** — ข้อมูลทั่วไปที่ไม่ใช่ความลับให้เก็บใน ConfigMap
2. **C (Base64 Encoded)** — ช่อง `data:` ใน Secret บังคับเป็น Base64
3. **B (`stringData:`)** — `stringData` รับข้อความ plain text และ K8s จะแปลงเป็น Base64 เก็บใน `data` ให้อัตโนมัติ
4. **B (Mount `ConfigMap` เป็น `Volume`)** — Volume Mount ใช้สำหรับจำลอง Key-Value ให้กลายเป็นไฟล์ในระบบไฟล์ของ Container
5. **B (ต้อง Restart/Recreate Pod ใหม่)** — Env ถูกฉีดเข้า process ตอน Container เริ่มทำงานเท่านั้น ไม่เปลี่ยนกลางคัน (ต่างจาก Volume Mount ที่ซิงค์ไฟล์อัปเดตได้)
6. **B (`kubectl create secret generic my-pass --from-literal=password=1234`)** — `generic` คือ Opaque Secret ทั่วไป
7. **B (ถูกทับ / Shadowed)** — การ mount volume ทับ directory จะซ่อนไฟล์เดิมใน image ไว้ หากต้องการแทรกไฟล์เดียวโดยไม่ทับทั้งโฟลเดอร์ให้ใช้ `subPath`
8. **B (Plain text และไม่รองรับ Secret Encryption/สิทธิ์เฉพาะ)** — การแยก Secret ช่วยให้บริหารจัดการ RBAC (สิทธิ์การอ่าน secret) แยกจาก config ทั่วไปได้

</details>
