variable "chart_version" {
  default = "7.4.4"
}

variable "eks_cluster_name" {
  default = "eks-sm"
}

variable "git_source_path" {
  default = "onboarding/k8s-manifests"
}

variable "git_source_repoURL" {
  default = "git@github.com:zkokk/eks-service-mesh.git"
}

variable "git_source_targetRevision" {
  default = "HEAD"
}