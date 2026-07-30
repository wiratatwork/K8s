# Lab 15 — Helm basics
$ErrorActionPreference = "Stop"

if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
  Write-Host "Install Helm 3: https://helm.sh/docs/intro/install/" -ForegroundColor Red
  exit 1
}

helm version
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

Write-Host "=== Install nginx chart ===" -ForegroundColor Cyan
helm install lab-nginx bitnami/nginx --set replicaCount=1 --wait --timeout 3m

helm list
kubectl get pods -l app.kubernetes.io/instance=lab-nginx

Write-Host "=== Upgrade replicas ===" -ForegroundColor Cyan
helm upgrade lab-nginx bitnami/nginx --set replicaCount=2 --wait --timeout 3m
kubectl get pods -l app.kubernetes.io/instance=lab-nginx

Write-Host "=== Cleanup ===" -ForegroundColor Yellow
Write-Host "helm uninstall lab-nginx"
