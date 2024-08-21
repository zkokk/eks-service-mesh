module "argocd" {
  source           = "./argocd"
  eks_cluster_name = "eks-sm"
  chart_version    = "7.4.4"
}

module "argocd-app" {
  source             = "./argocd"
  eks_cluster_name   = "eks-sm"
  git_source_path    = "onboarding/k8s-manifests"
  git_source_repoURL = "git@github.com:zkokk/eks-service-mesh.git"
}