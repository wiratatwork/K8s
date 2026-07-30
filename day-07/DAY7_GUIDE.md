# วันที่ 7 — Workloads แบบใช้งานจริง (Resources, Probes, HPA, Logs)

> เป้าหมายวันนี้: แอปไม่ล้มเงียบ ๆ, รู้ resource ที่ใช้จริง, scale ตาม CPU

**ต้องมี:** day-06 หรือ deployment vote ใน namespace ใดก็ได้

**อ้างอิง COURSE_CONTENT_2:** Resource Requirements, Rolling Updates, Monitor Cluster Components, HPA, Managing Application Logs

---

## สารบัญ

1. [ทบทวน Deployment rollout](#1-ทบทวน)
2. [requests / limits](#2-requests--limits)
3. [Liveness & Readiness probes](#3-probes)
4. [metrics-server & kubectl top](#4-metrics-server)
5. [Horizontal Pod Autoscaler](#5-hpa)
6. [Logs](#6-logs)
7. [Lab 10–11](#7-lab-10-11)
8. [อ่านเพิ่ม: Taints & DaemonSet](#8-อ่านเพิ่ม)

---

## โครงสร้างโฟลเดอร์

```
day-07/
├── DAY7_GUIDE.md
├── web-deployment-probes.yaml
├── web-deployment-no-resources.yaml   ← ฝึก OOM/limit
├── vote-hpa.yaml
├── lab10-commands.ps1
├── lab11-commands.ps1
└── notes.md
```

---

## 1. ทบทวน

```bash
kubectl rollout status deployment/<name>
kubectl describe pod <name>   # Events, OOMKilled, FailedScheduling
```

---

## 2. requests / limits

| | requests | limits |
|--|----------|--------|
| **Scheduler** | ใช้ตัดสินใจวาง Pod | — |
| **Runtime** | — | ห้ามใช้เกิน (CPU throttle / OOM kill) |

```yaml
resources:
  requests:
    cpu: 100m
    memory: 64Mi
  limits:
    cpu: 250m
    memory: 128Mi
```

**งานจริง:** ตั้ง requests จาก metrics จริง (Prometheus/VPA recommender) — HPA ต้องมี requests.cpu

---

## 3. Probes

- **readiness** — ไม่ส่ง traffic จน probe ผ่าน
- **liveness** — restart container ถ้า hang

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 15
  periodSeconds: 10
```

---

## 4. metrics-server

```powershell
minikube addons enable metrics-server
kubectl top nodes
kubectl top pods -A
```

---

## 5. HPA

เชื่อมกับ day-04 `vote-hpa.yaml` — ต้องมี metrics-server และ **cpu requests** ใน Deployment

```bash
kubectl get hpa -w
kubectl describe hpa vote
```

ทดสอบโหลด (ถ้ามี): ยิง request ไป vote แล้วดู replica เพิ่ม

---

## 6. Logs

```bash
kubectl logs <pod>
kubectl logs <pod> -c <container>   # multi-container
kubectl logs -f deployment/vote
kubectl logs --previous <pod>         # crash ครั้งก่อน
```

---

## 7. Lab 10–11

```powershell
.\lab10-commands.ps1   # probes + resources
.\lab11-commands.ps1   # metrics-server + HPA
```

**เกณฑ์ผ่าน Lab 11:**

- [ ] `kubectl top pods` แสดงค่าได้
- [ ] HPA แสดง TARGETS ไม่ใช่ `<unknown>`
- [ ] อธิบายได้ว่า HPA ใช้ metric อะไรใน lab นี้

---

## 8. อ่านเพิ่ม

| หัวข้อ | ใช้เมื่อ |
|--------|----------|
| **Taints / Tolerations** | แยก node ให้ GPU / system workload |
| **DaemonSet** | agent ต่อ node (log, monitoring) — ใน cluster มี kube-proxy แบบ DS |

ไม่ lab ใน Phase 2 — รู้จักพอเวลาอ่าน node scheduling error
