# วันที่ 10 — Helm, Kustomize, RBAC & Network Policy

> เป้าหมายวันนี้: ส่งมอบแอปแบบทีม — chart/overlay และจำกัดสิทธิ dev

**อ้างอิง COURSE_CONTENT_2:** Helm, Kustomize overlays, RBAC, Network Policy

---

## สารบัญ

1. [Helm พื้นฐาน](#1-helm)
2. [Kustomize base + overlay](#2-kustomize)
3. [RBAC สำหรับ dev team](#3-rbac)
4. [Network Policy ง่าย ๆ](#4-network-policy)
5. [Lab 15–16 & โปรเจกต์สรุป](#5-labs)
6. [Phase 2 ปิดคอร์ส](#6-ปิดคอร์ส)

---

## โครงสร้างโฟลเดอร์

```
day-10/
├── DAY10_GUIDE.md
├── lab15-helm.ps1
├── voting-prod-like/
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   └── vote-deployment.yaml
│   ├── overlays/
│   │   ├── dev/
│   │   │   └── kustomization.yaml
│   │   └── prod/
│   │       └── kustomization.yaml
│   ├── rbac-dev-editor.yaml
│   └── network-policy-db.yaml
├── lab16-kustomize-rbac.ps1
└── notes.md
```

---

## 1. Helm

```powershell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm search repo nginx
helm install my-nginx bitnami/nginx --set replicaCount=2
helm list
helm upgrade my-nginx bitnami/nginx --set replicaCount=3
helm rollback my-nginx 1
helm uninstall my-nginx
```

**งานจริง:** chart ของทีม + values ต่อ env ใน CI

---

## 2. Kustomize

```bash
kubectl apply -k voting-prod-like/overlays/dev
kubectl kustomize voting-prod-like/overlays/prod
```

- **base** — manifest ร่วม
- **overlay** — patch replicas, image tag, namespace

---

## 3. RBAC

```yaml
# Role (ใน namespace) + RoleBinding → User/Group/ServiceAccount
kind: Role
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "create", "delete"]
```

ทดสอบ: `kubectl auth can-i create deployment --as=dev-user -n voting-dev`

---

## 4. Network Policy

ต้องมี CNI รองรับ (minikube default มักใช้ได้) — จำกัดให้เฉพาะ Pod ที่มี label `app: worker` เข้า db port 5432

---

## 5. Labs

```powershell
.\lab15-helm.ps1
.\lab16-kustomize-rbac.ps1
```

**โปรเจกต์สรุด Phase 2:** ดู `TEACHING_PLAN_PHASE2.md` § โปรเจกต์สรุป

---

## 6. ปิดคอร์ส

| ต่อไป (ถ้าต้องการ) | ไม่จำเป็นสำหรับงาน app ทั่วไป |
|---------------------|-------------------------------|
| GitOps (Argo CD / Flux) | CKA mock exam |
| Observability (Prometheus/Grafana) | kubeadm upgrade |
| Platform (Istio, service mesh) | เขียน Operator |

คุณพร้อมดูแล Voting App บน cluster ทีม: config, storage, ingress, scale, สิทธิ์พื้นฐาน
