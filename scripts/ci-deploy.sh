#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PWD/.tools/bin:$PATH"
export KUBECONFIG="$PWD/.tools/kubeconfig"
: "${IMAGE_PREFIX:?Set the registry image prefix}"
: "${IMAGE_TAG:?Set the tested commit SHA}"
cluster_name="capstone-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}"
forward_pid=""
mkdir -p reports
cleanup() {
  result=$?
  set +e
  kubectl -n assignment-s21 get pods,deploy,sts,svc,pvc -o wide > reports/kubernetes.txt 2>&1
  kubectl -n assignment-s21 describe pods > reports/pod-details.txt 2>&1
  kubectl -n assignment-s21 get events --sort-by=.metadata.creationTimestamp > reports/events.txt 2>&1
  for service in ingestion-service suggestion-service frontend kafka postgres; do
    kubectl -n assignment-s21 logs -l "app=$service" --all-containers=true --tail=100 > "reports/$service.log" 2>&1
  done
  if [[ -n "$forward_pid" ]]; then kill "$forward_pid" 2>/dev/null; wait "$forward_pid" 2>/dev/null; fi
  kind delete cluster --name "$cluster_name" > reports/cleanup.txt 2>&1
  if kind get clusters 2>/dev/null | grep -Fxq "$cluster_name"; then
    echo 'FAIL: temporary cluster still exists' | tee -a reports/cleanup.txt
    result=1
  else
    echo 'PASS: temporary cluster is absent' | tee -a reports/cleanup.txt
  fi
  exit "$result"
}
trap cleanup EXIT
kind create cluster --name "$cluster_name" --wait 180s \
  --image kindest/node:v1.37.0@sha256:a1ed56cfb0e7b93589bdf97c8cd566405a265939e3620fc4f5de89adff580ae5
for component in ingestion suggestion frontend; do
  kind load docker-image "$IMAGE_PREFIX-$component:$IMAGE_TAG" --name "$cluster_name"
done
bash scripts/bootstrap.sh
helm lint helm
# The CI cluster has no metrics server or ingress controller. Local/EKS evidence
# exercises those separately; CI still verifies two replicas and all dependencies.
helm upgrade --install typeahead helm -n assignment-s21 --wait --timeout 10m \
  --set "imageTag=$IMAGE_TAG,version=$IMAGE_TAG" \
  --set "services.ingestion-service.image=$IMAGE_PREFIX-ingestion" \
  --set "services.suggestion-service.image=$IMAGE_PREFIX-suggestion" \
  --set "services.frontend.image=$IMAGE_PREFIX-frontend" \
  --set autoscaling.enabled=false,ingress.enabled=false
kubectl -n assignment-s21 get deployments -o json > reports/deployments.json
python3 - <<'PY'
import json
deployments = json.load(open('reports/deployments.json'))['items']
for item in deployments:
    if item['metadata']['name'] in ('ingestion-service', 'suggestion-service', 'frontend'):
        assert item['status'].get('readyReplicas', 0) >= 2, item['metadata']['name']
print('PASS: each application service has at least two ready replicas')
PY
kubectl -n assignment-s21 port-forward svc/frontend 18080:8080 --address=127.0.0.1 > reports/port-forward.txt 2>&1 &
forward_pid=$!
python3 scripts/smoke.py --url http://127.0.0.1:18080 | tee reports/smoke.json
kubectl -n assignment-s21 get pods -o json > reports/pods.json
echo 'PASS: Helm rollout, replica counts, CRUD, Kafka and search'
