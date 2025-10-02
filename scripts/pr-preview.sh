#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: bash scripts/pr_preview.sh up|down <PR_NUMBER>"; exit 1; }
[[ $# -eq 2 ]] || usage

CMD="$1"        # up | down
PR_NUMBER="$2"
NS="pr-${PR_NUMBER}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

case "$CMD" in
    up)
        kubectl create ns "$NS" --dry-run=client -o yaml | kubectl apply -f -

        # Optional PR-specific secrets file: deploy/pr-${PR_NUMBER}.env
        if [[ -f "deploy/pr-${PR_NUMBER}.env" ]]; then
        kubectl -n "$NS" create secret generic app-secrets \
            --from-env-file="deploy/pr-${PR_NUMBER}.env" \
            --dry-run=client -o yaml | kubectl apply -f -
        echo "Upserted secret app-secrets for ${NS}"
        fi

        # Build pr-template overlay and inject PR_NUMBER into hosts etc.
        export PR_NUMBER
        kustomize build k8s/overlays/pr-template | envsubst '$PR_NUMBER' | kubectl -n "$NS" apply -f -

        kubectl -n "$NS" get deploy -o name | xargs -r -n1 kubectl -n "$NS" rollout status --timeout=180s
        echo "PR environment ${NS} is up ✅"
        ;;
    down)
        kubectl delete ns "$NS" --ignore-not-found
        echo "PR environment ${NS} deleted ✅"
        ;;
    *)
        usage;;
esac
