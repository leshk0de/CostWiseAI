output "function_source_bucket_name" {
  description = "The name of the bucket created for Cloud Function source code"
  value       = google_storage_bucket.function_source.name
}

output "function_source_bucket_url" {
  description = "The URL of the bucket created for Cloud Function source code"
  value       = google_storage_bucket.function_source.url
}