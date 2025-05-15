variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "The region to deploy Cloud Functions"
  type        = string
}

variable "function_source_bucket_name" {
  description = "Name of the GCS bucket to store Cloud Function source code"
  type        = string
}

variable "service_account_email" {
  description = "Email of the service account used by Cloud Functions"
  type        = string
}

variable "dataset_id" {
  description = "The ID of the BigQuery dataset for cost data"
  type        = string
}

variable "cost_data_table_id" {
  description = "The ID of the BigQuery table for cost data"
  type        = string
}

variable "service_config_table_id" {
  description = "The ID of the BigQuery table for service configurations"
  type        = string
}