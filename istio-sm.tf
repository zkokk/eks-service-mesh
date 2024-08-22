resource "helm_release" "istio-base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  version          = "1.23.0"
  create_namespace = true
}

resource "helm_release" "istiod" {
  name             = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  namespace        = "istio-system"
  version          = "1.23.0"
  create_namespace = true
}

resource "helm_release" "istio-gw" {
  name             = "istio-ingressgateway"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  namespace        = "istio-system"
  version          = "1.23.0"
  create_namespace = true

  depends_on = [
    helm_release.istio-base,
    helm_release.istiod
  ]
  set {
    name  = "resources.requests.cpu"
    value = "500m"
  }
  set {
    name  = "resources.limits.cpu"
    value = "600m"
  }
  set {
    name  = "labels.app"
    value = "istio-gateway"
  }
  set {
    name  = "labels.istio"
    value = "gateway"
  }
}