resource "aws_ecs_task_definition" "ecs_task" {
  family                = "${var.app_name}-task-def"
  container_definitions = local.container_definition
  cpu                   = var.task_cpu
  memory                = var.task_memory
  task_role_arn         = aws_iam_role.ecs_task.arn
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  network_mode          = "awsvpc"


  dynamic "runtime_platform" {
    for_each = var.runtime == "default" ? {} : { arch = var.runtime }
    content {
      operating_system_family = "LINUX"
      cpu_architecture        = var.runtime
    }
  }

  dynamic "volume" {
    for_each = var.task_volume != "" ? [var.task_volume] : []
    content {
      name      = "valcache_data"
      host_path = volume.value
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage == 21 ? {} : { size = var.ephemeral_storage }
    content {
      size_in_gib = var.ephemeral_storage
    }
  }

  requires_compatibilities = [var.service_launch_type] # EC2 or FARGATE
}
