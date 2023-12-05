# Create observability namespace
resource "kubernetes_namespace" "observability" {
  metadata {
    name = "observability"
  }
}

# Create loki deployment
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = "observability"

  values = [
    templatefile("${path.module}/helm/loki.yaml", {})
  ]

  depends_on = [module.eks.eks_managed_node_groups,
                module.eks.aws_eks_addon,
                kubernetes_namespace.observability,
                module.vpc,
                helm_release.consul
                ]
}

# Create promtail deployment
resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  namespace  = "observability"

  values = [
    templatefile("${path.module}/helm/promtail.yaml", {})
  ]

  depends_on = [module.eks.eks_managed_node_groups,
                module.eks.aws_eks_addon,
                kubernetes_namespace.observability,
                module.vpc,
                helm_release.consul,
                helm_release.loki
                ]
}

# Create grafana deployment
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  version    = var.grafana_chart_version
  chart      = "grafana"
  namespace  = "observability"

  values = [
    templatefile("${path.module}/helm/grafana.yaml", {})
  ]

  depends_on = [module.eks.eks_managed_node_groups,
                module.eks.aws_eks_addon,
                kubernetes_namespace.observability,
                module.vpc,
                helm_release.loki
                ]
}