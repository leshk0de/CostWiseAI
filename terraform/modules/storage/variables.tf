variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "location" {
  description = "The location for the storage bucket"
  type        = string
}

variable "function_source_bucket_name" {
  description = "Name of the GCS bucket to store Cloud Function source code"
  type        = string
}

variable "function_service_account" {
  description = "Email of the service account that needs access to the bucket"
  type        = string
}

variable "labels" {
  description = "Labels to apply to storage resources"
  type        = map(string)
  default     = {}
}