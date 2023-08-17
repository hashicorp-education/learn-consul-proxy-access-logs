helm repo add grafana https://grafana.github.io/helm-charts && \
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts && \
helm repo add jetstack https://charts.jetstack.io && \
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && \
helm repo update && \
kubectl create namespace observability && \
kubectl create namespace cert-manager && \

helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.12.0 --set installCRDs=true && \
helm install opentelemetry-operator open-telemetry/opentelemetry-operator --namespace observability --set admissionWebhooks.certManager.enabled=false --set admissionWebhooks.certManager.autoGenerateCert=true && \

#helm install loki --values helm/loki.yaml grafana/loki-stack --version "2.9.9" --namespace observability && \
helm install loki --values helm/loki.yaml grafana/loki-stack --namespace observability && \
kubectl rollout status statefulset loki --namespace observability --timeout=300s && \
helm install --values helm/prometheus.yaml prometheus prometheus-community/prometheus --version "15.5.3" --namespace observability && \
kubectl rollout status deployment prometheus-server --namespace observability --timeout=300s && \
helm install tempo --values helm/tempo.yaml grafana/tempo --namespace observability && \
kubectl rollout status statefulset tempo --namespace observability --timeout=300s && \

#currently installs into default namespace for visibility
helm install otel-collector --values helm/otel-collector.yaml open-telemetry/opentelemetry-collector --namespace observability && \
kubectl rollout status deployment otel-collector-opentelemetry-collector --namespace observability --timeout=300s && \
echo "Open Telemetry Collector Deployment Complete" && \

helm install --values helm/grafana.yaml grafana grafana/grafana --namespace observability && \
kubectl rollout status deployment grafana --namespace observability --timeout=300s && \
echo "Grafana Deployment Complete" && \

echo "#######################################" && \
echo "Observability Suite Deployment Complete" && \
echo "#######################################"