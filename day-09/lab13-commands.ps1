# Lab 13 — Ingress for voting app
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

minikube addons enable ingress
Write-Host "Wait for ingress controller..." -ForegroundColor Yellow
Start-Sleep -Seconds 25
kubectl wait -n ingress-nginx --for=condition=ready pod -l app.kubernetes.io/component=controller --timeout=180s 2>$null

kubectl apply -f result-deployment.yaml
kubectl apply -f voting-ingress.yaml

Write-Host "`nMinikube IP (add to hosts as voting.local):" -ForegroundColor Cyan
minikube ip
kubectl get ingress -n voting-dev

Write-Host "`nTest from host (after hosts file):" -ForegroundColor Green
Write-Host "curl http://voting.local/"
Write-Host "curl http://voting.local/result"
