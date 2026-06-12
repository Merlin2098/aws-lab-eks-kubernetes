param(
  [string]$ClusterRoleName = $null,
  [string]$NodeRoleName    = $null
)

$project = $env:TF_VAR_project_name ?? "invoice-lab"
$envName = $env:TF_VAR_environment ?? "dev"
$prefix  = "$($project.ToLower())-$($envName.ToLower())"

$clusterRole = if ($ClusterRoleName) { $ClusterRoleName } else { "$prefix-eks-cluster-role" }
$nodeRole    = if ($NodeRoleName)    { $NodeRoleName }    else { "$prefix-eks-node-role" }

foreach ($roleName in @($clusterRole, $nodeRole)) {
  Write-Host "Validating IAM role: $roleName"
  $role = aws iam get-role --role-name $roleName | ConvertFrom-Json
  if (-not $role) { Write-Error "Role not found: $roleName"; exit 1 }

  $trust = $role.Role.AssumeRolePolicyDocument | ConvertFrom-Json
  $services = $trust.Statement.Principal.Service
  Write-Host "  Trust services: $services"

  $policies = aws iam list-attached-role-policies --role-name $roleName | ConvertFrom-Json
  Write-Host "  Attached policies: $($policies.AttachedPolicies.PolicyName -join ', ')"
}

Write-Host "IAM validation passed."
