module "eks_logging" {
  source = "../"
  fluentbit_cluster_info_configs = {
    "logs.region"    = var.region,
    "cluster.name"   = local.cluster_name,
    "http.server"    = "On",
    "http.port"      = "2020",
    "read.head"      = "Off",
    "read.tail"      = "On"
  }
  fluentbit_image        = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"
  namespace_name         = "amazon-cloudwatch"
  logs_destination_store = "cloudwatch"
  prefix_name            = "fluent-bit"
  #s3_kms_key_id          = "123123123-34324231231-123"
  eks_oidc_issuer_url    = local.eks_oidc_issuer_url
  eks_oidc_provider_arn  = local.eks_oidc_provider_arn
}