terraform init
terraform apply --auto-approve
# wait 10-15 minutes for build

# Connect to EKS
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw kubernetes_cluster_id)

# Set environment variables
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_root_token) && \
export CONSUL_HTTP_ADDR=$(terraform output -raw consul_url)

# Notice that Consul services exist
consul catalog services

# Upgrade Consul to enable metrics
terraform apply -var="consul_helm_filename=consul-v2.tpl"

# Redeploy HashiCups with updated proxies
kubectl rollout restart deployment --namespace default

# Go to API gateway URL and explore HashiCups to generate traffic
export CONSUL_APIGW_ADDR=http://$(kubectl get svc/api-gateway -o json | jq -r '.status.loadBalancer.ingress[0].hostname') && \
echo $CONSUL_APIGW_ADDR

# Go to Grafana URL and check out dashboards
export GRAFANA_URL=http://$(kubectl get svc/grafana --namespace observability -o json | jq -r '.status.loadBalancer.ingress[0].hostname') && \
echo $GRAFANA_URL

# Enable HCP observability
## Go to HCP portal and click on respective Consul cluster
## Click the Observability tab and scroll to the bottom
## set environment variables

export HCP_CLIENT_ID="ECzeLG2NBeFsKcKUZ3sL8mpmHRaUxPKA"
export HCP_CLIENT_SECRET="ahPMRQYZ20L9fqxficU3q65yA9n7w6gaieOuhz3rpRQOdVT2kDQVXfiKndexZGGj"
export HCP_RESOURCE_ID="organization/067acbc1-ed49-4dc2-9fcb-6b4aff713469/project/98a0dcc3-5473-4e4d-a28e-6c343c498530/hashicorp.consul.global-network-manager.cluster/learn-consul-82c0"

## Set kubernetes secrets

kubectl create secret generic consul-hcp-observability-client-id --from-literal=client-id=$HCP_CLIENT_ID --namespace consul

kubectl create secret generic consul-hcp-observability-client-secret --from-literal=client-secret=$HCP_CLIENT_SECRET --namespace consul

kubectl create secret generic consul-hcp-resource-id --from-literal=resource-id=$HCP_RESOURCE_ID --namespace consul

## verify secret contents
kubectl get secrets consul-hcp-resource-id -o jsonpath='{.data.resource-id}' --namespace consul | base64 -d

# Update Consul deployment to enable Consul telemetry collector
terraform apply -var="consul_helm_filename=consul-v3.tpl"

# Redeploy HashiCups with updated proxies
kubectl rollout restart deployment --namespace default

## Check out HCP dashboard

# Check out Consul (optional)
echo $CONSUL_HTTP_ADDR && export $CONSUL_HTTP_TOKEN