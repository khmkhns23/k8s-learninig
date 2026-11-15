# Workshop 1: Cluster Inspection & `kubectl` Basics

**เป้าหมาย:** ฝึกใช้คำสั่งพื้นฐาน `kubectl` เพื่อสำรวจสุขภาพของคลัสเตอร์ 3 Nodes (`192.168.1.10-12`) และรู้จัก System Pods ใน `kube-system`

> รันคำสั่งทั้งหมดในบทนี้บนเครื่อง **`k8s-control`** (`192.168.1.10`)

---

## ขั้นตอนที่ 1: ตรวจสอบ Nodes และข้อมูลคลัสเตอร์
```bash
# 1. ดูภาพรวม API Server และ CoreDNS
kubectl cluster-info

# 2. ดูสถานะ Node ทั้ง 3 เครื่อง พร้อม IP และเวอร์ชัน K8s
kubectl get nodes -o wide
```
**จุดสังเกต:** ทุก Node ต้องมีสถานะ `Ready` และมี `INTERNAL-IP` เป็น `.10`, `.11`, `.12` ตามลำดับ

---

## ขั้นตอนที่ 2: สำรวจ System Pods ใน `kube-system`
```bash
kubectl get pods -n kube-system -o wide
```
**คำถามชวนคิด (ลองสังเกตจากผลลัพธ์):**
- `etcd-k8s-control`, `kube-apiserver-k8s-control`, `kube-scheduler-k8s-control` รันอยู่ที่ Node ไหน? *(คำตอบ: `k8s-control`)*
- `kube-proxy` และ CNI (`kube-flannel` หรือ `calico`) มีกี่ตัว และรันอยู่บน Node ไหนบ้าง? *(คำตอบ: รันบนทุก Node)*

---

## ขั้นตอนที่ 3: ทดลองสร้าง Pod ชั่วคราวและเข้าไป Debug ข้างใน
```bash
# 1. สร้าง Namespace สำหรับทำ Lab เพื่อความเป็นระเบียบ
kubectl create namespace k8s-lab

# 2. สร้าง Pod ทดสอบชื่อ test-pod ด้วยคำสั่ง Imperative
kubectl run test-pod --image=nginx:1.25-alpine -n k8s-lab

# 3. ดูสถานะและรอจนขึ้น Running
kubectl get pods -n k8s-lab -w
# (กด Ctrl+C เพื่อออกจากการ watch)

# 4. ดูรายละเอียดเชิงลึกและ Events
kubectl describe pod test-pod -n k8s-lab

# 5. เข้าไปรันคำสั่งภายใน Pod
kubectl exec -it test-pod -n k8s-lab -- sh
# ลองพิมพ์คำสั่งข้างใน Pod:
#   hostname
#   cat /etc/os-release
#   exit

# 6. ดู Log ของ Pod
kubectl logs test-pod -n k8s-lab
```

---

## ขั้นตอนที่ 4: Cleanup (ลบทรัพยากรทดสอบ)
```bash
kubectl delete pod test-pod -n k8s-lab
```
*(เก็บ Namespace `k8s-lab` ไว้ใช้ต่อใน Workshop 2 ได้เลย)*
