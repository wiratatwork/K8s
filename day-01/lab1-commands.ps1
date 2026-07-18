# Lab 1: Minikube Setup
# วันที่ 1 — Kubernetes Hands-on Lab

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Lab 1: Minikube Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Pre-flight checks ---
Write-Host "[1/7] Checking tools..." -ForegroundColor Yellow

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker not found. Start Docker Desktop first." -ForegroundColor Red
    exit 1
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: kubectl not found." -ForegroundColor Red
    exit 1
}

$minikubeExe = "C:\Program Files\Kubernetes\Minikube\minikube.exe"
if (-not (Test-Path $minikubeExe)) {
    Write-Host "ERROR: minikube not found. Install with: winget install Kubernetes.minikube" -ForegroundColor Red
    exit 1
}
function minikube { & $minikubeExe @args }

Write-Host "  docker:   OK" -ForegroundColor Green
Write-Host "  kubectl:  OK" -ForegroundColor Green
Write-Host "  minikube: OK" -ForegroundColor Green
Write-Host ""

# --- Start cluster ---
Write-Host "[2/7] Starting minikube cluster (driver=docker)..." -ForegroundColor Yellow
minikube start --driver=docker
Write-Host ""

Write-Host "[3/7] Cluster status:" -ForegroundColor Yellow
minikube status
kubectl get nodes
kubectl cluster-info
Write-Host ""

# --- Deploy hello-minikube ---
Write-Host "[4/7] Deploying hello-minikube..." -ForegroundColor Yellow
kubectl create deployment hello-minikube --image=registry.k8s.io/echoserver:1.10 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Deployment already exists, continuing..." -ForegroundColor DarkYellow
}
kubectl rollout status deployment/hello-minikube --timeout=120s
kubectl get pods -l app=hello-minikube
Write-Host ""

# --- Expose service ---
Write-Host "[5/7] Exposing service (NodePort)..." -ForegroundColor Yellow
kubectl expose deployment hello-minikube --type=NodePort --port=8080 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Service already exists, continuing..." -ForegroundColor DarkYellow
}
kubectl get services hello-minikube
Write-Host ""

# --- Get URL ---
Write-Host "[6/7] Service URL:" -ForegroundColor Yellow
$serviceUrl = minikube service hello-minikube --url 2>$null
if ($serviceUrl) {
    Write-Host "  Open in browser: $serviceUrl" -ForegroundColor Green
    try {
        $response = Invoke-WebRequest -Uri $serviceUrl -UseBasicParsing -TimeoutSec 10
        Write-Host "  HTTP Status: $($response.StatusCode) - Service is reachable!" -ForegroundColor Green
    } catch {
        Write-Host "  Could not reach service automatically. Open URL manually." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  Run: minikube service hello-minikube --url" -ForegroundColor DarkYellow
}
Write-Host ""

# --- Summary ---
Write-Host "[7/7] Lab 1 Summary" -ForegroundColor Yellow
Write-Host "----------------------------------------"
kubectl get nodes,pods,services -l app=hello-minikube 2>$null
kubectl get nodes
kubectl get pods
kubectl get services
Write-Host ""
Write-Host "Checklist:" -ForegroundColor Cyan
Write-Host "  [ ] Cluster status = Ready"
Write-Host "  [ ] hello-minikube pod = Running"
Write-Host "  [ ] Service URL works in browser"
Write-Host "  [ ] Can explain Master vs Worker node"
Write-Host ""
Write-Host "Cleanup (when done):" -ForegroundColor DarkGray
Write-Host "  kubectl delete deployment,service hello-minikube"
Write-Host "  minikube stop"
Write-Host ""
