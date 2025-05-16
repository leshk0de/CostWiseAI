"""OpenAI API adapter for cost monitoring.

This module provides the adapter implementation for the OpenAI API.
"""

import requests
import time
from datetime import datetime, timedelta
import logging

# Get a logger specific to this adapter
logger = logging.getLogger('costwise-data-collection')
from typing import Dict, List, Any, Optional

# Try importing with different approaches to handle both deployment and local development
try:
    from .base_adapter import BaseServiceAdapter
except ImportError:
    from adapters.base_adapter import BaseServiceAdapter


class OpenAIAdapter(BaseServiceAdapter):
    """Adapter for OpenAI's API."""
    
    def __init__(self, api_key: str, api_base_url: str, models: Dict[str, Any]):
        """Initialize the OpenAI adapter.
        
        Args:
            api_key: The OpenAI API key.
            api_base_url: The base URL for the OpenAI API.
            models: Dictionary containing OpenAI model pricing information.
        """
        super().__init__(api_key, api_base_url, models)
        
    def collect_data(self, endpoint: str, additional_config: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """Collect usage and cost data from the OpenAI API.
        
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
        
        # Format timestamps for API request (ISO format for OpenAI organization costs API)
        start_date = start_time.strftime('%Y-%m-%d')
        end_date = end_time.strftime('%Y-%m-%d')
        
        # Set up the API request
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json'
        }
        
        # Use the organization costs endpoint if endpoint is 'organization/costs', otherwise use the specified endpoint
        if endpoint == 'organization/costs':
            # Avoid duplicate /v1 path segments
            if self.api_base_url.endswith('/v1'):
                url = f"{self.api_base_url}/organization/costs"
            else:
                url = f"{self.api_base_url}/v1/organization/costs"
            params = {
                'start_date': start_date,
                'end_date': end_date
            }
            logger.info(f"Using the organization costs endpoint", extra={
                "url": url,
                "start_date": start_date,
                "end_date": end_date
            })
        elif endpoint == 'usage':
            # For the usage endpoint (avoid duplicate /v1 path segments)
            # Use 'usage' directly if api_base_url already has /v1 suffix
            if self.api_base_url.endswith('/v1'):
                url = f"{self.api_base_url}/usage"
            else:
                url = f"{self.api_base_url}/v1/usage"
            params = {
                'date': start_date  # Start with just one day
            }
            logger.info(f"Using the usage endpoint", extra={
                "url": url,
                "date": start_date
            })
        else:
            # Custom endpoint - Check if the endpoint already has v1 prefix to avoid duplication
            if endpoint.startswith('v1/') and self.api_base_url.endswith('/v1'):
                # Remove 'v1/' from the endpoint to avoid duplication
                endpoint_path = endpoint[3:]  # Remove 'v1/' prefix
                url = f"{self.api_base_url}/{endpoint_path}"
            else:
                # Use endpoint as is
                url = f"{self.api_base_url}/{endpoint}"
                
            params = {
                'limit': additional_config.get('limit', 100)
            }
            
            # Add date range parameters depending on the endpoint format
            if endpoint.startswith('v1/'):
                # New API format (ISO dates)
                params['start_date'] = start_date
                params['end_date'] = end_date
            else:
                # Legacy API format (timestamps)
                params['starting_after'] = int(start_time.timestamp())
                params['ending_before'] = int(end_time.timestamp())
                
            logger.info(f"Using custom endpoint", extra={
                "url": url,
                "params": str(params)
            })
            
        # Add any additional parameters from the additional_config
        for key, value in additional_config.items():
            if key not in ['hours_lookback', 'limit'] and key not in params:
                params[key] = value
        
        try:
            logger.info(f"Making OpenAI API request", extra={
                "url": url,
                "params": str(params)
            })
            
            response = requests.get(url, headers=headers, params=params)
            response.raise_for_status()
            
            logger.info(f"OpenAI API request successful", extra={
                "status_code": response.status_code
            })
            
            raw_data = response.json()
            
            # Log the structure of the response data for debugging
            data_keys = list(raw_data.keys()) if isinstance(raw_data, dict) else "not a dict"
            data_length = len(raw_data.get('data', [])) if isinstance(raw_data, dict) and 'data' in raw_data else "no data key"
            
            logger.info(f"OpenAI API response structure", extra={
                "data_keys": str(data_keys),
                "data_length": str(data_length)
            })
            
            # Process the API response into standardized format based on the endpoint
            result = []
            
            if endpoint == 'organization/costs':
                # Handle organization costs endpoint
                for item in raw_data.get('data', []):
                    model = item.get('name', 'unknown')
                    timestamp = item.get('timestamp', end_time.isoformat())
                    cost = item.get('cost', 0.0)
                    usage_type = item.get('usage_type', 'unknown')
                    
                    # For costs API, we don't get tokens directly, 
                    # but we can estimate them from the cost using our models pricing info
                    model_info = self.models.get(model, {})
                    
                    # Estimate tokens based on cost and model pricing
                    # This is just an approximation since the costs API doesn't provide token counts
                    input_price = model_info.get('input_price_per_1k', 0.0)
                    output_price = model_info.get('output_price_per_1k', 0.0)
                    
                    # Avoid division by zero
                    if input_price > 0 or output_price > 0:
                        # Assume a 2:1 ratio of input to output tokens for estimation purposes
                        # This is just a reasonable default when we don't know the actual breakdown
                        est_input_tokens = 0
                        est_output_tokens = 0
                        
                        if input_price > 0 and output_price > 0:
                            # If we have both prices, assume 2:1 ratio
                            est_input_cost = cost * 0.66  # 2/3 of cost
                            est_output_cost = cost * 0.34  # 1/3 of cost
                            est_input_tokens = int((est_input_cost / input_price) * 1000)
                            est_output_tokens = int((est_output_cost / output_price) * 1000)
                        elif input_price > 0:
                            # Only input price exists
                            est_input_tokens = int((cost / input_price) * 1000)
                        elif output_price > 0:
                            # Only output price exists
                            est_output_tokens = int((cost / output_price) * 1000)
                    else:
                        # If no pricing info, use reasonable defaults
                        est_input_tokens = 0
                        est_output_tokens = 0
                        
                    # Create standardized record
                    record = {
                        'model': model,
                        'feature': usage_type,
                        'request_id': f"cost-{timestamp}",
                        'input_tokens': est_input_tokens,
                        'output_tokens': est_output_tokens,
                        'total_tokens': est_input_tokens + est_output_tokens,
                        'input_cost': cost * 0.66 if input_price > 0 and output_price > 0 else cost if input_price > 0 else 0,
                        'output_cost': cost * 0.34 if input_price > 0 and output_price > 0 else cost if output_price > 0 else 0,
                        'cost': cost,
                        'timestamp': timestamp,
                        'raw_response': item
                    }
                    
                    result.append(record)
                    
            elif endpoint == 'usage':
                # Handle usage endpoint
                for snapshot in raw_data.get('data', []):
                    timestamp = snapshot.get('timestamp')
                    
                    # Get usage breakdown by model
                    for model_usage in snapshot.get('usage', []):
                        model = model_usage.get('name', 'unknown')
                        usage_type = model_usage.get('usage_type', 'unknown')
                        n_requests = model_usage.get('n_requests', 0)
                        n_context = model_usage.get('n_context_tokens_total', 0)
                        n_generated = model_usage.get('n_generated_tokens_total', 0)
                        
                        # Calculate cost using our pricing model
                        cost_details = self.calculate_cost(model, n_context, n_generated)
                        
                        # Create standardized record
                        record = {
                            'model': model,
                            'feature': usage_type,
                            'request_id': f"usage-{timestamp}-{model}",
                            'input_tokens': n_context,
                            'output_tokens': n_generated,
                            'total_tokens': n_context + n_generated,
                            'input_cost': cost_details['input_cost'],
                            'output_cost': cost_details['output_cost'],
                            'cost': cost_details['total_cost'],
                            'n_requests': n_requests,
                            'timestamp': timestamp,
                            'raw_response': model_usage
                        }
                        
                        result.append(record)
            else:
                # Default processing for other endpoints
                for item in raw_data.get('data', []):
                    model = item.get('model', 'unknown')
                    usage = item.get('usage', {})
                    input_tokens = usage.get('prompt_tokens', 0)
                    output_tokens = usage.get('completion_tokens', 0)
                    
                    # Calculate costs based on model pricing
                    cost_details = self.calculate_cost(model, input_tokens, output_tokens)
                    
                    # Create standardized record
                    record = {
                        'model': model,
                        'feature': item.get('object', 'chat.completion'),
                        'request_id': item.get('id', f"request-{int(time.time())}"),
                        'input_tokens': input_tokens,
                        'output_tokens': output_tokens,
                        'total_tokens': usage.get('total_tokens', input_tokens + output_tokens),
                        'input_cost': cost_details['input_cost'],
                        'output_cost': cost_details['output_cost'],
                        'cost': cost_details['total_cost'],
                        'response_time_ms': int(item.get('response_ms', 0)),
                        'project': item.get('metadata', {}).get('project'),
                        'user_id': item.get('user', {}).get('id'),
                        'raw_response': item,
                        'metadata': item.get('metadata', {})
                    }
                    
                    result.append(record)
            
            logger.info(f"Processed {len(result)} records from OpenAI API", extra={
                "record_count": len(result)
            })
                
            return result
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error collecting data from OpenAI API: {e}", extra={
                "error": str(e),
                "error_type": type(e).__name__
            })
            raise
    
    def calculate_cost(self, model: str, input_tokens: int, output_tokens: int) -> Dict[str, float]:
        """Calculate the cost for an OpenAI API request.
        
        Args:
            model: The OpenAI model name used for the request.
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
