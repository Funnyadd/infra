#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p k8s/base

kompose convert -f docker-compose.yml -o k8s/base

echo "Rendered to k8s/base"
