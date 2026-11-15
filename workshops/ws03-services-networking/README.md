# Workshop 3: Services, CoreDNS & Multi-Tier Networking

**เป้าหมาย:** สร้างระบบจำลอง 2-Tier (Frontend + Backend) ที่สื่อสารกันภายในผ่าน `ClusterIP` (CoreDNS) และเปิดให้เข้าถึงจากภายนอกผ่าน `NodePort` (`30081`)

---

## ขั้นตอนที่ 1: Deploy ระบบ 2-Tier
```bash
kubectl apply -f two-tier-app.yaml
```

ตรวจสอบ Pod, Service และ Endpoints:
```bash
kubectl get pods,svc,endpoints -n k8s-lab -o wide
```
**จุดสังเกต:**
- `backend-svc` เป็นแบบ `ClusterIP` (ไม่มี NodePort — เข้าจากนอกคลัสเตอร์ไม่ได้)
- `frontend-svc` เป็นแบบ `NodePort` ที่พอร์ต `30081`
- ใน `endpoints` ของทั้งสอง Service ต้องมี IP ของ Pod แสดงอยู่ (ไม่เป็น `<none>`)

---

## ขั้นตอนที่ 2: ทดสอบการสื่อสารภายในผ่าน CoreDNS
เข้าไปใน Pod ของ `frontend` แล้วลองเรียก `backend-svc` ด้วยชื่อ DNS:

```bash
FRONTEND_POD=$(kubectl get pod -n k8s-lab -l app=ws03-frontend -o jsonpath='{.items[0].metadata.name}')

# 1. ทดสอบแปลงชื่อ DNS ของ backend-svc
kubectl exec -it $FRONTEND_POD -n k8s-lab -- nslookup backend-svc

# 2. ทดสอบเรียก HTTP ไปยัง backend-svc ผ่านชื่อ DNS (แทน IP)
kubectl exec -it $FRONTEND_POD -n k8s-lab -- wget -qO- http://backend-svc
```
**ผลลัพธ์:** จะได้หน้าเว็บ `Welcome to nginx!` จาก Backend ตอบกลับมา โดยที่เราไม่ต้องรู้ IP ของ Backend Pod เลย

---

## ขั้นตอนที่ 3: ทดสอบเข้าถึง Frontend จากภายนอกผ่าน `NodePort` (`30081`)
รันจาก `k8s-control` หรือ Windows PowerShell:
```bash
# ยิงเข้า Worker 1
curl http://192.168.1.11:30081

# ยิงเข้า Worker 2
curl http://192.168.1.12:30081
```
*(สังเกตว่าไม่ว่าจะยิงเข้า `.11` หรือ `.12` ก็เข้าถึง Frontend Pod ได้เหมือนกัน เพราะ `kube-proxy` เปิด NodePort `30081` ไว้บนทุก Node)*

---

## ขั้นตอนที่ 4: Cleanup
```bash
kubectl delete -f two-tier-app.yaml
```
