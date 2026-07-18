# Lab 8a: Deploy Voting App on GKE (GCP)
# วันที่ 5 — Kubernetes Hands-on Lab
#
# Usage:
#   .\lab8-gke.ps1 -ProjectId "my-gcp-project"
#   .\lab8-gke.ps1 -ProjectId "my-gcp-project" -Zone "asia-southeast1-a" -ClusterName "voting-gke"

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [string]$Zone = "asia-southeast1-b",
    [string]$ClusterName = "voting-gke",
    [int]$NumNodes = 2,
    [string]$MachineType = "e2-medium"
)

$ErrorActionPreference = "Continue"
$labDir = $PSScriptRoot
$manifestDir = Join-Path $labDir "voting-app"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Lab 8a: GKE + Voting App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/6] Checking tools..." -ForegroundColor Yellow
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: gcloud not found. Install Google Cloud SDK first." -ForegroundColor Red
    exit 1
}
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: kubectl not found." -ForegroundColor Red
    exit 1
}
Write-Host "  gcloud + kubectl OK" -ForegroundColor Green
Write-Host ""

Write-Host "[2/6] Configure project / zone..." -ForegroundColor Yellow
gcloud config set project $ProjectId
gcloud config set compute/zone $Zone
Write-Host ""

Write-Host "[3/6] Create GKE cluster '$ClusterName' (5-10 min)..." -ForegroundColor Yellow
$existing = gcloud container clusters describe $ClusterName --zone $Zone 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Cluster already exists — skipping create" -ForegroundColor DarkYellow
} else {
    gcloud container clusters create $ClusterName `
        --num-nodes=$NumNodes `
        --machine-type=$MachineType `
        --zone=$Zone
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: failed to create cluster." -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

Write-Host "[4/6] Get credentials for kubectl..." -ForegroundColor Yellow
gcloud container clusters get-credentials $ClusterName --zone $Zone
kubectl get nodes
Write-Host ""

Write-Host "[5/6] Deploy Voting App..." -ForegroundColor Yellow
kubectl apply -f $manifestDir
Write-Host "  Waiting for deployments..." -ForegroundColor DarkYellow
kubectl rollout status deployment/vote --timeout=180s
kubectl rollout status deployment/result --timeout=180s
kubectl rollout status deployment/worker --timeout=180s
kubectl get deploy,pods
Write-Host ""

Write-Host "[6/6] Waiting for LoadBalancer EXTERNAL-IP..." -ForegroundColor Yellow
Write-Host "  (อาจใช้เวลา 1-3 นาที — กด Ctrl+C ได้เมื่อได้ IP แล้ว)" -ForegroundColor DarkYellow
$deadline = (Get-Date).AddMinutes(5)
do {
    Start-Sleep -Seconds 10
    $svcs = kubectl get svc vote,result -o json 2>$null | ConvertFrom-Json
    $voteIp = $null
    $resultIp = $null
    foreach ($item in $svcs.items) {
        $ingress = $item.status.loadBalancer.ingress
        if ($ingress -and $ingress[0].ip) {
            if ($item.metadata.name -eq "vote") { $voteIp = $ingress[0].ip }
            if ($item.metadata.name -eq "result") { $resultIp = $ingress[0].ip }
        }
    }
    kubectl get svc vote,result
    if ($voteIp -and $resultIp) { break }
} while ((Get-Date) -lt $deadline)

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Lab 8a DONE" -ForegroundColor Green
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
Write-Host "  .\cleanup-cloud.ps1 -Provider gke -ProjectId $ProjectId -Zone $Zone -ClusterName $ClusterName"
Write-Host ""
