/**
 * # CostWise AI - Local Values
 *
 * This file defines local values and name generation functions for consistent resource naming.
 */

locals {
  # Environment information
  environment     = var.environment
  resource_prefix = var.resource_prefix != "" ? var.resource_prefix : "costwise"
  
  # Naming function for resources
  name_prefix = "${local.resource_prefix}-${local.environment}"
  
  # Resource name generator with consistent patterns
  names = {
    # BigQuery resources
    dataset           = "${replace(local.name_prefix, "-", "_")}_ai_cost_monitoring"
    cost_data_table   = "usage_costs"
    config_table      = "service_configs"
    
    # Storage resources
    function_bucket   = "${local.name_prefix}-functions-${random_id.suffix.hex}"
    
    # Service account
    service_account   = "${local.name_prefix}-sa"
    
    # Cloud Functions
    data_collection_function   = "${local.name_prefix}-data-collection"
    data_transform_function    = "${local.name_prefix}-data-transform"
    admin_function             = "${local.name_prefix}-admin"
    
    # Cloud Scheduler jobs
    collection_job    = "${local.name_prefix}-collection-job"
    
    # Secret naming pattern
    secret_pattern    = "${local.name_prefix}-{service}-api-key"
  }
  
  # Common tags/labels applied to all resources
  common_labels = {
    environment = local.environment
    project     = "costwise-ai"
    managed_by  = "terraform"
  }
}

# Generate a random suffix for globally unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}