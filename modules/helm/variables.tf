variable "nops_api_token" {
  type        = string
  description = "API token to authenticate with the nOps platform."
}

variable "chart_version" {
  type        = string
  description = "Compute Copilot chart version to install."
  default     = ""
}

variable "timeout" {
  type        = number
  description = "Timeout to be set for chart installation."
  default     = 300
}

variable "extra_set" {
  description = "Map with extra values to add to chart installation."
  type = map(object({
    name  = string,
    value = string,
    type  = optional(string, "auto")
  }))
  default = {}
}

variable "extra_set_sensitive" {
  description = "Map with extra sensitive values to add to chart installation."
  type = map(object({
    name  = string,
    value = string,
    type  = optional(string, "auto")
  }))
  default = {}
}

variable "datadog_api_key" {
  type        = string
  sensitive   = true
  description = "Datadog API key to be used to monitor the agent."
}

variable "container_insights_enabled" {
  type        = bool
  description = "Whether to enable container insights on installation."
  default     = true
}

variable "karpenops_enabled" {
  type        = bool
  description = "Whether to enable karpenops on installation."
  default     = true
}

variable "karpenops_image_tag" {
  type        = string
  description = "Image tag to use for the karpenops service."
}

variable "karpenops_cluster_id" {
  type        = string
  description = "nOps value to be used by the karpenops service."
}

variable "cluster_name" {
  type        = string
  description = "Cluster name where the agent will be deployed."
}
