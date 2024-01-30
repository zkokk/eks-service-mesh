locals {
  prefix   = var.env
  app_name = "${local.prefix}-${var.app_name}"

  cw_loggroup_name = var.log_group

  container_definition = jsonencode([
    merge(var.container_definition[0], {
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-group         = local.cw_loggroup_name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "json"
        }
      }
    })
  ])


  runtime = [
    {
      arch = var.runtime
    }
  ]
}