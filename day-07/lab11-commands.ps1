# Lab 11 — metrics-server, HPA, logs
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "=== Enable metrics-server ===" -ForegroundColor Cyan
minikube addons enable metrics-server
Start-Sleep -Seconds 30

Write-Host "`n=== Wait for metrics API ===" -ForegroundColor Cyan
$retries = 12
for ($i = 0; $i -lt $retries; $i++) {
  try {
    kubectl top nodes 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
  } catch {}
  Start-Sleep -Seconds 10
}
kubectl top nodes
kubectl top pods -A --sort-by=memory | Select-Object -First 15

Write-Host "`n=== HPA (namespace voting-dev from day-06) ===" -ForegroundColor Cyan
if (-not (kubectl get ns voting-dev 2>$null)) {
  Write-Host "Run day-06 lab9 first, or skip HPA section." -ForegroundColor Yellow
} else {
  # Ensure vote has CPU requests for HPA
  kubectl patch deployment vote -n voting-dev --type=json -p='[
    {"op":"add","path":"/spec/template/spec/containers/0/resources","value":{
      "requests":{"cpu":"100m","memory":"64Mi"},
      "limits":{"cpu":"250m","memory":"128Mi"}
    }}]' 2>$null
  kubectl apply -f vote-hpa.yaml
  kubectl get hpa -n voting-dev
  Write-Host "Watch: kubectl get hpa -n voting-dev -w"
}

Write-Host "`n=== Logs example ===" -ForegroundColor Cyan
$pod = kubectl get pod -n voting-dev -l app=vote -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($pod) { kubectl logs -n voting-dev $pod --tail=5 }

Write-Host "`n=== Done ===" -ForegroundColor Green
