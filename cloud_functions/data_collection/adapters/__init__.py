# CostWise AI Service Adapters package

"""
This package provides adapter classes for different AI service APIs.
It handles data collection, cost calculation, and standardization.
"""

# Explicitly export classes for direct importing from the package
__all__ = [
    'BaseServiceAdapter',
    'ClaudeAdapter', 
    'OpenAIAdapter',
    'PerplexityAdapter',
    'AdapterFactory',
    'get_adapter_class'
]

# Import the base adapter first since others depend on it
from .base_adapter import BaseServiceAdapter

# Import service-specific adapters
from .claude_adapter import ClaudeAdapter
from .openai_adapter import OpenAIAdapter 
from .perplexity_adapter import PerplexityAdapter

# Import factory after other imports to avoid circular imports
from .factory import AdapterFactory

# Helper function to get adapter class by name
def get_adapter_class(service_name):
    """Get adapter class by service name (case-insensitive)."""
    adapter_map = {
        'claude': ClaudeAdapter,
        'openai': OpenAIAdapter,
        'perplexity': PerplexityAdapter
    }
    return adapter_map.get(service_name.lower())
