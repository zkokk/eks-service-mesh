resource "aws_ecs_service" "ecs_service" {
  name            = "svc-${local.app_name}"
  cluster         = var.ecs_cluster
  task_definition = aws_ecs_task_definition.ecs_task.arn

  desired_count = 1

  scheduling_strategy = var.scheduling_strategy

  deployment_minimum_healthy_percent = var.minimum_healthy_percent
  health_check_grace_period_seconds  = 60

  capacity_provider_strategy {
    capacity_provider = var.capacity.provider
    weight            = var.capacity.weight
    base              = var.capacity.base
  }

  placement_constraints {
    type = var.distinct_instance
  }

  tags = merge(var.tags, {
    Name = "${local.app_name}-svc"
  })

  network_configuration {
    assign_public_ip = var.assign_public_ip
    subnets          = var.app_subnets
    security_groups  = var.sg_ids
  }

  dynamic "load_balancer" {
    for_each = var.lb_target_groups
    content {
      container_name   = "${local.app_name}-container"
      target_group_arn = load_balancer.value.lb_target_group_arn
      container_port   = load_balancer.value.container_port
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}