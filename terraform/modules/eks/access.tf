# kubectl access for the deploying IAM principal.
# Cluster uses API_AND_CONFIG_MAP auth mode with bootstrap_cluster_creator_admin_permissions
# left at its default (false), so admin access is granted explicitly here
# rather than implicitly.
#
# Defaults to the caller currently running `terraform apply` (matches
# PETPLAT-14's "deploying IAM principal" requirement). Set
# cluster_admin_principal_arns to pin an explicit, reviewed list of admin
# ARNs instead of relying on ambient caller identity (e.g. once this moves
# beyond a single-operator learning environment).
#
# To grant additional, non-admin access, add another aws_eks_access_entry +
# aws_eks_access_policy_association pair with a namespace-scoped access_scope
# referencing the target principal's ARN.

locals {
  cluster_admin_principal_arns = length(var.cluster_admin_principal_arns) > 0 ? toset(var.cluster_admin_principal_arns) : toset([data.aws_caller_identity.current.arn])
}

resource "aws_eks_access_entry" "admin" {
  for_each = local.cluster_admin_principal_arns

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"

  tags = local.common_tags
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = local.cluster_admin_principal_arns

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}
