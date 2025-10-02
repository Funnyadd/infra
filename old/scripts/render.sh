#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Requirements
command -v kompose >/dev/null 2>&1 || { echo "ERROR: kompose not found. Install it and retry."; exit 1; }
[[ -f docker-compose.yml ]] || { echo "ERROR: docker-compose.yml not found in repo root."; exit 1; }

# Fresh output dir
mkdir -p k8s/base
rm -f k8s/base/*.yml k8s/base/*.yaml 2>/dev/null || true

# Convert compose -> k8s manifests
kompose convert -f docker-compose.yml -o k8s/base

# Create a kustomization.yaml that includes all generated files
cd k8s/base
FILES=$(ls *.y*ml 2>/dev/null || true)
if [[ -z "${FILES}" ]]; then
  echo "ERROR: Kompose generated no YAML files"; exit 1
fi

cat > kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
$(f
