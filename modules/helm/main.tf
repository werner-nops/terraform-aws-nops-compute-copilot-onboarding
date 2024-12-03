resource "helm_release" "compute_copilot" {
  name             = "nops-kubernetes-agent"
  repository       = "oci://public.ecr.aws/nops/kubernetes-agent"
  chart            = "."
  version          = var.chart_version
  namespace        = "nops"
  create_namespace = true
  reset_values     = false
  timeout          = var.timeout

  set_sensitive {
    name  = "nops.apiKey"
    value = var.nops_api_token
  }

  set_sensitive {
    name  = "datadog.apiKey"
    value = var.datadog_api_key
  }

  set {
    name  = "containerInsights.enabled"
    value = var.container_insights_enabled
  }

  set {
    name  = "containerInsights.env_variables.APP_NOPS_K8S_AGENT_CLUSTER_ARN"
    value = data.aws_eks_cluster.cluster.arn
  }

  set {
    name  = "containerInsights.env_variables.APP_AWS_S3_BUCKET"
    value = data.aws_s3_bucket.bucket.id
  }

  set {
    name  = "karpenops.enabled"
    value = var.karpenops_enabled
  }

  set {
    name  = "karpenops.image.tag"
    value = var.karpenops_image_tag
  }

  set {
    name  = "karpenops.clusterId"
    value = var.karpenops_cluster_id
  }

  dynamic "set" {
    for_each = var.extra_set
    content {
      name  = set.value.name
      value = set.value.value
      type  = set.value.type
    }
  }

  dynamic "set_sensitive" {
    for_each = var.extra_set_sensitive
    content {
      name  = set_sensitive.value.name
      value = set_sensitive.value.value
      type  = set_sensitive.value.type
    }
  }
}
