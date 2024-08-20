provider "aws" {
  region = local.region
}

//provider "kubernetes" {
//  host                   = module.eks.cluster_endpoint
//  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
//
//  exec {
//    api_version = "client.authentication.k8s.io/v1beta1"
//    command     = "aws"
//    # This requires the awscli to be installed locally where Terraform is executed
//    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
//  }
//}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = element(concat(data.aws_eks_cluster_auth.eks_cluster[*].token, tolist([""])), 0)
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = element(concat(data.aws_eks_cluster_auth.eks_cluster[*].token, tolist([""])), 0)
  }
}