# Final Exam: Kubernetes Comprehensive Assessment (15 ข้อ)

แบบทดสอบประเมินผลรวมจากทั้ง 6 Modules แนะนำให้ลองทำด้วยตัวเองก่อนเปิดดูเฉลยด้านล่าง (เกณฑ์ผ่านที่แนะนำ: **12 / 15 ข้อ**)

---

### ส่วนที่ 1: ความเข้าใจสถาปัตยกรรมและพื้นฐาน (ข้อ 1 - 5)

**1.** เมื่อสั่ง `kubectl get pods` บน `k8s-control` ข้อมูลรายชื่อ Pod ถูกดึงมาจาก Component ใดผ่าน `kube-apiserver`?
- A. `kube-scheduler`
- B. `etcd`
- C. `kube-proxy`
- D. `containerd`

**2.** ในไฟล์ YAML ของ `Deployment` ส่วนใดที่เป็น "แม่พิมพ์" สำหรับสร้าง Pod?
- A. `metadata`
- B. `spec.selector`
- C. `spec.template`
- D. `status`

**3.** ข้อใด **ไม่จริง** เกี่ยวกับ `RollingUpdate` ของ Deployment?
- A. ช่วยให้แอปอัปเดตเวอร์ชันได้โดยไม่มี Downtime
- B. สร้าง ReplicaSet ใหม่ขึ้นมาคู่กับ ReplicaSet เดิม
- C. สามารถสั่ง `kubectl rollout undo` เพื่อย้อนกลับได้
- D. ต้องลบ Service เดิมทิ้งแล้วสร้างใหม่ทุกครั้งที่อัปเดต Image

**4.** หากคุณต้องการสร้างพื้นที่แยกสำหรับการทดสอบ Lab โดยไม่ปะปนกับงานใน `default` ควรสร้าง Resource ใด?
- A. `Node`
- B. `Namespace`
- C. `ClusterIP`
- D. `ReplicaSet`

**5.** คำสั่งใดแสดงทั้ง IP ของ Pod และชื่อ Worker Node ที่ Pod นั้นกำลังรันอยู่?
- A. `kubectl get pods`
- B. `kubectl get pods -o wide`
- C. `kubectl get nodes`
- D. `kubectl logs --all-pods`

---

### ส่วนที่ 2: Networking, Config และ Storage (ข้อ 6 - 10)

**6.** ในระบบ 2-Tier (Frontend + Backend) ที่รันใน Namespace เดียวกันชื่อ `shop` Pod ของ Frontend ควรเรียก Backend Service ชื่อ `api-svc` ด้วย URL ใด?
- A. `http://api-svc` (หรือ `http://api-svc.shop.svc.cluster.local`)
- B. `http://192.168.1.11:30080`
- C. `http://k8s-control:6443`
- D. `http://localhost`

**7.** Service แบบ `NodePort` ที่ตั้งค่า `port: 80`, `targetPort: 8080`, `nodePort: 30085` หาก External Load Balancer (`192.168.1.20`) ต้องการส่งทราฟฟิกเข้ามาที่ Worker Node 1 (`192.168.1.11`) ต้องยิงไปที่พอร์ตใด?
- A. `80`
- B. `8080`
- C. `30085`
- D. `6443`

**8.** เมื่อรัน `kubectl get endpoints web-svc` แล้วได้ผลลัพธ์ `<none>` สิ่งแรกที่ควรตรวจสอบคืออะไร?
- A. ตรวจสอบว่า `spec.selector` ของ `web-svc` ตรงกับ `labels` ของ Pod หรือไม่ และ Pod ผ่าน `readinessProbe` หรือยัง
- B. รีสตาร์ทเครื่อง `k8s-control`
- C. เปลี่ยน `ClusterIP` เป็น `hostPath`
- D. เพิ่ม RAM ให้ `k8s-lb`

**9.** ความแตกต่างที่สำคัญของการส่ง `ConfigMap` เข้า Pod แบบ **Volume Mount** เทียบกับ **Environment Variable** คือข้อใด?
- A. Volume Mount ใช้ได้เฉพาะกับ Secret เท่านั้น
- B. Volume Mount รองรับการ Mount เป็นไฟล์คอนฟิก (เช่น `nginx.conf`) และอัปเดตไฟล์อัตโนมัติเมื่อ ConfigMap เปลี่ยน ส่วน Env ต้องสร้าง Pod ใหม่จึงจะอัปเดต
- C. Environment Variable ปลอดภัยเท่ากับ Encryption at Rest
- D. ไม่มีข้อแตกต่าง

**10.** คุณสร้าง Pod Database ที่ต้องเก็บข้อมูลถาวรแม้ Pod ถูกลบและย้ายไปรัน Node อื่น ควรใช้ Storage แบบใด?
- A. `emptyDir`
- B. `ConfigMap`
- C. `PersistentVolumeClaim (PVC)` ที่ผูกกับ `PersistentVolume (PV)` แบบ Network/Shared Storage
- D. Container writable layer ปกติ

---

### ส่วนที่ 3: วิเคราะห์สถานการณ์และแก้ปัญหา (ข้อ 11 - 15)

**11.** จาก `kubectl get pods`:
```text
NAME                     READY   STATUS             RESTARTS   AGE
api-6d8f9b7c4-x9k2p      0/1     ImagePullBackOff   0          2m
```
สาเหตุที่เป็นไปได้มากที่สุดคือข้อใด?
- A. แรมบน Worker Node เต็ม
- B. พิมพ์ชื่อ Image หรือ Tag ผิด หรือ Worker Node ออกอินเทอร์เน็ต/Registry ไม่ได้
- C. `livenessProbe` ล้มเหลว
- D. `kube-proxy` หยุดทำงาน

