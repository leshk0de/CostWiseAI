output "dataset_id" {
  description = "The ID of the BigQuery dataset created"
  value       = google_bigquery_dataset.cost_monitoring.dataset_id
}

output "cost_data_table_id" {
  description = "The ID of the cost data table"
  value       = google_bigquery_table.cost_data.table_id
}

output "service_config_table_id" {
  description = "The ID of the service config table"
  value       = google_bigquery_table.service_config.table_id
}

output "cost_summary_view_id" {
  description = "The ID of the cost summary view"
  value       = google_bigquery_table.cost_summary_view.table_id
}

output "model_comparison_view_id" {
  description = "The ID of the model comparison view"
  value       = google_bigquery_table.model_comparison_view.table_id
}