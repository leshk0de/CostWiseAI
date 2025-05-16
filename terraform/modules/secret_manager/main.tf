/**
 * # CostWise AI - Secret Manager Module
 *
 * This module creates Secret Manager resources to securely store API keys for AI services.
 */

# Since we can't use the keys of service_credentials (it's sensitive),
# we'll use service_names for all resource creation

# Create secrets for services defined in service_names
resource "google_secret_manager_secret" "service_credentials" {
  for_each = toset(var.service_names)

  project  = var.project_id
  secret_id = "${var.secret_name_prefix}-${lower(each.value)}-api-key"
  
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }

  labels = merge(var.labels, {
    service = lower(each.value)
  })
}

# Dynamically create secret versions for each service in service_names
# that also has a corresponding entry in service_credentials
resource "google_secret_manager_secret_version" "service_credentials_values" {
  # We can't iterate directly over service_credentials keys (sensitive),
  # so we use service_names and then look up values conditionally
  for_each = toset(var.service_names)

  secret      = google_secret_manager_secret.service_credentials[each.key].id
  # Use a default dummy value that will be replaced in real environments
  secret_data = lookup(var.service_credentials, each.key, "dummy-placeholder-for-${each.key}")
}

# Grant access to the secrets for the service account
resource "google_secret_manager_secret_iam_member" "service_account_access" {
  for_each = toset(var.service_names)

  project  = var.project_id
  secret_id = google_secret_manager_secret.service_credentials[each.value].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}
