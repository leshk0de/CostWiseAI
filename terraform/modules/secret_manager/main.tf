/**
 * # CostWise AI - Secret Manager Module
 *
 * This module creates Secret Manager resources to securely store API keys for AI services.
 */

# Create secrets for each service
resource "google_secret_manager_secret" "service_credentials" {
  for_each = var.service_credentials

  secret_id = "${var.secret_name_prefix}-${lower(each.key)}-api-key"
  
  replication {
    automatic = true
  }

  labels = merge(var.labels, {
    service = lower(each.key)
  })
}

# Store the actual secret values
resource "google_secret_manager_secret_version" "service_credentials_values" {
  for_each = var.service_credentials

  secret      = google_secret_manager_secret.service_credentials[each.key].id
  secret_data = each.value
}

# Grant access to the secrets for the service account
resource "google_secret_manager_secret_iam_member" "service_account_access" {
  for_each = var.service_credentials

  secret_id = google_secret_manager_secret.service_credentials[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}
