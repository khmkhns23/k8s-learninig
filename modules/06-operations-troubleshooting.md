# Module 6: Operations, Health Probes & Troubleshooting

## 1. การตรวจสอบสุขภาพแอป (Health Probes)

บางครั้ง Container ยังทำงานอยู่ (Process ไม่ได้ตาย) แต่แอปข้างในค้างหรือยังบูตไม่เสร็จ K8s จึงมี **Probes** ให้ `kubelet` คอยตรวจสุขภาพ:

| Probe | หน้าที่ | ถ้าตรวจไม่ผ่าน (Fail) จะเกิดอะไร? |
| :--- | :--- | :--- |
| **`livenessProbe`** | เช็คว่าแอป **"ยังอยู่ดี/ไม่ค้าง"** หรือไม่ | `kubelet` จะสั่ง **Restart Container** ใหม่ |
| **`readinessProbe`** | เช็คว่าแอป **"พร้อมรับทราฟฟิก"** หรือยัง | Service จะ **ถอด Pod นี้ออกจาก Endpoints ชั่วคราว** (ไม่ส่งลูกค้ามาหา จนกว่าจะผ่าน) |
| **`startupProbe`** | ใช้กับแอปที่บูตช้ามาก | รอจนกว่าแอปจะตื่นตัวครั้งแรก ก่อนเริ่มเช็ค Liveness/Readiness |

```yaml
readinessProbe:
  httpGet:
    path: /healthz
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
```

---

## 2. การจัดการทรัพยากร (Resource Requests & Limits)

เพื่อป้องกันไม่ให้แอปตัวเดียวกิน RAM/CPU จนทำให้ Worker Node (ที่มี RAM 2GB) ค้างทั้งเครื่อง ควรกำหนดให้ชัดเจน:

- **`requests`**: ปริมาณขั้นต่ำที่ **การันตี** ให้ Pod (ใช้โดย `kube-scheduler` เพื่อเลือก Node ที่เหลือพื้นที่พอ)
- **`limits`**: เพดานสูงสุดที่ห้ามใช้เกิน
  - ถ้า CPU เกิน `limits` -> โดน **Throttled** (ถูกชะลอความเร็ว)
  - ถ้า RAM (Memory) เกิน `limits` -> โดน **`OOMKilled`** (Out of Memory — ถูกสั่งฆ่าและ Restart ทันที!)

---

## 3. คู่มือวิเคราะห์ปัญหา (Troubleshooting Cheatsheet)

เมื่อ Pod ไม่เป็น `Running` ให้ไล่เช็ค 3 ขั้นตอนเสมอ:
1. `kubectl get pods -o wide` (ดูสถานะ `STATUS` และ `RESTARTS`)
2. `kubectl describe pod <name>` (อ่านหัวข้อ `Events:` ด้านล่างสุด)
3. `kubectl logs <name>` (หรือเพิ่ม `--previous` เพื่อดู Log ของรอบที่เพิ่ง Crash ไป)

| สถานะ Error ที่พบบ่อย | สาเหตุที่เป็นไปได้มากที่สุด | วิธีแก้เบื้องต้น |
| :--- | :--- | :--- |
| **`Pending`** | 1. CPU/RAM บน Worker ไม่พอตาม `requests`<br>2. Node มี Taint หรือ PVC ยังไม่ Bound | เช็ค `kubectl describe pod` ดูข้อความ FailedScheduling |
| **`ImagePullBackOff` / `ErrImagePull`** | พิมพ์ชื่อ Image หรือ Tag ผิด, ไม่มีเน็ต, หรือ Registry ส่วนตัวไม่มี Secret | เช็คชื่อ Image ใน YAML ให้ถูกต้อง |
| **`CrashLoopBackOff`** | Container สตาร์ทแล้วพัง/จบการทำงานซ้ำๆ (Exit code != 0) หรือ `livenessProbe` ล้มเหลว | ดู `kubectl logs <pod> --previous` |
| **`OOMKilled`** | แอปใช้ RAM เกิน `resources.limits.memory` | เพิ่ม `limits.memory` หรือแก้ Memory Leak |
| **Pod `Running` แต่เข้าเว็บไม่ได้** | `readinessProbe` ไม่ผ่าน หรือ `Service` selector ไม่ตรงกับ Pod Label | เช็ค `kubectl get endpoints <svc>` ว่ามี IP Pod ขึ้นหรือไม่ |

---

## 4. ลงมือปฏิบัติ (Workshop 6 — Troubleshooting Challenge)
ไปฝึกไล่จับบักและซ่อมไฟล์ YAML ที่พังอยู่ 4 เคสจริงบนคลัสเตอร์ได้ที่: [ws06-troubleshooting-challenge](../../workshops/ws06-troubleshooting-challenge/README.md)

---

## 5. แบบทดสอบท้ายบท (Quiz 6)

