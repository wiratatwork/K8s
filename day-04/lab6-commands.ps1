# Lab 6: Voting App with Pods
# วันที่ 4 — Kubernetes Hands-on Lab

$ErrorActionPreference = "Continue"
$labDir = $PSScriptRoot
$podsDir = Join-Path $labDir "voting-pods"
$minikubeExe = "C:\Program Files\Kubernetes\Minikube\minikube.exe"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Lab 6: Voting App (Pods)" -ForegroundColor Cyan
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

# Clear Lab 5 + any previous voting resources
kubectl delete -f (Join-Path $labDir "web-deployment.yaml") --ignore-not-found 2>$null | Out-Null
kubectl delete -f (Join-Path $labDir "web-service.yaml") --ignore-not-found 2>$null | Out-Null
kubectl delete -f (Join-Path $labDir "web-service-broken.yaml") --ignore-not-found 2>$null | Out-Null
kubectl delete -f $podsDir --ignore-not-found 2>$null | Out-Null
kubectl delete -f (Join-Path $labDir "voting-deployments") --ignore-not-found 2>$null | Out-Null
Start-Sleep -Seconds 3
kubectl get nodes
Write-Host ""

Write-Host "[2/5] Apply voting-pods manifests..." -ForegroundColor Yellow
kubectl apply -f $podsDir
Write-Host ""

Write-Host "[3/5] Wait for pods Running..." -ForegroundColor Yellow
$names = @("redis", "db", "vote", "result", "worker")
foreach ($n in $names) {
    Write-Host "  Waiting for pod/$n ..." -ForegroundColor DarkYellow
    kubectl wait --for=condition=Ready pod/$n --timeout=180s 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  WARN: pod/$n not Ready yet — check: kubectl describe pod $n" -ForegroundColor Yellow
    }
}
kubectl get pods -o wide
Write-Host ""

Write-Host "[4/5] Check services and endpoints..." -ForegroundColor Yellow
kubectl get svc,endpoints
Write-Host ""

Write-Host "[5/5] Service URLs..." -ForegroundColor Yellow
Write-Host "  Vote:" -ForegroundColor White
minikube service vote --url
Write-Host "  Result:" -ForegroundColor White
minikube service result --url
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Lab 6 DONE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "  1) เปิด Vote URL → โหวต" -ForegroundColor White
Write-Host "  2) เปิด Result URL → ดูผล" -ForegroundColor White
Write-Host "  3) ทดลอง: kubectl delete pod vote  (จะไม่ขึ้นเอง = เหตุผลทำ Lab 7)" -ForegroundColor DarkYellow
Write-Host ""
