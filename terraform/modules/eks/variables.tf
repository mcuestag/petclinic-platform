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

variable "region" {
  description = "AWS region the cluster is deployed in (used to build the kubeconfig update command)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_admin_principal_arns" {
  description = "IAM principal ARNs to grant EKS cluster-admin access. Defaults to the caller running terraform apply (the deploying IAM principal) when left empty."
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster and node group (public subnets, all-public design)"
  type        = list(string)
}

variable "cluster_sg_id" {
  description = "EKS cluster (control plane) security group ID"
  type        = string
}

variable "node_sg_id" {
  description = "EKS worker node security group ID"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["t4g.small"]
}

variable "node_ami_type" {
  description = "AMI type for the managed node group"
  type        = string
  default     = "AL2023_ARM_64_STANDARD"
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.node_min_size <= var.node_desired_size && var.node_desired_size <= var.node_max_size
    error_message = "node_desired_size must be between node_min_size and node_max_size."
  }
}

variable "node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

variable "coredns_addon_version" {
  description = "Pinned version of the coredns EKS add-on"
  type        = string
  default     = "v1.12.4-eksbuild.18"
}

variable "kube_proxy_addon_version" {
  description = "Pinned version of the kube-proxy EKS add-on"
  type        = string
  default     = "v1.34.6-eksbuild.17"
}

variable "vpc_cni_addon_version" {
  description = "Pinned version of the vpc-cni EKS add-on"
  type        = string
  default     = "v1.22.3-eksbuild.1"
}

variable "ebs_csi_addon_version" {
  description = "Pinned version of the aws-ebs-csi-driver EKS add-on"
  type        = string
  default     = "v1.63.1-eksbuild.1"
}

variable "tags" {
  description = "Additional tags to merge into all resources"
  type        = map(string)
  default     = {}
}
