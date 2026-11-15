# Workshop 5: Persistent Storage (PV & PVC)

**เป้าหมาย:** สร้าง `PersistentVolume (PV)` และ `PersistentVolumeClaim (PVC)` แล้วพิสูจน์ว่าเมื่อลบ Pod ทิ้งและสร้างใหม่ ข้อมูลที่เขียนลง Volume ยังอยู่ครบ

> **หมายเหตุสำคัญ:** ใน Lab นี้เราใช้ `hostPath` บนเครื่อง `k8s-worker1` จึงใส่ `nodeSelector: kubernetes.io/hostname: k8s-worker1` ไว้ที่ Pod เพื่อให้ Pod กลับมาลง Node เดิมที่มีไฟล์อยู่เสมอ (ในระบบ Production จริงจะใช้ Shared Storage เช่น NFS หรือ Cloud EBS แทน)

---

## ขั้นตอนที่ 1: สร้าง PV, PVC และ Deployment
```bash
kubectl apply -f pv-pvc-app.yaml
```

ตรวจสอบสถานะ PV และ PVC (ต้องขึ้น **`Bound`**):
```bash
kubectl get pv,pvc,pods -n k8s-lab
```

---

## ขั้นตอนที่ 2: เขียนข้อมูลลงใน Volume ที่ Mount ไว้ (`/data`)
```bash
# หาชื่อ Pod
POD=$(kubectl get pod -n k8s-lab -l app=ws05-storage -o jsonpath='{.items[0].metadata.name}')

# เขียนไฟล์ทดสอบลง /data
kubectl exec -it $POD -n k8s-lab -- sh -c 'echo "Important Data saved at $(date)" > /data/record.txt'

# อ่านไฟล์ยืนยัน
kubectl exec -it $POD -n k8s-lab -- cat /data/record.txt
```

---

## ขั้นตอนที่ 3: ลบ Pod ทิ้ง แล้วพิสูจน์ว่าข้อมูลไม่หาย
```bash
# ลบ Pod ตัวเดิมทิ้ง
kubectl delete pod $POD -n k8s-lab

# รอให้ Deployment สร้าง Pod ใหม่ขึ้นมาแทน
kubectl get pods -n k8s-lab -w
# (กด Ctrl+C เมื่อ Pod ใหม่ขึ้น Running 1/1)

# หาชื่อ Pod ใหม่ (ชื่อจะเปลี่ยนไป!)
NEW_POD=$(kubectl get pod -n k8s-lab -l app=ws05-storage -o jsonpath='{.items[0].metadata.name}')
echo "New Pod: $NEW_POD"

# ลองอ่านไฟล์เดิมจาก Pod ใหม่
kubectl exec -it $NEW_POD -n k8s-lab -- cat /data/record.txt
```
**ผลลัพธ์:** ข้อความ `"Important Data saved at ..."` ยังอยู่ครบถ้วน แม้จะเป็น Pod ตัวใหม่!

---

## ขั้นตอนที่ 4: Cleanup (ลบตามลำดับ: Deployment/Pod -> PVC -> PV)
```bash
kubectl delete -f pv-pvc-app.yaml
```
*(หากต้องการลบไฟล์ทดสอบบนเครื่อง `k8s-worker1` ด้วย ให้รัน `sudo rm -rf /mnt/ws05-data` บนเครื่อง `k8s-worker1`)*
