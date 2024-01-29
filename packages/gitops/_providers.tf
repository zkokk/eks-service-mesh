provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = var.eks.host
  cluster_ca_certificate = base64decode(var.eks.cluster_certificate_authority_data)
  token                  = element(concat(data.aws_eks_cluster_auth.eks_cluster[*].token, tolist([""])), 0)
}