cluster_name = "staging-eks-mongo"
environment  = "staging"

node_groups = {
  "common" = {
    desired_size  = 1
    max_size      = 2
    min_size      = 1
    name          = "stag-common-ng"
    instance_types = ["t2.small"]
    capacity_type = "ON_DEMAND"
  },
  "mongo" = {
    desired_size  = 1
    max_size      = 2
    min_size      = 1
    name          = "stag-mongo-ng"
    instance_types = ["t2.small"]
    capacity_type = "ON_DEMAND"
    labels = {
      role = "mongo"
      workload = "database"
    }
  }
}

