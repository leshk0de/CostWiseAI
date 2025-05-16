"""Claude (Anthropic) API adapter for cost monitoring.

This module provides the adapter implementation for the Anthropic Claude API.
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


class ClaudeAdapter(BaseServiceAdapter):
    """Adapter for Anthropic's Claude API."""
    
    def __init__(self, api_key: str, api_base_url: str, models: Dict[str, Any]):
        """Initialize the Claude adapter.
        
        Args:
            api_key: The Anthropic API key.
            api_base_url: The base URL for the Anthropic API.
            models: Dictionary containing Claude model pricing information.
        """
        super().__init__(api_key, api_base_url, models)
        
    def collect_data(self, endpoint: str, additional_config: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """Collect usage and cost data from the Claude API.
        
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
        
        # Format timestamps for API request
        start_timestamp = start_time.isoformat() + 'Z'
        end_timestamp = end_time.isoformat() + 'Z'
        
        # Set up the API request
        headers = {
            'x-api-key': self.api_key,
            'Content-Type': 'application/json'
        }
        
        url = f"{self.api_base_url}/{endpoint}"
        params = {
            'start_time': start_timestamp,
            'end_time': end_timestamp
        }
        
        try:
            response = requests.get(url, headers=headers, params=params)
            response.raise_for_status()
            raw_data = response.json()
            
            # Process the API response into standardized format
            result = []
            for item in raw_data.get('data', []):
                model = item.get('model')
                input_tokens = item.get('input_tokens', 0)
                output_tokens = item.get('output_tokens', 0)
                
                # Calculate costs based on model pricing
                cost_details = self.calculate_cost(model, input_tokens, output_tokens)
                
                # Create standardized record
                record = {
                    'model': model,
                    'feature': item.get('endpoint', 'chat'),
                    'request_id': item.get('id'),
                    'input_tokens': input_tokens,
                    'output_tokens': output_tokens,
                    'total_tokens': input_tokens + output_tokens,
                    'input_cost': cost_details['input_cost'],
                    'output_cost': cost_details['output_cost'],
                    'cost': cost_details['total_cost'],
                    'response_time_ms': item.get('response_time_ms', 0),
                    'project': item.get('metadata', {}).get('project'),
                    'user_id': item.get('metadata', {}).get('user_id'),
                    'raw_response': item,
                    'metadata': item.get('metadata', {})
                }
                
                result.append(record)
                
            return result
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error collecting data from Claude API: {e}", extra={
                "error": str(e),
                "error_type": type(e).__name__
            })
            raise
    
    def calculate_cost(self, model: str, input_tokens: int, output_tokens: int) -> Dict[str, float]:
        """Calculate the cost for a Claude API request.
        
        Args:
            model: The Claude model name used for the request.
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
