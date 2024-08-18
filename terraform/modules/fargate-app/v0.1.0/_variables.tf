variable "env" {}

variable "app_name" {}

variable "iam_policy_task_role" {}

variable "container_definition" {}

variable "ecs_cluster" {}

variable "minimum_healthy_percent" {
  default = 100
}

variable "tags" {
  default = {}
}

variable "assign_public_ip" {
  default = false
}

variable "app_subnets" {}

variable "sg_ids" {
  type = list(string)
}

variable "lb_dns_name" {}

variable "lb_target_groups" {}

variable "task_cpu" {
  default = ""
}

variable "task_memory" {
  default = ""
}

variable "iam_policy_execution_role" {}

variable "aws_logs_retention_in_days" {
  default = 14
}

variable "log_group" {}

variable "runtime" {
  default = "default"
}

variable "ephemeral_storage" {
  default = 21
}

variable "service_launch_type" {
  default = "EC2"

}
variable "task_volume" {
  default = ""
}

variable "constraint_type" {
  default = ""
}

variable "scheduling_strategy" {
  default = "REPLICA"
}

variable "capacity" {
  default = {
    provider = {}
    weight   = 1
    base     = 1
  }
}

variable "distinct_instance" {
  default = ""
}