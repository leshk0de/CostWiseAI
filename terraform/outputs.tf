/**
 * # CostWise AI - Outputs
 *
 * This file defines the outputs from the Terraform deployment.
 */

# Basic infrastructure outputs
output "project_id" {
  description = "The Google Cloud Project ID where CostWise AI is deployed"
  value       = var.project_id
}

output "region" {
  description = "The region where CostWise AI resources are deployed"
  value       = var.location
}

# BigQuery outputs
output "bigquery_dataset_id" {
  description = "The ID of the BigQuery dataset created for AI cost data"
  value       = module.bigquery.dataset_id
}

output "cost_data_table_id" {
  description = "The ID of the cost data table"
  value       = module.bigquery.cost_data_table_id
}

output "service_config_table_id" {
  description = "The ID of the service configuration table"
  value       = module.bigquery.service_config_table_id
}

# IAM outputs
output "service_account_email" {
  description = "The email of the service account used by Cloud Functions"
  value       = module.iam.service_account_email
}

# Storage outputs
output "function_source_bucket" {
  description = "The GCS bucket storing Cloud Function source code"
  value       = module.storage.function_source_bucket_name
}

# Cloud Function URLs
output "data_collection_function_url" {
  description = "The URL of the data collection Cloud Function"
  value       = module.cloud_functions.data_collection_function_url
}

output "data_transformation_function_url" {
  description = "The URL of the data transformation Cloud Function"
  value       = module.cloud_functions.data_transformation_function_url
}

output "admin_function_url" {
  description = "The URL of the admin Cloud Function"
  value       = module.cloud_functions.admin_function_url
}

# Function names (for IAM permissions)
output "data_collection_function_name" {
  description = "Name of the data collection function"
  value       = module.cloud_functions.data_collection_function_name
}

# Service information
output "deployed_services" {
  description = "List of AI services currently configured for monitoring"
  value       = module.cloud_functions.deployed_services
}

# Cloud Scheduler outputs
output "scheduler_job_name" {
  description = "The name of the Cloud Scheduler job"
  value       = module.cloud_scheduler.data_collection_job_name
}

output "scheduler_job_schedule" {
  description = "The schedule for the data collection job"
  value       = module.cloud_scheduler.data_collection_job_schedule
}