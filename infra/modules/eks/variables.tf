variable "name_prefix" {
  description = "Prefix applied to resource names (e.g. <project>-<environment>)."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role assumed by the EKS cluster control plane."
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role assumed by EKS managed node group instances."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs (public + private) attached to the EKS cluster VPC config."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where managed node group instances are launched."
  type        = list(string)
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days for the EKS cluster control plane logs."
  type        = number
}

variable "node_instance_type" {
  description = "EC2 instance type for the EKS managed node group."
  type        = string
}

variable "node_desired_size" {
  description = "Desired number of nodes in the managed node group."
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of nodes in the managed node group."
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of nodes in the managed node group."
  type        = number
}

variable "tags" {
  description = "Common tags applied to all resources in this module."
  type        = map(string)
}
