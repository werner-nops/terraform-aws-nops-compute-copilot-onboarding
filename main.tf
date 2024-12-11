resource "nops_compute_copilot_integration" "integration" {
  cluster_arns = local.target_clusters_arns
  region_name  = data.aws_region.current.id
}
