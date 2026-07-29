# Lab 10 — Resources & Probes
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

minikube status | Out-Null

Write-Host "=== Deploy web with probes + resources ===" -ForegroundColor Cyan
kubectl apply -f web-deployment-probes.yaml
kubectl rollout status deployment/web --timeout=120s
kubectl get pods -l app=web

Write-Host "`n=== Optional: memory limit demo (may OOMKill) ===" -ForegroundColor Yellow
Write-Host "Apply memory-hog-deployment.yaml and watch: kubectl get pod -w -l app=memory-hog"
Write-Host "kubectl describe pod -l app=memory-hog | Select-String OOM"

Write-Host "`n=== Done ===" -ForegroundColor Green
