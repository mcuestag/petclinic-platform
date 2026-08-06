# Remote state backend — see docs/technical-spec.md#terraform-state-backend
# Bucket and DynamoDB table are provisioned once via scripts/bootstrap-state.sh
terraform {
  backend "s3" {
    bucket         = "petclinic-terraform-state-015229745250"
    key            = "petclinic/prod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "petclinic-terraform-locks"
    encrypt        = true
  }
}
