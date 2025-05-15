/**
 * # CostWise AI Staging - Variables
 *
 * This file defines variables specific to the staging environment.
 */

# Environment Configuration
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"
}

variable "resource_prefix" {
  description = "Prefix to apply to resource names"
  type        = string
  default     = "costwise"
}

# GCP Project Configuration
variable "project_id" {
  description = "The Google Cloud Project ID where resources will be deployed"
  type        = string
}

variable "location" {
  description = "The default location/region for resources"
  type        = string
  default     = "us-central1"
}

# BigQuery Configuration
variable "dataset_id" {
  description = "The ID of the BigQuery dataset for cost data (if not using auto-generated name)"
  type        = string
  default     = null
}

variable "cost_data_table_id" {
  description = "The ID of the BigQuery table for cost data"
  type        = string
  default     = "usage_costs"
}

variable "service_config_table_id" {
  description = "The ID of the BigQuery table for service configurations"
  type        = string
  default     = "service_configs"
}

variable "cost_data_retention_days" {
  description = "Number of days to retain cost data"
  type        = number
  default     = 730  # 2 years for staging
}

# Service Account Configuration
variable "service_account_id" {
  description = "The ID for the service account used by Cloud Functions (if not using auto-generated name)"
  type        = string
  default     = null
}

variable "service_account_name" {
  description = "Display name for the service account"
  type        = string
  default     = "CostWise AI Staging Service Account"
}

# Storage Configuration
variable "function_source_bucket_name" {
  description = "Name of the GCS bucket to store Cloud Function source code (if not using auto-generated name)"
  type        = string
  default     = null
}

# Cloud Scheduler Configuration
variable "data_collection_schedule" {
  description = "Cron schedule for data collection jobs"
  type        = string
  default     = "0 */8 * * *"  # Every 8 hours for staging
}

# Service Credentials
variable "service_credentials" {
  description = "Map of service names to their API credentials"
  type        = map(string)
  sensitive   = true
  default     = {}
}

# API Configuration
variable "api_config" {
  description = "Configuration for external APIs"
  type = object({
    anthropic_api_url   = string
    openai_api_url      = string
    perplexity_api_url  = string
  })
  default = {
    anthropic_api_url   = "https://api.anthropic.com/v1"
    openai_api_url      = "https://api.openai.com/v1"
    perplexity_api_url  = "https://api.perplexity.ai"
  }
}

# Security Configuration
variable "enable_vpc_connector" {
  description = "Whether to enable VPC connector for Cloud Functions"
  type        = bool
  default     = true  # Enabled by default in staging
}

variable "vpc_connector_name" {
  description = "Name of the VPC connector to use with Cloud Functions (if enable_vpc_connector is true)"
  type        = string
  default     = null
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP CIDR ranges for accessing the services"
  type        = list(string)
  default     = []
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Whether to enable Cloud Monitoring alerts"
  type        = bool
  default     = true
}

variable "alert_notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}