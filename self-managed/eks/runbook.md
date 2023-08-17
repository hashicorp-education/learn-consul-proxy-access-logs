terraform init
terraform apply --auto-approve
# wait 15 minutes for build

aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw kubernetes_cluster_id)

consul-k8s install -config-file=helm/values-v1.yaml
# OR
helm install --values helm/values-v1.yaml consul hashicorp/consul --create-namespace --namespace consul --version "1.2.1"

kubectl apply --filename hashicups/

export CONSUL_HTTP_TOKEN=$(kubectl get --namespace consul secrets/consul-bootstrap-acl-token --template={{.data.token}} | base64 -d) && \
export CONSUL_HTTP_ADDR=https://$(kubectl get services/consul-ui --namespace consul -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') && \
export CONSUL_HTTP_SSL_VERIFY=false && \
export CONSUL_APIGW_ADDR=http://$(kubectl get svc/api-gateway -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

consul catalog services

# no longer needed for metrics/logs with grafana agent? Still need for envoy spans.
# kubectl apply -f proxy/proxy-defaults.yaml
# kubectl delete --filename hashicups/ && \
# kubectl apply --filename hashicups/

# Do this within Terraform? Any value of teaching this?
./install-observability-stack.sh

# For troubleshooting
kubectl port-forward svc/prometheus-server -n observability 8080:80

export GRAFANA_URL=http://$(kubectl get svc/grafana --namespace observability -o json | jq -r '.status.loadBalancer.ingress[0].hostname')

echo $GRAFANA_URL
# Go to Grafana URL
# Check out metrics/logs/traces

echo $CONSUL_APIGW_ADDR
# Go to API gateway URL and explore HashiCups to generate traffic
