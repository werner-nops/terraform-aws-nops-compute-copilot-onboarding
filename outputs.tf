output "eks_clusters" {
  description = "Selected EKS clusters metadata"
  value       = data.aws_eks_cluster.cluster
}

output "nops_cross_account_role_arn" {
  description = "the ARN of the role used by nOps for cross account access to access the S3 bucket."
  value       = aws_iam_role.nops_cross_account_role.arn
}

output "nops_ccost_role_arn" {
  description = "The ARN of the role to be used by the agent."
  value       = !var.create_iam_user ? aws_iam_role.nops_ccost_role[0].arn : ""
}

output "nops_ccost_user_arn" {
  description = "The ARN of the role to be used by the agent."
  value       = !var.create_iam_user ? aws_iam_user.iam_user[0].arn : ""
}
