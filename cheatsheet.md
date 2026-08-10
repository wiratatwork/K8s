# Kubernetes Cheatsheet — ถ้าฉันต้องการ … ให้นึกถึง …

> สรุปจากหลักสูตร K8s (Day 1–10) รูปแบบจำง่าย: **ปัญหาที่เจอ → เครื่องมือ/คำสั่งที่ใช่**

---

## 1. เริ่มต้นใช้งาน (Setup)

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| เปิด Kubernetes จำลองบนเครื่อง Windows | `minikube start --driver=docker` |
| ดูว่า cluster เปิดอยู่หรือไม่ / node พร้อมไหม | `minikube status`, `kubectl get nodes` |
| ดูข้อมูล cluster (URL, version) | `kubectl cluster-info` |
| เปิด Dashboard GUI จัดการ minikube | `minikube dashboard` |
| สั่งงาน cluster ทั้งหมด (ดู/สร้าง/แก้/ลบ/debug) | `kubectl` (รีโมทคอนโทรลของ K8s) |
| รู้ว่า kubectl กำลังคุยกับ cluster ไหน | `kubectl config current-context` |

---

## 2. ดูสถานะ & Debug พื้นฐาน

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| ดู resource ทุกชนิด | `kubectl get pods`, `kubectl get deployments`, `kubectl get services`, `kubectl get rs`, `kubectl get nodes` |
| ดูรายละเอียดเพิ่ม (IP, node ที่รัน) | เพิ่ม `-o wide` เช่น `kubectl get pods -o wide` |
| ดูรายละเอียดเชิงลึก / หา error | `kubectl describe pod <name>` (ดู Events) |
| ดู log ของแอปใน Pod | `kubectl logs <pod-name>` |
| เข้าไปใน Container เพื่อ debug | `kubectl exec -it <pod> -- /bin/sh` |
| ส่ง traffic เข้า Pod/Service ผ่าน localhost | `kubectl port-forward <pod> 8080:80` |
| กรองดูเฉพาะ resource ที่มี label | `kubectl get deploy,pods -l app=web` |
| ดูว่า Pod ไหนขาด/มีปัญหา | `kubectl get pods` แล้วดูสถานะ (Running / CrashLoopBackOff / ImagePullBackOff) |

---

## 3. สร้าง / แก้ / ลบ Resource

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| สร้างหรืออัปเดตจากไฟล์ YAML | `kubectl apply -f <file.yaml>` |
| ลบตามไฟล์ YAML | `kubectl delete -f <file.yaml>` |
| ลบโดยไม่สนว่าไฟล์จะหายไปแล้ว (กัน error) | `kubectl delete -f <file.yaml> --ignore-not-found` |
| สร้าง Pod เร็ว ๆ แบบไม่ต้องเขียน YAML | `kubectl run nginx --image=nginx` (Imperative) |
| สร้าง Deployment เร็ว ๆ | `kubectl create deployment hello --image=nginx` |
| แก้ resource ที่กำลังรันอยู่ | `kubectl edit deployment <name>` |
| แนวทางที่ควรใช้จริงในงาน | Declarative (YAML + `kubectl apply`) — ไม่ใช้ imperative |

---

## 4. Pod & YAML

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| สร้าง Pod ตัวเดียวถาวร | YAML `kind: Pod` + `kubectl apply -f` |
| เขียน YAML ให้ถูกต้อง | VS Code + Red Hat YAML extension; ระวัง indentation (space ห้ามใช้ tab) |
| Pod ไม่ขึ้น (Pull image ไม่ได้) | ตรวจชื่อ image, network → `kubectl describe pod` ดู Event `ImagePullBackOff` |
| รู้ว่า Pod ควรมีกี่ container | หลัก 1 Pod = 1 Container; แยก app เป็น Pod ละตัว แล้วคุยกันด้วย Service |

---

## 5. ReplicaSet & Deployment (ความพร้อมใช้งาน)

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| ให้มี Pod หลายตัวคอยประกัน (self-healing) | ReplicaSet (`replicas: 3` + selector + template) |
| ปรับจำนวน Pod ขึ้น/ลง | `kubectl scale deployment <name> --replicas=5` |
| ดูว่า Pod ถูกแทนที่เองไหมเมื่อลบไป 1 ตัว | `kubectl get pods` หลัง `kubectl delete pod <name>` (ReplicaSet สร้างใหม่ให้อัตโนมัติ) |
| Deploy แบบ Production-ready (update ง่าย, rollback ได้) | Deployment — สร้าง ReplicaSet + ควบคุม version อัตโนมัติ |
| สร้าง Pod จาก template ใน Deployment | ใส่ใน `spec.template.spec.containers` |

---

