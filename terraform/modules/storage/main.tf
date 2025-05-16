/**
 * # CostWise AI - Storage Module
 *
 * This module creates the Google Cloud Storage resources needed for the CostWise AI system.
 */

# Generate random pet name for bucket uniqueness
resource "random_pet" "bucket_suffix" {
  length    = 2
  separator = "-"
}

# Create a bucket for Cloud Functions source code
resource "google_storage_bucket" "function_source" {
  project  = var.project_id
  name     = "${var.function_source_bucket_name}-${random_pet.bucket_suffix.id}"
  location = var.location
  
  uniform_bucket_level_access = true
  force_destroy               = false
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }
  
  labels = merge({
    application = "costwise-ai"
  }, var.labels)
}

# Grant access to the service account
resource "google_storage_bucket_iam_member" "function_source_access" {
  bucket = google_storage_bucket.function_source.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.function_service_account}"
}
