# เฉลย Workshop 6: Troubleshooting Challenge

### เคสที่ 1 (`broken-01-image.yaml`)
- **อาการ:** Pod ขึ้นสถานะ `ImagePullBackOff` หรือ `ErrImagePull`
- **วิธีตรวจ:** `kubectl describe pod -l app=case01 -n k8s-lab` จะเห็น Error ดึง image `nginxx:1.25-alpine` ไม่ได้
- **สาเหตุ & วิธีแก้:** พิมพ์ชื่อ Image ผิด (`nginxx` มี x เกินมา) ให้แก้เป็น `image: nginx:1.25-alpine`

---

### เคสที่ 2 (`broken-02-selector.yaml`)
- **อาการ:** Pod ขึ้น `Running 1/1` แต่เข้าเว็บผ่าน `NodePort 30083` ไม่ได้ และ `kubectl get endpoints case02-svc -n k8s-lab` ได้ค่า `<none>`
- **สาเหตุ & วิธีแก้:** ใน `Service` ตั้งค่า `selector.app: case02-wrong-label` ซึ่งไม่ตรงกับ `labels.app: case02-backend` ของ Pod ให้แก้ `selector.app` เป็น `case02-backend`

---

### เคสที่ 3 (`broken-03-resources.yaml`)
- **อาการ:** Pod ค้างสถานะ `Pending` ตลอดเวลา
- **วิธีตรวจ:** `kubectl describe pod -l app=case03 -n k8s-lab` จะพบ Event `0/3 nodes are available: ... Insufficient memory.`
- **สาเหตุ & วิธีแก้:** ขอ RAM (`requests.memory: "16Gi"`) เกินกว่าที่ Worker Node (2GB) มีอยู่ ให้ลดลงมาเป็นค่าที่เหมาะสม เช่น `requests.memory: "32Mi"` และ `limits.memory: "64Mi"`

---

### เคสที่ 4 (`broken-04-probe.yaml`)
- **อาการ:** Pod ขึ้น `READY 0/1` และตัวเลข `RESTARTS` เพิ่มขึ้นเรื่อยๆ จนอาจเป็น `CrashLoopBackOff`
- **วิธีตรวจ:** `kubectl describe pod -l app=case04 -n k8s-lab` จะเห็น `Liveness probe failed: HTTP probe failed with statuscode: 404` และ `Readiness probe failed: ... 404`
- **สาเหตุ & วิธีแก้:** `nginx:1.25-alpine` มีเฉพาะหน้า `/` (ไม่มี path `/non-existent-healthz` และ `/non-existent-ready`) ทำให้ตอบ 404 จน `kubelet` สั่ง Restart ซ้ำๆ ให้แก้ `path:` เป็น `/` ทั้งสอง Probe
