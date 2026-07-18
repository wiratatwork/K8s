# วันที่ 5 — Kubernetes on Cloud & สรุปหลักสูตร

> เป้าหมายวันนี้: Deploy Voting App ขึ้น Managed Kubernetes (GKE / EKS / AKS) ได้ และรู้เส้นทางเรียนต่อ

**ต้องมีจากวันที่ 1–4:** เข้าใจ Pod, Deployment, Service — และ Voting App บน minikube  
**หมายเหตุ:** ถ้ายังไม่มีโฟลเดอร์ Day 4 ใช้ manifests ใน `voting-app/` ของวันนี้ได้เลย (ปรับเป็น LoadBalancer สำหรับ Cloud)

---

## สารบัญ

1. [Kubernetes on Cloud — Introduction](#1-kubernetes-on-cloud--introduction)
2. [เลือก Cloud หนึ่งตัว (Lab 8)](#2-เลือก-cloud-หนึ่งตัว-lab-8)
3. [Lab 8a: GKE (GCP)](#3-lab-8a-gke-gcp)
4. [Lab 8b: EKS (AWS)](#4-lab-8b-eks-aws)
5. [Lab 8c: AKS (Azure)](#5-lab-8c-aks-azure)
6. [Best Practices & Next Steps](#6-best-practices--next-steps)
7. [โปรเจกต์สรุป / สอบปฏิบัติ](#7-โปรเจกต์สรุป--สอบปฏิบัติ)
8. [สรุปหลักสูตร & Cheat Sheet](#8-สรุปหลักสูตร--cheat-sheet)

---

## โครงสร้างโฟลเดอร์วันนี้

```
day-05/
├── DAY5_GUIDE.md              ← คุณอยู่ที่นี่
├── voting-app/                ← manifests สำหรับ Cloud (LoadBalancer)
│   ├── redis-deployment.yaml
│   ├── redis-service.yaml
│   ├── db-deployment.yaml
│   ├── db-service.yaml
│   ├── vote-deployment.yaml
│   ├── vote-service.yaml      ← type: LoadBalancer
│   ├── result-deployment.yaml
│   ├── result-service.yaml    ← type: LoadBalancer
│   └── worker-deployment.yaml
├── lab8-gke.ps1
├── lab8-eks.ps1
├── lab8-aks.ps1
├── cleanup-cloud.ps1          ← ลบ resources หลัง Lab (สำคัญ!)
└── notes.md
```

---

## 1. Kubernetes on Cloud — Introduction

### Self-hosted vs Managed

| | Self-hosted (minikube / kubeadm) | Managed (GKE / EKS / AKS) |
|--|----------------------------------|---------------------------|
| **ใครดูแล Control Plane** | คุณเอง | Cloud Provider |
| **อัปเกรด / แพตช์** | ทำเอง | Provider ช่วย |
| **เหมาะกับ** | เรียน, ทดลอง, on-prem | Production |
| **ค่าใช้จ่าย** | เครื่องคุณ | จ่ายตาม node + LB |
| **kubectl** | ใช้ได้เหมือนกัน | ใช้ได้เหมือนกัน |

> **Concept เดียวกันทั้ง 3 Cloud:** สร้าง cluster → ตั้งค่า kubectl → `kubectl apply` → Service แบบ **LoadBalancer** → ได้ URL สาธารณะ

### เปรียบเทียบสั้น ๆ

| Cloud | บริการ | CLI | จุดเด่นสำหรับ Lab |
|-------|--------|-----|-------------------|
| **GCP** | GKE | `gcloud` | สร้างง่าย, LB เร็ว |
| **AWS** | EKS | `aws` + `eksctl` | ใช้ในองค์กรเยอะ |
| **Azure** | AKS | `az` | Cloud Shell สะดวก |

### สิ่งที่เปลี่ยนจาก minikube

| ท้องถิ่น (Day 1–4) | Cloud (Day 5) |
|--------------------|---------------|
| `type: NodePort` + `minikube service` | `type: LoadBalancer` → ได้ External IP |
| Cluster ฟรีบนเครื่อง | **ต้องลบหลัง Lab** ไม่เช่นนั้นคิดเงิน |
| Driver = Docker Desktop | Provider สร้าง Worker nodes ให้ |

---

## 2. เลือก Cloud หนึ่งตัว (Lab 8)

ตามแผนสอน: **เลือกทำ Lab 8 เพียง Cloud เดียว** ตามบัญชีที่มี

### Lab 8 Checklist (ทุก Cloud)

- [ ] Cluster สถานะ Ready (`kubectl get nodes`)
- [ ] Voting App เข้าถึงได้ผ่าน LoadBalancer URL (Vote + Result)
- [ ] โหวตแล้วผลขึ้นใน Result UI
- [ ] ลบ resources / ลบ cluster หลังจบ (cost control)

### Architecture ที่จะ Deploy

```
Internet
   │
   ├── LoadBalancer ──► vote pods (Python) ──► redis (ClusterIP)
   │                                              │
   │                                         worker
   │                                              │
   └── LoadBalancer ──► result pods (Node.js) ◄── db/postgres (ClusterIP)
```

---

## 3. Lab 8a: GKE (GCP)

### สิ่งที่ต้องมี

- บัญชี [Google Cloud](https://console.cloud.google.com/) (มี Free Trial / credits)
- ติดตั้ง [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud`)
- เปิด Billing + API: Kubernetes Engine API

### ขั้นตอนหลัก

```powershell
# 1) Login + เลือก project
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud config set compute/zone asia-southeast1-b

# 2) สร้าง cluster (ใช้เวลา ~5–10 นาที)
gcloud container clusters create voting-gke `
  --num-nodes=2 `
  --machine-type=e2-medium `
  --zone=asia-southeast1-b

# 3) ดึง credentials ให้ kubectl
gcloud container clusters get-credentials voting-gke --zone=asia-southeast1-b

# 4) Deploy Voting App
kubectl apply -f voting-app/

# 5) รอ External IP
kubectl get svc -w
# รอจน vote และ result มี EXTERNAL-IP (ไม่ใช่ <pending>)

# 6) เปิดเบราว์เซอร์ที่ EXTERNAL-IP ของ vote และ result
```

หรือรันสคริปต์:

```powershell
cd "d:\demo kubernates\day-05"
.\lab8-gke.ps1 -ProjectId "YOUR_PROJECT_ID"
```

### Cleanup (สำคัญ!)

```powershell
kubectl delete -f voting-app/
gcloud container clusters delete voting-gke --zone=asia-southeast1-b --quiet
```

---

## 4. Lab 8b: EKS (AWS)

### สิ่งที่ต้องมี

- บัญชี [AWS](https://aws.amazon.com/)
- ติดตั้ง [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) + [eksctl](https://eksctl.io/)
- ตั้งค่า `aws configure` (Access Key, Secret, Region เช่น `ap-southeast-1`)

### ขั้นตอนหลัก

```powershell
# 1) สร้าง cluster + node group (ใช้เวลา ~15–20 นาที)
eksctl create cluster `
  --name voting-eks `
  --region ap-southeast-1 `
  --nodes 2 `
  --node-type t3.medium `
  --managed

# 2) ตรวจว่า kubectl ชี้ไปที่ EKS แล้ว
kubectl get nodes

# 3) Deploy
kubectl apply -f voting-app/

# 4) รอ EXTERNAL-IP / hostname ของ LoadBalancer
kubectl get svc -w
```

หรือ:

```powershell
.\lab8-eks.ps1
```

### Cleanup

```powershell
kubectl delete -f voting-app/
eksctl delete cluster --name voting-eks --region ap-southeast-1
```

> EKS + ELB คิดเงินเร็ว — ลบทันทีหลัง Lab

---

## 5. Lab 8c: AKS (Azure)

### สิ่งที่ต้องมี

- บัญชี [Azure](https://portal.azure.com/)
- ติดตั้ง [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az`)  
  หรือใช้ **Azure Cloud Shell** ในเบราว์เซอร์ (ไม่ต้องติดตั้ง)

### ขั้นตอนหลัก

```powershell
# 1) Login
az login
az account set --subscription "YOUR_SUBSCRIPTION"

# 2) Resource group + AKS
az group create --name voting-rg --location southeastasia

az aks create `
  --resource-group voting-rg `
  --name voting-aks `
  --node-count 2 `
  --node-vm-size Standard_B2s `
  --generate-ssh-keys

# 3) ดึง credentials
az aks get-credentials --resource-group voting-rg --name voting-aks

# 4) Deploy
kubectl apply -f voting-app/
kubectl get svc -w
```

หรือ:

```powershell
.\lab8-aks.ps1
```

### Cleanup

```powershell
kubectl delete -f voting-app/
az group delete --name voting-rg --yes --no-wait
```

---

## 6. Best Practices & Next Steps

หัวข้อที่คอร์สนี้ยังไม่ได้ลงลึก — เป็นเส้นทางเรียนต่อ:

| หัวข้อ | ทำไมสำคัญ | เริ่มจาก |
|--------|-----------|----------|
| **ConfigMaps / Secrets** | แยก config และรหัสผ่านออกจาก YAML | [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) |
| **Ingress** | รวม HTTP routing แทน LB หลายตัว | nginx Ingress / cloud Ingress |
| **Helm** | แพ็กเกจแอปเป็น chart ติดตั้งซ้ำได้ | `helm install` |
| **CI/CD** | push code → build image → deploy อัตโนมัติ | GitHub Actions + kubectl/Helm |
| **Observability** | metrics, logs, traces | Prometheus, Grafana, Loki |
| **RBAC / NetworkPolicy** | จำกัดสิทธิ์และ traffic | เอกสาร official |

### สิ่งที่ทำได้ทันทีหลังคอร์ส

1. Deploy Voting App บน Cloud ที่เลือก (โปรเจกต์สรุป)
2. ลองเปลี่ยน `replicas` แล้วดู self-healing / scale
3. ลอง `kubectl rollout undo` บน Cloud เหมือน Day 3
4. อ่าน kubectl Cheat Sheet อย่างน้อยสัปดาห์ละครั้ง

---

## 7. โปรเจกต์สรุป / สอบปฏิบัติ

**โจทย์:** Deploy Voting App บน Managed Kubernetes (เลือก GKE, EKS หรือ AKS) ภายในเวลาที่กำหนด

### Deliverables

1. YAML manifests ทั้งหมด (Deployment + Service) — ใช้โฟลเดอร์ `voting-app/` ได้
2. Screenshot แอปทำงานผ่าน LoadBalancer URL (หน้า Vote + หน้า Result)
3. คำตอบสั้น ๆ 3 ข้อ:
   - Pod กับ Deployment ต่างกันอย่างไร?
   - Service แบบ NodePort กับ LoadBalancer ใช้เมื่อไหร่?
   - จะ rollback deployment อย่างไร?

### คำใบ้คำตอบ (ตรวจหลังทำเอง)

| คำถาม | ทิศทางคำตอบ |
|-------|------------|
| Pod vs Deployment | Pod = หน่วยรัน; Deployment = จัดการ replicas, rolling update, rollback |
| NodePort vs LB | NodePort = เปิดพอร์ตบน node (lab/local); LB = cloud สร้าง balancer + IP สาธารณะ |
| Rollback | `kubectl rollout undo deployment/<name>` หรือ `--to-revision=N` |

---

## 8. สรุปหลักสูตร & Cheat Sheet

### สิ่งที่เรียนครบ 5 วัน

```
Day 1  Container + Architecture + minikube
Day 2  Pod + YAML
Day 3  ReplicaSet + Deployment + Rollback
Day 4  Service + Voting App (local)
Day 5  Managed Cloud (GKE/EKS/AKS) + สรุป
```

### kubectl ที่ต้องจำ

```powershell
# สถานะ
kubectl get nodes,pods,deploy,svc -o wide
kubectl describe pod <name>
kubectl logs <pod>

# Deploy
kubectl apply -f voting-app/
kubectl delete -f voting-app/

# Scale / Rollout
kubectl scale deployment vote --replicas=3
kubectl rollout status deployment/vote
kubectl rollout history deployment/vote
kubectl rollout undo deployment/vote

# Debug
kubectl get endpoints
kubectl exec -it <pod> -- /bin/sh
```

### เกณฑ์ผ่าน Lab 8

- [ ] Cluster บน Cloud สถานะ Ready
- [ ] Voting App เข้าถึงได้ผ่าน LoadBalancer URL
- [ ] ลบ resources หลัง Lab เสร็จ (cost control)

---

## คำสั่ง Cleanup รวดเร็ว

```powershell
cd "d:\demo kubernates\day-05"
.\cleanup-cloud.ps1 -Provider gke   # หรือ eks / aks
```

> **อย่าลืม:** Cloud cluster ที่ลืมลบ = ค่าใช้จ่ายสะสมทุกชั่วโมง

---

*อ้างอิง: TEACHING_PLAN.md § วันที่ 5, COURSE_CONTENT.txt (Kubernetes on Cloud)*  
*Voting App images: dockersamples/example-voting-app*
