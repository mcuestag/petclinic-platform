#!/usr/bin/env bash
#
# build-push-images.sh — build all 8 Petclinic service JARs with Maven, then
# build+push ARM64 (Graviton) Docker images to ECR with `docker buildx`.
#
# Deliberately does NOT use the app repo's `-P buildDocker` Maven profile
# (that profile builds native-arch images via jib/spring-boot:build-image,
# not ARM64 cross-platform images). Maven is used only to produce the JARs;
# `docker buildx build --platform linux/arm64` builds the actual images,
# since EKS nodes are Graviton (t4g.small) and this workstation is x86_64.
#
# Usage:
#   ./scripts/build-push-images.sh [--env dev] [--tag v1.0.0] [--region eu-central-1] [--app-repo ../spring-petclinic-microservices]
#
# Example:
#   ./scripts/build-push-images.sh --env dev --tag v1.0.0
#
# Equivalent manual commands, for reference:
#   cd ../spring-petclinic-microservices
#   ./mvnw clean package -DskipTests
#   aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.eu-central-1.amazonaws.com
#   docker buildx build --platform linux/arm64 \
#     --build-arg ARTIFACT_NAME=spring-petclinic-config-server-4.0.1 \
#     --build-arg EXPOSED_PORT=8888 \
#     -f docker/Dockerfile -t <account>.dkr.ecr.eu-central-1.amazonaws.com/petclinic-dev/config-server:v1.0.0 \
#     --push spring-petclinic-config-server/target

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENV="dev"
TAG="v1.0.0"
REGION="eu-central-1"
APP_REPO="${SCRIPT_DIR}/../../spring-petclinic-microservices"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENV="$2"
      shift 2
      ;;
    --tag)
      TAG="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --app-repo)
      APP_REPO="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--env dev] [--tag v1.0.0] [--region eu-central-1] [--app-repo path]" >&2
      exit 1
      ;;
  esac
done

if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "Error: --env must be 'dev' or 'prod'." >&2
  exit 1
fi

for cmd in aws docker; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

APP_REPO="$(cd "$APP_REPO" && pwd)"
if [[ ! -x "${APP_REPO}/mvnw" ]]; then
  echo "Error: '${APP_REPO}/mvnw' not found. Pass --app-repo pointing at the spring-petclinic-microservices checkout." >&2
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# module directory : ECR repository name : container port (docker/Dockerfile EXPOSED_PORT build-arg)
SERVICES=(
  "spring-petclinic-config-server:config-server:8888"
  "spring-petclinic-discovery-server:discovery-server:8761"
  "spring-petclinic-api-gateway:api-gateway:8080"
  "spring-petclinic-customers-service:customers-service:8081"
  "spring-petclinic-visits-service:visits-service:8082"
  "spring-petclinic-vets-service:vets-service:8083"
  "spring-petclinic-genai-service:genai-service:8084"
  "spring-petclinic-admin-server:admin-server:9090"
)

echo "== Building JARs with Maven =="
( cd "$APP_REPO" && ./mvnw clean package -DskipTests )

echo "== Logging in to ${REGISTRY} =="
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

echo "== Ensuring a multi-platform buildx builder is ready =="
docker buildx inspect --bootstrap >/dev/null

PUSHED_IMAGES=()

for entry in "${SERVICES[@]}"; do
  IFS=':' read -r module service port <<< "$entry"

  target_dir="${APP_REPO}/${module}/target"
  jar_path=$(find "$target_dir" -maxdepth 1 -name "${module}-*.jar" ! -name "*-plain.jar" | head -1)
  if [[ -z "$jar_path" ]]; then
    echo "Error: no built JAR found in ${target_dir} for ${module}." >&2
    exit 1
  fi
  artifact_name="$(basename "$jar_path" .jar)"

  image="${REGISTRY}/petclinic-${ENV}/${service}:${TAG}"
  echo "== Building and pushing ${image} (linux/arm64) =="

  docker buildx build \
    --platform linux/arm64 \
    --build-arg ARTIFACT_NAME="$artifact_name" \
    --build-arg EXPOSED_PORT="$port" \
    -f "${APP_REPO}/docker/Dockerfile" \
    -t "$image" \
    --push \
    "$target_dir"

  PUSHED_IMAGES+=("$image")
done

echo
echo "Pushed images:"
printf '  %s\n' "${PUSHED_IMAGES[@]}"
