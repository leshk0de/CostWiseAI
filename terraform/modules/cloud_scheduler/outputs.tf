output "data_collection_job_name" {
  description = "The name of the data collection scheduler job"
  value       = google_cloud_scheduler_job.data_collection.name
}

output "data_collection_job_schedule" {
  description = "The schedule of the data collection job"
  value       = google_cloud_scheduler_job.data_collection.schedule
}

output "scheduler_job_id" {
  description = "The ID of the scheduler job"
  value       = google_cloud_scheduler_job.data_collection.id
}

output "scheduler_job_project" {
  description = "The project ID where the scheduler job is created"
  value       = google_cloud_scheduler_job.data_collection.project
}

output "scheduler_job_region" {
  description = "The region where the scheduler job is created"
  value       = google_cloud_scheduler_job.data_collection.region
}

output "scheduler_job_time_zone" {
  description = "The time zone of the scheduler job"
  value       = google_cloud_scheduler_job.data_collection.time_zone
}

output "scheduler_job_attempt_deadline" {
  description = "The deadline for job attempts"
  value       = google_cloud_scheduler_job.data_collection.attempt_deadline
}

output "scheduler_job_target_uri" {
  description = "The URI of the target endpoint"
  value       = google_cloud_scheduler_job.data_collection.http_target[0].uri
}

output "scheduler_job_http_method" {
  description = "The HTTP method used by the scheduler job"
  value       = google_cloud_scheduler_job.data_collection.http_target[0].http_method
}

output "scheduler_job_headers" {
  description = "The headers used in the HTTP request"
  value       = google_cloud_scheduler_job.data_collection.http_target[0].headers
}

output "scheduler_job_service_account" {
  description = "The service account used for authentication"
  value       = google_cloud_scheduler_job.data_collection.http_target[0].oidc_token[0].service_account_email
}

output "scheduler_job_audience" {
  description = "The audience specified in the OIDC token"
  value       = google_cloud_scheduler_job.data_collection.http_target[0].oidc_token[0].audience
}

output "scheduler_job_retry_config" {
  description = "The retry configuration for the job"
  value = {
    retry_count          = google_cloud_scheduler_job.data_collection.retry_config[0].retry_count
    min_backoff_duration = google_cloud_scheduler_job.data_collection.retry_config[0].min_backoff_duration
    max_backoff_duration = google_cloud_scheduler_job.data_collection.retry_config[0].max_backoff_duration
    max_doublings        = google_cloud_scheduler_job.data_collection.retry_config[0].max_doublings
  }
}