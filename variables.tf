variable "include_regions" {
  type        = string
  description = "Comma-separated list of regions to include (e.g., us-east-1,us-east-2,us-west-1,us-west-2) or left blank to use the region where the Terraform Stack is being created"
  default     = ""
}

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

variable "token" {
  type        = string
  description = "nOps Client Token"
  sensitive   = true
}

# tflint-ignore: terraform_unused_declarations
variable "auto_update" {
  type        = bool
  description = "Whether to update the stack automatically when a new version is released or not"
  default     = false
  validation {
    condition     = contains([true, false], var.auto_update)
    error_message = "AutoUpdate must be either 'true' or 'false'."
  }
}
