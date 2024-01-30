variable "subnet_ids" {
  description = "List of subnet id where the LB will be running"
  default     = ""
}
variable "env" {
  description = "Environment"
  default     = ""
}
variable "ecr_image" {
  description = "Image location"
  default     = ""
}
variable "cont_port" {
  description = "Task container port"
  default     = ""
}
variable "host_port" {
  description = "Host container port"
  default     = ""
}
variable "cw_log_group_name" {
  description = "CloudWatch log group to stream logs to"
  default     = ""
}
variable "region" {
  description = "AWS Region"
  default     = ""
}
variable "ecs_cluster" {
  description = "ECS Cluster ID"
  default     = ""
}
variable "task_role_policy" {
  description = "ECS Task policy (!Execution Policy)"
  default     = ""
}
variable "lb_dns_name" {
  description = "Domain prefix that is going to be used for creating the R53 entry"
  default     = ""
}
variable "lb_target_group_1_arn" {
  description = "One of the TGs"
  default     = ""
}
variable "lb_target_group_2_arn" {
  description = "One of the TGs"
  default     = ""
}
variable "lb_zone_id" {
  description = "LB Zone ID when ALB is defined "
  default     = ""
}
variable "r53_hosted_zone" {
  description = "R53 Hosted Zone ID"
  default     = ""
}
variable "sg_ids" {
  description = "List of SGs"
  default     = ""
}
variable "task_cpu" {
  description = "CPU resources for single container in task"
  default     = ""
}
variable "task_memory" {
  description = "Memory resources for single container in task"
  default     = ""
}
