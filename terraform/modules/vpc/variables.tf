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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ)"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for the public subnets, matched by index to public_subnet_cidrs"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == length(var.public_subnet_cidrs)
    error_message = "availability_zones and public_subnet_cidrs must have the same length."
  }
}

variable "tags" {
  description = "Additional tags to merge into all resources"
  type        = map(string)
  default     = {}
}
