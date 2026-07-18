# Cleanup Cloud resources after Lab 8
# วันที่ 5 — ลบ Voting App + Cluster เพื่อควบคุมค่าใช้จ่าย
#
# Usage:
#   .\cleanup-cloud.ps1 -Provider gke -ProjectId "my-project"
#   .\cleanup-cloud.ps1 -Provider gke -ProjectId "my-project" -Zone "asia-southeast1-b" -ClusterName "voting-gke"
#   .\cleanup-cloud.ps1 -Provider eks
#   .\cleanup-cloud.ps1 -Provider eks -ClusterName "voting-eks" -Region "ap-southeast-1"
#   .\cleanup-cloud.ps1 -Provider aks
#   .\cleanup-cloud.ps1 -Provider aks -ResourceGroup "voting-rg"

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("gke", "eks", "aks")]
    [string]$Provider,

    [string]$ProjectId = "",
    [string]$Zone = "asia-southeast1-b",
    [string]$ClusterName = "",
    [string]$Region = "ap-southeast-1",
    [string]$ResourceGroup = "voting-rg"
)

$ErrorActionPreference = "Continue"
$labDir = $PSScriptRoot
$manifestDir = Join-Path $labDir "voting-app"

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Cleanup Lab 8 ($Provider)" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "[1/2] Delete Voting App manifests..." -ForegroundColor Yellow
if (Test-Path $manifestDir) {
    kubectl delete -f $manifestDir --ignore-not-found
} else {
    Write-Host "  voting-app/ not found — skip manifests" -ForegroundColor DarkYellow
}
Write-Host ""

Write-Host "[2/2] Delete cluster..." -ForegroundColor Yellow
switch ($Provider) {
    "gke" {
        if (-not $ProjectId) {
            Write-Host "ERROR: -ProjectId required for GKE" -ForegroundColor Red
            exit 1
        }
        $name = if ($ClusterName) { $ClusterName } else { "voting-gke" }
        gcloud config set project $ProjectId | Out-Null
        gcloud container clusters delete $name --zone $Zone --quiet
    }
    "eks" {
        $name = if ($ClusterName) { $ClusterName } else { "voting-eks" }
        eksctl delete cluster --name $name --region $Region
    }
    "aks" {
        Write-Host "  Deleting resource group '$ResourceGroup' (includes AKS)..." -ForegroundColor DarkYellow
        az group delete --name $ResourceGroup --yes --no-wait
        Write-Host "  Delete started (async). Check: az group show -n $ResourceGroup" -ForegroundColor DarkYellow
    }
}

Write-Host ""
Write-Host "Cleanup requested. Verify in cloud console that nothing is left running." -ForegroundColor Green
Write-Host ""
