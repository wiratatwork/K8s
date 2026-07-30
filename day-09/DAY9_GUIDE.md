# วันที่ 9 — Ingress, DNS และ Troubleshooting แอป

> เป้าหมายวันนี้: URL เดียวเข้า vote/result แทน NodePort หลายพอร์ต และมี flow แก้แอปพัง

**อ้างอิง COURSE_CONTENT_2:** DNS in kubernetes, Ingress, Application Failure

---

## สารบัญ

1. [DNS ใน cluster](#1-dns)
2. [Ingress vs NodePort/LB](#2-ingress)
3. [Lab 13: Ingress บน minikube](#3-lab-13)
4. [Troubleshooting flow](#4-troubleshooting)
5. [Lab 14](#5-lab-14)

---

## โครงสร้างโฟลเดอร์

```
day-09/
├── DAY9_GUIDE.md
├── voting-ingress.yaml
├── broken/
│   ├── vote-service-wrong-port.yaml
│   └── vote-deployment-wrong-label.yaml
├── lab13-commands.ps1
├── lab14-commands.ps1
└── notes.md
```

---

## 1. DNS

| ชื่อ | ความหมาย |
|------|----------|
| `redis` | Service ใน namespace เดียวกัน |
| `db.voting-dev.svc.cluster.local` | FQDN |

```bash
kubectl run tmp --rm -it --image=busybox --restart=Never -- nslookup db.voting-dev.svc.cluster.local
```

CoreDNS อยู่ใน `kube-system` — ถ้า resolve ไม่ได้ ดู Service/endpoints ก่อน blame DNS

---

## 2. Ingress

- **Ingress** = กฎ routing (HTTP path/host)
- **Ingress Controller** = nginx/traefik ที่ทำจริง (minikube: addon)

```
Browser → Ingress Controller → Service vote / result
```

---

## 3. Lab 13

```powershell
minikube addons enable ingress
.\lab13-commands.ps1
```

เพิ่มใน `C:\Windows\System32\drivers\etc\hosts` (ต้อง admin):

```
<minikube ip> voting.local
```

ทดสอบ: `http://voting.local/` และ `http://voting.local/result`

---

## 4. Troubleshooting

ลำดับที่ใช้ในงาน:

1. `kubectl get pods,svc,endpoints -n <ns>`
2. Pod ไม่ Running → `describe` + `logs` (+ `--previous`)
3. Service ไม่มี endpoints → **labels/selector**
4. Pod Running แต่ curl ไม่ได้ → **port targetPort**, NetworkPolicy
5. ข้าม namespace → **DNS name** ถูกไหม

---

## 5. Lab 14

ใช้ manifest ใน `broken/` — แก้จน vote กลับมา accessible

```powershell
.\lab14-commands.ps1
```

**เกณฑ์ผ่าน:** อธิบาย root cause 2 อย่าง (selector/port) เป็นภาษาไทยสั้น ๆ
