# CostWise AI - Deployment Guide

This guide provides step-by-step instructions for deploying the CostWise AI system to Google Cloud Platform.

## Prerequisites

Before you begin, ensure you have the following:

1. **Google Cloud Project**:
   - A GCP project with billing enabled
   - Owner or Editor role permissions on the project

2. **Required Tools**:
   - [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and configured
   - [Terraform](https://www.terraform.io/downloads.html) v1.0.0 or higher
   - [Git](https://git-scm.com/downloads) for cloning the repository

3. **GCP APIs Enabled**:
   - Cloud Functions API (`cloudfunctions.googleapis.com`)
   - Cloud Build API (`cloudbuild.googleapis.com`)
   - BigQuery API (`bigquery.googleapis.com`)
   - Secret Manager API (`secretmanager.googleapis.com`)
   - Cloud Scheduler API (`cloudscheduler.googleapis.com`)
   - Cloud Storage API (`storage.googleapis.com`)
   - Artifact Registry API (`artifactregistry.googleapis.com`)
   - Cloud Run API (`run.googleapis.com`)

   You can enable these APIs using the following command:
   ```bash
   gcloud services enable cloudfunctions.googleapis.com cloudbuild.googleapis.com bigquery.googleapis.com secretmanager.googleapis.com cloudscheduler.googleapis.com storage.googleapis.com artifactregistry.googleapis.com run.googleapis.com
   ```

4. **GCS Bucket for Terraform State**:
   - A GCS bucket for storing Terraform state
   - Create it with the following command:
   ```bash
   gsutil mb -l us-central1 gs://YOUR_UNIQUE_BUCKET_NAME_tfstate
   ```

## Deployment Steps

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/costwise-ai.git
cd costwise-ai
```

### 2. Configure Terraform Backend

1. Navigate to the terraform directory:
```bash
cd terraform
```

2. Create the backend configuration:
```bash
cp backend.hcl.example backend.hcl
```

3. Edit `backend.hcl` with your GCS bucket name:
```
bucket  = "YOUR_UNIQUE_BUCKET_NAME_tfstate"
prefix  = "costwise-ai/state"
```

### 3. Configure Deployment Variables

1. Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your own values:
```hcl
# Environment Configuration
environment     = "prod"
resource_prefix = "costwise"

# GCP Project Configuration
project_id = "your-project-id"
location   = "us-central1"  # Choose your preferred region

# Resource Naming
dataset_id                = "costwise_ai"
service_account_id        = "sa-costwise-ai"
function_source_bucket_name = "your-costwise-ai-functions"

# Service Credentials - Fill these in with your actual API keys
service_credentials = {
  "anthropic"   = "your-anthropic-api-key",
  "openai"      = "your-openai-api-key",
  "perplexity"  = "your-perplexity-api-key"
}

# Service Names - List of services to monitor
service_names = ["anthropic", "openai", "perplexity"]
```

### 4. Initialize Terraform

Initialize Terraform with the backend configuration:

```bash
terraform init -backend-config=backend.hcl
```

### 5. Validate the Configuration

Check that your Terraform configuration is valid:

```bash
terraform validate
```

### 6. Preview the Deployment

Generate a plan to see what resources will be created:

```bash
terraform plan
```

Review the plan output to ensure it will create the resources you expect.

### 7. Deploy the Infrastructure

Apply the Terraform configuration to create the resources:

```bash
terraform apply
```

When prompted, type `yes` to confirm the deployment.

The deployment process will take approximately 5-10 minutes. Terraform will display the progress and output the URLs for the deployed Cloud Functions when complete.

### 8. Verify the Deployment

1. Check that all resources were created successfully:
```bash
terraform output
```

2. Verify the BigQuery dataset and tables:
```bash
bq ls your-project-id:costwise_ai
```

3. Test the admin Cloud Function:
```bash
curl -X POST $(terraform output -raw admin_function_url) \
     -H "Content-Type: application/json" \
     -d '{"action": "list_services"}'
```

### 9. Verify Function Deployment

If you encounter issues with the Cloud Functions deployment such as "Archive not found in the storage location", you can check the deployment status and fix it:

```bash
# Check the storage bucket content
gsutil ls -la gs://$(terraform output -raw function_source_bucket)/source/

# Force redeployment of functions by modifying any Python file
touch cloud_functions/data_collection/main.py
terraform apply
```

### 10. Add Service Configurations

For each AI service you want to monitor, add its configuration using the admin Cloud Function:

```bash
curl -X POST $(terraform output -raw admin_function_url) \
     -H "Content-Type: application/json" \
     -d '{
           "action": "add_service",
           "service_name": "anthropic",
           "service_id": "claude-1",
           "api_type": "REST",
           "api_base_url": "https://api.anthropic.com/v1",
           "data_collection_endpoint": "usage",
           "secret_name": "costwise-anthropic-api-key",
           "models": {
             "claude-3-opus-20240229": {
               "input_price_per_1k": 15.0,
               "output_price_per_1k": 75.0
             },
             "claude-3-sonnet-20240229": {
               "input_price_per_1k": 3.0,
               "output_price_per_1k": 15.0
             }
           },
           "adapter_module": "claude_adapter"
         }'
```

Repeat for each AI service, adjusting the values as needed.

### 10. Trigger Initial Data Collection

Manually trigger the data collection function to start gathering data:

```bash
curl -X POST $(terraform output -raw data_collection_function_url)
```

The scheduler will automatically run the function according to the configured schedule.

## Updating the Deployment

To update the deployment after making changes:

1. Navigate to the terraform directory:
```bash
cd terraform
```

2. Pull the latest changes:
```bash
git pull
```

3. Apply the updates:
```bash
terraform apply
```

## Cleaning Up

To remove all deployed resources:

```bash
terraform destroy
```

When prompted, type `yes` to confirm deletion.

Note: This will delete all resources created by Terraform, including the BigQuery dataset and all data. Make sure to export any important data before running this command.

## Troubleshooting Cloud Scheduler Permissions

If you encounter a permission error with Cloud Scheduler like:

```
URL_ERROR-ERROR_OTHER. Original HTTP response code number = 403
PERMISSION_DENIED
```

This is likely due to incorrect permissions for the service account. To fix it:

1. First, check the service account being used:
```bash
terraform output service_account_email
```

2. Ensure the service account has `run.invoker` permissions:
```bash
gcloud run services add-iam-policy-binding costwise-data-collection \
  --member="serviceAccount:YOUR_SERVICE_ACCOUNT_EMAIL" \
  --role="roles/run.invoker" \
  --region=us-central1
```

3. Reapply the Terraform configuration:
```bash
terraform apply
```

## Other Common Issues

1. **Permission Denied Errors**:
   - Ensure you have the necessary permissions on your GCP project
   - Check that the service account has the required roles

2. **API Not Enabled**:
   - If you see errors about APIs not being enabled, use `gcloud services enable` to enable them

3. **Backend Initialization Failures**:
   - Verify the GCS bucket exists and you have access to it
   - Check for typos in the bucket name

4. **Function Deployment Failures**:
   - Check Cloud Build logs for details
   - Ensure the source code is correctly structured

5. **Missing Data**:
   - Verify API keys are correctly stored in Secret Manager
   - Check Cloud Function logs for API call errors
   - Confirm service configurations are active

For more detailed troubleshooting, refer to the logs in Cloud Logging.