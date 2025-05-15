# CostWise AI - Developer Guide

This guide provides information for developers who want to contribute to or extend the CostWise AI system.

## Development Environment Setup

### Prerequisites

1. **Install Required Tools**:
   - [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
   - [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
   - [Python](https://www.python.org/downloads/) (v3.9+)
   - [Git](https://git-scm.com/downloads)

2. **Configure Google Cloud SDK**:
   ```bash
   gcloud auth login
   gcloud config set project your-project-id
   ```

3. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/costwise-ai.git
   cd costwise-ai
   ```

4. **Set Up Python Environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

### Local Development

#### Cloud Functions Development

The Cloud Functions code is located in the `cloud_functions` directory:

```
cloud_functions/
├── adapters/          # Service adapter implementations
├── data_collection/   # Data collection function
├── data_transformation/ # Data transformation function
└── admin/             # Admin function
```

To work on Cloud Functions locally:

1. Install the Functions Framework:
   ```bash
   pip install functions-framework
   ```

2. Run a function locally:
   ```bash
   cd cloud_functions/data_collection
   functions-framework-python --target=collect_data
   ```

3. Test with curl:
   ```bash
   curl -X POST http://localhost:8080
   ```

#### Testing Service Adapters

Service adapters can be tested locally:

1. Create test configuration in `cloud_functions/adapters/tests`:
   ```python
   # test_adapters.py
   import os
   import json
   from ..factory import AdapterFactory
   
   # Set your API key for testing
   API_KEY = "your-test-api-key"
   
   # Test adapter creation and basic functionality
   def test_claude_adapter():
       models = {
           "claude-3-opus-20240229": {
               "input_price_per_1k": 15.0,
               "output_price_per_1k": 75.0
           }
       }
       
       adapter = AdapterFactory.create_adapter(
           "Claude", 
           API_KEY,
           "https://api.anthropic.com/v1",
           models
       )
       
       # Test cost calculation
       cost = adapter.calculate_cost("claude-3-opus-20240229", 1000, 500)
       assert cost["input_cost"] == 15.0
       assert cost["output_cost"] == 37.5
       assert cost["total_cost"] == 52.5
   
   if __name__ == "__main__":
       test_claude_adapter()
       print("All tests passed!")
   ```

2. Run the test:
   ```bash
   python -m cloud_functions.adapters.tests.test_adapters
   ```

#### Working with Terraform

For Terraform development:

1. Initialize in a specific environment:
   ```bash
   cd terraform/environments/dev
   terraform init
   ```

2. Validate changes:
   ```bash
   terraform validate
   terraform plan
   ```

3. Use variables file for local testing:
   ```bash
   terraform plan -var-file=dev-local.tfvars
   ```

## Code Architecture

### Cloud Functions

#### Data Collection Function

The main data collection function (`cloud_functions/data_collection/main.py`) follows this process:

1. Get service configurations from BigQuery
2. For each active service:
   - Load the appropriate adapter via the factory
   - Get API credentials from Secret Manager
   - Call the service API to collect data
   - Insert data into BigQuery

Key components:

- `collect_data()`: HTTP entry point for the function
- Adapter factory pattern for loading service adapters
- Dynamic import of adapter modules
- BigQuery data insertion

#### Data Transformation Function

The transformation function (`cloud_functions/data_transformation/main.py`):

1. Receives service-specific data in the request
2. Applies standardized transformations
3. Calculates costs based on model pricing
4. Inserts the transformed data into BigQuery

#### Admin Function

The admin function (`cloud_functions/admin/main.py`) handles:

1. Adding new services
2. Updating service configurations
3. Listing configured services
4. Deleting services

### Service Adapters

The service adapter pattern (`cloud_functions/adapters/`) uses:

1. `BaseServiceAdapter`: Abstract base class defining the interface
2. Service-specific adapters that implement the interface
3. `AdapterFactory`: Factory class for creating adapter instances

### Infrastructure Modules

The Terraform modules are organized as:

```
terraform/
├── modules/               # Reusable modules
│   ├── bigquery/          # BigQuery resources
│   ├── cloud_functions/   # Cloud Functions resources
│   ├── cloud_scheduler/   # Cloud Scheduler resources
│   ├── iam/               # IAM resources
│   ├── secret_manager/    # Secret Manager resources
│   └── storage/           # Storage resources
└── environments/          # Environment-specific configurations
    ├── dev/               # Development environment
    └── prod/              # Production environment
```

## Adding a New Feature

### Adding a New Service Adapter

To add support for a new AI service:

1. Create a new adapter class in `cloud_functions/adapters/`:
   ```python
   # new_service_adapter.py
   from .base_adapter import BaseServiceAdapter
   
   class NewServiceAdapter(BaseServiceAdapter):
       def __init__(self, api_key, api_base_url, models):
           super().__init__(api_key, api_base_url, models)
           
       def collect_data(self, endpoint, additional_config=None):
           # Implement service-specific data collection
           # ...
           
       def calculate_cost(self, model, input_tokens, output_tokens):
           # Implement service-specific cost calculation
           # ...
   ```

2. Register the adapter in `factory.py`:
   ```python
   from .new_service_adapter import NewServiceAdapter
   
   class AdapterFactory:
       _adapters = {
           'Claude': ClaudeAdapter,
           'OpenAI': OpenAIAdapter,
           'Perplexity': PerplexityAdapter,
           'NewService': NewServiceAdapter  # Add your new adapter
       }
       # ...
   ```

3. Deploy the updated function code

### Adding a New Data Field

To add a new field to track:

1. Update the BigQuery schema in `terraform/modules/bigquery/schemas/cost_data_schema.json`:
   ```json
   [
     // Existing fields...
     {
       "name": "new_field_name",
       "type": "STRING",
       "mode": "NULLABLE",
       "description": "Description of the new field"
     }
   ]
   ```

2. Update service adapters to collect and provide the field
3. Update any views that should include the new field
4. Apply the Terraform changes

### Adding a New Dashboard

To create a new Grafana dashboard:

1. Design the dashboard in Grafana
2. Export the dashboard JSON from Grafana
3. Save it to the `grafana/` directory
4. Document the new dashboard in the user guide

## Testing Strategy

### Unit Testing

Write unit tests for adapters and utility functions:

```python
# test_adapters.py
import unittest
from ..adapters.factory import AdapterFactory
from ..adapters.base_adapter import BaseServiceAdapter

class TestAdapters(unittest.TestCase):
    def test_adapter_factory(self):
        # Test adapter registration
        class TestAdapter(BaseServiceAdapter):
            def collect_data(self, endpoint, additional_config=None):
                return []
                
            def calculate_cost(self, model, input_tokens, output_tokens):
                return {"input_cost": 0, "output_cost": 0, "total_cost": 0}
        
        AdapterFactory.register_adapter("Test", TestAdapter)
        adapters = AdapterFactory.get_registered_adapters()
        self.assertIn("Test", adapters)
        
        # Test adapter creation
        adapter = AdapterFactory.create_adapter("Test", "key", "url", {})
        self.assertIsInstance(adapter, TestAdapter)
```

### Integration Testing

Test the integration between components:

```python
# integration_tests.py
import os
import unittest
from google.cloud import bigquery
from ..adapters.factory import AdapterFactory

class TestIntegration(unittest.TestCase):
    def setUp(self):
        self.project_id = os.environ.get("PROJECT_ID")
        self.dataset_id = os.environ.get("DATASET_ID")
        self.table_id = os.environ.get("COST_DATA_TABLE_ID")
        self.bq_client = bigquery.Client(project=self.project_id)
        
    def test_data_insertion(self):
        # Create test data
        test_data = [{
            "timestamp": "2023-01-01T00:00:00Z",
            "service_name": "TestService",
            "model": "test-model",
            "input_tokens": 100,
            "output_tokens": 50,
            "cost": 0.01
        }]
        
        # Insert test data
        table_ref = self.bq_client.dataset(self.dataset_id).table(self.table_id)
        errors = self.bq_client.insert_rows_json(table_ref, test_data)
        
        self.assertEqual(len(errors), 0)
        
        # Query to verify insertion
        query = f"""
            SELECT * FROM `{self.project_id}.{self.dataset_id}.{self.table_id}`
            WHERE service_name = 'TestService'
            LIMIT 1
        """
        results = list(self.bq_client.query(query).result())
        
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["service_name"], "TestService")
```

## Deployment Pipeline

The recommended CI/CD pipeline for CostWise AI:

1. **Source Control**:
   - Develop in feature branches
   - Pull requests for code review
   - Main branch for production-ready code

2. **Continuous Integration**:
   - Run unit tests on pull requests
   - Validate Terraform configurations
   - Check for security issues with static analysis

3. **Continuous Deployment**:
   - Automatically deploy to dev environment on merge to main
   - Manual approval for production deployment
   - Deploy infrastructure changes first, then application code

## Troubleshooting

### Common Development Issues

#### Cloud Function Deployment Failures

If a Cloud Function fails to deploy:
1. Check the Cloud Build logs for errors
2. Verify the function entry point matches the code
3. Ensure all dependencies are in requirements.txt
4. Check for syntax errors in the function code

#### Terraform Errors

For Terraform issues:
1. Run `terraform validate` to check for configuration errors
2. Use `terraform plan` to see what would be changed
3. Check for version compatibility issues
4. Verify IAM permissions for the Terraform service account

#### BigQuery Schema Issues

If you encounter BigQuery schema issues:
1. The schema is defined in `terraform/modules/bigquery/schemas/`
2. Fields can be added but existing fields should not be removed
3. Field types cannot be changed once data exists
4. Consider creating a new table for major schema changes

## Contributing Guidelines

1. **Code Style**:
   - Follow PEP 8 for Python code
   - Use consistent naming conventions
   - Add docstrings for all functions and classes
   - Add type hints for function parameters and return values

2. **Pull Requests**:
   - Reference issues in PR descriptions
   - Include test cases for new features
   - Update documentation as needed
   - Keep PRs focused on a single feature/fix

3. **Documentation**:
   - Update README.md for major changes
   - Add or update documentation in docs/ directory
   - Include code comments for complex logic
   - Update architecture diagrams for structural changes

4. **Testing**:
   - Write unit tests for new features
   - Include integration tests for major changes
   - Test with multiple AI services when relevant
   - Verify backward compatibility