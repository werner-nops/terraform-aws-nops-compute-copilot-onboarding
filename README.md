# nOps AWS Compute Copilot Onboarding Terraform Module

## Description


## Features
- Creation of an IAM role per cluster in a region or targeted clusters

## Prerequisites

- Terraform v1.0+
- AWS CLI configured with appropriate permissions
- nOps API key

## Usage

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.nops_ccost_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.nops_cross_account_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.nops_ccost_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.nops_cross_account_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.nops_read_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_user.iam_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy.attach_policy_to_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_s3_bucket.nops_container_cost](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.nops_bucket_deny_insecure_transport](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.nops_bucket_block_public_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.nops_bucket_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_clusters.clusters](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_clusters) | data source |
| [aws_iam_openid_connect_provider.provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_role.nops_integration_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_names"></a> [cluster\_names](#input\_cluster\_names) | EKS cluster name targeted to deploy resources, keep empty to create roles for all EKS clusters in this region. | `list(string)` | `[]` | no |
| <a name="input_create_iam_user"></a> [create\_iam\_user](#input\_create\_iam\_user) | Whether to create an IAM user (true or false), this is to support EKS clusters that do not have an IAM OIDC provider configured | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | nOps Environment | `string` | `"PROD"` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | The name of the IAM role to attach the read policy, it should be the same as the integration role created when onboarding into nOps. | `string` | n/a | yes |
| <a name="input_token"></a> [token](#input\_token) | nOps API Client Token | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_clusters"></a> [eks\_clusters](#output\_eks\_clusters) | Selected EKS clusters metadata |
| <a name="output_nops_ccost_role_arn"></a> [nops\_ccost\_role\_arn](#output\_nops\_ccost\_role\_arn) | The ARN of the role to be used by the agent. |
| <a name="output_nops_ccost_user_arn"></a> [nops\_ccost\_user\_arn](#output\_nops\_ccost\_user\_arn) | The ARN of the role to be used by the agent. |
| <a name="output_nops_cross_account_role_arn"></a> [nops\_cross\_account\_role\_arn](#output\_nops\_cross\_account\_role\_arn) | the ARN of the role used by nOps for cross account access to access the S3 bucket. |
<!-- END_TF_DOCS -->
