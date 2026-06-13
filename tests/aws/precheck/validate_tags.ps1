param(
  [string]$Project = $(if ($env:TF_VAR_project_name) { $env:TF_VAR_project_name } else { "invoice-lab" }),
  [string]$Region  = $(if ($env:AWS_DEFAULT_REGION) { $env:AWS_DEFAULT_REGION } else { "us-east-1" })
)

$required = @("Project", "Environment", "ManagedBy", "Lab", "Owner", "CostCenter")

$resources = aws resourcegroupstaggingapi get-resources `
  --tag-filters "Key=Project,Values=$Project" `
  --region $Region | ConvertFrom-Json

if ($resources.ResourceTagMappingList.Count -eq 0) {
  Write-Warning "No tagged resources found for Project=$Project in $Region."
}

foreach ($r in $resources.ResourceTagMappingList) {
  $tagKeys = $r.Tags | ForEach-Object { $_.Key }
  $missing = $required | Where-Object { $_ -notin $tagKeys }
  if ($missing) {
    Write-Warning "$($r.ResourceARN) missing tags: $($missing -join ', ')"
  }
}

Write-Host "Tag validation complete."
