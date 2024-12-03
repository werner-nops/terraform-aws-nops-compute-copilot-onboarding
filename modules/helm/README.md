# nOps AWS Compute Copilot Helm Installation Terraform Module

## Description
This module installs the nOps Compute Copilot on an EKS cluster.

## Features
- Creation of a helm release to install the Compute Copilot service on an EKS cluster

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
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.9.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.compute_copilot](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_s3_bucket.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Compute Copilot chart version to install. | `string` | `""` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name where the agent will be deployed. | `string` | n/a | yes |
| <a name="input_container_insights_enabled"></a> [container\_insights\_enabled](#input\_container\_insights\_enabled) | Whether to enable container insights on installation. | `bool` | `true` | no |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | Datadog API key to be used to monitor the agent. | `string` | n/a | yes |
| <a name="input_extra_set"></a> [extra\_set](#input\_extra\_set) | Map with extra values to add to chart installation. | <pre>map(object({<br>    name  = string,<br>    value = string,<br>    type  = optional(string, "auto")<br>  }))</pre> | `{}` | no |
| <a name="input_extra_set_sensitive"></a> [extra\_set\_sensitive](#input\_extra\_set\_sensitive) | Map with extra sensitive values to add to chart installation. | <pre>map(object({<br>    name  = string,<br>    value = string,<br>    type  = optional(string, "auto")<br>  }))</pre> | `{}` | no |
| <a name="input_karpenops_cluster_id"></a> [karpenops\_cluster\_id](#input\_karpenops\_cluster\_id) | nOps value to be used by the karpenops service. | `string` | n/a | yes |
| <a name="input_karpenops_enabled"></a> [karpenops\_enabled](#input\_karpenops\_enabled) | Whether to enable karpenops on installation. | `bool` | `true` | no |
| <a name="input_karpenops_image_tag"></a> [karpenops\_image\_tag](#input\_karpenops\_image\_tag) | Image tag to use for the karpenops service. | `string` | n/a | yes |
| <a name="input_nops_api_token"></a> [nops\_api\_token](#input\_nops\_api\_token) | API token to authenticate with the nOps platform. | `string` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout to be set for chart installation. | `number` | `300` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
