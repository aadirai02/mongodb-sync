cluster_name = "prod-eks-mongo"
environment  = "prod"

node_groups = {
  "common" = {
    desired_size  = 1
    max_size      = 3
    min_size      = 1
    name          = "prod-common-ng"
    instance_types = ["t2.small"]
    capacity_type = "ON_DEMAND"
  },
  "mongo" = {
    desired_size  = 1
    max_size      = 3
    min_size      = 1
    name          = "prod-mongo-ng"
    instance_types = ["t2.small", "t3.small"]
    capacity_type = "ON_DEMAND"
    labels = {
      role = "mongo"
      workload = "database"
    }
  },
  "sync" = {
    desired_size  = 0  # Starts at 0, scales up during sync
    max_size      = 1
    min_size      = 0
    name          = "prod-sync-ng"
    instance_types = ["t2.small"]
    capacity_type = "ON_DEMAND"
    labels = {
      role = "sync"
      workload = "data-sync"
    }
  }
}

