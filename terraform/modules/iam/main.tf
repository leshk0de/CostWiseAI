/**
 * # CostWise AI - IAM Module
 *
 * This module creates IAM resources needed for the CostWise AI system.
 */

# Create service account for the Cloud Functions
resource "google_service_account" "costwise_ai" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = var.service_account_name
  description  = "Service account for CostWise AI Cloud Functions and jobs"
}

# Grant Logs Writer role to the service account for proper logging
resource "google_project_iam_member" "logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.costwise_ai.email}"
}

# Create IAM binding for Cloud Run function invoker - specific to named service
resource "google_cloud_run_service_iam_binding" "run_invoker" {
  count    = var.cloud_run_service_name != "" ? 1 : 0
  location = var.region
  service  = var.cloud_run_service_name
  role     = "roles/run.invoker"
  members  = [
    "serviceAccount:${google_service_account.costwise_ai.email}",
  ]
  project  = var.project_id
}

# Grant Cloud Functions Invoker role to the service account - project-wide permission as fallback
resource "google_project_iam_member" "functions_invoker" {
  project = var.project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.costwise_ai.email}"
}

# Grant run.invoker at project level as well (for Cloud Run services)
resource "google_project_iam_member" "run_invoker_project" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.costwise_ai.email}"
}

# Create a custom IAM role with minimal permissions for AI cost monitoring
resource "google_project_iam_custom_role" "costwise_ai_minimal" {
  project     = var.project_id
  role_id     = "costwiseAIMinimal"
  title       = "CostWise AI Minimal Role"
  description = "Minimal permissions needed for CostWise AI operations"
  permissions = [
    # BigQuery table permissions
    "bigquery.tables.create",
    "bigquery.tables.get",
    "bigquery.tables.getData",
    "bigquery.tables.list",
    "bigquery.tables.update",
    "bigquery.tables.updateData",
    "bigquery.jobs.create",
    
    # BigQuery dataset permissions
    "bigquery.datasets.get",
    
    # Secret Manager permissions
    "secretmanager.versions.access",
    
    # Cloud Functions permissions
    "cloudfunctions.functions.invoke",
    
    # Cloud Run permissions
    "run.jobs.run",
    "run.routes.invoke"
  ]
}

# Assign the custom role to the service account
resource "google_project_iam_member" "custom_role_assignment" {
  project = var.project_id
  role    = "projects/${var.project_id}/roles/${google_project_iam_custom_role.costwise_ai_minimal.role_id}"
  member  = "serviceAccount:${google_service_account.costwise_ai.email}"
}

# Grant dataset-level access for the specific BigQuery dataset
resource "google_bigquery_dataset_iam_member" "dataset_access" {
  project    = var.project_id
  dataset_id = var.bigquery_dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.costwise_ai.email}"
}

# Grant dataset-level access as dataViewer (read-only)
resource "google_bigquery_dataset_iam_member" "dataset_viewer" {
  project    = var.project_id
  dataset_id = var.bigquery_dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.costwise_ai.email}"
}

# Grant the ability to run jobs - this role is only available at project level
resource "google_project_iam_member" "bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.costwise_ai.email}"
}