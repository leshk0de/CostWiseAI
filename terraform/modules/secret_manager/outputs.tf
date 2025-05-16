output "secret_ids" {
  description = "Map of service names to their Secret Manager secret IDs"
  value = { for name in var.service_names : name => google_secret_manager_secret.service_credentials[name].secret_id }
}

output "secret_versions" {
  description = "Map of service names to their Secret Manager secret version IDs"
  value = { for name in var.service_names : name => google_secret_manager_secret_version.service_credentials_values[name].id }
  sensitive = true
}