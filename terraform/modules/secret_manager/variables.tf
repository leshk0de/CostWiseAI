variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "service_account_email" {
  description = "Email of the service account that needs access to secrets"
  type        = string
}

variable "service_credentials" {
  description = "Map of service names to their API credentials"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "secret_name_prefix" {
  description = "Prefix to apply to secret names"
  type        = string
  default     = "costwise"
}

variable "labels" {
  description = "Labels to apply to all secrets"
  type        = map(string)
  default     = {}
}