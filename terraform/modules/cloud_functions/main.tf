/**
 * # CostWise AI - Cloud Functions Module
 *
 * This module deploys the Cloud Functions for AI cost data collection and processing.
 */

# Calculate source code hashes to detect changes
data "external" "source_hash" {
  program = ["bash", "-c", <<-EOT
    {
      echo -n '{'
      echo -n '"data_collection":"'$(find ${path.module}/../../../cloud_functions/data_collection -type f -name "*.py" -print0 | sort -z | xargs -0 md5sum | md5sum | cut -d' ' -f1)'",'
      echo -n '"data_transformation":"'$(find ${path.module}/../../../cloud_functions/data_transformation -type f -name "*.py" -print0 | sort -z | xargs -0 md5sum | md5sum | cut -d' ' -f1)'",'
      echo -n '"admin":"'$(find ${path.module}/../../../cloud_functions/admin -type f -name "*.py" -print0 | sort -z | xargs -0 md5sum | md5sum | cut -d' ' -f1)'"'
      echo '}'
    } | tr -d '\n'
  EOT
  ]
}

# Create source code directories for Cloud Functions and copy source code
resource "null_resource" "create_source_dirs" {
  # Only run when source code changes
  triggers = {
    data_collection_hash     = data.external.source_hash.result.data_collection
    data_transformation_hash = data.external.source_hash.result.data_transformation
    admin_hash               = data.external.source_hash.result.admin
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p ${path.module}/src/data_collection ${path.module}/src/data_transformation ${path.module}/src/admin
      
      # Copy the latest source code from the project directories
      cp -r ${path.module}/../../../cloud_functions/data_collection/* ${path.module}/src/data_collection/
      cp -r ${path.module}/../../../cloud_functions/data_transformation/* ${path.module}/src/data_transformation/
      cp -r ${path.module}/../../../cloud_functions/admin/* ${path.module}/src/admin/
    EOT
  }
}

# Generate random suffix for function names
resource "random_id" "function_suffix" {
  byte_length = 4
}

# Archive source code for the data collection function
data "archive_file" "data_collection_source" {
  type        = "zip"
  source_dir  = "${path.module}/src/data_collection"
  output_path = "/tmp/data_collection_${random_id.function_suffix.hex}.zip"

  depends_on = [null_resource.create_source_dirs]
}

# Upload the data collection function source code
resource "google_storage_bucket_object" "data_collection_archive" {
  name   = "source/data_collection_${random_id.function_suffix.hex}_${data.external.source_hash.result.data_collection}.zip"
  bucket = var.function_source_bucket_name
  source = data.archive_file.data_collection_source.output_path
}

# Deploy the data collection Cloud Function
resource "google_cloudfunctions2_function" "data_collection" {
  project     = var.project_id
  name        = var.data_collection_function_name
  location    = var.region
  description = "Collects usage and cost data from AI service APIs"
  
  labels = merge({
    application = "costwise-ai"
  }, var.labels)

  build_config {
    runtime     = "python310"
    entry_point = "collect_data"  # Set the entry point 
    source {
      storage_source {
        bucket = var.function_source_bucket_name
        object = google_storage_bucket_object.data_collection_archive.name
      }
    }
  }
  
  lifecycle {
    # Ensure a new revision is created when the source code changes
    replace_triggered_by = [
      google_storage_bucket_object.data_collection_archive
    ]
  }

  service_config {
    max_instance_count = 10
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      PROJECT_ID           = var.project_id
      DATASET_ID           = var.dataset_id
      COST_DATA_TABLE_ID   = var.cost_data_table_id
      SERVICE_CONFIG_TABLE_ID = var.service_config_table_id
    }
    service_account_email = var.service_account_email
    
    # Apply VPC connector if enabled
    vpc_connector = var.enable_vpc_connector && var.vpc_connector_name != null ? var.vpc_connector_name : null
    vpc_connector_egress_settings = var.enable_vpc_connector && var.vpc_connector_name != null ? var.vpc_connector_egress_settings : null
  }
}

# Archive source code for the data transformation function
data "archive_file" "data_transformation_source" {
  type        = "zip"
  source_dir  = "${path.module}/src/data_transformation"
  output_path = "/tmp/data_transformation_${random_id.function_suffix.hex}.zip"

  depends_on = [null_resource.create_source_dirs]
}

# Upload the data transformation function source code
resource "google_storage_bucket_object" "data_transformation_archive" {
  name   = "source/data_transformation_${random_id.function_suffix.hex}_${data.external.source_hash.result.data_transformation}.zip"
  bucket = var.function_source_bucket_name
  source = data.archive_file.data_transformation_source.output_path
}

# Deploy the data transformation Cloud Function
resource "google_cloudfunctions2_function" "data_transformation" {
  project     = var.project_id
  name        = var.data_transform_function_name
  location    = var.region
  description = "Transforms raw AI service data into unified format"
  
  labels = merge({
    application = "costwise-ai"
  }, var.labels)

  build_config {
    runtime     = "python310"
    entry_point = "transform_data"  # Set the entry point
    source {
      storage_source {
        bucket = var.function_source_bucket_name
        object = google_storage_bucket_object.data_transformation_archive.name
      }
    }
  }
  
  lifecycle {
    # Ensure a new revision is created when the source code changes
    replace_triggered_by = [
      google_storage_bucket_object.data_transformation_archive
    ]
  }

  service_config {
    max_instance_count = 5
    available_memory   = "512M"
    timeout_seconds    = 120
    environment_variables = {
      PROJECT_ID           = var.project_id
      DATASET_ID           = var.dataset_id
      COST_DATA_TABLE_ID   = var.cost_data_table_id
      SERVICE_CONFIG_TABLE_ID = var.service_config_table_id
    }
    service_account_email = var.service_account_email
    
    # Apply VPC connector if enabled
    vpc_connector = var.enable_vpc_connector && var.vpc_connector_name != null ? var.vpc_connector_name : null
    vpc_connector_egress_settings = var.enable_vpc_connector && var.vpc_connector_name != null ? var.vpc_connector_egress_settings : null
  }
}

# Archive source code for the admin function
data "archive_file" "admin_source" {
  type        = "zip"
  source_dir  = "${path.module}/src/admin"
  output_path = "/tmp/admin_${random_id.function_suffix.hex}.zip"

  depends_on = [null_resource.create_source_dirs]
}

# Upload the admin function source code
resource "google_storage_bucket_object" "admin_archive" {
  name   = "source/admin_${random_id.function_suffix.hex}_${data.external.source_hash.result.admin}.zip"
  bucket = var.function_source_bucket_name
  source = data.archive_file.admin_source.output_path
}

# Deploy the admin Cloud Function
resource "google_cloudfunctions2_function" "admin" {
  project     = var.project_id
  name        = var.admin_function_name
  location    = var.region
  description = "Administrative function for managing service configurations"
  
  labels = merge({
    application = "costwise-ai"
  }, var.labels)

  build_config {
    runtime     = "python310"
    entry_point = "admin_handler"  # Set the entry point
    source {
      storage_source {
        bucket = var.function_source_bucket_name
        object = google_storage_bucket_object.admin_archive.name
      }
    }
  }
  
  lifecycle {
    # Ensure a new revision is created when the source code changes
    replace_triggered_by = [
      google_storage_bucket_object.admin_archive
    ]
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      PROJECT_ID           = var.project_id
      DATASET_ID           = var.dataset_id
      COST_DATA_TABLE_ID   = var.cost_data_table_id
      SERVICE_CONFIG_TABLE_ID = var.service_config_table_id
    }
    service_account_email = var.service_account_email
    
    # Apply VPC connector if enabled
    vpc_connector = var.enable_vpc_connector && var.vpc_connector_name != null ? var.vpc_connector_name : null
    vpc_connector_egress_settings = var.enable_vpc_connector && var.vpc_connector_name != null ? var.vpc_connector_egress_settings : null
  }
}