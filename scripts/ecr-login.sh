#!/usr/bin/env bash
#
# ecr-login.sh — authenticate Docker to the private ECR registry.
#
# Usage:
#   ./scripts/ecr-login.sh [--region eu-central-1]

set -euo pipefail

REGION="eu-central-1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      REGION="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--region eu-central-1]" >&2
      exit 1
      ;;
  esac
done

for cmd in aws docker; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Logging in to ${REGISTRY}..."
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${REGISTRY}"
