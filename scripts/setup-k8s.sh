#!/usr/bin/env bash
# setup-k8s.sh - build, push, and deploy the Binary Calculator web app and a
# MySQL server to Google Kubernetes Engine (Lab 3 Part 1).
#
# Reference runbook. Run the subcommands in order from a machine with gcloud,
# kubectl, docker, and maven. Every gcloud call is scoped to the sdt-ms3 config.
#
#   ./scripts/setup-k8s.sh registry      # Artifact Registry repo + docker auth
#   ./scripts/setup-k8s.sh image         # mvn package, docker build, push
#   ./scripts/setup-k8s.sh cluster       # create the GKE cluster
#   ./scripts/setup-k8s.sh app-yaml      # deploy the web app with k8s/*.yaml
#   ./scripts/setup-k8s.sh app-cmd       # same, with imperative kubectl (lab)
#   ./scripts/setup-k8s.sh ip            # show the external IPs
#   ./scripts/setup-k8s.sh mysql-cmd     # MySQL deploy + service via kubectl
#   ./scripts/setup-k8s.sh mysql-yaml    # MySQL deploy + service via YAML
#   ./scripts/setup-k8s.sh mysql-access  # open a mysql client in the pod
#   ./scripts/setup-k8s.sh teardown      # delete the cluster
#
set -euo pipefail

export CLOUDSDK_ACTIVE_CONFIG_NAME="${CLOUDSDK_ACTIVE_CONFIG_NAME:-sdt-ms3}"
PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
PROJECT="${PROJECT:-project-177cbd41-037f-441e-80d}"
REGION="${REGION:-northamerica-northeast2}"
ZONE="${ZONE:-northamerica-northeast2-a}"
CLUSTER="${CLUSTER:-k8s-lab}"
AR_REPO="${AR_REPO:-sofe3980u}"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT}/${AR_REPO}/binarycalculator"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "project=$PROJECT region=$REGION cluster=$CLUSTER image=$IMAGE config=$CLOUDSDK_ACTIVE_CONFIG_NAME"

case "${1:-}" in
registry)
  gcloud services enable artifactregistry.googleapis.com container.googleapis.com \
    --project "$PROJECT"
  gcloud artifacts repositories create "$AR_REPO" --repository-format docker \
    --location "$REGION" --project "$PROJECT" || true
  gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet
  ;;
image)
  cd "$REPO_ROOT/webapp"
  mvn -q package
  docker build -t "$IMAGE" .
  docker push "$IMAGE"
  echo "pushed $IMAGE"
  ;;
cluster)
  gcloud container clusters create "$CLUSTER" --project "$PROJECT" \
    --zone "$ZONE" --num-nodes 2 --machine-type e2-small || true   # ok if it already exists
  gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --project "$PROJECT"
  ;;
app-yaml)
  # substitute the image into the deployment manifest, then apply both files
  sed "s#IMAGE_PATH#${IMAGE}#" "$REPO_ROOT/k8s/deployment.yaml" | kubectl apply -f -
  kubectl apply -f "$REPO_ROOT/k8s/service.yaml"
  kubectl get deployments,services
  ;;
app-cmd)
  # the lab's imperative method, kept for the "kubectl commands" demo
  kubectl create deployment binarycalculator-deployment --image "$IMAGE" --port 8080
  kubectl expose deployment binarycalculator-deployment \
    --type LoadBalancer --name binarycalculator-service --port 8080 --target-port 8080
  ;;
ip)
  kubectl get services -o wide
  echo "open http://<binarycalculator EXTERNAL-IP>:8080 in a browser"
  ;;
mysql-cmd)
  kubectl create deployment mysql-deployment --image mysql/mysql-server --port 3306
  kubectl expose deployment mysql-deployment \
    --type LoadBalancer --name mysql-service --port 3306 --target-port 3306
  kubectl get deployments,services
  ;;
mysql-yaml)
  kubectl apply -f "$REPO_ROOT/mysql/mysql-deploy.yaml"
  kubectl apply -f "$REPO_ROOT/mysql/mysql-service.yaml"
  kubectl get deployments,services
  ;;
mysql-access)
  POD="$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}')"
  echo "opening mysql client in pod $POD (password: sofe3980u)"
  kubectl exec -it "$POD" -- mysql -uroot -psofe3980u
  # from any machine once the service has an external IP:
  #   mysql -uuser -psofe3980u -h<EXTERNAL-IP>
  ;;
teardown)
  gcloud container clusters delete "$CLUSTER" --zone "$ZONE" --project "$PROJECT" --quiet || true
  echo "cluster deleted. Artifact Registry repo $AR_REPO kept; delete it manually if not needed."
  ;;
*)
  grep '^#   ' "$0" | sed 's/^#   //'
  ;;
esac
