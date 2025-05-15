/**
 * # CostWise AI - Outputs
 *
 * This file defines the outputs from the Terraform deployment.
 */

output "bigquery_dataset_id" {
  description = "The ID of the BigQuery dataset created for AI cost data"
  value       = module.bigquery.dataset_id
}

output "service_account_email" {
  description = "The email of the service account used by Cloud Functions"
  value       = module.iam.service_account_email
}

output "function_source_bucket" {
  description = "The GCS bucket storing Cloud Function source code"
  value       = module.storage.function_source_bucket_name
}

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

output "deployed_services" {
  description = "List of AI services currently configured for monitoring"
  value       = module.cloud_functions.deployed_services
}