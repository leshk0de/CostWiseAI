/**
 * # CostWise AI - Cloud Scheduler Module
 *
 * This module creates Cloud Scheduler jobs for recurring tasks in the CostWise AI system.
 */

# Create a scheduler job for regular data collection
resource "google_cloud_scheduler_job" "data_collection" {
  project          = var.project_id
  name             = var.scheduler_job_name
  description      = "Regularly collect AI service usage and cost data"
  schedule         = var.data_collection_schedule
  time_zone        = "UTC"
  attempt_deadline = "320s"
  region           = var.region
  
  # Note: Cloud Scheduler does not support labels directly
  # We keep the labels variable for consistency across modules, but it's not used here

  http_target {
    http_method = "POST"
    uri         = var.data_collection_function_url
    
    oidc_token {
      service_account_email = var.service_account_email
      audience              = var.data_collection_function_url
    }

    headers = {
      "Content-Type" = "application/json"
    }
  }

  retry_config {
    retry_count = 3
    min_backoff_duration = "1s"
    max_backoff_duration = "10s"
    max_doublings = 2
  }
}
