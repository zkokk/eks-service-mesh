module "demo" {
  source = "../"

  app_name             = "demo-app"
  app_subnets          = var.subnet_ids
  container_definition = jsonencode([
    {
      name         = "${var.env}-demo-app"
      image        = var.ecr_image
      essential    = true
      portMappings = [
        {
          containerPort = var.cont_port
          hostPort      = var.host_port
        }
      ],
      environment = [
        { "name" : "VAR1", "value" : "value_one" },
        { "name" : "VAR2", "value" : "value_two" },

      ]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          awslogs-group         = var.cw_log_group_name
          awslogs-region        = var.region
          awslogs-stream-prefix = "tf-SomePrefix"
        }
      }
    }
  ])
  ecs_cluster          = var.ecs_cluster
  env                  = var.env
  iam_policy_task_role = var.task_role_policy
  lb_dns_name          = var.lb_dns_name
  lb_target_groups     = [
    {
      lb_target_group_arn = var.lb_target_group_1_arn
      container_port      = var.cont_port
    },
    {
      lb_target_group_arn = var.lb_target_group_2_arn
      container_port      = var.cont_port
    }
  ]
  sg_ids                     = var.sg_ids
  task_cpu                   = var.task_cpu
  task_memory                = var.task_memory
  iam_policy_execution_role  = ""
  log_group                  = ""
}