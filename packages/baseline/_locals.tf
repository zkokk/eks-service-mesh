locals {
  name            = "swo-baseline"
  cluster_version = "1.29"
  region          = var.region

  tags = merge({
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }, var.tags)
}
