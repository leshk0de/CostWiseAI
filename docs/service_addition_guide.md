# CostWise AI - Service Addition Guide

This guide provides detailed instructions for adding new AI service integrations to the CostWise AI system.

## Overview

CostWise AI is designed with extensibility in mind. Adding a new AI service involves:

1. Creating a service adapter class
2. Registering the adapter with the factory
3. Adding the service configuration to BigQuery
4. Updating the Cloud Functions (if necessary)

## Prerequisites

Before adding a new service, ensure you have:

- API access to the service you want to integrate
- Documentation for the service's usage/billing API
- Pricing information for the service's models
- Access to edit and deploy the CostWise AI codebase

## Step 1: Create a Service Adapter

Each AI service needs an adapter class that implements the standardized interface for collecting and processing cost data.

1. Create a new file in `cloud_functions/adapters/` named `your_service_adapter.py`:

```python
"""Your Service API adapter for cost monitoring.

This module provides the adapter implementation for Your Service API.
"""

import requests
import time
from datetime import datetime, timedelta
import logging
from typing import Dict, List, Any, Optional

from .base_adapter import BaseServiceAdapter


class YourServiceAdapter(BaseServiceAdapter):
    """Adapter for Your Service's API."""
    
    def __init__(self, api_key: str, api_base_url: str, models: Dict[str, Any]):
        """Initialize the Your Service adapter.
        
        Args:
            api_key: The Your Service API key.
            api_base_url: The base URL for the Your Service API.
            models: Dictionary containing model pricing information.
        """
        super().__init__(api_key, api_base_url, models)
        
    def collect_data(self, endpoint: str, additional_config: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """Collect usage and cost data from the Your Service API.
        
        Args:
            endpoint: The specific API endpoint to collect data from.
            additional_config: Additional service-specific configuration.
            
        Returns:
            A list of dictionaries containing usage and cost data.
        """
        if additional_config is None:
            additional_config = {}
            
        # Configure the time range for data collection
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(hours=additional_config.get('hours_lookback', 24))
        
        # Format timestamps for API request - adjust format as needed for your service
        start_timestamp = start_time.isoformat() + 'Z'
        end_timestamp = end_time.isoformat() + 'Z'
        
        # Set up the API request - adjust headers and authentication as needed
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json'
        }
        
        url = f"{self.api_base_url}/{endpoint}"
        params = {
            'start_time': start_timestamp,
            'end_time': end_timestamp,
            # Add any other parameters required by your service
        }
        
        try:
            # Make the API request
            response = requests.get(url, headers=headers, params=params)
            response.raise_for_status()
            raw_data = response.json()
            
            # Process the API response into standardized format
            result = []
            # Iterate through the response items - adjust this to match your service's response format
            for item in raw_data.get('items', []):
                # Extract relevant fields from the response
                model = item.get('model', 'unknown')
                input_tokens = item.get('input_tokens', 0)
                output_tokens = item.get('output_tokens', 0)
                
                # Calculate costs based on model pricing
                cost_details = self.calculate_cost(model, input_tokens, output_tokens)
                
                # Create standardized record - map your service's fields to the standard format
                record = {
                    'model': model,
                    'feature': item.get('type', 'completion'),
                    'request_id': item.get('id'),
                    'input_tokens': input_tokens,
                    'output_tokens': output_tokens,
                    'total_tokens': input_tokens + output_tokens,
                    'input_cost': cost_details['input_cost'],
                    'output_cost': cost_details['output_cost'],
                    'cost': cost_details['total_cost'],
                    'response_time_ms': item.get('duration_ms', 0),
                    'project': item.get('metadata', {}).get('project'),
                    'user_id': item.get('user_id'),
                    'raw_response': item,
                    'metadata': item.get('metadata', {})
                }
                
                result.append(record)
                
            return result
            
        except requests.exceptions.RequestException as e:
            logging.error(f"Error collecting data from Your Service API: {e}")
            raise
    
    def calculate_cost(self, model: str, input_tokens: int, output_tokens: int) -> Dict[str, float]:
        """Calculate the cost for a Your Service API request.
        
        Args:
            model: The model name used for the request.
            input_tokens: Number of input/prompt tokens.
            output_tokens: Number of output/completion tokens.
            
        Returns:
            A dictionary containing input_cost, output_cost, and total cost in USD.
        """
        # Get model pricing information
        model_info = self.models.get(model, {})
        input_price_per_1k = model_info.get('input_price_per_1k', 0.0)
        output_price_per_1k = model_info.get('output_price_per_1k', 0.0)
        
        # Calculate costs
        input_cost = (input_tokens / 1000) * input_price_per_1k
        output_cost = (output_tokens / 1000) * output_price_per_1k
        total_cost = input_cost + output_cost
        
        return {
            'input_cost': input_cost,
            'output_cost': output_cost,
            'total_cost': total_cost
        }
```

