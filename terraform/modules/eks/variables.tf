variable "cluster_name" {}
variable "environment" {}
variable "node_groups" {
  type = map(object({
    desired_size  = number
    max_size      = number
    min_size      = number
    instance_types = list(string)
    capacity_type = string
    labels        = optional(map(string))
  }))
  default = {}
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

