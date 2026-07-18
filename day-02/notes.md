


# บันทึกส่วนตัว — วันที่ 2

## คำถามทบทวน Day 2 (15 ข้อ)

### Pods

1. Pod คืออะไร และต่างจาก Container อย่างไร?

   > ตอบ: Container = แอปที่รัน ส่วน Pod = ห่อหุ้มที่ Kubernetes ใช้สร้าง / ลบ / วางบน node

2. ทำไมส่วนใหญ่จึงใส่ container เดียวต่อ Pod?

   > ตอบ: ต้องการ Scale แยกได้, Failure ไม่ปนกัน

3. Pod Status `Pending`, `Running`, `ImagePullBackOff` หมายความว่าอย่างไร?

   > ตอบ: Pending = กำลังรอ Schedule - ดึง Image - รอ Resource, Running = ถูกวางบน node แล้ว, ImagePullBackOff = ชื่อ Image ผิดหรือไม่มี - ไม่มีสิทธิ์ดึง

4. เมื่อ Pod ถูกลบโดยไม่มี ReplicaSet/Deployment จะเกิดอะไรขึ้น?

   > ตอบ: หายไปถาวร ไม่สร้างใหม่

### Imperative vs Declarative

5. Imperative กับ Declarative ต่างกันอย่างไร? ยกตัวอย่างคำสั่ง

   > ตอบ: Imperative = สั่งทำงานทีละขั้นตอน, Declarative = สั่งทำงานทั้งหมดพร้อมกันจากไฟล์ YAML

6. คำสั่งใดใช้สร้าง nginx pod แบบ imperative?

   > ตอบ: kubectl run nginx --image=nginx:1.25 --port=80

7. คำสั่งใดใช้สร้าง/อัปเดต resource จากไฟล์ YAML?

   > ตอบ: kubectl apply -f <ไฟล์.yaml>

### YAML & Pod Manifest

8. กฎ indentation ของ YAML ที่สำคัญที่สุดคืออะไร?

   > ตอบ: ใช้ Space 2 ช่อง

9. อธิบายหน้าที่ของ `apiVersion`, `kind`, `metadata`, `spec`

   > ตอบ: apiVersion = ระบุ Version ของ Resource, kind = ระบุชนิดของ Resource (Pod, Service, Deployment), metadata = ข้อมูลระบุตัวตน (name, labels, namespace), spec = สถานะที่ต้องการ (image, ports, replicas)

10. `labels` ใน metadata ใช้ทำอะไร?

    > ตอบ: ใช้เป็นป้ายสำหรับจัดกลุ่ม Resource

11. `containerPort` หมายถึงอะไร? ต่างจาก Service port อย่างไร (ระดับแนวคิด)?

    > ตอบ: containerPort = พอร์ตของ Container, Service port = พอร์ตของ Service

### Debug

12. เมื่อ Pod ไม่ขึ้น Running ควรใช้คำสั่งใดดู Events ก่อน?

    > ตอบ: kubectl describe pod <ชื่อ-pod>

13. สาเหตุที่พบบ่อยของ `ImagePullBackOff` มีอะไรบ้าง?

    > ตอบ: ชื่อ Image / Tag ผิด, Regisry ผิด, เครือข่ายอออกไม่ได้, ไม่มีสิทธิ์ดึง, Rate Limit ของ Registry

14. `kubectl delete -f` กับ `kubectl delete pod <name>` ต่างกันอย่างไร?

    > ตอบ: ลบทุก Resource ที่อยู่ใน YAML, ลบแค่ Pod ที่ชื่อตามที่ระบุ

15. ทำไม Declarative (YAML) จึงเหมาะกับงานจริงมากกว่า Imperative?

    > ตอบ: งานจริงต้องการทำซ้ำได้ ตรวจสอบได้ และทำงานเป็นทีม
   เก็บใน Git ได้, ทำซ้ำได้, CI/CD ง่าย, หลาย Resource พร้อมกัน

---

## Lab 2 Checklist

- [x] สร้าง Pod จาก YAML สำเร็จ (Status = Running)
- [x] ใช้ `kubectl describe pod` หา error ได้เมื่อ image ผิด
- [x] ใช้ `kubectl delete -f` และ `kubectl apply -f` ได้

---

## คำสั่งที่ใช้วันนี้

```
(จดคำสั่งที่ใช้ระหว่าง Lab)
```

---

## สิ่งที่ยังไม่เข้าใจ / ถามวันหน้า

-
