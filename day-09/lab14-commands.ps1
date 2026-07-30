# Lab 14 — Troubleshooting (apply ONE broken scenario at a time)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "=== Scenario A: wrong targetPort ===" -ForegroundColor Cyan
Write-Host "1. kubectl apply -f broken/vote-service-wrong-port.yaml"
Write-Host "2. kubectl get endpoints vote -n voting-dev"
Write-Host "3. Fix targetPort to 80 and re-apply voting-ingress.yaml service section or patch"

Write-Host "`n=== Scenario B: selector mismatch ===" -ForegroundColor Cyan
Write-Host "1. kubectl apply -f broken/vote-deployment-wrong-label.yaml"
Write-Host "2. kubectl get pods -n voting-dev --show-labels"
Write-Host "3. Align labels on pod template and service selector"

Write-Host "`nHint checklist: get pods -> describe -> get svc -> get endpoints -> logs" -ForegroundColor Yellow
