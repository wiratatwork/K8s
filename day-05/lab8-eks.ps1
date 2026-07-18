# Lab 8b: Deploy Voting App on EKS (AWS)
# วันที่ 5 — Kubernetes Hands-on Lab
#
# Usage:
#   .\lab8-eks.ps1
#   .\lab8-eks.ps1 -ClusterName "voting-eks" -Region "ap-southeast-1"

param(
    [string]$ClusterName = "voting-eks",
    [string]$Region = "ap-southeast-1",
    [int]$Nodes = 2,
    [string]$NodeType = "t3.medium"
)

$ErrorActionPreference = "Continue"
$labDir = $PSScriptRoot
$manifestDir = Join-Path $labDir "voting-app"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Lab 8b: EKS + Voting App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/5] Checking tools..." -ForegroundColor Yellow
foreach ($tool in @("aws", "eksctl", "kubectl")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: $tool not found. Install AWS CLI, eksctl, and kubectl." -ForegroundColor Red
        exit 1
    }
}
Write-Host "  aws + eksctl + kubectl OK" -ForegroundColor Green
aws sts get-caller-identity
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: AWS credentials not configured. Run: aws configure" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "[2/5] Create EKS cluster '$ClusterName' (15-20 min)..." -ForegroundColor Yellow
$check = eksctl get cluster --name $ClusterName --region $Region 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Cluster already exists — skipping create" -ForegroundColor DarkYellow
    aws eks update-kubeconfig --name $ClusterName --region $Region
} else {
    eksctl create cluster `
        --name $ClusterName `
        --region $Region `
        --nodes $Nodes `
        --node-type $NodeType `
        --managed
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: failed to create cluster." -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

Write-Host "[3/5] Verify nodes..." -ForegroundColor Yellow
kubectl get nodes
Write-Host ""

Write-Host "[4/5] Deploy Voting App..." -ForegroundColor Yellow
kubectl apply -f $manifestDir
kubectl rollout status deployment/vote --timeout=180s
kubectl rollout status deployment/result --timeout=180s
kubectl rollout status deployment/worker --timeout=180s
kubectl get deploy,pods
Write-Host ""

Write-Host "[5/5] Waiting for LoadBalancer hostname..." -ForegroundColor Yellow
Write-Host "  (อาจใช้เวลา 2-5 นาที)" -ForegroundColor DarkYellow
$deadline = (Get-Date).AddMinutes(8)
do {
    Start-Sleep -Seconds 15
    kubectl get svc vote,result
    $voteHost = kubectl get svc vote -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    $resultHost = kubectl get svc result -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    if ($voteHost -and $resultHost) { break }
} while ((Get-Date) -lt $deadline)

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Lab 8b DONE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
if ($voteHost) {
    Write-Host "  Vote:   http://$voteHost" -ForegroundColor White
} else {
    Write-Host "  Vote LB ยัง pending — รัน: kubectl get svc vote -w" -ForegroundColor Yellow
}
if ($resultHost) {
    Write-Host "  Result: http://$resultHost" -ForegroundColor White
} else {
    Write-Host "  Result LB ยัง pending — รัน: kubectl get svc result -w" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Cleanup เมื่อจบ Lab:" -ForegroundColor Magenta
Write-Host "  .\cleanup-cloud.ps1 -Provider eks -ClusterName $ClusterName -Region $Region"
Write-Host ""
