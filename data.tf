data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_role" "nops_integration_role" {
  name = var.role_name
}

data "aws_eks_clusters" "clusters" {}

data "aws_eks_cluster" "cluster" {
  for_each = local.target_clusters
  name     = each.value
}

data "aws_iam_openid_connect_provider" "provider" {
  for_each = var.create_iam_user == false ? local.target_clusters : toset([])
  url      = data.aws_eks_cluster.cluster[each.value].identity[0].oidc[0].issuer
}
