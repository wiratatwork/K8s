# Lab 9 — Namespaces, ConfigMaps, Secrets
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$minikubeExe = "C:\Program Files\Kubernetes\Minikube\minikube.exe"
if (-not (Test-Path $minikubeExe)) {
    Write-Host "ERROR: minikube not found. Install with: winget install Kubernetes.minikube" -ForegroundColor Red
    exit 1
}
function minikube { & $minikubeExe @args }

Write-Host "=== Check tools ===" -ForegroundColor Cyan
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: kubectl not found." -ForegroundColor Red
    exit 1
}
& $minikubeExe status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Starting minikube..." -ForegroundColor DarkYellow
    minikube start --driver=docker
}
minikube status
kubectl cluster-info | Out-Null

Write-Host "`n=== Apply namespace + config + secret ===" -ForegroundColor Cyan
kubectl apply -f namespace-voting.yaml
kubectl apply -f vote-configmap.yaml
kubectl apply -f db-secret.yaml

Write-Host "`n=== Deploy vote (ConfigMap) and db (Secret) ===" -ForegroundColor Cyan
kubectl apply -f vote-deployment-config.yaml
kubectl apply -f db-deployment-secret.yaml
kubectl wait -n voting-dev --for=condition=available deployment/vote --timeout=120s
kubectl wait -n voting-dev --for=condition=available deployment/db --timeout=180s

Write-Host "`n=== Verify env from ConfigMap ===" -ForegroundColor Cyan
$pod = kubectl get pod -n voting-dev -l app=vote -o jsonpath='{.items[0].metadata.name}'
kubectl exec -n voting-dev $pod -- printenv | Select-String "OPTION_"

Write-Host "`n=== Summary ===" -ForegroundColor Green
kubectl get ns voting-dev
kubectl get cm,secret,deploy,pods -n voting-dev
