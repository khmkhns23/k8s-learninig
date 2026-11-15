# Workshop 4: ConfigMap & Secret

**เป้าหมาย:** ฝึกแยกหน้าเว็บ HTML (`ConfigMap` แบบ Volume Mount) และค่าตัวแปรรหัสผ่าน (`Secret` แบบ Environment Variable) ออกจาก Container Image

---

## ขั้นตอนที่ 1: Deploy ConfigMap, Secret, Pod และ Service (`NodePort 30082`)
```bash
kubectl apply -f config-secret-app.yaml
kubectl get cm,secret,pods,svc -n k8s-lab
```

---

## ขั้นตอนที่ 2: ทดสอบผลลัพธ์
1. **ตรวจสอบหน้าเว็บที่ Mount มาจาก ConfigMap:**
```bash
curl http://192.168.1.11:30082
```
จะเห็นหน้า HTML ที่เรากำหนดเองใน `ConfigMap` (ไม่ใช่หน้า Welcome ปกติของ Nginx!)

2. **ตรวจสอบ Environment Variables ที่ฉีดมาจาก ConfigMap และ Secret:**
```bash
kubectl exec -it ws04-app -n k8s-lab -- env | grep -E "APP_ENV|DB_USER|DB_PASS"
```
**สังเกต:** ถึงแม้ใน YAML ของ Secret เราจะใช้ `stringData` (หรือ Base64) เมื่อเข้าไปอยู่ใน Container แล้ว แอปพลิเคชันจะอ่านได้เป็น Plain text พร้อมใช้งานทันที

---

## ขั้นตอนที่ 3: ทดลองแก้ ConfigMap แบบ Live (ไม่ต้อง Rebuild Image!)
ลองแก้ไขข้อความใน `config-secret-app.yaml` ตรงส่วน `index.html` เช่น เปลี่ยนจาก `Version 1` เป็น `Version 2 (Updated via ConfigMap)` แล้วรัน:
```bash
kubectl apply -f config-secret-app.yaml
```
รอประมาณ 30-60 วินาที (Kubelet Sync Loop) แล้วลองยิงใหม่:
```bash
curl http://192.168.1.11:30082
```
จะเห็นเนื้อหาเว็บเปลี่ยนเป็น Version 2 โดยที่ Pod ไม่ต้อง Restart เลย!

---

## ขั้นตอนที่ 4: Cleanup
```bash
kubectl delete -f config-secret-app.yaml
```
