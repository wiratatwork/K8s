# Lab 12 — PVC for Postgres
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (kubectl get ns voting-dev 2>$null)) {
  Write-Host "Create voting-dev first (day-06 lab9)." -ForegroundColor Red
  exit 1
}

Write-Host "=== Apply PVC ===" -ForegroundColor Cyan
kubectl apply -f postgres-pvc.yaml
kubectl wait -n voting-dev --for=jsonpath='{.status.phase}'=Bound pvc/postgres-data --timeout=120s
kubectl get pvc -n voting-dev

Write-Host "`n=== Deploy DB with volume ===" -ForegroundColor Cyan
kubectl apply -f db-deployment-pvc.yaml
kubectl rollout status -n voting-dev deployment/db --timeout=180s

Write-Host "`n=== Verify mount ===" -ForegroundColor Cyan
$pod = kubectl get pod -n voting-dev -l app=db -o jsonpath='{.items[0].metadata.name}'
kubectl exec -n voting-dev $pod -- df -h /var/lib/postgresql/data

Write-Host "`nPersistence test: delete pod and wait for new one — data dir should remain on same PVC" -ForegroundColor Yellow
Write-Host "kubectl delete pod -n voting-dev $pod"

Write-Host "`n=== Done ===" -ForegroundColor Green
