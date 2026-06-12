#!/usr/bin/env bash
set -euo pipefail

REGION=${AWS_DEFAULT_REGION:-us-east-1}

OUTPUTS=$(terraform -chdir=infra output -json)
CLUSTER_NAME=$(echo "$OUTPUTS" | jq -r '.cluster_name.value')
LOG_GROUP=$(echo "$OUTPUTS" | jq -r '.log_group_name.value')

echo "Checking EKS cluster: $CLUSTER_NAME"
aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" > /dev/null

echo "Checking node groups for: $CLUSTER_NAME"
aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --region "$REGION" > /dev/null

echo "Checking CloudWatch log group: $LOG_GROUP"
aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "$REGION" > /dev/null

echo "All precheck validations passed."
