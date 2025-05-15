/**
 * # CostWise AI - Cloud Scheduler Module
 *
 * This module creates Cloud Scheduler jobs for recurring tasks in the CostWise AI system.
 */

# Create a scheduler job for regular data collection
resource "google_cloud_scheduler_job" "data_collection" {
  name             = "costwise-ai-data-collection"
  description      = "Regularly collect AI service usage and cost data"
  schedule         = var.data_collection_schedule
  time_zone        = "UTC"
  attempt_deadline = "320s"
  region           = var.region

  http_target {
    http_method = "POST"
    uri         = var.data_collection_function_url
    
    oidc_token {
      service_account_email = var.service_account_email
      audience              = var.data_collection_function_url
    }
  }

  retry_config {
    retry_count = 3
    min_backoff_duration = "1s"
    max_backoff_duration = "10s"
    max_doublings = 2
  }
}
