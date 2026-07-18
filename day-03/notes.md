# บันทึกส่วนตัว — วันที่ 3

## คำถามทบทวน Day 3 (15 ข้อ)

### ReplicaSet

1. ReplicaSet แก้ปัญหาอะไรของ Pod เดี่ยว?

   > ตอบ: Pod เดี่ยว = รันครั้งเดียวจบ ส่วน ReplicaSet = คอยให้มีจำนวน Pod ตามที่ต้องการอยู่เสมอ

2. `replicas`, `selector`, `template` ใน ReplicaSet ทำหน้าที่อะไร?

   > ตอบ: replicas: 3          → ต้องมี 3 ตัว
selector: app=nginx  → นับเฉพาะ Pod ที่ label ตรงนี้
template: ...        → ถ้าขาด → สร้าง Pod ตามแม่พิมพ์นี้

3. ทำไม `selector.matchLabels` ต้องตรงกับ `template.metadata.labels`?

   > ตอบ: เพื่อให้ Pod ที่สร้างจาก template ถูกนับใน desired replicas และ self-healing / scale ทำงานถูกต้อง

4. Self-healing ของ ReplicaSet ทำงานอย่างไรเมื่อลบ Pod?

   > ตอบ: คอยเติม Pod ให้ครบ replicas อัตโนมัติ เมื่อมีตัวหายไป

5. คำสั่ง scale ReplicaSet เป็น 5 replicas คืออะไร?

   > ตอบ: kubectl scale rs nginx-rs --replicas=5

### Deployment

6. Deployment ต่างจาก ReplicaSet อย่างไร?

   > ตอบ: ReplicaSet = จำนวน ส่วน Deployment = จำนวน + การปล่อยเวอร์ชันอย่างปลอดภัย + การ rollback

7. RollingUpdate กับ Recreate ต่างกันอย่างไร?

   > ตอบ: เปลี่ยนทีละส่วน — สร้างใหม่ค่อย ๆ / ลดเก่าค่อย ๆ กับ ลบ Pod เก่าทั้งหมด แล้วค่อยสร้างใหม่

8. เมื่อเปลี่ยน image ของ Deployment จะเกิดอะไรขึ้นกับ ReplicaSet?

   > ตอบ: สร้าง RS ชุดใหม่ แล้วค่อยย้าย Pod จากชุดเก่าไปชุดใหม่

9. คำสั่งดูสถานะ rolling update คืออะไร?

   > ตอบ: kubectl rollout status deployment/nginx-deployment

10. คำสั่งดูประวัติ revision ของ Deployment คืออะไร?

    > ตอบ: kubectl rollout history deployment/nginx-deployment

11. คำสั่ง rollback กลับเวอร์ชันก่อนหน้าคืออะไร?

    > ตอบ: kubectl rollout undo deployment/nginx-deployment หรือถ้าต้องการเจาะจง
    kubectl rollout undo deployment/nginx-deployment --to-revision=1

12. `--to-revision=2` ใช้ทำอะไร?

    > ตอบ: ใช้กับ kubectl rollout undo เพื่อ ย้อนกลับไป revision ที่ระบุ ไม่ใช่แค่ตัวก่อนหน้าเสมอ

### เปรียบเทียบ & งานจริง

13. งานจริงควรสร้างแอปด้วย Pod, ReplicaSet หรือ Deployment? ทำไม?

    > ตอบ: ประกาศเป็น Deployment แล้วให้มันจัดการ ReplicaSet และ Pod ให้เอง

14. ถ้า label ของ Pod ไม่ตรง selector ของ Service/ReplicaSet จะเกิดอะไรขึ้น?

    > ตอบ: Service หรือ ReplicaSet จะ “มองไม่เห็น” Pod นั้น

15. สรุปความสัมพันธ์ Deployment → ReplicaSet → Pod

    > ตอบ: Deployment คุมเวอร์ชัน → ReplicaSet คุมจำนวน → Pod คือตัวที่รันจริง

---

## Lab 3 Checklist

- [x] ReplicaSet รักษา desired replicas อัตโนมัติเมื่อลบ Pod
- [x] Scale 5 → 2 ได้
- [x] Debug label mismatch ได้

## Lab 4 Checklist

- [x] Deployment rolling update สำเร็จ
- [x] Rollback กลับ revision ก่อนหน้าได้

---

## คำสั่งที่ใช้วันนี้

```
(จดคำสั่งที่ใช้ระหว่าง Lab)
```

---

## สิ่งที่ยังไม่เข้าใจ / ถามวันหน้า

-
