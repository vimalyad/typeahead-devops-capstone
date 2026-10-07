variable "region" {
  type    = string
  default = "us-east-1"
}
variable "operator_cidr" {
  type        = string
  description = "Operator public IPv4 /32 for the Kubernetes API."
  validation {
    condition     = can(cidrhost(var.operator_cidr, 0)) && endswith(var.operator_cidr, "/32")
    error_message = "Supply a single public IPv4 /32."
  }
}
variable "cluster_name" {
  type    = string
  default = "vimal-typeahead-capstone"
}
variable "node_type" {
  type        = string
  default     = "c7i-flex.large"
  description = "One 2-vCPU/4-GiB x86 worker; confirm measured lab usage fits before apply."
}
