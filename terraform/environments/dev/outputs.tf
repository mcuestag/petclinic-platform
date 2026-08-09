output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.internet_gateway_id
}

output "eks_cluster_sg_id" {
  description = "EKS cluster (control plane) security group ID"
  value       = module.vpc.eks_cluster_sg_id
}

output "eks_node_sg_id" {
  description = "EKS worker node security group ID"
  value       = module.vpc.eks_node_sg_id
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = module.vpc.rds_sg_id
}

output "alb_sg_id" {
  description = "ALB security group ID"
  value       = module.vpc.alb_sg_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate (base64)"
  value       = module.eks.cluster_ca_certificate
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN (for IRSA trust policies)"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL (for IRSA trust policies)"
  value       = module.eks.oidc_provider_url
}

output "node_group_name" {
  description = "Managed node group name"
  value       = module.eks.node_group_name
}

output "node_role_arn" {
  description = "Node IAM role ARN"
  value       = module.eks.node_role_arn
}

output "ebs_csi_role_arn" {
  description = "IRSA role ARN for the EBS CSI Driver add-on"
  value       = module.eks.ebs_csi_role_arn
}

output "kubeconfig_command" {
  description = "Command to update the local kubeconfig for this cluster"
  value       = module.eks.kubeconfig_command
}
