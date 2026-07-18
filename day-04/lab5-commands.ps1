# Lab 5: Services (NodePort + Endpoints debug)
# วันที่ 4 — Kubernetes Hands-on Lab

$ErrorActionPreference = "Continue"
$labDir = $PSScriptRoot
$minikubeExe = "C:\Program Files\Kubernetes\Minikube\minikube.exe"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Lab 5: Services" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/6] Checking tools and cluster..." -ForegroundColor Yellow
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: kubectl not found." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $minikubeExe)) {
    Write-Host "ERROR: minikube not found." -ForegroundColor Red
    exit 1
}
function minikube { & $minikubeExe @args }
& $minikubeExe status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Starting minikube..." -ForegroundColor DarkYellow
    minikube start --driver=docker
}

kubectl delete -f (Join-Path $labDir "web-deployment.yaml") --ignore-not-found 2>$null | Out-Null
kubectl delete -f (Join-Path $labDir "web-service.yaml") --ignore-not-found 2>$null | Out-Null
kubectl delete -f (Join-Path $labDir "web-service-broken.yaml") --ignore-not-found 2>$null | Out-Null
Start-Sleep -Seconds 2
kubectl get nodes
Write-Host ""

Write-Host "[2/6] Apply web Deployment (3 replicas)..." -ForegroundColor Yellow
kubectl apply -f (Join-Path $labDir "web-deployment.yaml")
kubectl rollout status deployment/web --timeout=120s
kubectl get deploy,pods -l app=web
Write-Host ""

Write-Host "[3/6] Apply web-service (NodePort 30080)..." -ForegroundColor Yellow
kubectl apply -f (Join-Path $labDir "web-service.yaml")
kubectl get svc web-service
kubectl get endpoints web-service
Write-Host ""

Write-Host "[4/6] Get service URL..." -ForegroundColor Yellow
minikube service web-service --url
Write-Host ""

Write-Host "[5/6] Debug broken selector (expect empty endpoints)..." -ForegroundColor Yellow
kubectl apply -f (Join-Path $labDir "web-service-broken.yaml")
kubectl get endpoints web-service-broken
kubectl describe svc web-service-broken | Select-String -Pattern "Selector|Endpoints|Type"
Write-Host "  Expected: Endpoints empty because selector app=website != app=web" -ForegroundColor DarkYellow
Write-Host ""

Write-Host "[6/6] Cleanup broken service..." -ForegroundColor Yellow
kubectl delete -f (Join-Path $labDir "web-service-broken.yaml") --ignore-not-found
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Lab 5 DONE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "  web-deployment + web-service ยังอยู่ — ใช้ทดสอบ browser ได้" -ForegroundColor White
Write-Host "  Cleanup: kubectl delete -f web-deployment.yaml,web-service.yaml" -ForegroundColor DarkYellow
Write-Host ""
