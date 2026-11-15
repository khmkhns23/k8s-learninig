# Workshop 6: Troubleshooting Challenge (4 เคสจำลองปัญหาจริง)

**เป้าหมาย:** ฝึกวิเคราะห์ปัญหาและซ่อมไฟล์ YAML ทั้ง 4 เคสให้กลับมาทำงานได้ปกติ (`Running 1/1` และเข้าถึงผ่าน Service ได้)

---

## กติกาการฝึก
ในโฟลเดอร์นี้มีไฟล์ที่ถูกวาง Bug ไว้ 4 ไฟล์:
1. `broken-01-image.yaml`
2. `broken-02-selector.yaml`
3. `broken-03-resources.yaml`
4. `broken-04-probe.yaml`

**ขั้นตอนสำหรับแต่ละเคส:**
1. สั่งรันไฟล์: `kubectl apply -f broken-0X-....yaml`
2. สังเกตอาการด้วย `kubectl get pods,svc,endpoints -n k8s-lab`
3. สืบหาสาเหตุด้วย `kubectl describe pod ... -n k8s-lab` หรือ `kubectl logs ...`
4. แก้ไขไฟล์ YAML ให้ถูกต้อง แล้ว `kubectl apply` ใหม่จนกว่า `READY` จะเป็น `1/1` (`Running`) และเข้าใช้งานได้จริง!
5. ดูเฉลยเปรียบเทียบได้ที่ [solutions.md](./solutions.md)

---

## Cleanup หลังจบทุกเคส (และจบคอร์ส)
```bash
kubectl delete -f .
# หรือลบทั้ง Namespace k8s-lab เพื่อคืนทรัพยากรทั้งหมด
kubectl delete namespace k8s-lab
```