## 6. Rolling Update & Rollback

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| อัปเดตแอปโดยไม่ downtime | เปลี่ยน `image` ใน deployment.yaml → `kubectl apply` (Rolling Update: สร้าง pod ใหม่ก่อน ลด pod เก่า) |
| รอจนกว่าการ update จะเสร็จ | `kubectl rollout status deployment/<name> --timeout=120s` |
| ดูประวัติ version | `kubectl rollout history deployment/<name>` |
| กลับไป version ก่อนหน้า | `kubectl rollout undo deployment/<name>` |
| กลับไป version ที่ระบุ | `kubectl rollout undo deployment/<name> --to-revision=2` |
| หยุด/เริ่ม update ชั่วคราว | `kubectl rollout pause/resume deployment/<name>` |
| ควบคุมจังหวะ update | `strategy: RollingUpdate` + `maxUnavailable: 1` + `maxSurge: 1` |

---

## 7. Services & Networking

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| ให้ Pod ต่าง ๆ คุยกันภายใน cluster (backend ไม่เปิดนอก) | ClusterIP (เช่น redis, postgres) — ใช้ชื่อ service ได้เลย |
| ให้ผู้ใช้ภายนอกเปิดเว็บผ่าน browser | NodePort (`nodePort: 30080`) — minikube: `minikube service <name> --url` |
| ให้ cloud สร้าง Load Balancer จริงให้ | LoadBalancer (ใช้บน GKE/EKS/AKS) |
| ดูว่า Service ส่ง traffic ไป Pod ไหน | `kubectl get endpoints <service-name>` |
| Service ไม่เจอ Pod | ตรวจ `selector` กับ `labels` ของ Pod ให้ตรงกัน |
| เข้าใจพอร์ต 3 ชั้น | `port` = port ของ Service, `targetPort` = port ของ Pod, `nodePort` = port ด้านนอก |
| Pod ใน namespace อื่นเรียก Service ข้าม namespace | DNS: `<service>.<namespace>.svc.cluster.local` เช่น `db.default` |

---

## 8. ConfigMap / Secret / Namespace

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| เก็บค่า config ที่ไม่ลับ (แยกจาก code) | ConfigMap → ฉีดด้วย `envFrom.configMapRef` |
| เก็บรหัสผ่าน / ความลับ | Secret `type: Opaque` + `stringData` → ฉีดด้วย `secretKeyRef` |
| image ต้องการชื่อ env ตายตัว แต่ key ใน Secret ต่างกัน | map ทีละตัวด้วย `secretKeyRef` แทน `envFrom` |
| แยก app / environment ออกจากกัน | Namespace (เช่น `voting-dev`, `voting-staging`) — แยกชื่อชนกัน + RBAC ต่อ namespace |
| ดู Secret โดยไม่ให้รหัสหลุด | `kubectl get secret db-secret -n voting-dev` (ดู key อย่างเดียว ไม่ decode) |
| เปลี่ยน ConfigMap แล้วให้ Pod เห็นค่าใหม่ | `kubectl rollout restart deployment/<name>` (ถ้าใช้ envFrom ต้องสร้าง Pod ใหม่) |
| เก็บรหัส production จริง ๆ | อย่า commit ใน git → ใช้ Cloud Secret Manager / Vault / CI/CD Secrets |
| จำลำดับการ override ของ env | `.env` (local) → ConfigMap → env ใน Deployment (อันหลังชนะ) |
| สร้าง ConfigMap/Secret/Namespace ก่อน Deployment | ต้อง apply ก่อนเสมอ เพราะ Deployment พึ่งพามันตอนสร้าง Pod |

---

## 9. Resource Limits & Probes (สุขภาพแอป)

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| จอง/จำกัด CPU-RAM ให้ Pod | `resources.requests` (ขั้นต่ำ) และ `resources.limits` (สูงสุด) |
| ไม่ส่ง traffic เข้า Pod ที่ยัง boot ไม่เสร็จ | `readinessProbe` (httpGet / tcpSocket / exec) — ไม่ผ่าน = ตัดออกจาก Endpoint ไม่ restart |
| restart Pod ที่แฮงค์ / ตายไปแล้ว | `livenessProbe` — ไม่ผ่านหลายครั้ง = K8s restart container |
| แอป boot ช้า กลัว probe ยิงก่อนพร้อม | `startupProbe` (หน่วงให้ readiness/liveness รอ) |
| CPU เกิน limit | throttle (ช้าลง แต่ยังรัน) |
| RAM เกิน limit | OOMKill → Pod ถูก kill แล้วสร้างใหม่ |
| รู้ว่า probe เช็คอย่างไร | `httpGet` = ยิง HTTP, `tcpSocket` = เช็ค port, `exec` = รันคำสั่งใน container |

---

