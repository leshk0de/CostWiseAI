/**
 * # CostWise AI - BigQuery Module
 *
 * This module creates the BigQuery resources needed for storing AI service usage and cost data.
 */

# Create a dataset for all AI cost monitoring data
# Format dataset_id to ensure it contains only letters, numbers, or underscores
locals {
  formatted_dataset_id = replace(var.dataset_id, "-", "_")
}

resource "google_bigquery_dataset" "cost_monitoring" {
  project                     = var.project_id
  dataset_id                  = local.formatted_dataset_id
  friendly_name               = "AI Cost Monitoring"
  description                 = "Dataset for storing AI service usage and cost data"
  location                    = var.location
  default_table_expiration_ms = var.cost_data_retention_days * 24 * 60 * 60 * 1000

  labels = merge({
    application = "costwise-ai"
  }, var.labels)

  # Default access for dataset
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }

  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }
}

# Create a table for detailed cost data with proper partitioning and clustering
resource "google_bigquery_table" "cost_data" {
  project   = var.project_id
  dataset_id = google_bigquery_dataset.cost_monitoring.dataset_id
  table_id   = var.cost_data_table_id
  
  schema = file("${path.module}/schemas/cost_data_schema.json")

  time_partitioning {
    type                     = "DAY"
    field                    = "timestamp"
    require_partition_filter = true
    expiration_ms            = var.cost_data_retention_days * 24 * 60 * 60 * 1000
  }

  clustering = ["service_name", "model"]

  description = "AI service usage and cost data with daily partitioning"
  labels = merge({
    application = "costwise-ai"
  }, var.labels)
}

# Create a table for service configurations
resource "google_bigquery_table" "service_config" {
  project   = var.project_id
  dataset_id = google_bigquery_dataset.cost_monitoring.dataset_id
  table_id   = var.service_config_table_id

  schema = file("${path.module}/schemas/service_config_schema.json")

  description = "Configuration data for AI services being monitored"
  labels = merge({
    application = "costwise-ai"
  }, var.labels)
}

# Create a view for simplified cost analysis
resource "google_bigquery_table" "cost_summary_view" {
  project   = var.project_id
  dataset_id = google_bigquery_dataset.cost_monitoring.dataset_id
  table_id   = "cost_summary_view"
  view {
    query = <<SQL
SELECT
  DATE(timestamp) as date,
  service_name,
  model,
  feature,
  project,
  COUNT(*) as request_count,
  SUM(input_tokens) as total_input_tokens,
  SUM(output_tokens) as total_output_tokens,
  SUM(total_tokens) as total_tokens,
  SUM(cost) as total_cost
FROM
  `${var.project_id}.${google_bigquery_dataset.cost_monitoring.dataset_id}.${var.cost_data_table_id}`
GROUP BY
  date, service_name, model, feature, project
ORDER BY
  date DESC, total_cost DESC
SQL
    use_legacy_sql = false
  }

  description = "Summarized daily cost data by service and model"
  labels = merge({
    application = "costwise-ai"
  }, var.labels)
}

# Create a view for model comparison
resource "google_bigquery_table" "model_comparison_view" {
  project   = var.project_id
  dataset_id = google_bigquery_dataset.cost_monitoring.dataset_id
  table_id   = "model_comparison_view"
  view {
    query = <<SQL
SELECT
  service_name,
  model,
  COUNT(*) as request_count,
  SUM(input_tokens) as total_input_tokens,
  SUM(output_tokens) as total_output_tokens,
  SUM(total_tokens) as total_tokens,
  SUM(cost) as total_cost,
  SUM(cost) / SUM(total_tokens) * 1000 as cost_per_1k_tokens,
  AVG(response_time_ms) as avg_response_time_ms
FROM
  `${var.project_id}.${google_bigquery_dataset.cost_monitoring.dataset_id}.${var.cost_data_table_id}`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY
  service_name, model
ORDER BY
  cost_per_1k_tokens ASC
SQL
    use_legacy_sql = false
  }

  description = "Comparison of different AI models by cost efficiency"
  labels = merge({
    application = "costwise-ai"
  }, var.labels)
}

# Create directories for schema files
resource "null_resource" "create_schema_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/schemas"
  }
}
