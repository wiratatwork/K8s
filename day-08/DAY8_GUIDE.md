# วันที่ 8 — Persistent Storage (PV, PVC, StorageClass)

> เป้าหมายวันนี้: Postgres / stateful workload ไม่เสียข้อมูลเมื่อ Pod ถูกสร้างใหม่

**อ้างอิง COURSE_CONTENT_2:** Volumes, Persistent Volumes, PVC, Storage Class

---

## สารบัญ

1. [ทำไม emptyDir ไม่พอ](#1-ทำไม-emptydir-ไม่พอ)
2. [PV vs PVC](#2-pv-vs-pvc)
3. [StorageClass & dynamic provisioning](#3-storageclass)
4. [Lab 12](#4-lab-12)
5. [งานจริง vs lab](#5-งานจริง)

---

## โครงสร้างโฟลเดอร์

```
day-08/
├── DAY8_GUIDE.md
├── postgres-pvc.yaml
├── db-deployment-pvc.yaml
├── lab12-commands.ps1
└── notes.md
```

---

## 1. ทำไม emptyDir ไม่พอ

- **emptyDir** หายเมื่อ Pod ถูกลบ
- **Production DB** → managed DB (RDS/Cloud SQL) หรือ PVC + backup

---

## 2. PV vs PVC

| | PV | PVC |
|--|----|-----|
| ใครสร้าง | admin / dynamic | developer |
| ความสัมพันธ์ | 1 PVC → 1 PV (bound) | ขอ capacity + accessMode |

**accessModes:** `ReadWriteOnce` (หนึ่ง node), `ReadOnlyMany`, `ReadWriteMany` (ต้อง storage รองรับ)

---

## 3. StorageClass

minikube มี default StorageClass — สร้าง PVC แล้วได้ PV อัตโนมัติ

```bash
kubectl get storageclass
kubectl describe pvc <name>
```

---

## 4. Lab 12

```powershell
.\lab12-commands.ps1
```

**เกณฑ์ผ่าน:**

- [ ] PVC status = Bound
- [ ] ลบ Pod db แล้วสร้างใหม่ — ข้อมูลใน `/var/lib/postgresql/data` ยังอยู่ (ทดสอบด้วย table ง่าย ๆ ถ้าต้องการ)

---

## 5. งานจริง

- Cloud: ใช้ CSI driver ของ EBS/GCE/Azure Disk
- อย่าเก็บ Postgres บน hostPath ใน production multi-node
- Backup: Velero, native snapshot, หรือ logical backup
