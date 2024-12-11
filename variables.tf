variable "role_name" {
  type        = string
  description = "The name of the IAM role to attach the read policy, it should be the same as the integration role created when onboarding into nOps."
}

variable "create_iam_user" {
  type        = bool
  description = "Whether to create an IAM user (true or false), this is to support EKS clusters that do not have an IAM OIDC provider configured"
  default     = false
  validation {
    condition     = contains([true, false], var.create_iam_user)
    error_message = "create_iam_user must be either true or false."
  }
}

variable "environment" {
  type        = string
  description = "nOps Environment"
  default     = "PROD"
  validation {
    condition     = contains(["PROD", "UAT"], var.environment)
    error_message = "Environment must be either 'PROD' or 'UAT'."
  }
}

variable "cluster_names" {
  type        = list(string)
  description = "EKS cluster name targeted to deploy resources, keep empty to create roles for all EKS clusters in this region."
  default     = []
}

variable "create_bucket" {
  type        = bool
  description = "Whether to create the S3 bucket or not, this variable can be used for cases where the bucket is already present or in another region."
  default     = true
}
