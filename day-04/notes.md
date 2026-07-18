# วันที่ 4 — Notes & ทบทวน

## เป้าหมายวันนี้
- [ ] อธิบายทำไมต้องใช้ Service (Pod IP เปลี่ยนได้)
- [ ] แยก ClusterIP / NodePort / LoadBalancer ได้
- [ ] Lab 5: สร้าง Service + ตรวจ Endpoints
- [ ] Lab 6: Voting App ด้วย Pod ทำงาน
- [ ] Lab 7: Voting App ด้วย Deployment + self-heal

---

## Lab 5 — Services
Vote/web URL: _______________

Endpoints ของ web-service มีกี่ตัว: _______________

ทำไม web-service-broken จึง Endpoints ว่าง?



---

## Lab 6 — Voting App (Pods)
Vote URL: _______________

Result URL: _______________

โหวตแล้ว Result ขึ้นหรือยัง: [ ] ใช่  [ ] ไม่

ถ้าลบ `kubectl delete pod vote` เกิดอะไร?



---

## Lab 7 — Voting App (Deployments)
หลังลบ vote pod → กลับมาเองหรือยัง: [ ] ใช่  [ ] ไม่

หลัง scale เป็น 3 → มีกี่ pods: _______________

---

## คำถามทบทวน

### 1. Pod IP ทำไมไม่ควร hardcode ในแอป?
คำตอบ:



### 2. ClusterIP กับ NodePort ต่างกันอย่างไร? ใช้เมื่อไหร่?
คำตอบ:



### 3. Service หา Pod ยังไง? ถ้า selector ผิดจะเป็นอย่างไร?
คำตอบ:



### 4. Voting App: ทำไม redis/db ใช้ ClusterIP แต่ vote/result ใช้ NodePort?
คำตอบ:



### 5. ทำไม Lab 7 ใช้ Deployment แทน Pod?
คำตอบ:



---

## สิ่งที่ติด / บันทึก error

| อาการ | สาเหตุ | วิธีแก้ |
|-------|--------|---------|
| | | |
| | | |

---

## เตรียม Day 5
- [ ] Voting App บน minikube ผ่านแล้ว
- [ ] พร้อมเลือก Cloud (GKE / EKS / AKS) สำหรับ Lab 8
