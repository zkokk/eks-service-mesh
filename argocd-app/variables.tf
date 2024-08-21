variable "git_source_path" {
  default = "k8s-manifests"
}

variable "git_source_repoURL" {
  default = "git@github.com:zkokk/eks-service-mesh.git"
}

variable "git_source_targetRevision" {
  default = "HEAD"
}

variable "eks_cluster_name" {
  default = "eks-sm"
}