resource "kubernetes_manifest" "argocd-app" {
  manifest = yamldecode(templatefile("${path.module}/argocd-app.yaml", {
    path           = var.git_source_path
    repoURL        = var.git_source_repoURL
    targetRevision = var.git_source_targetRevision
  }))
}