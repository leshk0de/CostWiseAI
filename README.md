# CostWise AI - AI Cost Monitoring System

CostWise AI is a comprehensive monitoring system for tracking costs across multiple AI services (Claude, ChatGPT, Perplexity, etc.). It collects usage data from each service's API, stores it in BigQuery, and visualizes it in Grafana dashboards.

## Architecture

The system is built on Google Cloud Platform using:

- **Google Cloud Functions Gen 2**: For serverless data collection and processing
- **BigQuery**: For storing and analyzing cost data
- **Secret Manager**: For securely storing API credentials
- **Cloud Scheduler**: For scheduling regular data collection
- **Cloud Storage**: For storing function code and other assets

## Features

- **Multi-Service Tracking**: Monitor costs across multiple AI services in one place
- **Unified Data Model**: Standardized schema for comparing costs across services
- **Extensible Design**: Factory pattern for easily adding new AI services
- **Secure Credentials**: API keys stored securely in Secret Manager
- **Cost Analysis Views**: Pre-built BigQuery views for common analyses
- **Scheduled Collection**: Automated regular data collection
- **Multi-Environment Support**: Dev, staging, and production environment configurations
- **Secure Configuration Management**: Environment-specific values kept out of version control

## Deployment

### Prerequisites

- Google Cloud Project with billing enabled
- Terraform 1.0+ installed
- Google Cloud SDK installed and configured
- Required APIs enabled:
  - Cloud Functions API
  - BigQuery API
  - Secret Manager API
  - Cloud Scheduler API
  - Cloud Storage API

### Deployment Steps

1. Clone this repository:
```
git clone https://github.com/yourusername/costwise-ai.git
cd costwise-ai
```

2. Initialize your environment using the provided script:
```
./init-environment.sh --environment dev  # or staging, prod
```

3. Edit the generated configuration files:
```
# Update with your values
vim terraform/environments/dev/terraform.tfvars
vim terraform/environments/dev/backend.hcl
```

4. Initialize Terraform with the backend configuration:
```
cd terraform/environments/dev
terraform init -backend-config=backend.hcl
```

5. Apply the Terraform configuration:
```
terraform plan  # Review the changes
terraform apply # Apply the changes
```

For detailed deployment instructions, see the [Deployment Guide](docs/deployment_guide.md).
For information on the secure configuration approach, see the [Secure Configuration Guide](docs/secure_configuration.md).

### Adding AI Service API Keys

For each AI service you want to track, you need to add their API credentials:

1. Add the API key to your `terraform.tfvars` file in the `service_credentials` map
2. The system will automatically create the Secret Manager secrets and grant appropriate access
3. Use the admin Cloud Function to register the service configuration

## Usage

### Adding a New Service

Use the admin Cloud Function to add a new service:

```
curl -X POST https://your-admin-function-url \
     -H "Content-Type: application/json" \
     -d '{
           "action": "add_service",
           "service_name": "Claude",
           "service_id": "claude-1",
           "api_type": "REST",
           "api_base_url": "https://api.anthropic.com/v1",
           "data_collection_endpoint": "usage",
           "secret_name": "costwise-dev-claude-api-key",  # Note environment-specific prefix
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

### Viewing Cost Data

1. Access BigQuery via the Google Cloud Console
2. Navigate to the dataset (auto-generated name based on environment) 
3. Query the `cost_summary_view` or `model_comparison_view` for common analyses

For more advanced visualization, set up Grafana with the BigQuery data source and import the included dashboard JSONs from the `grafana` directory.

### Grafana Dashboard Setup

1. **Install and Configure Grafana**:
   - Set up a Grafana instance (cloud-hosted or self-hosted)
   - Configure the BigQuery data source in Grafana
   - Ensure your Grafana instance has permissions to query the BigQuery dataset

2. **Import the Dashboard**:
   - In Grafana, navigate to Dashboards > Import
   - Either upload the JSON file from the `grafana/cost_overview_dashboard.json` or copy-paste its contents
   - Configure the BigQuery data source for the dashboard during import
   - Adjust dashboard variables if necessary to match your project and dataset IDs

3. **Dashboard Features**:
   - Total costs and usage metrics
   - Cost breakdown by service, model, and project/team
   - Model efficiency comparison
   - Time-based trends of AI service usage
   - Filterable by date range and service type

4. **Customization**:
   - The dashboard is fully customizable to your specific needs
   - You can add additional panels or modify existing ones
   - Consider adding alerts for cost thresholds to proactively monitor spending

## Development

### Project Structure

```
costwise-ai/
├── terraform/              # Terraform infrastructure code
│   ├── modules/            # Reusable Terraform modules
│   └── environments/       # Environment-specific configurations
│       ├── dev/            # Development environment
│       ├── staging/        # Staging environment
│       └── prod/           # Production environment
├── cloud_functions/        # Cloud Functions source code
│   ├── adapters/           # Service adapter implementations
│   ├── data_collection/    # Data collection function
│   ├── data_transformation/ # Data transformation function
│   └── admin/              # Admin function
├── grafana/                # Grafana dashboard definitions
├── docs/                   # Documentation
└── init-environment.sh     # Environment initialization script
```

### Adding a New Service Adapter

1. Create a new adapter class in `cloud_functions/adapters/` that extends `BaseServiceAdapter`
2. Implement the required methods: `collect_data` and `calculate_cost`
3. Register the new adapter in `factory.py`
4. Deploy the updated functions
5. Add the service configuration using the admin function

For detailed development instructions, see the [Developer Guide](docs/developer_guide.md).

## Secure Configuration

CostWise AI uses a comprehensive secure configuration strategy:

1. Sensitive values (API keys, bucket names) are kept out of version control
2. Environment-specific configuration is separated (dev, staging, prod)
3. Resource naming is consistent and environment-aware
4. Backend configuration is provided separately for enhanced security

For details on the secure configuration approach, see the [Secure Configuration Guide](docs/secure_configuration.md).

## Troubleshooting

### Common Issues

- **Missing Data**: Check that the service API key is correctly configured in Secret Manager and that the service configuration is active
- **Permission Errors**: Verify that the service account has the necessary permissions for BigQuery, Secret Manager, etc.
- **Function Errors**: Check the Cloud Function logs for specific error messages
- **Configuration Issues**: Ensure you've properly initialized the environment with `init-environment.sh` and updated all required values

## License

This project is licensed under the MIT License - see the LICENSE file for details.