# OpenAI Usage Endpoint URL Fix

## Issue

When attempting to access the OpenAI usage endpoint, users encountered 404 errors due to incorrectly constructed URLs. The issue was observed with the following error:

```
404 Client Error: Not Found for url: https://api.openai.com/v1/v1/usage?date=2025-05-15
```

This occurred because the adapter was appending `/v1/usage` to the `api_base_url`, which already included `/v1`, resulting in duplicate path segments.

## Fix Implementation

The issue has been resolved in the OpenAI adapter by adding conditional logic to check if the `api_base_url` already ends with `/v1` before constructing the URL path:

```python
# For the usage endpoint (avoid duplicate /v1 path segments)
if self.api_base_url.endswith('/v1'):
    url = f"{self.api_base_url}/usage"
else:
    url = f"{self.api_base_url}/v1/usage"
```

This fix was also applied to:
- The `organization/costs` endpoint
- Custom endpoints with `v1/` prefixes

## Configuration Recommendations

1. **Usage Endpoint**: To collect data from the OpenAI usage endpoint:
   ```json
   {
     "service_name": "OpenAI",
     "adapter_module": "openai_adapter",
     "api_base_url": "https://api.openai.com",
     "data_collection_endpoint": "usage",
     "additional_config": {
       "hours_lookback": 24
     }
   }
   ```

2. **Organization Costs Endpoint**: To collect data from the organization costs endpoint:
   ```json
   {
     "service_name": "OpenAI",
     "adapter_module": "openai_adapter",
     "api_base_url": "https://api.openai.com",
     "data_collection_endpoint": "organization/costs",
     "additional_config": {
       "hours_lookback": 24
     }
   }
   ```

3. **Important Notes**:
   - The `date` parameter for the usage endpoint will automatically use the date based on your `hours_lookback` configuration
   - You must have the appropriate permissions in your OpenAI account to access these endpoints
   - The usage endpoint provides more detailed token usage information
   - The organization/costs endpoint provides actual billed cost information

## Troubleshooting

If you continue to experience issues:

1. Verify your API key has the appropriate permissions for the usage endpoints
2. Confirm your OpenAI account type supports the usage endpoints
3. Test the API endpoints directly using a tool like curl or Postman
4. Check the Cloud Function logs for detailed error messages and request URLs

This fix ensures proper URL construction for all OpenAI API endpoints while maintaining backward compatibility.