data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix = lower(replace("${var.project_name}-${var.environment}", "_", "-"))

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Lab         = "LAB-004"
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  )
}

module "network" {
  source = "./modules/network"

  name_prefix        = local.name_prefix
  cluster_name       = var.cluster_name
  tags               = local.common_tags
  availability_zones = data.aws_availability_zones.available.names
}

module "iam" {
  source = "./modules/iam"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  name_prefix        = local.name_prefix
  cluster_name       = var.cluster_name
  cluster_role_arn   = module.iam.cluster_role_arn
  node_role_arn      = module.iam.node_role_arn
  subnet_ids         = concat(module.network.public_subnet_ids, module.network.private_subnet_ids)
  private_subnet_ids = module.network.private_subnet_ids
  log_retention_days = var.log_retention_days
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  tags               = local.common_tags
}
