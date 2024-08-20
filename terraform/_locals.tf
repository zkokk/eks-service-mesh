locals {
<<<<<<< HEAD
<<<<<<< HEAD
  name            = "eks-service-mesh"
=======
  name            = "my-cluster"
>>>>>>> 5aff51d59142b4d02d8e33b562ac176a22c7995d
=======
  name            = "my-cluster"
=======
  name            = "eks-service-mesh"
>>>>>>> c3b38ad4042de24c6d6e0d98f850c4466fc52635
>>>>>>> 5ddafab0d39250718146f0de3c0e881e18f913ba
  cluster_version = "1.30"
  region          = var.region
  vpc_id          = "vpc-022d1faa647803d63"

  tags = merge({
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }, var.tags)
}

### Logging module locals:
locals {
  partition  = data.aws_partition.current.partition
  account_id = var.account_id == null ? data.aws_caller_identity.current.account_id : var.account_id
  cluster_name          = var.fluentbit_cluster_info_configs["cluster.name"]
  eks_oidc_issuer_url   = replace(data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
  eks_oidc_provider_arn = "arn:${local.partition}:iam::${local.account_id}:oidc-provider/${local.eks_oidc_issuer_url}"
}