# วันที่ 2 — Pod และ YAML Fundamentals

> เป้าหมายวันนี้: สร้าง Pod แบบ imperative และ declarative (YAML) ได้ และ debug เมื่อ image ผิด

**ต้องมีจากวันที่ 1:** minikube รันได้, kubectl ใช้ได้, Docker Desktop เปิดอยู่

---

## สารบัญ

1. [Pods — แนวคิด](#1-pods--แนวคิด)
2. [Demo: Deploy Pod (Imperative)](#2-demo-deploy-pod-imperative)
3. [Introduction to YAML](#3-introduction-to-yaml)
4. [Pods with YAML (Declarative)](#4-pods-with-yaml-declarative)
5. [YAML Tips (VS Code)](#5-yaml-tips-vs-code)
6. [Lab 2: Pods with YAML](#6-lab-2-pods-with-yaml)
7. [Review & Cheat Sheet](#7-review--cheat-sheet)

---

## โครงสร้างโฟลเดอร์วันนี้

```
day-02/
├── DAY2_GUIDE.md              ← คุณอยู่ที่นี่
├── nginx-pod.yaml             ← Pod ที่ถูกต้อง
├── nginx-pod-broken.yaml      ← Pod จงใจผิด (ฝึก debug)
├── yaml-practice.yaml         ← แบบฝึก YAML พื้นฐาน
├── lab2-commands.ps1          ← สคริปต์ Lab 2
└── notes.md                   ← คำถามทบทวน
```

---

## 1. Pods — แนวคิด

### Pod คืออะไร?

**Pod** คือหน่วยที่เล็กที่สุดที่ Kubernetes จัดการ  
ภายใน Pod มี container หนึ่งตัวหรือมากกว่า

```
┌──────────── Worker Node ────────────┐
│                                     │
│   ┌──────────── Pod ────────────┐   │
│   │  Container: nginx           │   │
│   │  (แชร์ network / storage)   │   │
│   └─────────────────────────────┘   │
│                                     │
│   ┌──────────── Pod ────────────┐   │
│   │  Container: app             │   │
│   │  Container: sidecar         │   │
│   └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### กฎสำคัญสำหรับผู้เริ่มต้น

| แนวคิด | ความหมาย |
|--------|----------|
| 1 Pod ≈ 1 แอปหลัก | ส่วนใหญ่ใส่ container เดียวต่อ Pod |
| Pod มี IP ของตัวเอง | container ใน Pod เดียวกันคุยกันผ่าน localhost |
| Pod ตายแล้วไม่กลับมาเอง | ต้องมี ReplicaSet/Deployment คอยดูแล (เรียนวันที่ 3) |
| Scale = สร้าง Pod เพิ่ม | ไม่ scale โดยการเพิ่ม container ใน Pod เดิม |

### Pod Lifecycle (สถานะที่พบบ่อย)

| Status | ความหมาย |
|--------|----------|
| Pending | รอ schedule / กำลัง pull image |
| Running | container รันอยู่ |
| Succeeded | จบงานสำเร็จ (Job) |
| Failed | จบล้มเหลว |
| CrashLoopBackOff | container รีสตาร์ทซ้ำ ๆ |
| ImagePullBackOff | ดึง image ไม่ได้ |

---

## 2. Demo: Deploy Pod (Imperative)

Imperative = สั่งตรงด้วยคำสั่ง (ไม่ผ่านไฟล์ YAML)

### ขั้นตอน

```powershell
# ตรวจว่า cluster พร้อม
kubectl get nodes

# สร้าง nginx pod (imperative)
kubectl run nginx --image=nginx:1.25 --port=80

# ดูรายการ pods
kubectl get pods

# ดูรายละเอียด + Events (สำคัญมากเมื่อ debug)
kubectl describe pod nginx

# ดู logs
kubectl logs nginx

# ลบเมื่อทดลองเสร็จ
kubectl delete pod nginx
```

### สิ่งที่ควรสังเกตจาก `describe`

- **Status / Ready**
- **IP** ของ Pod
- **Events** — บอกเหตุผลถ้าติด Pending / ImagePullBackOff

---

## 3. Introduction to YAML

YAML เป็นรูปแบบข้อมูลที่ Kubernetes ใช้เขียน manifest

### กฎพื้นฐาน

1. **Indent ด้วย space** — ห้ามใช้ Tab
2. **Key: value** — มีช่องว่างหลัง colon
3. **List** ใช้ `-`
4. **Nesting** ใช้การเยื้องระดับ

### ตัวอย่าง

```yaml
# key-value
name: Ada
age: 28

# list
hobbies:
  - reading
  - cycling

# dictionary (nested)
nutrition:
  fruits:
    - apple
    - banana
  vegetables:
    - carrot
```

### แบบฝึก

เปิดไฟล์ `yaml-practice.yaml` แล้วเพิ่ม `spinach` และ `broccoli` ใน `vegetables` ให้ indentation ถูกต้อง

---

## 4. Pods with YAML (Declarative)

Declarative = บอกสถานะที่ต้องการในไฟล์ แล้วให้ Kubernetes ทำให้ตรงตามนั้น

### โครง Pod YAML 4 ส่วน

```yaml
apiVersion: v1          # 1) API version ของ resource
kind: Pod               # 2) ประเภท resource
metadata:               # 3) ชื่อ + labels
  name: nginx-pod
  labels:
    app: nginx
spec:                   # 4) สิ่งที่ต้องการให้รัน
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
```

| ฟิลด์ | ความหมาย |
|------|----------|
| `apiVersion` | เวอร์ชัน API (`v1` สำหรับ Pod) |
| `kind` | ชนิด resource (`Pod`) |
| `metadata.name` | ชื่อ Pod (ต้องไม่ซ้ำใน namespace) |
| `metadata.labels` | ป้ายกำกับ ใช้คัดเลือกทีหลัง |
| `spec.containers` | รายการ container ใน Pod |
| `image` | ชื่อ image จาก registry |
| `containerPort` | พอร์ตที่แอปฟังอยู่ |

### คำสั่งหลัก

```powershell
kubectl apply -f nginx-pod.yaml      # สร้างหรืออัปเดต
kubectl get pods
kubectl describe pod nginx-pod
kubectl delete -f nginx-pod.yaml     # ลบตามไฟล์
```

---

## 5. YAML Tips (VS Code)

1. ติดตั้ง extension **YAML** โดย Red Hat
2. เปิด `nginx-pod.yaml` — ควรมี autocomplete และ error underline
3. ตรวจ indentation เป็น space 2 หรือ 4 ช่องแบบสม่ำเสมอ
4. ถ้า schema ไม่ขึ้น ตรวจว่าไฟล์ขึ้นต้นด้วย `apiVersion` / `kind` ถูกต้อง

---

## 6. Lab 2: Pods with YAML

### เป้าหมาย Lab

- [ ] สร้าง Pod จาก YAML สำเร็จ (Status = Running)
- [ ] ใช้ `kubectl describe pod` หา error เมื่อ image ผิด
- [ ] ใช้ `kubectl delete -f` และ `kubectl apply -f` ได้

### ขั้นตอนที่ 1 — เตรียม cluster

```powershell
# เปิด Docker Desktop ก่อน
$minikube = "C:\Program Files\Kubernetes\Minikube\minikube.exe"
& $minikube start --driver=docker
kubectl get nodes
```

### ขั้นตอนที่ 2 — สร้าง Pod จาก YAML

```powershell
cd "D:\demo kubernates\day-02"
kubectl apply -f nginx-pod.yaml
kubectl get pods
kubectl describe pod nginx-pod
```

รอจน Status = **Running**

### ขั้นตอนที่ 3 — Debug ImagePullBackOff

```powershell
kubectl apply -f nginx-pod-broken.yaml
kubectl get pods
kubectl describe pod nginx-pod-broken
```

สังเกตใน Events ว่ามีข้อความเกี่ยวกับ image ไม่พบ / pull failed

จากนั้นลบและแก้ (หรือใช้ไฟล์ที่ถูกต้องแทน):

```powershell
kubectl delete -f nginx-pod-broken.yaml
```

### ขั้นตอนที่ 4 — delete / apply วนซ้ำ

```powershell
kubectl delete -f nginx-pod.yaml
kubectl get pods
kubectl apply -f nginx-pod.yaml
kubectl get pods -w
# กด Ctrl+C เมื่อเห็น Running
```

### รัน Lab อัตโนมัติ

```powershell
cd "D:\demo kubernates\day-02"
.\lab2-commands.ps1
```

### Cleanup

```powershell
kubectl delete -f nginx-pod.yaml --ignore-not-found
kubectl delete -f nginx-pod-broken.yaml --ignore-not-found
kubectl delete pod nginx --ignore-not-found
```

---

## 7. Review & Cheat Sheet

### สรุปวันที่ 2

| หัวข้อ | สิ่งที่ต้องจำ |
|-------|-------------|
| Pod | หน่วยเล็กสุดของ K8s, บรรจุ container |
| Imperative | `kubectl run` สั่งตรง |
| Declarative | YAML + `kubectl apply -f` |
| describe | ดู Events เพื่อ debug |
| ImagePullBackOff | ชื่อ image / tag / network ผิด |

### kubectl Cheat Sheet วันที่ 2

```bash
kubectl run <name> --image=<image>
kubectl apply -f <file.yaml>
kubectl delete -f <file.yaml>
kubectl get pods
kubectl get pods -o wide
kubectl describe pod <name>
kubectl logs <name>
kubectl delete pod <name>
```

### Checklist ผ่านวันที่ 2

- [ ] สร้าง Pod ด้วย `kubectl run` ได้
- [ ] สร้าง Pod จาก YAML ได้ (Running)
- [ ] อ่าน Events จาก `describe` เมื่อ image ผิดได้
- [ ] ใช้ `apply` / `delete -f` ได้
- [ ] อธิบาย `apiVersion`, `kind`, `metadata`, `spec` ได้

### เตรียมวันที่ 3

พรุ่งนี้เรียน **ReplicaSet** และ **Deployment** — self-healing และ rolling update

---

*วันที่ 2 | Module 2: ติดตั้ง Cluster & Pod / YAML Fundamentals*
