# วันที่ 4 — Networking, Services และ Microservices

> เป้าหมายวันนี้: เชื่อมต่อหลาย Pod ด้วย Service และ deploy Voting App จริงบน minikube

**ต้องมีจากวันที่ 1–3:** minikube พร้อม, เข้าใจ Pod / Deployment / labels / selector

---

## สารบัญ

1. [Basics of Networking](#1-basics-of-networking)
2. [Services — ClusterIP / NodePort / LoadBalancer](#2-services--clusterip--nodeport--loadbalancer)
3. [Demo & Lab 5: Services](#3-demo--lab-5-services)
4. [Microservices — Voting App](#4-microservices--voting-app)
5. [Lab 6: Voting App with Pods](#5-lab-6-voting-app-with-pods)
6. [Lab 7: Voting App with Deployments](#6-lab-7-voting-app-with-deployments)
7. [Review & Cheat Sheet](#7-review--cheat-sheet)

---

## โครงสร้างโฟลเดอร์วันนี้

```
day-04/
├── DAY4_GUIDE.md
├── web-deployment.yaml          ← Lab 5: nginx 3 replicas
├── web-service.yaml             ← Lab 5: NodePort 30080
├── web-service-broken.yaml      ← Lab 5: selector ผิด (ฝึก debug)
├── voting-pods/                 ← Lab 6: Pod + Service
├── voting-deployments/          ← Lab 7: Deployment + Service
├── lab5-commands.ps1
├── lab6-commands.ps1
├── lab7-commands.ps1
└── notes.md
```

---

## 1. Basics of Networking

### Pod มี IP ของตัวเอง

ทุก Pod ได้ IP ใน cluster (เช่น `10.244.x.x`) และ **Pod คุยกันได้โดยตรง**  
แต่ IP ของ Pod **เปลี่ยนได้** เมื่อ Pod ถูกสร้างใหม่ → แอปอื่นไม่ควรจำ IP

```
┌──────── Worker ────────┐
│  Pod A  10.244.1.5     │  ← IP เปลี่ยนได้เมื่อ recreate
│  Pod B  10.244.1.6     │
└────────────────────────┘
```

### ทำไมต้องมี Service?

**Service** = จุดเข้าถึงคงที่ (ชื่อ DNS + Cluster IP) ที่ชี้ไปยัง Pod กลุ่มหนึ่งผ่าน **selector / labels**

| โดยไม่มี Service | มี Service |
|------------------|------------|
| ต้องรู้ Pod IP | เรียกด้วยชื่อ เช่น `redis`, `db` |
| IP หายเมื่อ Pod ตาย | Endpoints อัปเดตอัตโนมัติ |
| ไม่กระจาย traffic | กระจายไปยัง Pod ที่ Ready |

---

## 2. Services — ClusterIP / NodePort / LoadBalancer

| ประเภท | เข้าจากภายนอก? | ใช้เมื่อ |
|--------|-----------------|---------|
| **ClusterIP** (default) | ไม่ | คุยภายใน cluster (redis, db) |
| **NodePort** | ได้ (พอร์ตบน Node เช่น 30080) | Lab / minikube / ทดสอบ |
| **LoadBalancer** | ได้ (External IP จาก Cloud) | Production บน GKE/EKS/AKS (Day 5) |

### ส่วนสำคัญใน YAML

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  selector:
    app: web          # ต้องตรงกับ labels ของ Pod
  ports:
  - port: 80          # พอร์ตของ Service ใน cluster
    targetPort: 80    # พอร์ตของ container
    nodePort: 30080   # พอร์ตบน Node (30000–32767)
```

> ถ้า `selector` ไม่ตรงกับ `labels` → **Endpoints ว่าง** → เข้า Service ไม่ได้ (ฝึกใน Lab 5)

---

## 3. Demo & Lab 5: Services

### Lab 5 Checklist

- [ ] Deployment `web` มี 3 replicas Running
- [ ] Service `web-service` มี Endpoints
- [ ] เข้าหน้า nginx ผ่าน NodePort / `minikube service` ได้
- [ ] debug Service ที่ selector ผิดได้

### ขั้นตอน

```powershell
cd "D:\demo kubernates\day-04"

# สร้าง Deployment + Service
kubectl apply -f web-deployment.yaml
kubectl apply -f web-service.yaml

kubectl get deploy,pods,svc -l app=web
kubectl get endpoints web-service

# เปิดในเบราว์เซอร์ (minikube จะให้ URL)
minikube service web-service --url

# Debug: selector ผิด → Endpoints ว่าง
kubectl apply -f web-service-broken.yaml
kubectl get endpoints web-service-broken
kubectl describe svc web-service-broken
```

**รันอัตโนมัติ:** `.\lab5-commands.ps1`

---

## 4. Microservices — Voting App

### Architecture

```
Browser
   │
   ├── NodePort :31000 ──► vote (Python) ──► redis (ClusterIP)
   │                                            │
   │                                         worker (.NET)
   │                                            │
   └── NodePort :31001 ──► result (Node.js) ◄── db/postgres (ClusterIP)
```

| Component | Tech | Service type | หน้าที่ |
|-----------|------|--------------|---------|
| **vote** | Python | NodePort | หน้าโหวต |
| **redis** | Redis | ClusterIP | คิวชั่วคราว |
| **worker** | .NET | (ไม่มี) | ย้ายโหวต Redis → Postgres |
| **db** | Postgres | ClusterIP | เก็บผลโหวต |
| **result** | Node.js | NodePort | แสดงผล |

> ชื่อ Service สำคัญ: แอปเรียก `redis` และ `db` ผ่าน DNS ใน cluster

---

## 5. Lab 6: Voting App with Pods

### Lab 6 Checklist

- [ ] Pod ทั้งหมด Status = Running
- [ ] Vote ผ่าน browser ได้
- [ ] ผลโหวตขึ้นใน Result UI

### ขั้นตอน

```powershell
cd "D:\demo kubernates\day-04"

# ล้างของ Lab 5 ก่อน (optional)
kubectl delete -f web-deployment.yaml,web-service.yaml,web-service-broken.yaml --ignore-not-found

# Deploy ทีละชั้น: datastore → worker → frontends
kubectl apply -f voting-pods/

kubectl get pods,svc
kubectl get endpoints

# เปิด Vote / Result
minikube service vote --url
minikube service result --url
```

**รันอัตโนมัติ:** `.\lab6-commands.ps1`

### ข้อจำกัดของ Pod เดี่ยว

ลบ Pod แล้ว **ไม่มีใครสร้างใหม่** → ไม่มี self-healing  
Lab 7 จะแก้ด้วย Deployment

---

## 6. Lab 7: Voting App with Deployments

### Lab 7 Checklist

- [ ] ใช้ Deployment แทน Pod
- [ ] Vote / Result ทำงานเหมือน Lab 6
- [ ] ลบ Pod แล้ว self-heal (สร้างใหม่เอง)
- [ ] scale `vote` ได้

### ขั้นตอน

```powershell
cd "D:\demo kubernates\day-04"

# ลบ Pod-based ก่อน (ชื่อ resource ชนกัน)
kubectl delete -f voting-pods/ --ignore-not-found

# Deploy แบบ Deployment
kubectl apply -f voting-deployments/

kubectl get deploy,pods,svc
kubectl rollout status deployment/vote
kubectl rollout status deployment/result

# Self-healing
$pod = kubectl get pods -l app=vote -o jsonpath="{.items[0].metadata.name}"
kubectl delete pod $pod
kubectl get pods -l app=vote

# Scale
kubectl scale deployment vote --replicas=3
kubectl get pods -l app=vote

minikube service vote --url
minikube service result --url
```

**รันอัตโนมัติ:** `.\lab7-commands.ps1`

---

## 7. Review & Cheat Sheet

| หัวข้อ | สิ่งที่ต้องจำ |
|-------|-------------|
| Pod IP | เปลี่ยนได้ — อย่า hardcode |
| Service | จุดเข้าถึงคงที่ + เลือก Pod ด้วย selector |
| ClusterIP | ภายใน cluster เท่านั้น |
| NodePort | เปิดพอร์ตบน Node (lab/local) |
| LoadBalancer | Cloud ให้ External IP (Day 5) |
| Endpoints ว่าง | ตรวจ labels ↔ selector |

### คำสั่งที่ใช้บ่อยวันนี้

```powershell
kubectl get svc,endpoints -o wide
kubectl describe svc <name>
kubectl get pods -o wide                    # ดู Pod IP
minikube service <svc> --url
kubectl apply -f voting-deployments/
kubectl scale deployment vote --replicas=3
```

### Cleanup

```powershell
kubectl delete -f web-deployment.yaml,web-service.yaml,web-service-broken.yaml --ignore-not-found
kubectl delete -f voting-pods/ --ignore-not-found
kubectl delete -f voting-deployments/ --ignore-not-found
```

### เตรียมวันที่ 5

- Voting App บน minikube ผ่านแล้ว
- Day 5 จะ deploy ขึ้น Cloud ด้วย `type: LoadBalancer` (ดู `day-05/voting-app/`)

---

*อ้างอิง: TEACHING_PLAN.md § วันที่ 4, COURSE_CONTENT.txt*  
*Images: dockersamples/example-voting-app*
