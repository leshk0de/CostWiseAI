/**
 * # CostWise AI - Staging Environment Configuration
 *
 * This is the main entry point for the staging environment of CostWise AI.
 */

module "costwise_ai" {
  source = "../../"

  # Environment Configuration
  environment                 = var.environment
  resource_prefix             = var.resource_prefix

  # General Configuration
  project_id                  = var.project_id
  location                    = var.location
  
  # BigQuery Configuration
  dataset_id                  = var.dataset_id
  cost_data_table_id          = var.cost_data_table_id
  service_config_table_id     = var.service_config_table_id
  cost_data_retention_days    = var.cost_data_retention_days
  
  # Service Account Configuration
  service_account_id          = var.service_account_id
  service_account_name        = var.service_account_name
  
  # Storage Configuration
  function_source_bucket_name = var.function_source_bucket_name
  
  # Scheduler Configuration
  data_collection_schedule    = var.data_collection_schedule
  
  # Service Credentials
  service_credentials         = var.service_credentials
  
  # API Configuration
  api_config                  = var.api_config
  
  # Security Configuration
  enable_vpc_connector        = var.enable_vpc_connector
  vpc_connector_name          = var.vpc_connector_name
  allowed_ip_ranges           = var.allowed_ip_ranges
  
  # Monitoring Configuration
  enable_monitoring           = var.enable_monitoring
  alert_notification_channels = var.alert_notification_channels
}