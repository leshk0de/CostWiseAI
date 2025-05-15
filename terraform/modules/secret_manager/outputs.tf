output "secret_ids" {
  description = "Map of service names to their Secret Manager secret IDs"
  value = { for k, v in google_secret_manager_secret.service_credentials : k => v.secret_id }
}

output "secret_versions" {
  description = "Map of service names to their Secret Manager secret version IDs"
  value = { for k, v in google_secret_manager_secret_version.service_credentials_values : k => v.id }
  sensitive = true
}