## 10. Auto Scaling (HPA)

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| ขยาย/ลดจำนวน Pod อัตโนมัติตามโหลด | HorizontalPodAutoscaler (HPA) ดู CPU/เมตริกทุก ~15 วินาที |
| เปิดเครื่องมือวัด CPU ก่อนใช้ HPA | `minikube addons enable metrics-server` แล้วทดสอบ `kubectl top nodes` |
| ตั้งเป้า scaling | `averageUtilization: 50` = รักษา CPU เฉลี่ย 50% ของ request |
| กำหนดขอบเขต Pod | `minReplicas` / `maxReplicas` ใน hpa.yaml |
| ดู HPA ทำงานสด ๆ | `kubectl get hpa vote --watch` / `kubectl get pods -l app=vote --watch` |
| HPA ใช้ได้ต้องมี `requests.cpu` | ถ้าตั้งแค่ limits ไม่มี requests → HPA autoscale ไม่ได้ |

---

## 11. Storage (ข้อมูลไม่หาย)

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| Pod ถูกสร้างใหม่แล้วข้อมูลยังอยู่ | PVC (PersistentVolumeClaim) + `volumeMounts` ใน Deployment |
| กัน Pod หลายตัวเขียน disk พร้อมกัน | `accessModes: ReadWriteOnce` (เขียนได้ node เดียวกัน ป้องกัน data corruption) |
| ข้อมูล production บน cloud | Cloud managed DB (เช่น Cloud SQL) แทน PV ใน cluster |
| ตรวจว่า mount สำเร็จ | `kubectl get pvc`, `kubectl describe pod <name>` |

---

## 12. Ingress

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| เข้าถึงหลาย Service ด้วย host/path เดียว (ไม่ต้องเปิด port) | Ingress — เป็น Router/Reverse Proxy คล้าย Nginx |
| เปิดใช้งาน Ingress บน minikube | `minikube addons enable ingress` + รอ controller ready (`kubectl wait -n ingress-nginx ...`) |
| route ตาม path | ใน `voting-ingress.yaml`: `voting.local/` → service vote, `voting.local/result` → service result |
| เข้าเว็บด้วยชื่อโดเมน | เพิ่ม IP ของ minikube ลงไฟล์ hosts เช่น `voting.local` แล้ว `curl http://voting.local/` |
| จัดการ HTTPS / หลาย env / rate limit ที่จุดเดียว | Ingress (บน cloud ใช้ concept เดียวกันกับ on-prem) |

---

## 13. Cloud (GKE / EKS / AKS)

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| สร้าง cluster บน GCP | `gcloud container clusters create voting-gke --num-nodes=2 --machine-type=e2-medium --zone=asia-southeast1-b` |
| ให้ kubectl ควบคุม cluster GKE | `gcloud container clusters get-credentials voting-gke` |
| อยากได้ IP ภายนอกถาวร | จอง Static IP บน Cloud แล้วชี้ domain |
| ลบของหลัง Lab (ประหยัดค่าใช้จ่าย) | `kubectl delete -f ...` แล้วลบ cluster ตาม provider (cleanup script) |
| Deploy ขึ้น cloud | `kubectl apply -f <manifests>` เหมือน local เลย (concept เดียวกัน) |

---

## 14. Helm & ขั้นสูง

| ถ้าฉันต้องการ | ให้นึกถึง |
|---|---|
| ติดตั้งแอปทั้งก้อนโดยไม่เขียน YAML เอง | Helm (Package Manager คล้าย npm): `helm install` จาก Chart |
| ปรับค่าการติดตั้ง Chart | `values.yaml` (Values) |
| ดู/ย้อนเวอร์ชันการติดตั้ง Helm | Release + Revision → `helm history`, `helm rollback` |
| base เดียว + ปรับตาม env | Kustomize (overlay สำหรับ dev/staging/prod) |
| กำหนดว่าใครทำอะไรได้ใน cluster | RBAC (Role/ClusterRole + Binding) |
| จำกัดว่า Pod ไหนคุยกับ Pod ไหนได้ | NetworkPolicy |

---

## สรุปเส้นทางคิด (Flow)

```
ถ้าฉันต้องการ "แอปไม่หลุด / scale / ไม่มี downtime"
  → ให้นึกถึง Deployment (+ HPA) ไม่ใช่ Pod เปล่า

ถ้าฉันต้องการ "ให้คนอื่นเข้าแอปได้"
  → NodePort (local) / LoadBalancer (cloud) / Ingress (หลาย route + HTTPS)

ถ้าฉันต้องการ "ให้ Pod คุยกัน"
  → ClusterIP + selector ให้ตรง

ถ้าฉันต้องการ "ค่า config ไม่ hard-code"
  → ConfigMap (ไม่ลับ) + Secret (ลับ) + Namespace แยก env

ถ้าฉันต้องการ "แอปไม่พังเมื่อ Pod ตาย"
  → ReplicaSet/Deployment (self-heal) + Probes (ตรวจสุขภาพ) + PVC (ข้อมูลไม่หาย)
```

*อ้างอิง: NOTE.txt, TEACHING_PLAN.md, Labs day-01 ถึง day-10*
