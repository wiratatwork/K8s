# Lab 2: Pods with YAML
# วันที่ 2 — Kubernetes Hands-on Lab

$ErrorActionPreference = "Stop"
$labDir = $PSScriptRoot
$minikubeExe = "C:\Program Files\Kubernetes\Minikube\minikube.exe"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Lab 2: Pods with YAML" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Pre-flight ---
Write-Host "[1/6] Checking tools and cluster..." -ForegroundColor Yellow

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker not found. Start Docker Desktop first." -ForegroundColor Red
    exit 1
}
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: kubectl not found." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $minikubeExe)) {
    Write-Host "ERROR: minikube not found at $minikubeExe" -ForegroundColor Red
    exit 1
}

function minikube { & $minikubeExe @args }

# Ensure cluster is up
$status = & $minikubeExe status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Starting minikube..." -ForegroundColor DarkYellow
    minikube start --driver=docker
}

kubectl get nodes
Write-Host ""

# --- Imperative demo ---
Write-Host "[2/6] Imperative: kubectl run nginx..." -ForegroundColor Yellow
kubectl delete pod nginx --ignore-not-found 2>$null | Out-Null
kubectl run nginx --image=nginx:1.25 --port=80
kubectl wait --for=condition=Ready pod/nginx --timeout=120s
kubectl get pod nginx
kubectl delete pod nginx
Write-Host "  Imperative demo done (pod deleted)." -ForegroundColor Green
Write-Host ""

# --- Declarative apply ---
Write-Host "[3/6] Declarative: apply nginx-pod.yaml..." -ForegroundColor Yellow
kubectl apply -f (Join-Path $labDir "nginx-pod.yaml")
kubectl wait --for=condition=Ready pod/nginx-pod --timeout=120s
kubectl get pod nginx-pod -o wide
Write-Host ""

# --- Debug broken image ---
Write-Host "[4/6] Debug: apply broken image (expect ImagePullBackOff)..." -ForegroundColor Yellow
kubectl apply -f (Join-Path $labDir "nginx-pod-broken.yaml")
Start-Sleep -Seconds 8
kubectl get pod nginx-pod-broken
Write-Host "  Events (look for Failed / ErrImagePull / ImagePullBackOff):" -ForegroundColor DarkYellow
kubectl describe pod nginx-pod-broken | Select-String -Pattern "Events:|Failed|ErrImage|BackOff|Pulling|Successfully" -Context 0,15
Write-Host ""

# --- Cleanup broken + re-apply good ---
Write-Host "[5/6] delete/apply cycle..." -ForegroundColor Yellow
kubectl delete -f (Join-Path $labDir "nginx-pod-broken.yaml") --ignore-not-found
kubectl delete -f (Join-Path $labDir "nginx-pod.yaml") --ignore-not-found
Start-Sleep -Seconds 2
kubectl apply -f (Join-Path $labDir "nginx-pod.yaml")
kubectl wait --for=condition=Ready pod/nginx-pod --timeout=120s
kubectl get pods
Write-Host ""

# --- Summary ---
Write-Host "[6/6] Lab 2 Summary" -ForegroundColor Yellow
Write-Host "----------------------------------------"
kubectl get pods -o wide
Write-Host ""
Write-Host "Checklist:" -ForegroundColor Cyan
Write-Host "  [ ] Pod from YAML = Running"
Write-Host "  [ ] describe showed ImagePullBackOff on broken pod"
Write-Host "  [ ] delete -f and apply -f worked"
Write-Host ""
Write-Host "Cleanup (when done):" -ForegroundColor DarkGray
Write-Host "  kubectl delete -f nginx-pod.yaml --ignore-not-found"
Write-Host "  kubectl delete -f nginx-pod-broken.yaml --ignore-not-found"
Write-Host ""
