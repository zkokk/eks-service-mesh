data "aws_availability_zones" "available" {}

locals {
  name   = "demo-app"
  region = var.region

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-vpc"
    GithubOrg  = "terraform-aws-modules"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]

  private_subnet_names = ["Private Subnet One", "Private Subnet Two"]

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_dhcp_options  = true

  enable_nat_gateway = true
  single_nat_gateway = true


  tags = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.4.1"

  name                       = local.name
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 82
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 445
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {}
  target_groups = {
    demo-ecs = {
      name_prefix                       = "d1"
      protocol                          = "HTTP"
      port                              = 80
      target_type                       = "ip"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = var.host_port
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }

      protocol_version = "HTTP1"
      port             = var.host_port
      tags = {
        InstanceTargetGroupTag = "demo-1"
      }
    }
  }
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.8.0"

  cluster_name = local.name

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = local.tags
}


module "demo" {
  source = "../"

  app_name    = local.name
  app_subnets = var.subnet_ids
  container_definition = jsonencode([
    {
      name      = "${local.name}-demo-app"
      image     = var.ecr_image
      essential = true
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
        options = {
          awslogs-group         = var.cw_log_group_name
          awslogs-region        = var.region
          awslogs-stream-prefix = "DemoPrefix"
        }
      }
    }
  ])
  ecs_cluster               = module.ecs.name
  env                       = var.env
  iam_policy_task_role      = ""
  iam_policy_execution_role = ""
  lb_dns_name               = var.lb_dns_name
  lb_target_groups = [
    {
      lb_target_group_arn = module.alb.target_groups["demo-ecs"]
      container_port      = var.cont_port
    }
  ]
  sg_ids      = ["module.alb.security_group_id"]
  task_cpu    = var.task_cpu
  task_memory = var.task_memory
  log_group   = var.cw_log_group_name
}