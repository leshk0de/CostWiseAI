output "data_collection_function_url" {
  description = "The URL of the data collection Cloud Function"
  value       = google_cloudfunctions2_function.data_collection.service_config[0].uri
}

output "data_transformation_function_url" {
  description = "The URL of the data transformation Cloud Function"
  value       = google_cloudfunctions2_function.data_transformation.service_config[0].uri
}

output "admin_function_url" {
  description = "The URL of the admin Cloud Function"
  value       = google_cloudfunctions2_function.admin.service_config[0].uri
}

output "deployed_services" {
  description = "Map of deployed Cloud Functions"
  value = {
    data_collection    = google_cloudfunctions2_function.data_collection.name,
    data_transformation = google_cloudfunctions2_function.data_transformation.name,
    admin              = google_cloudfunctions2_function.admin.name
  }
}