# วันที่ 1 — พื้นฐาน Container และ Kubernetes Architecture

> เป้าหมายวันนี้: เข้าใจ "ทำไมต้องใช้ Kubernetes" และรัน cluster แรกได้ด้วยตัวเอง

---

## สารบัญ

1. [แนะนำหลักสูตร & Lab Environment](#1-แนะนำหลักสูตร--lab-environment)
2. [Containers Overview](#2-containers-overview)
3. [Container Orchestration](#3-container-orchestration)
4. [Kubernetes Architecture](#4-kubernetes-architecture)
5. [Docker vs containerd & CRI](#5-docker-vs-containerd--cri)
6. [Lab 1: Minikube Setup](#6-lab-1-minikube-setup)
7. [Review & Cheat Sheet](#7-review--cheat-sheet)

---

## 1. แนะนำหลักสูตร & Lab Environment

### โครงสร้างโฟลเดอร์ Lab

```
k8s-labs/
└── day-01/
    ├── DAY1_GUIDE.md          ← คุณอยู่ที่นี่
    ├── lab1-commands.ps1      ← สคริปต์ Lab 1
    └── notes.md               ← จดบันทึกส่วนตัว
```

### เครื่องมือที่ใช้วันนี้

| เครื่องมือ | หน้าที่ |
|-----------|--------|
| **Docker Desktop** | รัน container runtime บนเครื่อง |
| **minikube** | สร้าง Kubernetes cluster ท้องถิ่น |
| **kubectl** | สั่งงาน cluster (CLI หลัก) |

### ตรวจสอบเครื่องมือ

```powershell
docker version
kubectl version --client
minikube version
```

---

## 2. Containers Overview

### Container คืออะไร?

**Container** คือแพ็กเกจที่รวม application + dependencies ทั้งหมดไว้ด้วยกัน ทำให้รันได้เหมือนกันทุกที่

```
┌─────────────────────────────────┐
│         Container               │
│  ┌───────────────────────────┐  │
│  │   Application (nginx)     │  │
│  ├───────────────────────────┤  │
│  │   Libraries / Runtime     │  │
│  ├───────────────────────────┤  │
│  │   OS (shared kernel)      │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### Image vs Container

| คำศัพท์ | ความหมาย | เปรียบเทียบ |
|---------|----------|------------|
| **Image** | Template อ่านอย่างเดียว (read-only) | เหมือน "แม่พิมพ์" |
| **Container** | Instance ที่รันจาก Image | เหมือน "ของที่พิมพ์ออกมา" |

### ทดลอง Docker พื้นฐาน (Optional)

```powershell
# ดึง image
docker pull nginx:latest

# รัน container
docker run -d -p 8080:80 --name my-nginx nginx:latest

# ทดสอบใน browser: http://localhost:8080

# ดู container ที่รันอยู่
docker ps

# หยุดและลบ
docker stop my-nginx
docker rm my-nginx
```

### ทำไม Container ถึงสำคัญ?

- **Portable** — รันได้ทุกที่ (laptop, server, cloud)
- **Isolated** — แอปไม่รบกวนกัน
- **Lightweight** — เร็วกว่า VM เพราะแชร์ kernel
- **Consistent** — "works on my machine" หายไป

---

## 3. Container Orchestration

### ปัญหาเมื่อมี Container หลายตัว

เมื่อแอปโตขึ้น คุณอาจมี container หลายสิบ/หลายร้อยตัว ปัญหาที่เกิด:

| ปัญหา | คำถาม |
|-------|-------|
| Scaling | จะเพิ่ม/ลด container อย่างไร? |
| Load Balancing | กระจาย traffic ไป container ไหน? |
| Self-healing | container ตายแล้วจะ restart เองไหม? |
| Networking | container คุยกันอย่างไร? |
| Updates | อัปเดตแอปโดยไม่ downtime อย่างไร? |

### Kubernetes แก้ปัญหาอย่างไร?

**Kubernetes (K8s)** = Container Orchestrator โอเพนซอร์ส ที่ Google สร้างและส่งต่อให้ CNCF

```
คุณบอก K8s ว่า "ต้องการ nginx 3 ตัว"
         ↓
K8s จัดการทุกอย่างให้เอง:
  ✓ สร้าง container 3 ตัว
  ✓ กระจายไปหลาย node
  ✓ restart อัตโนมัติเมื่อตาย
  ✓ อัปเดตแบบ rolling (ไม่ downtime)
```

### Declarative vs Imperative

| แบบ | ตัวอย่าง | แนวคิด |
|-----|---------|--------|
| **Imperative** | `kubectl run nginx --image=nginx` | บอก "ทำอะไร" |
| **Declarative** | สร้าง YAML แล้ว `kubectl apply -f` | บอก "ต้องการสถานะแบบไหน" |

> หลักสูตรนี้เน้น **Declarative (YAML)** เป็นหลัก ตั้งแต่วันที่ 2 เป็นต้นไป

---

## 4. Kubernetes Architecture

### ภาพรวม Cluster

```
┌─────────────────── Kubernetes Cluster ───────────────────┐
│                                                         │
│  ┌──────────── Control Plane (Master) ──────────────┐  │
│  │                                                   │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │  │
│  │  │ API      │ │ Scheduler│ │ Controller       │  │  │
│  │  │ Server   │ │          │ │ Manager          │  │  │
│  │  └────┬─────┘ └──────────┘ └──────────────────┘  │  │
│  │       │                                           │  │
│  │  ┌────▼─────┐                                     │  │
│  │  │  etcd    │  ← ฐานข้อมูล cluster (key-value)   │  │
│  │  └──────────┘                                     │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────── Worker Node(s) ──────────────────────┐  │
│  │                                                   │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐       │  │
│  │  │  Pod     │  │  Pod     │  │  Pod     │       │  │
│  │  │ (nginx)  │  │ (nginx)  │  │ (app)    │       │  │
│  │  └──────────┘  └──────────┘  └──────────┘       │  │
│  │                                                   │  │
│  │  kubelet ← ตัวแทน K8s บน node, จัดการ pod        │  │
│  │  kube-proxy ← จัดการ network                      │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### องค์ประกอบสำคัญ

| องค์ประกอบ | บทบาท |
|-----------|--------|
| **API Server** | ประตูหลัก — kubectl คุยกับตัวนี้ |
| **etcd** | เก็บ state ทั้งหมดของ cluster |
| **Scheduler** | เลือก node ที่จะวาง pod |
| **Controller Manager** | ดูแลให้ cluster ตรงตามที่ประกาศไว้ |
| **kubelet** | Agent บน worker node จัดการ pod |
| **kube-proxy** | จัดการ network rules |

### kubectl ทำงานอย่างไร?

```
คุณพิมพ์: kubectl get pods
     ↓
kubectl → API Server → etcd
     ↓
แสดงผล list ของ pods
```

### คำถามทบทวน (ตอบใน notes.md)

1. Control Plane กับ Worker Node ต่างกันอย่างไร?
2. ถ้า etcd พัง จะเกิดอะไรขึ้น?
3. kubectl คุยกับ component ไหนโดยตรง?

---

## 5. Docker vs containerd & CRI

### ประวัติสั้น ๆ

```
เดิม:  Kubernetes → Docker (runtime เดียว)
ตอนนี้: Kubernetes → CRI (Container Runtime Interface) → containerd, CRI-O, ...
```

### CRI คืออะไร?

**CRI** = มาตรฐาน interface ให้ Kubernetes คุยกับ container runtime ได้หลายตัว

```
Kubernetes
    │
    ▼ (CRI)
┌─────────┬─────────┬─────────┐
│containerd│ CRI-O  │  ...    │
└─────────┴─────────┴─────────┘
```

### Docker ยังใช้ได้ไหม?

| ใช้สำหรับ | สถานะ |
|----------|-------|
| พัฒนาแอป (build image, docker run) | ✅ ใช้ได้ดี |
| Runtime ของ Kubernetes node | ❌ ถูกแทนด้วย containerd |

> **สรุป:** ใช้ Docker สร้าง image → push ขึ้น registry → Kubernetes ดึงมารันด้วย containerd

### เครื่องมือ debug runtime

```bash
# บน node จริง (Linux)
crictl ps          # ดู containers ผ่าน CRI
crictl logs <id>   # ดู logs
nerdctl ps         # CLI คล้าย docker สำหรับ containerd
```

---

## 6. Lab 1: Minikube Setup

### เป้าหมาย Lab

- [ ] เริ่ม minikube cluster สำเร็จ
- [ ] Node status = Ready
- [ ] Deploy hello-minikube และเข้าถึงได้
- [ ] อธิบาย Master vs Worker ได้

### ขั้นตอนที่ 1 — เริ่ม Cluster

```powershell
# ใช้ Docker เป็น driver (ต้องเปิด Docker Desktop ก่อน)
minikube start --driver=docker

# ตรวจสอบ
minikube status
kubectl get nodes
kubectl cluster-info
```

**ผลลัพธ์ที่คาดหวัง:**
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.x.x
```

### ขั้นตอนที่ 2 — Deploy แอปแรก

```powershell
kubectl create deployment hello-minikube --image=registry.k8s.io/echoserver:1.10

kubectl get deployments
kubectl get pods
```

### ขั้นตอนที่ 3 — Expose Service

```powershell
kubectl expose deployment hello-minikube --type=NodePort --port=8080

kubectl get services
minikube service hello-minikube --url
```

เปิด URL ที่ได้ใน browser — ควรเห็นข้อมูล request

### ขั้นตอนที่ 4 — สำรวจเพิ่มเติม

```powershell
# ดูรายละเอียด deployment
kubectl describe deployment hello-minikube

# ดู logs
kubectl logs -l app=hello-minikube

# ดู dashboard (optional)
minikube dashboard
```

### ขั้นตอนที่ 5 — ทำความสะอาด (เมื่อจบ Lab)

```powershell
kubectl delete deployment hello-minikube
kubectl delete service hello-minikube
# minikube stop    ← หยุด cluster (ยังเก็บ state)
# minikube delete  ← ลบ cluster ทั้งหมด
```

### รัน Lab อัตโนมัติ

```powershell
cd "D:\demo kubernates\day-01"
.\lab1-commands.ps1
```

---

## 7. Review & Cheat Sheet

### สรุปวันที่ 1

| หัวข้อ | สิ่งที่ต้องจำ |
|-------|-------------|
| Container | แพ็กเกจ app + deps, portable, isolated |
| Orchestration | จัดการ container หลายตัว — scaling, healing, networking |
| Kubernetes | Control Plane + Worker Nodes |
| kubectl | CLI สั่งงาน cluster ผ่าน API Server |
| minikube | Cluster ท้องถิ่นสำหรับเรียน/ทดสอบ |

### kubectl Cheat Sheet วันที่ 1

```bash
kubectl get nodes                    # ดู nodes
kubectl get pods                     # ดู pods
kubectl get deployments              # ดู deployments
kubectl get services                 # ดู services
kubectl describe <type> <name>       # รายละเอียด + events
kubectl logs <pod-name>              # ดู logs
kubectl cluster-info                 # ข้อมูล cluster
```

### Checklist ผ่านวันที่ 1

- [ ] Cluster status = Ready
- [ ] เข้าถึง hello-minikube ผ่าน browser ได้
- [ ] อธิบายบทบาท Master vs Worker node ได้
- [ ] รู้ความต่าง Image vs Container
- [ ] รู้ว่า kubectl คุยกับ API Server

### เตรียมวันที่ 2

พรุ่งนี้จะเรียน **Pod** และ **YAML** — อ่านล่วงหน้าได้ที่ `TEACHING_PLAN.md` ส่วนวันที่ 2

---

*วันที่ 1 | Module 1: พื้นฐาน Container & K8s Architecture*
