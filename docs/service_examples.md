# CostWise AI - Service Configuration Examples

This document provides real-world examples of service configurations for popular AI providers. These examples can be used as templates for adding new services to your CostWise AI deployment.

## Authentication

To run these examples, first authenticate with gcloud:

```bash
gcloud auth login
```

Then use the following command structure to add a service:

```bash
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/admin_handler \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer $(gcloud auth print-identity-token)" \
  -d '{...service configuration...}'
```

Replace `REGION-PROJECT_ID` with your actual Cloud Function URL.

## OpenAI Configuration

This example adds OpenAI with up-to-date pricing for various models:

```bash
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/admin_handler \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer $(gcloud auth print-identity-token)" \
  -d '{
    "action": "add_service",
    "service_name": "OpenAI",
    "service_id": "openai",
    "api_type": "REST",
    "api_base_url": "https://api.openai.com/v1",
    "data_collection_endpoint": "usage",
    "secret_name": "your-openai-api-key-secret",
    "models": {
      "gpt-4o": {
        "input_price_per_1k": 5.0,
        "output_price_per_1k": 15.0,
        "description": "GPT-4o model - multimodal capabilities"
      },
      "gpt-4-turbo": {
        "input_price_per_1k": 10.0,
        "output_price_per_1k": 30.0,
        "description": "GPT-4 Turbo model - efficient high capability"
      },
      "gpt-4": {
        "input_price_per_1k": 30.0,
        "output_price_per_1k": 60.0,
        "description": "GPT-4 base model"
      },
      "gpt-3.5-turbo": {
        "input_price_per_1k": 0.5,
        "output_price_per_1k": 1.5,
        "description": "GPT-3.5 Turbo model - efficient"
      },
      "text-embedding-ada-002": {
        "input_price_per_1k": 0.1,
        "output_price_per_1k": 0.0,
        "description": "Text embedding model"
      },
      "dall-e-3": {
        "input_price_per_1k": 40.0,
        "output_price_per_1k": 0.0,
        "description": "DALL-E 3 image generation model"
      }
    },
    "adapter_module": "openai_adapter",
    "active": true,
    "additional_config": {
      "hours_lookback": 24
    }
  }'
```

## Claude (Anthropic) Configuration

This example adds Anthropic's Claude models:

```bash
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/admin_handler \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer $(gcloud auth print-identity-token)" \
  -d '{
    "action": "add_service",
    "service_name": "Claude",
    "service_id": "claude",
    "api_type": "REST",
    "api_base_url": "https://api.anthropic.com",
    "data_collection_endpoint": "v1/usage",
    "secret_name": "your-claude-api-key-secret",
    "models": {
      "claude-3-opus-20240229": {
        "input_price_per_1k": 15.0,
        "output_price_per_1k": 75.0,
        "description": "Claude 3 Opus - most capable model"
      },
      "claude-3-sonnet-20240229": {
        "input_price_per_1k": 3.0,
        "output_price_per_1k": 15.0,
        "description": "Claude 3 Sonnet - balanced model"
      },
      "claude-3-haiku-20240307": {
        "input_price_per_1k": 0.25,
        "output_price_per_1k": 1.25,
        "description": "Claude 3 Haiku - fast, efficient model"
      },
      "claude-2.1": {
        "input_price_per_1k": 8.0,
        "output_price_per_1k": 24.0,
        "description": "Claude 2.1 - legacy model"
      },
      "claude-2.0": {
        "input_price_per_1k": 8.0,
        "output_price_per_1k": 24.0,
        "description": "Claude 2.0 - legacy model"
      },
      "claude-instant-1.2": {
        "input_price_per_1k": 0.8,
        "output_price_per_1k": 2.4,
        "description": "Claude Instant - legacy fast model"
      }
    },
    "adapter_module": "claude_adapter",
    "active": true,
    "additional_config": {
      "hours_lookback": 24
    }
  }'
```

## Perplexity AI Configuration

This example adds Perplexity AI models:

```bash
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/admin_handler \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer $(gcloud auth print-identity-token)" \
  -d '{
    "action": "add_service",
    "service_name": "Perplexity",
    "service_id": "perplexity",
    "api_type": "REST",
    "api_base_url": "https://api.perplexity.ai",
    "data_collection_endpoint": "usage",
    "secret_name": "your-perplexity-api-key-secret",
    "models": {
      "sonar-small-online": {
        "input_price_per_1k": 0.2,
        "output_price_per_1k": 0.8,
        "description": "Sonar Small - online search model"
      },
      "sonar-medium-online": {
        "input_price_per_1k": 0.4,
        "output_price_per_1k": 1.6,
        "description": "Sonar Medium - online search model"
      },
      "sonar-large-online": {
        "input_price_per_1k": 0.8,
        "output_price_per_1k": 3.2,
        "description": "Sonar Large - online search model"
      },
      "mistral-7b-instruct": {
        "input_price_per_1k": 0.05,
        "output_price_per_1k": 0.15,
        "description": "Mistral 7B - small model"
      },
      "mixtral-8x7b-instruct": {
        "input_price_per_1k": 0.27,
        "output_price_per_1k": 0.27,
        "description": "Mixtral 8x7B - mixture of experts model"
      },
      "llama-3-70b-instruct": {
        "input_price_per_1k": 0.7,
        "output_price_per_1k": 0.85,
        "description": "Llama 3 70B - large open model"
      }
    },
    "adapter_module": "perplexity_adapter",
    "active": true,
    "additional_config": {
      "hours_lookback": 24
    }
  }'
```

