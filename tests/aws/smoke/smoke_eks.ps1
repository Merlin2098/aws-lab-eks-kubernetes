param(
  [string]$Region = $(if ($env:AWS_DEFAULT_REGION) { $env:AWS_DEFAULT_REGION } else { "us-east-1" })
)

$clusterName = terraform -chdir=infra output -raw cluster_name

Write-Host "Configuring kubeconfig for cluster: $clusterName"
aws eks update-kubeconfig --region $Region --name $clusterName | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to update kubeconfig for $clusterName"; exit 1 }

Write-Host "Checking node readiness..."
kubectl get nodes
if ($LASTEXITCODE -ne 0) { Write-Error "kubectl get nodes failed"; exit 1 }

Write-Host "Checking invoice-processor resources in namespace default..."
kubectl get deployments,pods,services -n default -l app=invoice-processor

Write-Host "EKS smoke check complete."
