data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_s3_bucket" "bucket" {
  bucket = "nops-container-cost-${data.aws_caller_identity.current.account_id}"
}
