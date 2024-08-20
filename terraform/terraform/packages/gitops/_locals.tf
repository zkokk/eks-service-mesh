locals {
  name            = "swo-gitops"
  cluster_version = "1.28"
  region          = var.region

  tags = merge({
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }, var.tags)
}
