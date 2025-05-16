"""Base adapter module for AI service cost tracking.

This module defines the base adapter interface that all service-specific adapters must implement.
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Any, Optional


class BaseServiceAdapter(ABC):
    """Base class for all AI service adapters.
    
    This abstract class defines the interface that all service adapters must implement.
    Concrete implementations should handle the specifics of each AI service API.
    """
    
    def __init__(self, api_key: str, api_base_url: str, models: Dict[str, Any]):
        """Initialize the service adapter.
        
        Args:
            api_key: The API key for authentication.
            api_base_url: The base URL for the service API.
            models: Dictionary containing model pricing information.
        """
        self.api_key = api_key
        self.api_base_url = api_base_url
        self.models = models
    
    @abstractmethod
    def collect_data(self, endpoint: str, additional_config: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """Collect usage and cost data from the AI service API.
        
        Args:
            endpoint: The specific API endpoint to collect data from.
            additional_config: Additional service-specific configuration.
            
        Returns:
            A list of dictionaries containing usage and cost data.
        """
        pass
    
    @abstractmethod
    def calculate_cost(self, model: str, input_tokens: int, output_tokens: int) -> Dict[str, float]:
        """Calculate the cost for a specific API request.
        
        Args:
            model: The model name used for the request.
            input_tokens: Number of input/prompt tokens.
            output_tokens: Number of output/completion tokens.
            
        Returns:
            A dictionary containing input_cost, output_cost, and total cost in USD.
        """
        pass
