module "eks_logging" {
  source = "./modules/terraform-modules-eks-logging-fluentbit"
  fluentbit_cluster_info_configs = {
    "logs.region"  = var.region,
    "cluster.name" = module.eks.cluster_id,
    "http.server"  = "On",
    "http.port"    = "2020",
    "read.head"    = "Off",
    "read.tail"    = "On"
  }
  fluentbit_image        = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"
  namespace_name         = "amazon-cloudwatch"
  logs_destination_store = "cloudwatch"
  prefix_name            = "fluent-bit"
  eks_oidc_issuer_url    = local.eks_oidc_issuer_url
  eks_oidc_provider_arn  = local.eks_oidc_provider_arn
}