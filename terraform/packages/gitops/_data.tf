data "aws_caller_identity" "current" {}

### Logging module data resources:
data "aws_eks_cluster_auth" "eks_cluster" {
  name  = var.eks.cluster_id
}