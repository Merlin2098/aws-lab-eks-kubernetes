variable "name_prefix" {
  description = "Prefix applied to resource names (e.g. <project>-<environment>)."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name, used for the kubernetes.io/cluster/<name> subnet tags."
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources in this module."
  type        = map(string)
}

variable "availability_zones" {
  description = "Availability zones to spread public/private subnets across."
  type        = list(string)
}
