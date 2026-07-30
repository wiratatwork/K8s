# วันที่ 6 — Configuration & Isolation (ConfigMap, Secret, Namespace)

> เป้าหมายวันนี้: แยก config/รหัสผ่านออกจาก YAML แอป และแยกทีม/สภาพแวดล้อมด้วย Namespace

**ต้องมีจาก Phase 1:** minikube, Voting App หรือ nginx deployment, เข้าใจ `kubectl apply`

**อ้างอิง COURSE_CONTENT_2:** Namespaces, Configuring ConfigMaps, Secrets, Application Configuration

---

## สารบัญ

1. [ทบทวน 10 นาที](#1-ทบทวน-10-นาที)
2. [Namespaces](#2-namespaces)
3. [ConfigMaps](#3-configmaps)
4. [Secrets](#4-secrets)
5. [Lab 9: Config + Secret + Namespace](#5-lab-9)
6. [Review & Cheat Sheet](#6-review--cheat-sheet)

---

## โครงสร้างโฟลเดอร์วันนี้

```
day-06/
├── DAY6_GUIDE.md
├── namespace-voting.yaml
├── vote-configmap.yaml
├── db-secret.yaml          ← ตัวอย่าง — อย่า commit รหัส production จริง
├── vote-deployment-config.yaml
├── lab9-commands.ps1
└── notes.md
```

---

## 1. ทบทวน 10 นาที

| คำถาม | คำตอบสั้น |
|--------|-----------|
| Deployment vs Pod? | Deployment จัด replica + rolling update |
| Service ทำไม? | DNS + IP คงที่, endpoints ตาม label |
| ทำไมไม่ hard-code ใน image? | เปลี่ยน env ต่อ dev/staging/prod โดยไม่ build ใหม่ |

---

## 2. Namespaces

- **default** — งานทั่วไป (เริ่มต้น)
- **kube-system** — ระบบ cluster (CoreDNS, proxy, …)
- สร้างของทีม: `voting-dev`, `voting-staging`

```bash
kubectl create namespace voting-dev
kubectl get ns
kubectl -n voting-dev get pods
```

**DNS ข้าม namespace:** `db.voting-dev.svc.cluster.local`

---

## 3. ConfigMaps

เก็บ config ไม่ลับ (สี UI, feature flag, `config.json`)

**แบบ env:**

```yaml
envFrom:
- configMapRef:
    name: vote-config
```

**แบบไฟล์ใน Pod:**

```yaml
volumeMounts:
- name: config-vol
  mountPath: /etc/config
volumes:
- name: config-vol
  configMap:
    name: vote-config
```

---

## 4. Secrets

เก็บรหัสผ่าน, token — ใน etcd เป็น base64 (ไม่ใช่ encryption โดยอัตโนมัติทุก cluster)

```yaml
env:
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: password
```

**ในงานจริง:** ใช้ External Secrets / Vault / cloud secret manager; ใน lab ใช้ `kubectl create secret generic`

---

## 5. Lab 9

รัน:

```powershell
cd "c:\Data\Drive D\K8s\day-06"
.\lab9-commands.ps1
```

**เกณฑ์ผ่าน:**

- [ ] มี namespace `voting-dev`
- [ ] Pod vote อ่านค่าจาก ConfigMap ได้ (`kubectl exec` ดู env)
- [ ] db deployment ใช้ password จาก Secret
- [ ] ลบ ConfigMap แล้ว Pod ใหม่ fail ชัดเจน (เข้าใจ dependency)

---

## 6. Review & Cheat Sheet

```bash
kubectl create configmap vote-config --from-literal=OPTION_A=Cats --dry-run=client -o yaml
kubectl create secret generic db-secret --from-literal=password=devpass --dry-run=client -o yaml
kubectl apply -f namespace-voting.yaml
kubectl apply -n voting-dev -f vote-configmap.yaml
kubectl get cm,secret -n voting-dev
```

**งานจริง:** แยก manifest ตาม namespace ใน CI; secret มาจาก pipeline ไม่ใช่ git
