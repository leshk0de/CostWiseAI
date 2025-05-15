# CostWise AI - Secure Configuration Guide

This guide explains the secure configuration approach used in the CostWise AI project and how to properly manage environment-specific and sensitive values.

## Overview

The CostWise AI project uses a comprehensive configuration strategy that:

1. Keeps sensitive values out of version control
2. Works consistently across local development and CI/CD
3. Follows infrastructure-as-code best practices
4. Provides flexibility for different environments

## Configuration Structure

### File Structure

For each environment, the configuration structure includes:

- `terraform.tfvars.example` - Template with placeholders that is checked into version control
- `terraform.tfvars` - Actual values that are **NOT** checked into version control
- `backend.hcl.example` - Backend template that is checked into version control
- `backend.hcl` - Actual backend configuration that is **NOT** checked into version control

### Variable Organization

All configuration is organized into logical groups:

1. **Environment Configuration**
   - `environment` - Deployment environment (dev, staging, prod)
   - `resource_prefix` - Prefix applied to resource names

2. **General Configuration**
   - `project_id` - GCP Project ID
   - `location` - Default region for resources

3. **BigQuery Configuration**
   - Dataset, table, and retention settings

4. **Service Account Configuration**
   - Service account IDs and display names

5. **Storage Configuration**
   - Bucket naming and configuration

6. **Scheduler Configuration**
   - Cron schedules and job settings

7. **Service Credentials**
   - API keys for external services (stored securely)

8. **API Configuration**
   - API endpoints and configuration

9. **Security Configuration**
   - VPC settings, IP allowlists, etc.

10. **Monitoring Configuration**
    - Alert settings and notification channels

## Resource Naming

Resources use a consistent naming function throughout the codebase:

```hcl
local.name_prefix = "${var.resource_prefix}-${var.environment}"

local.names = {
  dataset         = "${local.name_prefix}-ai-cost-monitoring"
  function_bucket = "${local.name_prefix}-functions-${random_id.suffix.hex}"
  service_account = "${local.name_prefix}-sa"
  # ... more resources
}
```

This ensures consistent naming across all resources and environments.

## Using the Configuration

### Local Development

For local development, follow these steps:

1. Initialize the environment using the provided script:
   ```bash
   ./init-environment.sh --environment dev
   ```

2. Edit the created configuration files:
   - `terraform/environments/dev/terraform.tfvars` - Fill in your specific values
   - `terraform/environments/dev/backend.hcl` - Set your GCS bucket details

3. Initialize Terraform with the backend configuration:
   ```bash
   cd terraform/environments/dev
   terraform init -backend-config=backend.hcl
   ```

4. Apply your configuration:
   ```bash
   terraform plan  # Review the changes
   terraform apply # Apply the changes
   ```

### CI/CD Integration

For CI/CD pipelines:

1. Store your sensitive values securely in your CI/CD platform's secret management
   - GitHub Secrets
   - GitLab CI/CD Variables
   - CircleCI Environment Variables
   - etc.

2. Generate the configuration files as part of your pipeline:
   ```yaml
   # Example GitHub Actions workflow step
   - name: Set up Terraform configuration
     run: |
       echo 'project_id = "${{ secrets.GCP_PROJECT_ID }}"' > terraform/environments/prod/terraform.tfvars
       echo 'service_credentials = { "Claude" = "${{ secrets.ANTHROPIC_API_KEY }}", "OpenAI" = "${{ secrets.OPENAI_API_KEY }}" }' >> terraform/environments/prod/terraform.tfvars
       # ... add other configuration
   ```

3. Initialize Terraform with the backend:
   ```yaml
   - name: Initialize Terraform
     run: |
       echo 'bucket = "${{ secrets.TF_STATE_BUCKET }}"' > terraform/environments/prod/backend.hcl
       echo 'prefix = "terraform/state/costwise-ai/prod"' >> terraform/environments/prod/backend.hcl
       cd terraform/environments/prod
       terraform init -backend-config=backend.hcl
   ```

4. Apply the configuration:
   ```yaml
   - name: Apply Terraform
     run: |
       cd terraform/environments/prod
       terraform apply -auto-approve
   ```

## Working with Multiple Environments

The project supports multiple environments out of the box:

- **Development** (`terraform/environments/dev`)
  - Used for development and testing
  - Less restrictive security settings
  - Shorter data retention

- **Staging** (`terraform/environments/staging`)
  - Used for pre-production testing
  - Similar to production configuration
  - Isolated resources for testing

- **Production** (`terraform/environments/prod`)
  - Used for the live system
  - Strict security settings
  - Longer data retention
  - Enhanced monitoring

Each environment has its own configuration files and state, allowing for isolated deployments.

## Adding New Configurations

To add a new configuration variable:

1. Add the variable definition to the main `variables.tf` file
2. Update the relevant module's variables and code to use the new variable
3. Update the example tfvars files for each environment
4. Update the documentation to reflect the new configuration option

## Security Best Practices

- Never commit actual values to version control
- Use Secret Manager for storing API keys and credentials
- Apply the principle of least privilege for service accounts
- Use environment-specific configurations to isolate environments
- Encrypt all sensitive data in transit and at rest
- Regularly rotate API keys and credentials

## Troubleshooting

### Missing Configuration

If Terraform complains about missing variables:

1. Check that you've correctly initialized the environment with `init-environment.sh`
2. Ensure all required variables are set in `terraform.tfvars`
3. Verify that backend configuration is correct in `backend.hcl`

### State Access Issues

If Terraform can't access the state:

1. Verify GCS bucket permissions
2. Check that the bucket name in `backend.hcl` is correct
3. Ensure the service account has access to the bucket

### Secret Access Issues

If Cloud Functions can't access secrets:

1. Check the Secret Manager IAM permissions
2. Verify that the service account has the `secretmanager.secretAccessor` role
3. Ensure the secret exists and has the correct name