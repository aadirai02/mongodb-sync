terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


# VPC (unchanged)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  # ... (VPC configuration unchanged)
  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr
  # ... (rest of vpc config)
  azs              = ["us-east-1a", "us-east-1b"]
  private_subnets  = [cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2)]
  public_subnets   = [cidrsubnet(var.vpc_cidr, 8, 101), cidrsubnet(var.vpc_cidr, 8, 102)]
  enable_nat_gateway = true
  single_nat_gateway = true
  tags = {
    Name        = "${var.cluster_name}-vpc"
    Environment = var.environment
  }
}


locals {
  # Take incoming node_groups from tfvars and inject subnet_ids based on index
  processed_node_groups = {
    for name, ng in var.node_groups :
    name => merge(
      ng,
      name == "mongo" ? { subnet_ids = [module.vpc.private_subnets[0]] } :
      name == "sync"  ? { subnet_ids = [module.vpc.private_subnets[0]] } :
                        { subnet_ids = module.vpc.private_subnets }
    )
  }
}
# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.1.1"

  cluster_name    = var.cluster_name
  cluster_version = "1.33"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true
  eks_managed_node_groups        = local.processed_node_groups

  cluster_addons = {
    coredns   = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni   = { most_recent = true }
    aws-ebs-csi-driver = { 
      most_recent = true
      addon_version = "v1.51.1-eksbuild.1" # EKS 1.34 compatible
      # IMPORTANT: Change this to reference the IAM Role created *in this module*
      service_account_role_arn = aws_iam_role.ebs_csi.arn 
    }
  }

  enable_irsa = true
  access_entries = {
    aaditya = {
      principal_arn = "arn:aws:iam::561030001202:user/aaditya"

      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  tags = { Environment = var.environment }
}

# EBS CSI IAM Role 
resource "aws_iam_role" "ebs_csi" {
  name = "${var.cluster_name}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = module.eks.oidc_provider_arn }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
  tags = { Name = "${var.cluster_name}-ebs-csi", Environment = var.environment }
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}
