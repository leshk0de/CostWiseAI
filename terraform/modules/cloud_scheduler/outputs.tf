output "data_collection_job_name" {
  description = "The name of the data collection scheduler job"
  value       = google_cloud_scheduler_job.data_collection.name
}

output "data_collection_job_schedule" {
  description = "The schedule of the data collection job"
  value       = google_cloud_scheduler_job.data_collection.schedule
}