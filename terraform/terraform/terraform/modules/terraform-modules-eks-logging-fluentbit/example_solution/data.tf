data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "eks_cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = local.cluster_name
}

# Need to be provided from the root module!!!
provider "kubernetes" {
  host                   = element(concat(data.aws_eks_cluster.eks_cluster[*].endpoint, tolist([""])), 0)
  cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.eks_cluster[*].certificate_authority.0.data, tolist([""])), 0))
  token                  = element(concat(data.aws_eks_cluster_auth.eks_cluster[*].token, tolist([""])), 0)
}