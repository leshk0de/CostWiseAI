variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "The region for Cloud Scheduler jobs"
  type        = string
}

variable "service_account_email" {
  description = "Email of the service account used by Cloud Scheduler"
  type        = string
}

variable "data_collection_schedule" {
  description = "Cron schedule for data collection job"
  type        = string
}

variable "data_collection_function_url" {
  description = "URL of the data collection Cloud Function"
  type        = string
}

variable "labels" {
  description = "Labels for consistent module interface (not used - Cloud Scheduler doesn't support labels)"
  type        = map(string)
  default     = {}
}

variable "scheduler_job_name" {
  description = "Name for the Cloud Scheduler job"
  type        = string
  default     = "costwise-ai-data-collection"
}