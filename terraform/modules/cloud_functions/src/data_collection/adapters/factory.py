"""Factory for creating service adapters.

This module provides a factory pattern implementation for creating service adapters.
"""

from typing import Dict, Any, Optional

# Import directly from their respective modules to avoid circular imports
from .base_adapter import BaseServiceAdapter
from .claude_adapter import ClaudeAdapter
from .openai_adapter import OpenAIAdapter
from .perplexity_adapter import PerplexityAdapter


class AdapterFactory:
    """Factory for creating AI service adapters."""
    
    # Define adapter mapping directly in the factory
    _adapters = {
        'Claude': ClaudeAdapter,
        'OpenAI': OpenAIAdapter,
        'Perplexity': PerplexityAdapter
    }
    
    @classmethod
    def register_adapter(cls, service_name: str, adapter_class):
        """Register a new adapter class for a service.
        
        Args:
            service_name: The name of the AI service.
            adapter_class: The adapter class to register.
        """
        if not issubclass(adapter_class, BaseServiceAdapter):
            raise TypeError(f"Adapter class must be a subclass of BaseServiceAdapter")
        
        cls._adapters[service_name] = adapter_class
    
    @classmethod
    def create_adapter(cls, service_name: str, api_key: str, api_base_url: str, 
                      models: Dict[str, Any]) -> BaseServiceAdapter:
        """Create an adapter instance for the specified service.
        
        Args:
            service_name: The name of the AI service.
            api_key: The API key for the service.
            api_base_url: The base URL for the service API.
            models: Dictionary containing model pricing information.
            
        Returns:
            An instance of the appropriate service adapter.
            
        Raises:
            ValueError: If no adapter is registered for the service.
        """
        # Try case-insensitive matching first
        for registered_name, adapter_class in cls._adapters.items():
            if registered_name.lower() == service_name.lower():
                return adapter_class(api_key, api_base_url, models)
        
        # If no match found, try using the service name directly
        if service_name in cls._adapters:
            adapter_class = cls._adapters[service_name]
            return adapter_class(api_key, api_base_url, models)
        
        # If still not found, raise error
        raise ValueError(f"No adapter registered for service: {service_name}. Available adapters: {list(cls._adapters.keys())}")
    
    @classmethod
    def get_registered_adapters(cls) -> Dict[str, Any]:
        """Get a dictionary of all registered adapters.
        
        Returns:
            A dictionary mapping service names to adapter classes.
        """
        return cls._adapters.copy()
