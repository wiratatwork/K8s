# Lab 8c: Deploy Voting App on AKS (Azure)
# วันที่ 5 — Kubernetes Hands-on Lab
#
# Usage:
#   .\lab8-aks.ps1
#   .\lab8-aks.ps1 -ResourceGroup "voting-rg" -ClusterName "voting-aks" -Location "southeastasia"

param(
    [string]$ResourceGroup = "voting-rg",
    [string]$ClusterName = "voting-aks",
    [string]$Location = "southeastasia",
    [int]$NodeCount = 2,
    [string]$NodeVmSize = "Standard_B2s"
)

$ErrorActionPreference = "Continue"
$labDir = $PSScriptRoot
$manifestDir = Join-Path $labDir "voting-app"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Lab 8c: AKS + Voting App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/6] Checking tools..." -ForegroundColor Yellow
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: az not found. Install Azure CLI, or use Azure Cloud Shell." -ForegroundColor Red
    exit 1
}
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: kubectl not found." -ForegroundColor Red
    exit 1
}
Write-Host "  az + kubectl OK" -ForegroundColor Green
Write-Host ""

Write-Host "[2/6] Azure login check..." -ForegroundColor Yellow
az account show 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Not logged in — opening browser..." -ForegroundColor DarkYellow
    az login
}
az account show --query "{name:name, id:id}" -o table
Write-Host ""

Write-Host "[3/6] Create resource group + AKS (10-15 min)..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location | Out-Null

$exists = az aks show --resource-group $ResourceGroup --name $ClusterName 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Cluster already exists — skipping create" -ForegroundColor DarkYellow
} else {
    az aks create `
        --resource-group $ResourceGroup `
        --name $ClusterName `
        --node-count $NodeCount `
        --node-vm-size $NodeVmSize `
        --generate-ssh-keys
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: failed to create AKS cluster." -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

Write-Host "[4/6] Get credentials for kubectl..." -ForegroundColor Yellow
az aks get-credentials --resource-group $ResourceGroup --name $ClusterName --overwrite-existing
kubectl get nodes
Write-Host ""

Write-Host "[5/6] Deploy Voting App..." -ForegroundColor Yellow
kubectl apply -f $manifestDir
kubectl rollout status deployment/vote --timeout=180s
kubectl rollout status deployment/result --timeout=180s
kubectl rollout status deployment/worker --timeout=180s
kubectl get deploy,pods
Write-Host ""

Write-Host "[6/6] Waiting for LoadBalancer EXTERNAL-IP..." -ForegroundColor Yellow
$deadline = (Get-Date).AddMinutes(5)
do {
    Start-Sleep -Seconds 10
    kubectl get svc vote,result
    $voteIp = kubectl get svc vote -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    $resultIp = kubectl get svc result -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if ($voteIp -and $resultIp) { break }
} while ((Get-Date) -lt $deadline)

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Lab 8c DONE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
if ($voteIp) {
    Write-Host "  Vote:   http://$voteIp" -ForegroundColor White
} else {
    Write-Host "  Vote EXTERNAL-IP ยัง pending — รัน: kubectl get svc vote -w" -ForegroundColor Yellow
}
if ($resultIp) {
    Write-Host "  Result: http://$resultIp" -ForegroundColor White
} else {
    Write-Host "  Result EXTERNAL-IP ยัง pending — รัน: kubectl get svc result -w" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Cleanup เมื่อจบ Lab:" -ForegroundColor Magenta
Write-Host "  .\cleanup-cloud.ps1 -Provider aks -ResourceGroup $ResourceGroup"
Write-Host ""
