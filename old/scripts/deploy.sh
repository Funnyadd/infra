#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: bash scripts/deploy.sh <staging|prod>"
  exit 1
fi
ENV="$1"

# Sanity: kubectl context
kubectl cluster-info >/dev/null

# Ensure namespace exists
kubectl create ns "$ENV" --dry-run=client -o yaml | kubectl apply -f -

# Build & apply overlay
( command -v kustomize >/dev/null 2>&1 \
  && kustomize build "k8s/overlays/${ENV}" \
  || kubectl kustomize "k8s/overlays/${ENV}" ) \
| kubectl -n "$ENV" apply -f -

# Wait for all deployments to roll out
kubectl -n "$ENV" get deploy -o name | xargs -r -n1 kubectl -n "$ENV" rollout status --timeout=180s

echo "Deployed ${ENV}"
