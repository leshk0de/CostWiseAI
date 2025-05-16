variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "dataset_id" {
  description = "The ID of the BigQuery dataset for cost data"
  type        = string
}

variable "location" {
  description = "The location for the BigQuery dataset"
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

variable "cost_data_retention_days" {
  description = "Number of days to retain cost data"
  type        = number
}

variable "labels" {
  description = "Labels to apply to BigQuery resources"
  type        = map(string)
  default     = {}
}