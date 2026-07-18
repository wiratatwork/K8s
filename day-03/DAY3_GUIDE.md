# วันที่ 3 — ReplicaSet และ Deployment

> เป้าหมายวันนี้: จัดการ High Availability (self-healing, scale) และ Rolling Update / Rollback ได้

**ต้องมีจากวันที่ 1–2:** minikube พร้อม, เข้าใจ Pod + YAML (`labels`, `selector`)

---

## สารบัญ

1. [ReplicaSet — แนวคิด](#1-replicaset--แนวคิด)
2. [Demo & Lab 3: ReplicaSets](#2-demo--lab-3-replicasets)
3. [Deployment — แนวคิด](#3-deployment--แนวคิด)
4. [Demo & Lab 4: Deployments](#4-demo--lab-4-deployments)
5. [Update & Rollback](#5-update--rollback)
6. [Review & Cheat Sheet](#6-review--cheat-sheet)

---

## โครงสร้างโฟลเดอร์วันนี้

```
day-03/
├── DAY3_GUIDE.md
├── nginx-rs.yaml              ← ReplicaSet (ถูกต้อง)
├── nginx-rs-mismatch.yaml     ← label mismatch (ฝึก debug)
├── nginx-deployment.yaml      ← Deployment 3 replicas
├── lab3-commands.ps1
├── lab4-commands.ps1
└── notes.md
```

---

## 1. ReplicaSet — แนวคิด

### ปัญหาของ Pod เดี่ยว (วันที่ 2)

ลบ Pod แล้ว **ไม่มีใครสร้างใหม่** → ไม่มี High Availability

### ReplicaSet แก้ยังไง?

**ReplicaSet** คอยให้จำนวน Pod ตรงกับ `replicas` ที่ประกาศไว้เสมอ

```
คุณบอก: replicas: 3
         ↓
ReplicaSet:
  ✓ สร้าง Pod ให้ครบ 3
  ✓ ถ้าลบไป 1 ตัว → สร้างใหม่ทันที (self-healing)
  ✓ scale ขึ้น/ลงได้
```

### ส่วนสำคัญใน YAML

| ฟิลด์ | ความหมาย |
|------|----------|
| `spec.replicas` | จำนวน Pod ที่ต้องการ |
| `spec.selector.matchLabels` | เลือก Pod ที่มี label ตรงนี้ |
| `spec.template` | แม่พิมพ์สร้าง Pod ใหม่ |
| `template.metadata.labels` | **ต้องตรงกับ selector** |

> ถ้า selector กับ labels ใน template ไม่ตรง → apply ไม่ผ่าน / ReplicaSet ทำงานผิด (Lab 3)

### ReplicationController vs ReplicaSet

- **ReplicationController** = รุ่นเก่า
- **ReplicaSet** = รุ่นใหม่ — ใช้ตัวนี้
- งานจริงมักใช้ **Deployment** ครอบ ReplicaSet อีกชั้น

---

## 2. Demo & Lab 3: ReplicaSets

### Lab 3 Checklist

- [ ] ReplicaSet รักษา desired replicas เมื่อลบ Pod
- [ ] scale จาก 5 → 2 ได้
- [ ] debug label mismatch ได้

### ขั้นตอนสำคัญ

```powershell
cd "D:\demo kubernates\day-03"
kubectl apply -f nginx-rs.yaml
kubectl get rs,pods --show-labels

# Self-healing
$pod = kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}"
kubectl delete pod $pod
kubectl get pods -l app=nginx

# Scale
kubectl scale rs nginx-rs --replicas=5
kubectl scale rs nginx-rs --replicas=2

# Mismatch (คาดว่า error)
kubectl apply -f nginx-rs-mismatch.yaml
```

**รันอัตโนมัติ:** `.\lab3-commands.ps1`

---

## 3. Deployment — แนวคิด

ReplicaSet เก่งเรื่องจำนวน Pod แต่ **อัปเดตเวอร์ชัน / rollback** ยุ่ง  
**Deployment** จัดการ ReplicaSet ให้ และรองรับ Rolling Update, history, undo

```
Deployment
   └── ReplicaSet (revision ปัจจุบัน)
          └── Pods
```

| Strategy | พฤติกรรม |
|----------|----------|
| **RollingUpdate** (default) | เปลี่ยนทีละส่วน — downtime น้อย |
| **Recreate** | ลบของเก่าก่อนสร้างใหม่ — มี downtime |

---

## 4. Demo & Lab 4: Deployments

### Lab 4 Checklist

- [ ] Deployment มี 3 replicas และ Ready
- [ ] Rolling update เปลี่ยน image ได้
- [ ] Rollback กลับ revision ก่อนหน้าได้

```powershell
kubectl apply -f nginx-deployment.yaml
kubectl rollout status deployment/nginx-deployment
.\lab4-commands.ps1
```

---

## 5. Update & Rollback

```powershell
kubectl set image deployment/nginx-deployment nginx=nginx:1.26
kubectl rollout status deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment --to-revision=1
```

### คำสั่งที่ใช้บ่อยวันนี้

```bash
kubectl scale rs <name> --replicas=5
kubectl get rs,pods --show-labels
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=2
```

---

## 6. Review & Cheat Sheet

| หัวข้อ | สิ่งที่ต้องจำ |
|-------|-------------|
| ReplicaSet | รักษาจำนวน Pod + self-healing |
| selector ↔ labels | ต้องตรงกัน |
| Deployment | ครอบ RS + rolling update + rollback |
| rollout undo | กลับเวอร์ชันก่อนหน้า |

### Cleanup

```powershell
kubectl delete -f nginx-rs.yaml --ignore-not-found
kubectl delete -f nginx-rs-mismatch.yaml --ignore-not-found
kubectl delete -f nginx-deployment.yaml --ignore-not-found
```

### เตรียมวันที่ 4

พรุ่งนี้เรียน **Services & Networking** และเริ่ม Voting App

---

*วันที่ 3 | Module 3: YAML & Workload Controllers*
