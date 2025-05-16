variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "service_account_id" {
  description = "The ID for the service account"
  type        = string
}

variable "service_account_name" {
  description = "Display name for the service account"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "cloud_run_service_name" {
  description = "Name of the Cloud Run service to grant invoker permissions to"
  type        = string
  default     = ""
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
}

variable "bigquery_dataset_id" {
  description = "The ID of the BigQuery dataset to grant permissions for"
  type        = string
  default     = "costwise_ai"  # Default value matching your dataset name
}