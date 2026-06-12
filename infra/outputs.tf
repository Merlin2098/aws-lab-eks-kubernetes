output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster API server."
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority data for the EKS cluster."
  value       = module.eks.cluster_ca_certificate
}

output "cluster_security_group" {
  description = "Security group ID created by EKS for the cluster control plane."
  value       = module.eks.cluster_security_group
}

output "oidc_provider" {
  description = "OIDC provider ARN for the EKS cluster, used by future IRSA roles."
  value       = module.eks.oidc_provider_arn
}

output "log_group_name" {
  description = "CloudWatch log group name for the EKS cluster control plane logs."
  value       = module.eks.log_group_name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN for the EKS cluster control plane logs."
  value       = module.eks.log_group_arn
}

output "resource_arn" {
  description = "ARN of the primary managed resource (the EKS cluster)."
  value       = module.eks.cluster_arn
}
