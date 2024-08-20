module "eks-addons" {

  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.16.2"

  cluster_name      = local.name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Cluster Auto-scaler
  enable_cluster_autoscaler = true
  cluster_autoscaler        = {
    namespace     = "cluster-autoscaler"
  }

  # AWS LB Controller
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    namespace     = "alb"
  }

  # Metrics Server
  enable_metrics_server = true
  metrics_server      = {
    namespace     = "metrics-server"
  }

  depends_on = [module.eks]
}