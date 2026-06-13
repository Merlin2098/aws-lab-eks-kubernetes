param(
  [string]$Region = $(if ($env:AWS_DEFAULT_REGION) { $env:AWS_DEFAULT_REGION } else { "us-east-1" })
)

$logGroup = terraform -chdir=infra output -raw log_group_name

Write-Host "Checking log group: $logGroup"
$result = aws logs describe-log-groups --log-group-name-prefix $logGroup --region $Region | ConvertFrom-Json

$match = $result.logGroups | Where-Object { $_.logGroupName -eq $logGroup }
if (-not $match) { Write-Error "Log group not found: $logGroup"; exit 1 }

if (-not $match.retentionInDays) {
  Write-Error "Log group $logGroup has no retentionInDays configured."
  exit 1
}

Write-Host "CloudWatch OK: $logGroup (retention: $($match.retentionInDays) days)"
