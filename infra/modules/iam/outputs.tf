output "cluster_role_arn" {
  description = "ARN of the IAM role assumed by the EKS cluster control plane."
  value       = aws_iam_role.eks_cluster.arn
}

output "node_role_arn" {
  description = "ARN of the IAM role assumed by EKS managed node group instances."
  value       = aws_iam_role.eks_node.arn
}
