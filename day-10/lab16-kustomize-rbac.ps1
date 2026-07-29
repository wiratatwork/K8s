# Lab 16 — Kustomize + RBAC + NetworkPolicy
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$base = Join-Path $PSScriptRoot "voting-prod-like"

Write-Host "=== Preview dev overlay ===" -ForegroundColor Cyan
kubectl kustomize (Join-Path $base "overlays/dev")

Write-Host "`n=== Apply dev overlay ===" -ForegroundColor Cyan
kubectl apply -k (Join-Path $base "overlays/dev")
kubectl get deploy -n voting-dev

Write-Host "`n=== RBAC (dev-user is example — wire to your kubeconfig user) ===" -ForegroundColor Cyan
kubectl apply -f (Join-Path $base "rbac-dev-editor.yaml")
kubectl auth can-i create deployment --as=dev-user -n voting-dev
kubectl auth can-i create clusterrole --as=dev-user -n voting-dev

Write-Host "`n=== NetworkPolicy (apply when worker deployment exists) ===" -ForegroundColor Cyan
Write-Host "kubectl apply -f voting-prod-like/network-policy-db.yaml"

Write-Host "`n=== Done ===" -ForegroundColor Green
