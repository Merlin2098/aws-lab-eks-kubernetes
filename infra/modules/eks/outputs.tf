output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority data for the EKS cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group" {
  description = "Security group ID created by EKS for the cluster control plane."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for the EKS cluster, used by future IRSA roles."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "log_group_name" {
  description = "CloudWatch log group name for the EKS cluster control plane logs."
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN for the EKS cluster control plane logs."
  value       = aws_cloudwatch_log_group.eks_cluster.arn
}
