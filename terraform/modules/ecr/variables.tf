variable "project" {
  description = "Project name, used for resource naming and tagging"
  type        = string
  default     = "petclinic"
}

variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be \"dev\" or \"prod\"."
  }
}

variable "service_names" {
  description = "Service names to create one ECR repository each for, under the petclinic-{env}/ namespace"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "Tag mutability for all repositories (MUTABLE for dev, IMMUTABLE for prod). Required, no default, so every environment must make an explicit choice."
  type        = string

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be \"MUTABLE\" or \"IMMUTABLE\"."
  }
}

variable "tags" {
  description = "Additional tags to merge into all resources"
  type        = map(string)
  default     = {}
}
