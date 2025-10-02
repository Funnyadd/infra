#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: bash scripts/deploy.sh <staging|prod>"
    exit 1
fi
ENV="$1"  # staging | prod
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# 0) sanity: kubectl context
kubectl cluster-info >/dev/null

# 1) ensure namespace
kubectl create ns "$ENV" --dry-run=client -o yaml | kubectl apply -f -

# 2) secrets (optional but recommended)
SECRETS_FILE="deploy/${ENV}.env"
if [[ -f "$SECRETS_FILE" ]]; then
    kubectl -n "$ENV" create secret generic app-secrets \
        --from-env-file="$SECRETS_FILE" \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "Upserted secret app-secrets from $SECRETS_FILE"
else
    echo "WARN: $SECRETS_FILE not found; skipping app-secrets"
fi

# 3) deploy overlay
# was: kustomize build "k8s/overlays/${ENV}" | kubectl -n "$ENV" apply -f -
( command -v kustomize >/dev/null 2>&1 \
  && kustomize build "k8s/overlays/${ENV}" \
  || kubectl kustomize "k8s/overlays/${ENV}" ) \
| kubectl -n "$ENV" apply -f -


# 4) wait for rollouts (all deployments)
kubectl -n "$ENV" get deploy -o name | xargs -r -n1 kubectl -n "$ENV" rollout status --timeout=180s

echo "Deployed ${ENV} ✅"