Customize this template to match your service's specific API requirements:

- Update the authentication method (API key, OAuth, etc.)
- Adjust timestamp formats to match your service's requirements
- Map the service's response fields to the standard format
- Handle any service-specific edge cases or rate limiting

## Step 2: Register the Adapter with the Factory

Add your adapter to the factory to make it available for use:

1. Edit `cloud_functions/adapters/factory.py`:

```python
# Import your new adapter
from .your_service_adapter import YourServiceAdapter

class AdapterFactory:
    """Factory for creating AI service adapters."""
    
    _adapters = {
        'Claude': ClaudeAdapter,
        'OpenAI': OpenAIAdapter,
        'Perplexity': PerplexityAdapter,
        'YourService': YourServiceAdapter  # Add your service here
    }
    
    # Rest of the factory class...
```

## Step 3: Deploy the Updated Code

Package and deploy the updated Cloud Functions:

1. Create a ZIP archive of the Cloud Functions code:
```bash
cd cloud_functions
zip -r ../function_source.zip .
```

2. Upload to your Cloud Storage bucket:
```bash
gsutil cp ../function_source.zip gs://your-costwise-ai-functions/source/
```

3. Update the Cloud Functions to use the new code:
```bash
gcloud functions deploy costwise-ai-data-collection \
    --gen2 \
    --region=us-central1 \
    --source=gs://your-costwise-ai-functions/source/function_source.zip \
    --entry-point=collect_data \
    --runtime=python39
```

Repeat for the other functions as needed.

## Step 4: Create a Secret for the API Key

Store your service's API key securely in Secret Manager:

```bash
echo -n "your-api-key" | gcloud secrets create costwise-ai-yourservice-api-key \
    --replication-policy="automatic" \
    --data-file=-
```

## Step 5: Add the Service Configuration

Use the admin Cloud Function to add your service configuration:

```bash
curl -X POST https://your-admin-function-url \
     -H "Content-Type: application/json" \
     -d '{
           "action": "add_service",
           "service_name": "YourService",
           "service_id": "yourservice-1",
           "api_type": "REST",
           "api_base_url": "https://api.yourservice.com/v1",
           "data_collection_endpoint": "usage",
           "secret_name": "costwise-ai-yourservice-api-key",
           "models": {
             "model-name-1": {
               "input_price_per_1k": 5.0,
               "output_price_per_1k": 15.0
             },
             "model-name-2": {
               "input_price_per_1k": 1.0,
               "output_price_per_1k": 3.0
             }
           },
           "adapter_module": "your_service_adapter",
           "additional_config": {
             "hours_lookback": 24,
             "custom_option": "value"
           }
         }'
```

Adjust the values to match your service's actual configuration:
- `service_name`: The display name for your service
- `service_id`: A unique identifier for your service
- `api_base_url`: The base URL for your service's API
- `data_collection_endpoint`: The specific endpoint for usage data
- `models`: Dictionary of models with their pricing information
- `adapter_module`: The name of your adapter module without the .py extension
- `additional_config`: Any service-specific configuration options

## Step 6: Test the Integration

1. Trigger a manual data collection:

```bash
curl -X POST https://your-data-collection-function-url
```

2. Check the Cloud Function logs for any errors:

```bash
gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=costwise-ai-data-collection" --limit 50
```

3. Verify data is appearing in BigQuery:

```bash
bq query --nouse_legacy_sql 'SELECT * FROM `your-project.ai_cost_monitoring.usage_costs` WHERE service_name = "YourService" LIMIT 10'
```

## Common Integration Issues

### Authentication Errors

If you see authentication errors in the logs:
- Double-check the API key in Secret Manager
- Verify the authentication headers in your adapter
- Check for any required API scopes or permissions

### Parsing Errors

If the adapter fails to parse the API response:
- Print the raw response in your adapter for debugging
- Check for changes in the service's API response format
- Add error handling for unexpected response structures

### Missing Data

If no data appears in BigQuery:
- Check if the service has any usage data in the time period
- Verify that the API endpoint is correct
- Adjust the time parameters for data collection

### Rate Limiting

If you encounter rate limiting:
- Add exponential backoff in your adapter
- Reduce the frequency of data collection
- Break up large requests into smaller batches

## Advanced Integration Features

### Custom Metrics

If your service provides additional metrics beyond tokens and costs:
- Add these to the `metadata` field in your adapter
- Create custom BigQuery views to analyze these metrics

### Incremental Data Collection

For services with large volumes of data:
- Implement cursor-based pagination
- Store the last collection timestamp
- Use incremental collection to avoid duplicate data

## Conclusion

After completing these steps, your new service will be fully integrated into CostWise AI. The system will collect usage and cost data on the configured schedule, and you can view the data in BigQuery or Grafana dashboards.

Remember to keep your service adapter updated if the API changes, and adjust model pricing as needed to maintain accurate cost reporting.