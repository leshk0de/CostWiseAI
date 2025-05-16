# OpenAI Adapter URL Fix

## Issue

When using the OpenAI API integration, users encountered 404 errors due to malformed API URLs. The issue occurred because the adapter was incorrectly constructing URLs with duplicate `/v1` path segments when the configured `api_base_url` already included `/v1` at the end.

For example, if a user configured:
```
api_base_url = "https://api.openai.com/v1"
```

The adapter would construct request URLs like:
```
https://api.openai.com/v1/v1/chat/completions
```

This resulted in 404 errors as the endpoint does not exist.

## Fix Implementation

The issue was resolved by adding logic to check if the configured `api_base_url` already ends with `/v1`. The adapter now constructs URLs correctly to avoid path duplication:

```python
def construct_endpoint_url(self, endpoint):
    # Check if the base URL already ends with /v1
    if self.api_base_url.endswith('/v1'):
        return f"{self.api_base_url}/{endpoint}"
    else:
        return f"{self.api_base_url}/v1/{endpoint}"
```

With this fix, URLs are constructed properly:
- When `api_base_url = "https://api.openai.com/v1"` → `https://api.openai.com/v1/chat/completions`
- When `api_base_url = "https://api.openai.com"` → `https://api.openai.com/v1/chat/completions`

## Configuration Recommendations

When configuring the OpenAI service in your BigQuery configuration, follow these guidelines:

1. Specify the `api_base_url` without the trailing `/v1` when possible:
   ```json
   "api_base_url": "https://api.openai.com"
   ```

2. If you must include `/v1` in the URL (such as with certain OpenAI-compatible APIs):
   ```json
   "api_base_url": "https://your-custom-endpoint.com/v1"
   ```

3. Always verify your API key and endpoint configuration in isolation before running full integration.

4. If using Azure OpenAI service, follow Azure's specific endpoint format:
   ```json
   "api_base_url": "https://{your-resource-name}.openai.azure.com"
   ```

This fix ensures reliable API connectivity across different OpenAI API endpoint configurations while maintaining compatibility with both standard OpenAI and OpenAI-compatible services.