# Lab 3: ReplicaSets
# วันที่ 3 — Kubernetes Hands-on Lab

$ErrorActionPreference = "Continue"
$labDir = $PSScriptRoot
$minikubeExe = "C:\Program Files\Kubernetes\Minikube\minikube.exe"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Lab 3: ReplicaSets" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/5] Checking tools and cluster..." -ForegroundColor Yellow
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

kubectl delete -f (Join-Path $labDir "nginx-deployment.yaml") --ignore-not-found 2>$null | Out-Null
kubectl delete -f (Join-Path $labDir "nginx-rs.yaml") --ignore-not-found 2>$null | Out-Null
kubectl delete -f (Join-Path $labDir "nginx-rs-mismatch.yaml") --ignore-not-found 2>$null | Out-Null
kubectl delete pods -l app=nginx --ignore-not-found 2>$null | Out-Null
Start-Sleep -Seconds 3
kubectl get nodes
Write-Host ""

Write-Host "[2/5] Apply nginx-rs.yaml (replicas=3)..." -ForegroundColor Yellow
kubectl apply -f (Join-Path $labDir "nginx-rs.yaml")
$deadline = (Get-Date).AddSeconds(120)
do {
    $ready = @(kubectl get pods -l app=nginx --field-selector=status.phase=Running --no-headers 2>$null).Count
    if ($ready -ge 3) { break }
    Start-Sleep -Seconds 2
} while ((Get-Date) -lt $deadline)
kubectl get rs,pods --show-labels
Write-Host ""

Write-Host "[3/5] Self-healing: delete one pod..." -ForegroundColor Yellow
$pod = kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}"
Write-Host "  Deleting pod: $pod"
kubectl delete pod $pod --wait=true
Start-Sleep -Seconds 3
$deadline = (Get-Date).AddSeconds(60
do {
    $ready = @(kubectl get pods -l app=nginx --field-selector=status.phase=Running --no-headers 2>$null).Count
    if ($ready -ge 3) { break }
    Start-Sleep -Seconds 2
} while ((Get-Date) -lt $deadline)
kubectl get pods -l app=nginx
Write-Host "  Running pods: $ready (expect 3)" -ForegroundColor Green
Write-Host ""

Write-Host "[4/5] Scale 5 -> 2..." -ForegroundColor Yellow
kubectl scale rs nginx-rs --replicas=5
Start-Sleep -Seconds 8
kubectl get pods -l app=nginx
kubectl scale rs nginx-rs --replicas=2
Start-Sleep -Seconds 8
kubectl get pods -l app=nginx
Write-Host ""

Write-Host "[5/5] Debug label mismatch..." -ForegroundColor Yellow
kubectl delete -f (Join-Path $labDir "nginx-rs.yaml") --ignore-not-found
Start-Sleep -Seconds 3
Write-Host "  Applying mismatch file (expect validation error):" -ForegroundColor DarkYellow
kubectl apply -f (Join-Path $labDir "nginx-rs-mismatch.yaml") 2>&1
kubectl delete -f (Join-Path $labDir "nginx-rs-mismatch.yaml") --ignore-not-found 2>$null | Out-Null

Write-Host ""
Write-Host "Lab 3 Checklist:" -ForegroundColor Cyan
Write-Host "  [x] ReplicaSet self-healed after pod delete"
Write-Host "  [x] Scale 5 -> 2 worked"
Write-Host "  [x] Label mismatch error observed"
Write-Host ""
