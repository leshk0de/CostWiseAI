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

# Making service_names optional allows for fully dynamic secrets
# If service_names is provided, it acts as a superset of names to create
# If not provided, secrets are only created for keys in service_credentials

variable "service_names" {
  description = "List of service names to create secrets for (used to work around sensitive value for_each issue)"
  type        = list(string)
  default     = []  
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