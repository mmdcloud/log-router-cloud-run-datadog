#!/usr/bin/env bash
# ==============================================================================
# Helper build and push script for sample Cloud Run container image
# ==============================================================================
set -euo pipefail

PROJECT_ID="${1:-}"

if [[ -z "$PROJECT_ID" ]]; then
  echo "Usage: $0 <PROJECT_ID>"
  exit 0
fi

echo "Deploying Cloud Run sample image for project: $PROJECT_ID"

