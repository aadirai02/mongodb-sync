variable "cluster_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "node_groups" {
  type = map(object({
    desired_size  = number
    max_size      = number
    min_size      = number
    instance_types = list(string)
    capacity_type = string
    labels        = optional(map(string))
  }))
}

variable "vpc_cidr" {
  type    = string
  default = "10.200.0.0/16"
}