**ข้อ 1.** เมื่อแอปพลิเคชันกำลังเชื่อมต่อฐานข้อมูลตอนเปิดเครื่อง (ต้องใช้เวลา 15 วินาทีถึงจะพร้อมรับ User) แต่ Process ทำงานปกติ ควรใช้ Probe ชนิดใดเพื่อไม่ให้ Service ส่งทราฟฟิกเข้ามาตอนยังเปิดไม่เสร็จ?
- A. `livenessProbe`
- B. `readinessProbe`
- C. `networkProbe`
- D. `restartProbe`

**ข้อ 2.** หาก `livenessProbe` ตรวจเช็คไม่ผ่านติดต่อกันเกิน `failureThreshold` จะเกิดอะไรขึ้นกับ Pod?
- A. Pod จะถูกลบออกจากคลัสเตอร์ถาวร
- B. `kubelet` จะสั่ง Restart Container นั้นใหม่
- C. Pod จะถูกย้ายไป Node อื่นทันที
- D. Service จะปิดพอร์ต

**ข้อ 3.** สถานะ `OOMKilled` (Exit Code 137) เกิดจากสาเหตุใด?
- A. Container ใช้ CPU เกิน `limits.cpu`
- B. Container ใช้ Memory (RAM) เกิน `limits.memory`
- C. Disk บน Worker เต็ม
- D. พิมพ์ชื่อ Image ผิด

**ข้อ 4.** `kube-scheduler` ใช้ค่าใดในการคำนวณว่า Worker Node เครื่องไหนมีพื้นที่พอสำหรับวาง Pod ใหม่?
- A. `resources.limits`
- B. `resources.requests`
- C. `livenessProbe`
- D. `replicas`

**ข้อ 5.** Pod ขึ้นสถานะ `CrashLoopBackOff` และรีสตาร์ทไปแล้ว 5 ครั้ง คุณต้องการดู Log ของรอบก่อนหน้าที่เพิ่ง Crash ไป ควรใช้คำสั่งใด?
- A. `kubectl logs <pod> --tail=10`
- B. `kubectl logs <pod> --previous`
- C. `kubectl describe pod <pod> --old`
- D. `kubectl exec <pod> -- cat /var/log/crash`

**ข้อ 6.** Pod ขึ้นสถานะ `ImagePullBackOff` คำสั่งแรกที่ควรรันเพื่อดูว่าติดปัญหาอะไร (เช่น หา Tag ไม่เจอ หรือ DNS พัง) คือข้อใด?
- A. `kubectl logs <pod>`
- B. `kubectl describe pod <pod>`
- C. `kubectl exec -it <pod> -- sh`
- D. `kubectl delete node`

**ข้อ 7.** หากกำหนด `requests.memory: "4Gi"` แต่ในคลัสเตอร์มี Worker Node ที่เหลือ RAM ว่างเพียง `1.5Gi` ต่อเครื่อง Pod จะมีสถานะเป็นอะไร?
- A. `Running`
- B. `OOMKilled`
- C. `Pending`
- D. `CrashLoopBackOff`

**ข้อ 8.** เมื่อ `kubectl get pods` เห็น `READY 0/1` และ `STATUS Running` นานผิดปกติ มักเกิดจากอะไร?
- A. Container Runtime ตาย
- B. `readinessProbe` ยังตรวจไม่ผ่าน
- C. `ImagePullBackOff`
- D. ไม่มี Service

---

<details>
<summary>คลิกเพื่อดูเฉลย Quiz 6</summary>

1. **B (`readinessProbe`)** — Readiness คุมการรับทราฟฟิกจาก Service; ถ้ายังไม่พร้อมจะยังไม่ใส่ IP ลงใน Endpoints แต่ไม่สั่ง Restart
2. **B (`kubelet` จะสั่ง Restart Container)** — Liveness มีไว้กู้ชีพแอปที่ค้าง/Deadlock
3. **B (ใช้ Memory เกิน `limits.memory`)** — Linux Kernel OOM Killer จะสั่งฆ่า process ที่ใช้แรมเกินเพดาน
4. **B (`resources.requests`)** — Scheduler จองพื้นที่บน Node ตามค่า `requests`
5. **B (`kubectl logs <pod> --previous`)** — flag `-p` หรือ `--previous` แสดง log ของ container ตัวก่อนหน้าใน Pod ที่เพิ่งตายไป
6. **B (`kubectl describe pod <pod>`)** — เมื่อ Container ยังไม่ถูกสร้าง (`ImagePullBackOff`) จะยังไม่มี log ให้ดู ต้องดูที่ `Events` ใน `describe`
7. **C (`Pending`)** — ไม่มี Node ไหนมีทรัพยากรว่างพอตาม `requests` จึงค้างรอการ Schedule
8. **B (`readinessProbe` ยังตรวจไม่ผ่าน)** — Container รันอยู่ (`Running`) แต่ยังไม่ถือว่า Ready (`0/1`)

</details>
