#module "argo-cd" {
#  source           = "./argocd"
#  eks_cluster_name = "eks-sm"
#  chart_version    = "7.4.4"
#  depends_on       = [module.eks, module.vpc]
#}
#
#module "argocd-app" {
#  source             = "./argocd-app"
#  eks_cluster_name   = "eks-sm"
#  git_source_path    = "k8s-manifests"
#  git_source_repoURL = "git@github.com:zkokk/eks-service-mesh.git"
#  depends_on         = [module.eks, module.argo-cd, module.vpc]
#}