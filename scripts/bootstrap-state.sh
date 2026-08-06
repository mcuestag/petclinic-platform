#!/usr/bin/env bash
#
# bootstrap-state.sh — one-time provisioning of the Terraform remote state backend.
#
# Creates (idempotently):
#   - an S3 bucket for state files, with versioning + encryption + public access blocked
#   - a DynamoDB table for state locking (LockID partition key)
#
# This is run ONCE, outside Terraform, before `terraform init` in any environment.
# See docs/technical-spec.md#terraform-state-backend
#
# Usage:
#   ./scripts/bootstrap-state.sh [--region eu-central-1]

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

for cmd in aws; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="petclinic-terraform-state-${ACCOUNT_ID}"
DYNAMODB_TABLE="petclinic-terraform-locks"

echo "Region:          ${REGION}"
echo "Account ID:      ${ACCOUNT_ID}"
echo "State bucket:    ${BUCKET_NAME}"
echo "Lock table:      ${DYNAMODB_TABLE}"
echo

# --- S3 bucket ---------------------------------------------------------

if aws s3api head-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" 2>/dev/null; then
  echo "S3 bucket '${BUCKET_NAME}' already exists — skipping creation."
else
  echo "Creating S3 bucket '${BUCKET_NAME}'..."
  if [[ "${REGION}" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}"
  else
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
fi

echo "Enabling versioning on '${BUCKET_NAME}'..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

echo "Enabling default server-side encryption (AES256) on '${BUCKET_NAME}'..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }
    ]
  }'

echo "Blocking all public access on '${BUCKET_NAME}'..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# --- DynamoDB table -----------------------------------------------------

if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${REGION}" >/dev/null 2>&1; then
  echo "DynamoDB table '${DYNAMODB_TABLE}' already exists — skipping creation."
else
  echo "Creating DynamoDB table '${DYNAMODB_TABLE}'..."
  aws dynamodb create-table \
    --table-name "${DYNAMODB_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}" \
    --tags Key=Project,Value=petclinic Key=ManagedBy,Value=bootstrap-script

  echo "Waiting for table to become ACTIVE..."
  aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}" --region "${REGION}"
fi

# --- Tag the bucket (matches PETPLAT tagging convention) ---------------

aws s3api put-bucket-tagging \
  --bucket "${BUCKET_NAME}" \
  --tagging "TagSet=[{Key=Project,Value=petclinic},{Key=ManagedBy,Value=bootstrap-script}]"

echo
echo "Bootstrap complete."
echo
echo "Backend values to use in terraform/environments/{dev,prod}/backend.tf:"
echo "  bucket         = \"${BUCKET_NAME}\""
echo "  dynamodb_table = \"${DYNAMODB_TABLE}\""
echo "  region         = \"${REGION}\""
