# Workshop 2: Deployment, Scaling, Rolling Update & Rollback

**เป้าหมาย:** ฝึกสร้าง `Deployment` ด้วย YAML, ทดสอบ Self-healing (ลบ Pod แล้วเกิดใหม่เอง), Scale จำนวน Pod, อัปเดตเวอร์ชันแบบ Rolling Update และ Rollback

---

## ขั้นตอนที่ 1: Deploy แอปพลิเคชัน (3 Replicas)
ตรวจสอบให้แน่ใจว่ามี Namespace `k8s-lab` แล้ว (`kubectl create ns k8s-lab` หากยังไม่มี)

```bash
kubectl apply -f webapp-deploy.yaml
```

ตรวจสอบ Deployment, ReplicaSet และ Pods:
```bash
kubectl get deploy,rs,pods -n k8s-lab -o wide
```
**สังเกต:** `READY` ของ Deployment จะขึ้น `3/3` และ Pod จะถูกกระจายลงบน `k8s-worker1` และ `k8s-worker2`

---

## ขั้นตอนที่ 2: ทดสอบ Self-Healing (ReplicaSet รักษาจำนวน Pod)
ลองสุ่มลบ Pod ออกมา 1 ตัว แล้วดูว่าเกิดอะไรขึ้นทันที:
```bash
# ดึงชื่อ Pod ตัวแรกมาลบ
POD_NAME=$(kubectl get pods -n k8s-lab -l app=ws02-web -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME -n k8s-lab

# ดู Pod ทันที
kubectl get pods -n k8s-lab
```
**ผลลัพธ์:** ReplicaSet จะสั่งสร้าง Pod ใหม่ขึ้นมาทดแทนให้ครบ `3/3` ทันที!

---

## ขั้นตอนที่ 3: ทดลอง Scale เพิ่ม-ลด Pod
```bash
# เพิ่มเป็น 5 Replicas
kubectl scale deployment ws02-webapp --replicas=5 -n k8s-lab
kubectl get pods -n k8s-lab -o wide

# ลดกลับมาเหลือ 2 Replicas
kubectl scale deployment ws02-webapp --replicas=2 -n k8s-lab
kubectl get pods -n k8s-lab
```

---

## ขั้นตอนที่ 4: ทดสอบ Rolling Update และ Rollback
1. **อัปเดต Image เป็นเวอร์ชันใหม่ (`nginx:1.27-alpine`):**
```bash
kubectl set image deployment/ws02-webapp nginx=nginx:1.27-alpine -n k8s-lab --record
kubectl rollout status deployment/ws02-webapp -n k8s-lab
```

2. **จำลองการอัปเดตพลาด (ใส่ชื่อ Image ที่ไม่มีอยู่จริง):**
```bash
kubectl set image deployment/ws02-webapp nginx=nginx:wrong-tag-999 -n k8s-lab
kubectl get pods -n k8s-lab
```
**สังเกต:** Pod ใหม่จะติด `ImagePullBackOff` **แต่ Pod เก่ายังคงทำงานอยู่** ทำให้ระบบไม่ล่มทั้งหมด!

3. **สั่ง Rollback ย้อนกลับไปเวอร์ชันที่ใช้งานได้ทันที:**
```bash
kubectl rollout history deployment/ws02-webapp -n k8s-lab
kubectl rollout undo deployment/ws02-webapp -n k8s-lab
kubectl rollout status deployment/ws02-webapp -n k8s-lab
kubectl get pods -n k8s-lab
```

---

## ขั้นตอนที่ 5: Cleanup
```bash
kubectl delete -f webapp-deploy.yaml
```
