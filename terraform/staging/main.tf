module "eks" {
  source = "../modules/eks"

  cluster_name = var.cluster_name
  environment  = var.environment
  node_groups  = var.node_groups
  vpc_cidr     = "10.200.0.0/16"
}

