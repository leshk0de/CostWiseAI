/**
 * # CostWise AI - IAM Module
 *
 * This module creates IAM resources needed for the CostWise AI system.
 */

# Create service account for the Cloud Functions
resource "google_service_account" "costwise_ai" {
  account_id   = var.service_account_id
  display_name = var.service_account_name
  description  = "Service account for CostWise AI Cloud Functions and jobs"
}

# Grant BigQuery Data Editor role to the service account
resource "google_project_iam_member" "bigquery_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.costwise_ai.email}"
}

# Grant BigQuery Job User role to the service account
resource "google_project_iam_member" "bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.costwise_ai.email}"
}

# Grant Cloud Functions Invoker role to the service account
resource "google_project_iam_member" "functions_invoker" {
  project = var.project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.costwise_ai.email}"
}

# Grant Logs Writer role to the service account for proper logging
resource "google_project_iam_member" "logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.costwise_ai.email}"
}

# Create a custom IAM role with minimal permissions for AI cost monitoring
resource "google_project_iam_custom_role" "costwise_ai_minimal" {
  role_id     = "costwiseAIMinimal"
  title       = "CostWise AI Minimal Role"
  description = "Minimal permissions needed for CostWise AI operations"
  permissions = [
    "bigquery.tables.create",
    "bigquery.tables.get",
    "bigquery.tables.getData",
    "bigquery.tables.list",
    "bigquery.tables.update",
    "bigquery.tables.updateData",
    "bigquery.jobs.create",
    "secretmanager.versions.access",
    "cloudfunctions.functions.invoke"
  ]
}

# Assign the custom role to the service account
resource "google_project_iam_member" "custom_role_assignment" {
  project = var.project_id
  role    = "projects/${var.project_id}/roles/${google_project_iam_custom_role.costwise_ai_minimal.role_id}"
  member  = "serviceAccount:${google_service_account.costwise_ai.email}"
}
