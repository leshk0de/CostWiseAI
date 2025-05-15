/**
 * # CostWise AI - Development Environment Remote State Configuration
 *
 * This file configures the backend for storing Terraform state in Google Cloud Storage.
 * Backend configuration is provided separately to keep sensitive values out of version control.
 */

terraform {
  backend "gcs" {}
}