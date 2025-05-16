/**
 * # CostWise AI - Main Terraform Configuration
 *
 * This is the main entry point for the CostWise AI infrastructure.
 * It orchestrates all the modules needed for the AI cost monitoring system.
 */

# Call the BigQuery module to set up the data warehouse
module "bigquery" {
  source = "./modules/bigquery"

  project_id                  = var.project_id
  dataset_id                  = var.dataset_id != null ? var.dataset_id : local.names.dataset
  location                    = var.location
  cost_data_table_id          = var.cost_data_table_id
  service_config_table_id     = var.service_config_table_id
  cost_data_retention_days    = var.cost_data_retention_days
  labels                      = local.common_labels
}

# Set up Secret Manager for secure API key storage
module "secret_manager" {
  source = "./modules/secret_manager"

  project_id                  = var.project_id
  service_account_email       = module.iam.service_account_email
  service_credentials         = var.service_credentials != null ? var.service_credentials : {}
  service_names               = var.service_names
  secret_name_prefix          = local.name_prefix
  labels                      = local.common_labels
}

# Configure IAM permissions for the system
module "iam" {
  source = "./modules/iam"

  project_id                  = var.project_id
  service_account_id          = var.service_account_id != null ? var.service_account_id : local.names.service_account
  service_account_name        = var.service_account_name
  region                      = var.location
  labels                      = local.common_labels
  
  # Set to the actual function name (use output after first apply)
  cloud_run_service_name      = try(module.cloud_functions.data_collection_function_name, "")
  
  # Pass the BigQuery dataset ID to restrict permissions to this dataset only
  bigquery_dataset_id         = module.bigquery.dataset_id
}

# Set up storage buckets for Cloud Functions code and other assets
module "storage" {
  source = "./modules/storage"

  project_id                  = var.project_id
  location                    = var.location
  function_source_bucket_name = var.function_source_bucket_name != null ? var.function_source_bucket_name : local.names.function_bucket
  function_service_account    = module.iam.service_account_email
  labels                      = local.common_labels
}

# Deploy Cloud Functions for data collection and processing
module "cloud_functions" {
  source = "./modules/cloud_functions"

  project_id                  = var.project_id
  region                      = var.location
  function_source_bucket_name = module.storage.function_source_bucket_name
  service_account_email       = module.iam.service_account_email
  dataset_id                  = module.bigquery.dataset_id
  cost_data_table_id          = module.bigquery.cost_data_table_id
  service_config_table_id     = module.bigquery.service_config_table_id
  
  # Security-related settings
  enable_vpc_connector        = var.enable_vpc_connector
  vpc_connector_name          = var.vpc_connector_name
  vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"
  
  # API configuration
  api_config                  = var.api_config
  
  # Resource naming
  data_collection_function_name = local.names.data_collection_function
  data_transform_function_name  = local.names.data_transform_function
  admin_function_name           = local.names.admin_function
  
  # Common labels
  labels                      = local.common_labels
}

# Set up scheduled jobs to collect data regularly
module "cloud_scheduler" {
  source = "./modules/cloud_scheduler"

  project_id                  = var.project_id
  region                      = var.location
  service_account_email       = module.iam.service_account_email
  data_collection_schedule    = var.data_collection_schedule
  data_collection_function_url = module.cloud_functions.data_collection_function_url
  scheduler_job_name          = local.names.collection_job
  labels                      = local.common_labels
}