## Google Gemini (Vertex AI) Configuration

This example shows how to configure Google's Gemini models via Vertex AI:

```bash
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/admin_handler \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer $(gcloud auth print-identity-token)" \
  -d '{
    "action": "add_service",
    "service_name": "Gemini",
    "service_id": "gemini",
    "api_type": "REST",
    "api_base_url": "https://us-central1-aiplatform.googleapis.com/v1",
    "data_collection_endpoint": "projects/YOUR_PROJECT_ID/locations/us-central1/usageStats",
    "secret_name": "your-google-api-key-secret",
    "models": {
      "gemini-1.5-pro": {
        "input_price_per_1k": 3.5,
        "output_price_per_1k": 10.5,
        "description": "Gemini 1.5 Pro - multimodal model"
      },
      "gemini-1.5-flash": {
        "input_price_per_1k": 0.125,
        "output_price_per_1k": 0.375,
        "description": "Gemini 1.5 Flash - efficient model"
      },
      "gemini-1.0-pro": {
        "input_price_per_1k": 1.0,
        "output_price_per_1k": 2.0,
        "description": "Gemini 1.0 Pro - first gen model"
      },
      "gemini-1.0-pro-vision": {
        "input_price_per_1k": 3.5,
        "output_price_per_1k": 10.5,
        "description": "Gemini 1.0 Pro Vision - multimodal model"
      },
      "text-bison": {
        "input_price_per_1k": 0.5,
        "output_price_per_1k": 0.5,
        "description": "Legacy PaLM2 model"
      }
    },
    "adapter_module": "google_vertex_adapter",
    "active": true,
    "additional_config": {
      "hours_lookback": 24,
      "location": "us-central1",
      "auth_type": "application_default"
    }
  }'
```

## Updating an Existing Service

To update an existing service, use the `update_service` action and provide the service_id:

```bash
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/admin_handler \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer $(gcloud auth print-identity-token)" \
  -d '{
    "action": "update_service",
    "service_id": "openai",
    "models": {
      "gpt-4o": {
        "input_price_per_1k": 5.0,
        "output_price_per_1k": 15.0,
        "description": "GPT-4o model - multimodal capabilities"
      },
      "gpt-4-turbo": {
        "input_price_per_1k": 10.0,
        "output_price_per_1k": 30.0,
        "description": "GPT-4 Turbo model - efficient high capability"
      },
      "gpt-4": {
        "input_price_per_1k": 30.0,
        "output_price_per_1k": 60.0,
        "description": "GPT-4 base model"
      },
      "gpt-3.5-turbo": {
        "input_price_per_1k": 0.5,
        "output_price_per_1k": 1.5,
        "description": "GPT-3.5 Turbo model - efficient"
      }
    },
    "active": true
  }'
```

## Listing All Services

To view all configured services:

```bash
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/admin_handler \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer $(gcloud auth print-identity-token)" \
  -d '{
    "action": "list_services"
  }'
```

## Deleting a Service

To remove a service from monitoring:

```bash
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/admin_handler \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer $(gcloud auth print-identity-token)" \
  -d '{
    "action": "delete_service",
    "service_id": "service-to-delete"
  }'
```

## Checking a Secret

To verify that a secret exists and is accessible:

```bash
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/admin_handler \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer $(gcloud auth print-identity-token)" \
  -d '{
    "action": "check_secret",
    "secret_name": "your-openai-api-key-secret"
  }'
```

## Notes on Service Pricing

Pricing for AI models changes frequently. Always refer to the official pricing pages for the most up-to-date information:

- [OpenAI Pricing](https://openai.com/pricing)
- [Anthropic Pricing](https://www.anthropic.com/pricing)
- [Perplexity Pricing](https://www.perplexity.ai/pricing)
- [Google Vertex AI Pricing](https://cloud.google.com/vertex-ai/pricing)

The pricing format in CostWise AI is standardized as:
- `input_price_per_1k`: Cost per 1,000 input/prompt tokens in USD
- `output_price_per_1k`: Cost per 1,000 output/completion tokens in USD

For models that charge differently (e.g., per image or per API call), adapt the pricing to fit this token-based model as closely as possible for tracking purposes.

## Monitoring Collections

After adding a service, you can manually trigger a data collection:

```bash
curl -X POST https://REGION-PROJECT_ID.cloudfunctions.net/collect_data \
  -H "Authorization: bearer $(gcloud auth print-identity-token)"
```

Check the logs to verify the collection is working:

```bash
gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=costwise-ai-data-collection" --limit 20
```