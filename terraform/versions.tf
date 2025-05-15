/**
 * # CostWise AI - Terraform Version Constraints
 *
 * This file defines the Terraform version and provider requirements.
 */

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.34.0"
    }
  }
}