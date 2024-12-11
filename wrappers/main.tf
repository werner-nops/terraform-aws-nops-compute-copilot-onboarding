module "wrapper" {
  source = "../"

  for_each = var.items

  cluster_names   = try(each.value.cluster_names, var.defaults.cluster_names, [])
  create_bucket   = try(each.value.create_bucket, var.defaults.create_bucket, true)
  create_iam_user = try(each.value.create_iam_user, var.defaults.create_iam_user, false)
  environment     = try(each.value.environment, var.defaults.environment, "PROD")
  role_name       = try(each.value.role_name, var.defaults.role_name)
}
