#!/bin/bash

source .env

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found!"
  exit 1
fi

required_vars=("DOCKERHUB_USERNAME" "DOCKERHUB_TOKEN" "DOCKERHUB_EMAIL")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not set. Please export the variable and try again."
    exit 1
  fi
done

DOCKERHUB_NAMESPACE="samjsui"
K8S_NAMESPACE="default"
OVERHANG_BACKEND_CONFIG_NAME="overhang-backend-config"
OVERHANG_BACKEND_REGISTRY_NAME="overhang-backend-registry"
OVERHANG_BACKEND_AUTH_NAME="overhang-backend-auth"
OVERHANG_BACKEND_GATEWAY_NAME="overhang-backend-gateway"

echo "Starting Minikube..."
minikube start --driver=docker

echo "Configuring kubectl to use Minikube context..."
kubectl config use-context minikube

echo "Install NGINX Gateway Fabric..."
kubectl kustomize "https://github.com/nginxinc/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.3.0" | kubectl apply -f -

echo "Logging into Docker Hub..."
minikube ssh "docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_TOKEN"

echo "Moving Docker credentials to be read by Kubelet"
minikube ssh "cat /home/docker/.docker/config.json >> /var/lib/kubelet/config.json"

echo "Cleaning up Service Namespace..."
if kubectl get namespace $K8S_NAMESPACE; then
  kubectl delete all --all -n $K8S_NAMESPACE
  kubectl delete configmaps --all -n $K8S_NAMESPACE
  kubectl delete secrets --all -n $K8S_NAMESPACE
else
  echo "Namespace $K8S_NAMESPACE does not exist, skipping cleanup."
fi

echo "Enabling Minikube registry-cred..."
minikube addons enable registry-creds

echo "Creating Docker Registry Secret..."
kubectl create secret docker-registry dev-overhang-registry \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=${DOCKERHUB_USERNAME} \
  --docker-password=${DOCKERHUB_TOKEN} \
  --docker-email=${DOCKERHUB_EMAIL} \
  -n $K8S_NAMESPACE || echo "Secret already exists"

echo "Deploy PostgreSQL database..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install postgres bitnami/postgresql -f ./charts/postgres/value.yaml  \
    --set auth.username=postgres \
    --set auth.password=postgres \
    --set persistence.enabled=true \
    --namespace $K8S_NAMESPACE --create-namespace

echo "Deploying Config Service..."
helm upgrade --install $OVERHANG_BACKEND_CONFIG_NAME ./charts/$OVERHANG_BACKEND_CONFIG_NAME \
  --set image.tag=latest \
  --namespace $K8S_NAMESPACE --create-namespace

echo "Deploying Registry Service..."
helm upgrade --install $OVERHANG_BACKEND_REGISTRY_NAME ./charts/$OVERHANG_BACKEND_REGISTRY_NAME \
  --set image.tag=latest \
  --set spring.config.import=http://overhang-backend-config.$K8S_NAMESPACE.svc.cluster.local:8888/ \
  --namespace $K8S_NAMESPACE --create-namespace

echo "Deploying Auth Service..."
helm upgrade --install $OVERHANG_BACKEND_AUTH_NAME ./charts/$OVERHANG_BACKEND_AUTH_NAME \
  --set image.tag=latest \
  --set spring.config.import=http://overhang-backend-config.$K8S_NAMESPACE.svc.cluster.local:8888/ \
  --set db.name="auth_dev" \
  --namespace $K8S_NAMESPACE --create-namespace

echo "Deploying Gateway Service..."
helm upgrade --install $OVERHANG_BACKEND_GATEWAY_NAME ./charts/$OVERHANG_BACKEND_GATEWAY_NAME \
  --set image.tag=latest \
  --set spring.config.import=http://overhang-backend-config.$K8S_NAMESPACE.svc.cluster.local:8888/ \
  --set overhang.service.auth.url=http://overhang-backend-auth.$K8S_NAMESPACE.svc.cluster.local:8081/ \
  --namespace $K8S_NAMESPACE --create-namespace

echo "Verifying deployments..."
kubectl get pods -n $K8S_NAMESPACE

echo "Deployment to Minikube completed."
