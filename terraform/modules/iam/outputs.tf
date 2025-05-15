output "service_account_email" {
  description = "The email of the created service account"
  value       = google_service_account.costwise_ai.email
}

output "service_account_id" {
  description = "The ID of the created service account"
  value       = google_service_account.costwise_ai.id
}

output "custom_role_id" {
  description = "The ID of the custom IAM role created"
  value       = google_project_iam_custom_role.costwise_ai_minimal.id
}