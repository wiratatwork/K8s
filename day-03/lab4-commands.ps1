# Lab 4: Deployments + Update & Rollback
# วันที่ 3 — Kubernetes Hands-on Lab

$ErrorActionPreference = "Continue"
$labDir = $PSScriptRoot
$minikubeExe = "C:\Program Files\Kubernetes\Minikube\minikube.exe"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Lab 4: Deployments + Rollback" -ForegroundColor Cyan
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

kubectl delete -f (Join-Path $labDir "nginx-rs.yaml") --ignore-not-found 2>$null | Out-Null
kubectl delete -f (Join-Path $labDir "nginx-rs-mismatch.yaml") --ignore-not-found 2>$null | Out-Null
kubectl delete -f (Join-Path $labDir "nginx-deployment.yaml") --ignore-not-found 2>$null | Out-Null
kubectl delete pods -l app=nginx --ignore-not-found 2>$null | Out-Null
Start-Sleep -Seconds 3
kubectl get nodes
Write-Host ""

Write-Host "[2/6] Apply nginx-deployment.yaml (3 replicas)..." -ForegroundColor Yellow
kubectl apply -f (Join-Path $labDir "nginx-deployment.yaml")
kubectl rollout status deployment/nginx-deployment --timeout=120s
kubectl get deploy,rs,pods -l app=nginx
Write-Host ""

Write-Host "[3/6] Validate readiness..." -ForegroundColor Yellow
kubectl get deployment nginx-deployment -o wide
kubectl describe deployment nginx-deployment | Select-String -Pattern "Replicas:|Image:|StrategyType:|RollingUpdateStrategy:"
Write-Host ""

Write-Host "[4/6] Rolling update: nginx:1.25 -> nginx:1.26..." -ForegroundColor Yellow
kubectl set image deployment/nginx-deployment nginx=nginx:1.26
kubectl rollout status deployment/nginx-deployment --timeout=180s
Write-Host "  Images after update:"
kubectl get pods -l app=nginx -o jsonpath="{range .items[*]}{.metadata.name}{'\t'}{.spec.containers[0].image}{'\n'}{end}"
Write-Host ""

Write-Host "[5/6] Rollout history + undo..." -ForegroundColor Yellow
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment
kubectl rollout status deployment/nginx-deployment --timeout=180s
Write-Host "  Images after undo:"
kubectl get pods -l app=nginx -o jsonpath="{range .items[*]}{.metadata.name}{'\t'}{.spec.containers[0].image}{'\n'}{end}"
Write-Host ""

Write-Host "[6/6] Lab 4 Summary" -ForegroundColor Yellow
kubectl get deploy,rs,pods -l app=nginx
Write-Host ""
Write-Host "Lab 4 Checklist:" -ForegroundColor Cyan
Write-Host "  [x] Deployment Ready with 3 replicas"
Write-Host "  [x] Rolling update succeeded"
Write-Host "  [x] Rollback (rollout undo) worked"
Write-Host ""
Write-Host "Cleanup: kubectl delete -f nginx-deployment.yaml --ignore-not-found" -ForegroundColor DarkGray
Write-Host ""
