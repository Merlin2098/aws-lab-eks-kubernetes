# tests/aws — LAB-004 validation scripts

Operational validation for the EKS infrastructure provisioned in `infra/`.
All scripts read identifiers from `terraform output` — never hardcode ARNs
or resource names.

## Usage

Run from the repository root, after `terraform apply` in `infra/`:

```powershell
# Precheck — IAM roles, tags, and core resources exist
.\tests\aws\precheck\validate_iam.ps1
.\tests\aws\precheck\validate_tags.ps1
.\tests\aws\precheck\smoke_resources.ps1

# Smoke — cluster reachable, log group configured
.\tests\aws\smoke\smoke_cloudwatch.ps1
.\tests\aws\smoke\smoke_eks.ps1

# Logs — export terraform outputs and control-plane log streams
.\tests\aws\logs\export_pipeline_outputs.ps1
.\tests\aws\logs\download_cloudwatch_logs.ps1
```

On Linux/CI (git-bash equivalent):

```bash
bash tests/aws/gitbash/precheck.sh
```

## Structure

```
tests/aws/
├── precheck/
│   ├── validate_iam.ps1        # EKS cluster + node role trust policy and attached policies
│   ├── validate_tags.ps1       # Mandatory tags (Project, Environment, ManagedBy, Lab, Owner, CostCenter)
│   └── smoke_resources.ps1     # EKS cluster, node group(s), CloudWatch log group exist
├── smoke/
│   ├── smoke_cloudwatch.ps1    # Log group exists and retention is configured
│   └── smoke_eks.ps1           # kubectl connectivity + invoice-processor resources
├── logs/
│   ├── export_pipeline_outputs.ps1  # terraform output -json -> logs/tf_outputs.json
│   └── download_cloudwatch_logs.ps1 # download control-plane log streams
├── gitbash/
│   └── precheck.sh             # bash equivalent for CI/Linux
└── README.md
```

## Notes

- `smoke_eks.ps1` runs `aws eks update-kubeconfig` and `kubectl get nodes`;
  it expects nodes in `Ready` state (see SPEC_LAB_004D step 2).
- Run `terraform destroy` at the end of the lab — these scripts only validate,
  they do not provision or tear down resources.
