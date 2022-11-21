locals {
  region = var.region
}

locals {
  name            = "swo-onboarding"
  cluster_version = "1.22"
  region          = "eu-west-1"

  tags = merge({
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }, var.tags)
}