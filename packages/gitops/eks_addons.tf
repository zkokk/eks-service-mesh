module "eks-addons" {

  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.12.0"

  cluster_name      = local.name
  cluster_endpoint  = var.eks.cluster_endpoint
  cluster_version   = var.eks.cluster_version
  oidc_provider_arn = var.eks.oidc_provider_arn

  enable_argocd = true
  argocd        = {
    name             = "argo-cd"
    description      = "A Helm chart to install the ArgoCD"
    namespace        = "argocd"
    create_namespace = true
    chart            = "argo-cd"
    chart_version    = "5.42.1"
    repository       = "https://argoproj.github.io/argo-helm"
    values           = []
    set              = [
      ### Defailt values.yaml file: https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd/values.yaml
      # Sets Admin Password
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = var.argocd_admin_assword
      },
      # Enabled Ingress resource definition
      {
        name  = "ingress.enabled"
        value = "enabled"
      },
      # Below 2 map object will help you define ingress annotations. You need to create more or update current ones.
      # Applying as is will result in having these two annotations : "ingress.annotations.example.one.swo.package.io/gitops: true" and ""ingress.annotations.example.two.swo.package.io/gitops: true""
      {
        name  = "ingress.annotations.example\\.one\\.swo\\.package\\.io/gitops"
        value = "true"
      },
      {
        name  = "ingress.annotations.example\\.two\\.swo\\.package\\.io/gitops"
        value = "true"
      },
      # Sets Ingress Host
      {
        name  = "ingress.hosts"
        value = []
      },
      {
        name  = "ingress.paths"
        value = ["/"]
      }
    ]
  }

  depends_on = [var.eks]
}