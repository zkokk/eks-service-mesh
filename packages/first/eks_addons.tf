module "eks-addons" {

  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.12.0"

  cluster_name      = local.name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # EKS Blueprints Add-ons:
  # Cluster Auto-scaler
  enable_cluster_autoscaler = true

  # AWS LB Controller
  enable_aws_load_balancer_controller = true

  # Metrics Server
  enable_metrics_server = true

  depends_on = [module.eks]
}