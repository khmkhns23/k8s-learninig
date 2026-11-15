# คู่มือการศึกษา Kubernetes (K8s) พร้อมบททดสอบและ Workshop

ยินดีต้อนรับสู่ชุดบทเรียน **Kubernetes ภาคปฏิบัติ (Hands-on)** ที่ออกแบบมาให้ใช้งานร่วมกับคลัสเตอร์จริงของคุณ:

| Node / เครื่อง | บทบาท (Role) | IP Address | หมายเหตุ |
| :--- | :--- | :--- | :--- |
| `k8s-control` | Control Plane (Master) | `192.168.1.10` | รันคำสั่ง `kubectl` จากเครื่องนี้ |
| `k8s-worker1` | Worker Node 1 | `192.168.1.11` | รัน Workload (Pods) |
| `k8s-worker2` | Worker Node 2 | `192.168.1.12` | รัน Workload (Pods) |
| `k8s-lb` | External Load Balancer (Nginx) | `192.168.1.20` | รับทราฟฟิกจากภายนอกพอร์ต `80` -> `30080` |

---

## แผนการเรียน (Module 0 - Module 6)

แนะนำให้เรียนตามลำดับ (หากยังไม่มีคลัสเตอร์ ให้เริ่มที่ **Module 0** ก่อน) โดยในแต่ละบทจะมี **ทฤษฎี + Workshop ลงมือทำจริง + แบบทดสอบท้ายบท**

0. **Module 0: การสร้าง Cluster ตั้งแต่เริ่มต้น (Kind / Minikube / `kubeadm`)** *(สำหรับผู้ที่ยังไม่มีคลัสเตอร์)*
   - บทเรียน & แบบทดสอบ: [00-cluster-setup.md](./modules/00-cluster-setup.md)
   - Workshop 0: [ws00-build-cluster](./workshops/ws00-build-cluster/README.md)
1. **Module 1: Architecture & `kubectl` Basics**
   - บทเรียน & แบบทดสอบ: [01-architecture.md](./modules/01-architecture.md)
   - Workshop 1: [ws01-cluster-inspection](./workshops/ws01-cluster-inspection/README.md)
2. **Module 2: Workloads — Pod, ReplicaSet & Deployment**
   - บทเรียน & แบบทดสอบ: [02-workloads-deployment.md](./modules/02-workloads-deployment.md)
   - Workshop 2: [ws02-deployment-scaling](./workshops/ws02-deployment-scaling/README.md)
3. **Module 3: Networking, Services & Load Balancing**
   - บทเรียน & แบบทดสอบ: [03-networking-services.md](./modules/03-networking-services.md)
   - Workshop 3: [ws03-services-networking](./workshops/ws03-services-networking/README.md)
4. **Module 4: Configuration — ConfigMap & Secret**
   - บทเรียน & แบบทดสอบ: [04-configmap-secret.md](./modules/04-configmap-secret.md)
   - Workshop 4: [ws04-configmap-secret](./workshops/ws04-configmap-secret/README.md)
5. **Module 5: Storage & Persistence — Volume, PV & PVC**
   - บทเรียน & แบบทดสอบ: [05-storage-pv-pvc.md](./modules/05-storage-pv-pvc.md)
   - Workshop 5: [ws05-persistent-storage](./workshops/ws05-persistent-storage/README.md)
6. **Module 6: Operations, Probes & Troubleshooting**
   - บทเรียน & แบบทดสอบ: [06-operations-troubleshooting.md](./modules/06-operations-troubleshooting.md)
   - Workshop 6 (Challenge): [ws06-troubleshooting-challenge](./workshops/ws06-troubleshooting-challenge/README.md)

**ประเมินผลรวม:** [final-exam.md](./final-exam.md) (ข้อสอบรวม 15 ข้อ + เฉลยอธิบายเหตุผล)

---

## วิธีนำไฟล์ Workshop ไปรันบน `k8s-control`

เนื่องจากไฟล์บทเรียนอยู่ที่เครื่อง Windows (`d:\DPU\K8s\k8s-learning\`) คุณสามารถส่งไฟล์เข้าไปยัง `k8s-control` (`192.168.1.10`) ได้ด้วย `scp` จาก PowerShell บน Windows:

```powershell
# คัดลอกโฟลเดอร์ workshops ทั้งหมดไปยัง home ของ user บน k8s-control
scp -r D:\DPU\K8s\k8s-learning\workshops <username>@192.168.1.10:~/
```

> **ข้อแนะนำ:** หลังจบแต่ละ Workshop ควรรันคำสั่ง **Cleanup** ท้ายบทเสมอ เพื่อคืน RAM/CPU ให้ VM ก่อนเริ่มบทถัดไป
