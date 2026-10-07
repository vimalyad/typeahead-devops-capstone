#!/usr/bin/env bash
set -euo pipefail
# Use only the dedicated assignment cluster selected in KUBECONFIG.
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
file=$(mktemp)
trap 'rm -f "$file"' EXIT
if [[ -n "${ARGOCD_MANIFEST:-}" ]]; then
  cp "$ARGOCD_MANIFEST" "$file"
else
  curl --max-time 180 --retry 2 -fsSL 'https://raw.githubusercontent.com/argoproj/argo-cd/c9c369efcc5b2a0bd720803f8d14a1c3eaddf579/manifests/core-install.yaml' -o "$file"
fi
printf '%s  %s\n' '1a87025d8eb2eae621653fd312fb9ca51df1b4b3b6992a030e3a9ef38e45c448' "$file" | sha256sum -c -
kubectl -n argocd apply --server-side -f "$file"
kubectl -n argocd patch configmap argocd-cm --type merge -p '{"data":{"timeout.reconciliation":"30s"}}'
# Reuse the versioned image already pulled by the init container on the local node.
kubectl -n argocd patch deployment argocd-repo-server --type strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"argocd-repo-server","imagePullPolicy":"IfNotPresent"}],"initContainers":[{"name":"copyutil","imagePullPolicy":"IfNotPresent"}]}}}}'
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=600s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=600s
