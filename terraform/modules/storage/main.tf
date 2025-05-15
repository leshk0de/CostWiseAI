/**
 * # CostWise AI - Storage Module
 *
 * This module creates the Google Cloud Storage resources needed for the CostWise AI system.
 */

# Create a bucket for Cloud Functions source code
resource "google_storage_bucket" "function_source" {
  name     = var.function_source_bucket_name
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
  
  labels = {
    environment = "production"
    application = "costwise-ai"
  }
}

# Grant access to the service account
resource "google_storage_bucket_iam_member" "function_source_access" {
  bucket = google_storage_bucket.function_source.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.function_service_account}"
}
