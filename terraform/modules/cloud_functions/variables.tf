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

variable "labels" {
  description = "Labels to apply to Cloud Function resources"
  type        = map(string)
  default     = {}
}

variable "enable_vpc_connector" {
  description = "Whether to enable VPC connector for the Cloud Functions"
  type        = bool
  default     = false
}

variable "vpc_connector_name" {
  description = "Name of the VPC connector to use with Cloud Functions"
  type        = string
  default     = null
}

variable "vpc_connector_egress_settings" {
  description = "VPC connector egress settings for Cloud Functions"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
  validation {
    condition     = contains(["PRIVATE_RANGES_ONLY", "ALL_TRAFFIC"], var.vpc_connector_egress_settings)
    error_message = "The vpc_connector_egress_settings must be either PRIVATE_RANGES_ONLY or ALL_TRAFFIC."
  }
}

variable "api_config" {
  description = "Configuration for API Gateway"
  type        = map(string)
  default     = {}
}

variable "data_collection_function_name" {
  description = "Name for the data collection function"
  type        = string
  default     = "costwise-ai-data-collection"
}

variable "data_transform_function_name" {
  description = "Name for the data transformation function"
  type        = string
  default     = "costwise-ai-data-transformation"
}

variable "admin_function_name" {
  description = "Name for the admin function"
  type        = string
  default     = "costwise-ai-admin"
}