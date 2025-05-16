import functions_framework
import os
import json
import logging
import importlib
import time
from datetime import datetime
import google.cloud.bigquery as bigquery
import google.cloud.secretmanager as secretmanager
import google.cloud.logging

# Setup structured logging
logging_client = google.cloud.logging.Client()
logging_client.setup_logging()
logger = logging.getLogger('costwise-data-collection')
logger.setLevel(logging.INFO)


@functions_framework.http
def collect_data(request):
    """HTTP Cloud Function to collect data from AI service APIs.
    Args:
        request (flask.Request): The request object.
    Returns:
        The response text, or any set of values that can be turned into a
        Response object using `make_response`
    """
    start_time = time.time()
    request_id = request.headers.get('X-Request-Id', datetime.utcnow().isoformat())
    logger.info(f"Starting data collection job", extra={
        "request_id": request_id,
        "event_type": "job_start"
    })
    
    try:
        # Get environment variables
        project_id = os.environ.get("PROJECT_ID")
        dataset_id = os.environ.get("DATASET_ID")
        service_config_table_id = os.environ.get("SERVICE_CONFIG_TABLE_ID")
        cost_data_table_id = os.environ.get("COST_DATA_TABLE_ID")
        
        logger.info(f"Configuration loaded", extra={
            "request_id": request_id,
            "project_id": project_id,
            "dataset_id": dataset_id,
            "service_config_table_id": service_config_table_id,
            "cost_data_table_id": cost_data_table_id
        })

        # Initialize clients
        bq_client = bigquery.Client(project=project_id)
        sm_client = secretmanager.SecretManagerServiceClient()

        # Query service configurations from BigQuery
        query = f"""SELECT * FROM `{project_id}.{dataset_id}.{service_config_table_id}` WHERE active = TRUE"""
        logger.info(f"Querying service configurations", extra={"request_id": request_id, "query": query})
        
        service_configs = list(bq_client.query(query).result())
        logger.info(f"Found {len(service_configs)} active service configurations", extra={
            "request_id": request_id,
            "service_count": len(service_configs),
            "services": [config["service_name"] for config in service_configs]
        })

        results = [] 
        for service_config in service_configs:
            service_start_time = time.time()
            service_name = service_config["service_name"]
            logger.info(f"Processing service: {service_name}", extra={
                "request_id": request_id,
                "service_name": service_name,
                "adapter_module": service_config["adapter_module"],
                "event_type": "service_processing_start"
            })
            
            try:
                # Import the appropriate service adapter module dynamically
                adapter_module_name = service_config["adapter_module"]
                logger.info(f"Importing adapter module: {adapter_module_name}", extra={
                    "request_id": request_id,
                    "service_name": service_name,
                    "adapter_module_path": f"adapters.{adapter_module_name}"
                })
                
                # Get API credentials from Secret Manager first
                secret_name = service_config["secret_name"]
                
                # Construct the full path to the secret version
                secret_version_path = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
                
                logger.info(f"Accessing secret version: {secret_name}", extra={
                    "request_id": request_id,
                    "service_name": service_name,
                    "secret_name": secret_name,
                    "secret_version_path": secret_version_path
                })
                
                try:
                    # Access the secret value directly
                    response = sm_client.access_secret_version(name=secret_version_path)
                    api_key = response.payload.data.decode("UTF-8")
                    
                    logger.info(f"Retrieved API key successfully", extra={
                        "request_id": request_id,
                        "service_name": service_name
                    })
                except Exception as e:
                    error_message = f"Error accessing secret '{secret_name}': {str(e)}"
                    logger.error(error_message, extra={
                        "request_id": request_id,
                        "service_name": service_name,
                        "secret_name": secret_name,
                        "error": str(e),
                        "error_type": type(e).__name__,
                        "secret_version_path": secret_version_path
                    })
                    raise Exception(error_message)
                
                # Now try to create the adapter with the API key
                try:
                    # Import the adapters package
                    from adapters import AdapterFactory
                    
                    logger.info(f"Using adapter factory to create adapter for {service_name}", extra={
                        "request_id": request_id,
                        "service_name": service_name,
                        "adapter_module": adapter_module_name
                    })
                    
                    # Create the adapter through the factory pattern
                    adapter = AdapterFactory.create_adapter(
                        service_name=service_name,
                        api_key=api_key,
                        api_base_url=service_config["api_base_url"],
                        models=service_config["models"]
                    )
                    
                    logger.info(f"Successfully created adapter through factory", extra={
                        "request_id": request_id,
                        "service_name": service_name,
                        "adapter_class": adapter.__class__.__name__
                    })
                    
                except (ImportError, AttributeError, ValueError) as e:
                    # Factory approach failed, fall back to direct import 
                    logger.warning(f"Factory approach failed, trying direct import: {str(e)}", extra={
                        "request_id": request_id,
                        "service_name": service_name,
                        "error": str(e),
                        "error_type": type(e).__name__
                    })
                    
                    # Try direct import from the adapters package
                    try:
                        # Import the adapter helper function from the adapters package
                        import adapters
                        
                        # Try using the helper function to get the adapter class
                        adapter_class = adapters.get_adapter_class(service_name)
                        
                        if adapter_class:
                            logger.info(f"Found adapter class using helper function", extra={
                                "request_id": request_id,
                                "service_name": service_name,
                                "adapter_class": adapter_class.__name__
                            })
                        else:
                            # Try direct imports as a fallback
                            try:
                                if service_name.lower() == 'claude':
                                    from adapters.claude_adapter import ClaudeAdapter
                                    adapter_class = ClaudeAdapter
                                elif service_name.lower() == 'openai':
                                    from adapters.openai_adapter import OpenAIAdapter
                                    adapter_class = OpenAIAdapter
                                elif service_name.lower() == 'perplexity':
                                    from adapters.perplexity_adapter import PerplexityAdapter
                                    adapter_class = PerplexityAdapter
                                
                                logger.info(f"Found adapter class using direct import", extra={
                                    "request_id": request_id,
                                    "service_name": service_name,
                                    "adapter_class": adapter_class.__name__
                                })
                            except (ImportError, AttributeError):
                                logger.warning(f"Failed to import specific adapter class", extra={
                                    "request_id": request_id,
                                    "service_name": service_name
                                })
                            
                            # If still no match, raise an error
                            if adapter_class is None:
                                raise ValueError(f"No adapter found for service: {service_name}")
                                
                    except (ImportError, AttributeError) as e:
                        logger.error(f"Failed to import adapter for {service_name}: {str(e)}", extra={
                            "request_id": request_id,
                            "service_name": service_name,
                            "error": str(e),
                            "error_type": type(e).__name__
                        })
                        raise

                # Initialize the adapter if we got a class (not an instance)
                if 'adapter_class' in locals():
                    # We have a class, need to instantiate it
                    logger.info(f"Initializing adapter for {service_name}", extra={
                        "request_id": request_id,
                        "service_name": service_name,
                        "api_base_url": service_config["api_base_url"],
                        "models_count": len(service_config["models"])
                    })
                    
                    adapter = adapter_class(
                        api_key=api_key,
                        api_base_url=service_config["api_base_url"],
                        models=service_config["models"],
                    )
                    
                    logger.info(f"Successfully instantiated adapter from class", extra={
                        "request_id": request_id,
                        "service_name": service_name,
                        "adapter_class": adapter_class.__name__
                    })

                # Collect data using the adapter with better error handling
                logger.info(f"Collecting data from {service_name}", extra={
                    "request_id": request_id,
                    "service_name": service_name,
                    "endpoint": service_config["data_collection_endpoint"],
                    "event_type": "data_collection_start"
                })
                
                # Get the additional config with defaults to prevent errors
                additional_config = service_config.get("additional_config", {})
                if not isinstance(additional_config, dict):
                    logger.warning(f"additional_config is not a dictionary, using empty dict", extra={
                        "request_id": request_id,
                        "service_name": service_name,
                        "additional_config_type": type(additional_config).__name__
                    })
                    additional_config = {}
                
                # Set a default hours_lookback if not specified
                if "hours_lookback" not in additional_config:
                    additional_config["hours_lookback"] = 24
                    logger.info(f"Using default hours_lookback of 24", extra={
                        "request_id": request_id,
                        "service_name": service_name
                    })
                
                # Add retry logic for API calls
                max_retries = 3
                retry_count = 0
                
                while retry_count < max_retries:
                    try:
                        collection_start = time.time()
                        service_data = adapter.collect_data(
                            endpoint=service_config["data_collection_endpoint"],
                            additional_config=additional_config,
                        )
                        collection_duration = time.time() - collection_start
                        
                        logger.info(f"Data collection complete for {service_name}", extra={
                            "request_id": request_id,
                            "service_name": service_name,
                            "records_count": len(service_data),
                            "collection_duration_seconds": round(collection_duration, 2),
                            "event_type": "data_collection_complete"
                        })
                        break  # Success, exit the retry loop
                        
                    except Exception as e:
                        retry_count += 1
                        logger.warning(f"Data collection attempt {retry_count} failed: {str(e)}", extra={
                            "request_id": request_id,
                            "service_name": service_name,
                            "error": str(e),
                            "error_type": type(e).__name__,
                            "retry_count": retry_count,
                            "max_retries": max_retries
                        })
                        
                        if retry_count >= max_retries:
                            logger.error(f"All retry attempts failed for {service_name}", extra={
                                "request_id": request_id,
                                "service_name": service_name,
                                "error": str(e),
                                "retries_exhausted": True
                            })
                            raise  # Re-raise the last exception after all retries failed
                        
                        # Wait before retrying (exponential backoff)
                        time.sleep(2 ** retry_count)  # 2, 4, 8 seconds
                
                # Validate the service data
                if not service_data:
                    logger.warning(f"Service {service_name} returned no data", extra={
                        "request_id": request_id,
                        "service_name": service_name,
                        "event_type": "empty_data"
                    })
                    # Continue with empty data rather than raising an error
                    service_data = []
                
                # Transform data to standard format
                logger.info(f"Transforming data for {service_name}", extra={
                    "request_id": request_id,
                    "service_name": service_name,
                    "items_to_transform": len(service_data)
                })
                
                for item in service_data:
                    # Add required fields with validation
                    item["service_name"] = service_config["service_name"]
                    item["timestamp"] = datetime.utcnow().isoformat()
                    
                    # Ensure all required fields have values
                    for field in ["model", "input_tokens", "output_tokens", "cost"]:
                        if field not in item or item[field] is None:
                            logger.warning(f"Missing required field '{field}' in data item, using default", extra={
                                "request_id": request_id,
                                "service_name": service_name,
                                "item_id": item.get("request_id", "unknown")
                            })
                            
                            # Set default values for missing fields
                            if field == "model":
                                item[field] = "unknown"
                            elif field in ["input_tokens", "output_tokens"]:
                                item[field] = 0
                            elif field == "cost":
                                item[field] = 0.0

                # Skip BigQuery insertion if there's no data
                if not service_data:
                    logger.info(f"No data to insert for {service_name}, skipping BigQuery insertion", extra={
                        "request_id": request_id,
                        "service_name": service_name,
                        "event_type": "bigquery_insert_skipped"
                    })
                else:
                    # Validate and clean up data before insertion
                    validated_data = []
                    for item in service_data:
                        # Convert numerical fields to the correct type to avoid BigQuery errors
                        try:
                            item["input_tokens"] = int(item["input_tokens"])
                            item["output_tokens"] = int(item["output_tokens"])
                            
                            if "total_tokens" in item:
                                item["total_tokens"] = int(item["total_tokens"])
                            else:
                                item["total_tokens"] = item["input_tokens"] + item["output_tokens"]
                                
                            item["cost"] = float(item["cost"])
                            
                            if "input_cost" in item:
                                item["input_cost"] = float(item["input_cost"])
                            if "output_cost" in item:
                                item["output_cost"] = float(item["output_cost"])
                                
                            validated_data.append(item)
                        except (ValueError, TypeError) as e:
                            logger.warning(f"Data validation error for item: {str(e)}", extra={
                                "request_id": request_id,
                                "service_name": service_name,
                                "item_id": item.get("request_id", "unknown"),
                                "error": str(e)
                            })
                    
                    # Insert data into BigQuery with better error handling
                    logger.info(f"Inserting {len(validated_data)} records into BigQuery for {service_name}", extra={
                        "request_id": request_id,
                        "service_name": service_name,
                        "records_count": len(validated_data),
                        "table": f"{project_id}.{dataset_id}.{cost_data_table_id}",
                        "event_type": "bigquery_insert_start"
                    })
                    
                    if validated_data:
                        insert_start = time.time()
                        try:
                            table_ref = bq_client.dataset(dataset_id).table(cost_data_table_id)
                            errors = bq_client.insert_rows_json(table_ref, validated_data)
                            insert_duration = time.time() - insert_start
    
                            if errors:
                                error_message = f"Error inserting rows for {service_name}: {errors}"
                                logger.error(error_message, extra={
                                    "request_id": request_id,
                                    "service_name": service_name,
                                    "errors": str(errors),
                                    "event_type": "bigquery_insert_error"
                                })
                                # Don't raise exception, continue with other services
                                # This allows one service to fail while others still work
                            else:
                                logger.info(f"Successfully inserted data for {service_name}", extra={
                                    "request_id": request_id,
                                    "service_name": service_name,
                                    "records_count": len(validated_data),
                                    "insert_duration_seconds": round(insert_duration, 2),
                                    "event_type": "bigquery_insert_complete"
                                })
                        except Exception as e:
                            logger.error(f"BigQuery insertion error for {service_name}: {str(e)}", extra={
                                "request_id": request_id,
                                "service_name": service_name,
                                "error": str(e),
                                "error_type": type(e).__name__,
                                "event_type": "bigquery_insert_exception"
                            })
                            # Don't raise exception, continue with other services
                            # This allows one service to fail while others still work

                service_duration = time.time() - service_start_time
                results.append(
                    {
                        "service": service_name,
                        "records_collected": len(service_data),
                        "status": "success",
                        "duration_seconds": round(service_duration, 2)
                    }
                )
                
                logger.info(f"Completed processing for {service_name}", extra={
                    "request_id": request_id,
                    "service_name": service_name,
                    "duration_seconds": round(service_duration, 2),
                    "event_type": "service_processing_complete",
                    "status": "success"
                })

            except Exception as e:
                service_duration = time.time() - service_start_time
                error_message = str(e)
                logger.error(f"Error processing {service_name}: {error_message}", extra={
                    "request_id": request_id,
                    "service_name": service_name,
                    "error": error_message,
                    "duration_seconds": round(service_duration, 2),
                    "event_type": "service_processing_error"
                })
                
                results.append(
                    {
                        "service": service_name,
                        "status": "error",
                        "error": error_message,
                        "duration_seconds": round(service_duration, 2)
                    }
                )

        total_duration = time.time() - start_time
        response_data = {
            "results": results,
            "total_duration_seconds": round(total_duration, 2),
            "timestamp": datetime.utcnow().isoformat(),
            "request_id": request_id
        }
        
        logger.info(f"Data collection job completed successfully", extra={
            "request_id": request_id,
            "total_duration_seconds": round(total_duration, 2),
            "services_processed": len(service_configs),
            "event_type": "job_complete"
        })
        
        return (
            json.dumps(response_data),
            200,
            {"Content-Type": "application/json"},
        )

    except Exception as e:
        total_duration = time.time() - start_time
        error_message = str(e)
        
        logger.error(f"Data collection job failed: {error_message}", extra={
            "request_id": request_id,
            "error": error_message,
            "total_duration_seconds": round(total_duration, 2),
            "event_type": "job_error"
        })
        
        return json.dumps({
            "error": error_message,
            "request_id": request_id,
            "timestamp": datetime.utcnow().isoformat()
        }), 500, {"Content-Type": "application/json"}