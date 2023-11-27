# Create observability namespace
resource "kubernetes_namespace" "observability" {
  metadata {
    name = "observability"
  }
}

# Create prometheus deployment
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = var.prometheus_chart_version
  chart      = "prometheus"
  namespace  = "observability"

  values = [
    templatefile("${path.module}/helm/prometheus.yaml", {})
  ]

  depends_on = [module.eks.eks_managed_node_groups,
                module.eks.aws_eks_addon,
                kubernetes_namespace.observability,
                hcp_consul_cluster.main,
                module.vpc
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
                hcp_consul_cluster.main,
                module.vpc,
                helm_release.prometheus
                ]
}