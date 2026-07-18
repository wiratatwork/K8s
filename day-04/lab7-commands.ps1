# Lab 7: Voting App with Deployments (+ self-healing / scale)
# วันที่ 4 — Kubernetes Hands-on Lab

$ErrorActionPreference = "Continue"
$labDir = $PSScriptRoot
$podsDir = Join-Path $labDir "voting-pods"
$deployDir = Join-Path $labDir "voting-deployments"
$minikubeExe = "C:\Program Files\Kubernetes\Minikube\minikube.exe"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Lab 7: Voting App (Deployments)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/7] Checking tools and cluster..." -ForegroundColor Yellow
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

Write-Host "  Removing Pod-based voting app (if any)..." -ForegroundColor DarkYellow
kubectl delete -f $podsDir --ignore-not-found 2>$null | Out-Null
kubectl delete -f $deployDir --ignore-not-found 2>$null | Out-Null
Start-Sleep -Seconds 3
kubectl get nodes
Write-Host ""

Write-Host "[2/7] Apply voting-deployments..." -ForegroundColor Yellow
kubectl apply -f $deployDir
Write-Host ""

Write-Host "[3/7] Wait for rollouts..." -ForegroundColor Yellow
foreach ($d in @("redis", "db", "vote", "result", "worker")) {
    kubectl rollout status deployment/$d --timeout=180s
}
kubectl get deploy,pods,svc
Write-Host ""

Write-Host "[4/7] Self-healing demo (delete one vote pod)..." -ForegroundColor Yellow
$pod = kubectl get pods -l app=vote -o jsonpath="{.items[0].metadata.name}"
Write-Host "  Deleting pod: $pod" -ForegroundColor DarkYellow
kubectl delete pod $pod
Start-Sleep -Seconds 5
kubectl get pods -l app=vote
Write-Host "  Expected: replica count restored automatically" -ForegroundColor DarkYellow
Write-Host ""

Write-Host "[5/7] Scale vote 2 → 3..." -ForegroundColor Yellow
kubectl scale deployment vote --replicas=3
kubectl rollout status deployment/vote --timeout=60s
kubectl get pods -l app=vote
Write-Host ""

Write-Host "[6/7] Endpoints check..." -ForegroundColor Yellow
kubectl get endpoints vote,result,redis,db
Write-Host ""

Write-Host "[7/7] Service URLs..." -ForegroundColor Yellow
Write-Host "  Vote:" -ForegroundColor White
minikube service vote --url
Write-Host "  Result:" -ForegroundColor White
minikube service result --url
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Lab 7 DONE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Checklist:" -ForegroundColor White
Write-Host "  [ ] Vote ผ่าน browser ได้" -ForegroundColor White
Write-Host "  [ ] Result แสดงผลโหวต" -ForegroundColor White
Write-Host "  [ ] ลบ pod แล้ว self-heal" -ForegroundColor White
Write-Host ""
Write-Host "Cleanup: kubectl delete -f voting-deployments/" -ForegroundColor DarkYellow
Write-Host ""
