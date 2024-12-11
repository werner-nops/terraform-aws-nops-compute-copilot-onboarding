module "wrapper" {
  source = "../../modules/helm"

  for_each = var.items

  chart_version              = try(each.value.chart_version, var.defaults.chart_version, "")
  cluster_name               = try(each.value.cluster_name, var.defaults.cluster_name)
  container_insights_enabled = try(each.value.container_insights_enabled, var.defaults.container_insights_enabled, true)
  datadog_api_key            = try(each.value.datadog_api_key, var.defaults.datadog_api_key)
  extra_set                  = try(each.value.extra_set, var.defaults.extra_set, {})
  extra_set_sensitive        = try(each.value.extra_set_sensitive, var.defaults.extra_set_sensitive, {})
  karpenops_cluster_id       = try(each.value.karpenops_cluster_id, var.defaults.karpenops_cluster_id)
  karpenops_enabled          = try(each.value.karpenops_enabled, var.defaults.karpenops_enabled, true)
  karpenops_image_tag        = try(each.value.karpenops_image_tag, var.defaults.karpenops_image_tag, "1.23.6")
  nops_api_token             = try(each.value.nops_api_token, var.defaults.nops_api_token)
  s3_bucket_name             = try(each.value.s3_bucket_name, var.defaults.s3_bucket_name, "")
  timeout                    = try(each.value.timeout, var.defaults.timeout, 300)
}