**12.** จาก `kubectl get pods`:
```text
NAME                     READY   STATUS    RESTARTS   AGE
worker-5f4b8c7d9-m2n4q   0/1     Pending   0          5m
```
เมื่อรัน `kubectl describe pod` พบข้อความ `0/3 nodes are available: 1 node(s) had untolerated taint, 2 Insufficient memory.` หมายความว่าอย่างไร?
- A. Control Plane ปฏิเสธ Pod (มี Taint) และ Worker ทั้ง 2 เครื่องเหลือ RAM ไม่พอตามค่า `requests.memory` ของ Pod
- B. Image มีขนาดใหญ่เกินไป
- C. ชื่อ Pod ซ้ำกัน
- D. Nginx LB ยังไม่เปิด

**13.** แอป Node.js ใน Pod ทำงานอยู่ดีๆ แล้วรีสตาร์ทตัวเอง เมื่อดู `kubectl describe pod` พบ `Last State: Terminated, Reason: OOMKilled, Exit Code: 137` ต้องแก้ไขอย่างไร?
- A. ปิด `readinessProbe`
- B. เพิ่มค่า `resources.limits.memory` ใน YAML (หรือตรวจสอบปัญหา Memory Leak ในแอป)
- C. เปลี่ยน Service เป็น `NodePort`
- D. ลบ `etcd`

**14.** หากต้องการเปิดเว็บไซต์ผ่าน External Load Balancer (`192.168.1.20:80`) แล้ว Nginx แจ้ง `502 Bad Gateway` สลับกับ `200 OK` (ตามที่เคยเกิดขึ้นใน Lab!) จุดใดควรตรวจสอบเป็นอันดับแรก?
- A. ตรวจสอบว่า Worker Node ทุกตัวที่อยู่ใน `upstream` ของ Nginx มี IP ถูกต้องไม่ชนกัน และพอร์ต NodePort เปิดรับทราฟฟิกได้จริงทั้งสองเครื่อง
- B. เปลี่ยนจาก Ubuntu เป็น Windows
- C. เพิ่ม `replicas` จาก 3 เป็น 100
- D. ลบไฟล์ `/etc/hosts`

**15.** คุณแก้ไขค่า `livenessProbe` ใน Deployment แต่เผลอตั้ง `httpGet.path: /wrong-path` (ซึ่งไม่มีอยู่จริงและตอบ 404) เมื่อ Apply แล้วจะเกิดอะไรขึ้น?
- A. ไม่มีผลอะไร เว็บยังเข้าได้ปกติ
- B. Pod จะขึ้น `Running` สักพักแล้วถูกรีสตาร์ทซ้ำเรื่อยๆ จนอาจเข้าสู่สถานะ `CrashLoopBackOff`
- C. Service จะสร้างหน้า `/wrong-path` ขึ้นมาเอง
- D. `kube-scheduler` จะลบ Deployment ทิ้ง

---

<details>
<summary>คลิกเพื่อดูเฉลย Final Exam พร้อมคำอธิบาย</summary>

1. **B (`etcd`)** — `etcd` เก็บ state ของทุก object ในคลัสเตอร์ และ API Server เป็นตัวอ่าน/เขียนกับ `etcd`
2. **C (`spec.template`)** — ส่วน `template` คือ Pod specification ที่ ReplicaSet ใช้สร้าง Pod
3. **D** — ไม่ต้องลบ Service เลย เพราะ Service ใช้ Label Selector คอยจับคู่กับ Pod ทั้งเก่าและใหม่ให้อัตโนมัติระหว่าง Rolling Update
4. **B (`Namespace`)** — ใช้แบ่งพื้นที่เสมือนสำหรับแยกโปรเจกต์หรือสภาพแวดล้อม
5. **B (`kubectl get pods -o wide`)** — `-o wide` เพิ่มคอลัมน์ `IP` และ `NODE`
6. **A (`http://api-svc`)** — CoreDNS แปลงชื่อ Service ใน Namespace เดียวกันให้เป็น ClusterIP อัตโนมัติ
7. **C (`30085`)** — การเรียกจากภายนอกเข้า IP ของ Node ต้องยิงที่ `nodePort` เสมอ
8. **A** — Endpoints ว่างเกิดจาก Selector ไม่ตรง หรือ Pod ยังไม่ Ready
9. **B** — Volume Mount ใช้ทำไฟล์คอนฟิกและซิงค์อัปเดตได้ ส่วน Env ใช้รับค่าตอนเริ่ม container เท่านั้น
10. **C (`PV` + `PVC`)** — แยกชีวิตของข้อมูลออกจากชีวิตของ Pod และ Node
11. **B (`ImagePullBackOff`)** — ดึง Image ไม่สำเร็จ
12. **A** — อธิบายตาม Event ชัดเจน: Control Plane มี Taint `control-plane:NoSchedule` ส่วน Worker 2 ตัวมี `Insufficient memory`
13. **B (`OOMKilled`)** — แรมเกินเพดาน `limits.memory`
14. **A** — 502 สลับ 200 ใน Round-Robin หมายความว่า Worker ตัวหนึ่งตอบได้แต่อีกตัวหนึ่งมีปัญหา (IP ชนกันหรือ NodePort ไม่ตอบสนอง)
15. **B** — เมื่อ Liveness Probe ได้รับ HTTP 404 (ไม่ใช่อยู่ในช่วง 200-399) Kubelet จะถือว่า Container ตายและสั่ง Restart วนซ้ำ

</details>
