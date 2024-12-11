locals {
  target_clusters      = length(var.cluster_names) == 0 ? toset(data.aws_eks_clusters.clusters.names) : toset([for name in data.aws_eks_clusters.clusters.names : name if contains(var.cluster_names, name)])
  target_clusters_arns = [for cluster in data.aws_eks_cluster.cluster : cluster.arn]
  s3_bucket_name       = "arn:aws:s3:::nops-container-cost-${data.aws_caller_identity.current.account_id}"
  nops_account         = var.environment == "PROD" ? "202279780353" : "844856862745"
}
