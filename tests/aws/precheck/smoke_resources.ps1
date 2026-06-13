param(
  [string]$Region = $(if ($env:AWS_DEFAULT_REGION) { $env:AWS_DEFAULT_REGION } else { "us-east-1" })
)

$outputs = terraform -chdir=infra output -json | ConvertFrom-Json

# EKS cluster
$clusterName = $outputs.cluster_name.value
$cluster = aws eks describe-cluster --name $clusterName --region $Region | ConvertFrom-Json
if (-not $cluster) { Write-Error "EKS cluster not found: $clusterName"; exit 1 }
Write-Host "EKS cluster OK: $clusterName (status: $($cluster.cluster.status))"

# Node group(s)
$nodegroups = aws eks list-nodegroups --cluster-name $clusterName --region $Region | ConvertFrom-Json
if ($nodegroups.nodegroups.Count -eq 0) { Write-Error "No node groups found for cluster $clusterName"; exit 1 }
foreach ($ng in $nodegroups.nodegroups) {
  $detail = aws eks describe-nodegroup --cluster-name $clusterName --nodegroup-name $ng --region $Region | ConvertFrom-Json
  Write-Host "Node group OK: $ng (status: $($detail.nodegroup.status))"
}

# CloudWatch log group
$logGroup = $outputs.log_group_name.value
aws logs describe-log-groups --log-group-name-prefix $logGroup --region $Region | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "Log group not found: $logGroup"; exit 1 }
Write-Host "CloudWatch log group OK: $logGroup"

Write-Host "All smoke checks passed."
