import functions_framework
import os
import json
import logging
import traceback
from datetime import datetime
import google.cloud.bigquery as bigquery
import google.cloud.secretmanager as secretmanager
import google.cloud.logging

# Setup structured logging
logging_client = google.cloud.logging.Client()
logging_client.setup_logging()
logger = logging.getLogger('costwise-admin')
logger.setLevel(logging.DEBUG)  # Set to DEBUG for maximum logging

@functions_framework.http
def admin_handler(request):
    """HTTP Cloud Function for administrative operations.
    Args:
        request (flask.Request): The request object.
    Returns:
        The response text, or any set of values that can be turned into a
        Response object using `make_response`
    """
    request_id = request.headers.get('X-Request-Id', datetime.utcnow().isoformat())
    logger.info(f"Starting admin handler", extra={
        "request_id": request_id,
        "event_type": "admin_request_start",
        "remote_addr": request.remote_addr,
        "method": request.method
    })
    
    try:
        # Get environment variables
        project_id = os.environ.get('PROJECT_ID')
        dataset_id = os.environ.get('DATASET_ID')
        service_config_table_id = os.environ.get('SERVICE_CONFIG_TABLE_ID')
        
        logger.info(f"Configuration loaded", extra={
            "request_id": request_id,
            "project_id": project_id,
            "dataset_id": dataset_id,
            "service_config_table_id": service_config_table_id
        })
        
        # Initialize clients
        bq_client = bigquery.Client(project=project_id)
        sm_client = secretmanager.SecretManagerServiceClient()
        
        # Extract request data
        request_json = request.get_json(silent=True)
        if not request_json or 'action' not in request_json:
            logger.error("Invalid request: missing action", extra={
                "request_id": request_id,
                "request_body": request.data.decode('utf-8') if request.data else None,
                "event_type": "admin_request_error"
            })
            return json.dumps({"error": "Invalid request: missing action"}), 400, {'Content-Type': 'application/json'}
        
        action = request_json['action']
        logger.info(f"Processing admin action: {action}", extra={
            "request_id": request_id,
            "action": action
        })
        
        # Handle different administrative actions
        if action == 'add_service':
            # Validate required fields
            required_fields = ['service_name', 'service_id', 'api_type', 'api_base_url', 
                             'data_collection_endpoint', 'secret_name', 'models', 'adapter_module']
            
            for field in required_fields:
                if field not in request_json:
                    logger.error(f"Missing required field", extra={
                        "request_id": request_id,
                        "field": field,
                        "event_type": "validation_error"
                    })
                    return json.dumps({"error": f"Missing required field: {field}"}), 400, {'Content-Type': 'application/json'}
            
            # Prepare service configuration
            service_config = {
                "service_name": request_json['service_name'],
                "service_id": request_json['service_id'],
                "api_type": request_json['api_type'],
                "api_base_url": request_json['api_base_url'],
                "data_collection_endpoint": request_json['data_collection_endpoint'],
                "secret_name": request_json['secret_name'],
                "models": json.dumps(request_json['models']),
                "adapter_module": request_json['adapter_module'],
                "active": request_json.get('active', True),
                "data_collection_frequency": request_json.get('data_collection_frequency', None),
                "updated_at": datetime.utcnow().isoformat(),
                "additional_config": json.dumps(request_json.get('additional_config', {}))
            }
            
            logger.info(f"Adding new service configuration", extra={
                "request_id": request_id,
                "service_name": service_config['service_name'],
                "service_id": service_config['service_id'],
                "secret_name": service_config['secret_name']
            })
            
            # Check if the secret exists and is accessible
            secret_name = service_config['secret_name']
            # Construct the full path to the secret VERSION, not just the secret
            secret_version_path = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
            
            logger.info(f"Verifying access to secret version", extra={
                "request_id": request_id,
                "secret_name": secret_name,
                "secret_version_path": secret_version_path
            })
            
            try:
                # Try to access the secret VALUE, not just metadata
                response = sm_client.access_secret_version(name=secret_version_path)
                # If we got here, we successfully accessed the secret
                logger.info(f"Successfully accessed secret '{secret_name}'", extra={
                    "request_id": request_id,
                    "secret_name": secret_name
                })
            except Exception as e:
                logger.error(f"Error accessing secret '{secret_name}': {str(e)}", extra={
                    "request_id": request_id,
                    "secret_name": secret_name,
                    "error": str(e),
                    "error_type": type(e).__name__,
                    "secret_version_path": secret_version_path
                })
                
                return json.dumps({
                    "error": f"Error accessing secret '{secret_name}': {str(e)}",
                    "secret_name": secret_name,
                    "secret_version_path": secret_version_path
                }), 400, {'Content-Type': 'application/json'}
            
            # Insert into BigQuery
            logger.info(f"Inserting service configuration into BigQuery", extra={
                "request_id": request_id,
                "table": f"{project_id}.{dataset_id}.{service_config_table_id}"
            })
            
            table_ref = bq_client.dataset(dataset_id).table(service_config_table_id)
            errors = bq_client.insert_rows_json(table_ref, [service_config])
            
            if errors:
                logger.error(f"Error inserting into BigQuery", extra={
                    "request_id": request_id,
                    "errors": errors
                })
                return json.dumps({"error": f"Error inserting service configuration: {errors}"}), 500, {'Content-Type': 'application/json'}
            
            logger.info(f"Service added successfully", extra={
                "request_id": request_id,
                "service_name": service_config['service_name'],
                "service_id": service_config['service_id'],
                "event_type": "service_added"
            })
            
            return json.dumps({
                "success": True,
                "message": f"Service {service_config['service_name']} added successfully",
                "service_id": service_config['service_id']
            }), 200, {'Content-Type': 'application/json'}
            
        elif action == 'update_service':
            # Validate service_id
            if 'service_id' not in request_json:
                logger.error("Missing service_id in update request", extra={
                    "request_id": request_id
                })
                return json.dumps({"error": "Missing service_id"}), 400, {'Content-Type': 'application/json'}
            
            service_id = request_json['service_id']
            logger.info(f"Updating service", extra={
                "request_id": request_id,
                "service_id": service_id
            })
            
            # Get existing service configuration
            query = f"""SELECT * FROM `{project_id}.{dataset_id}.{service_config_table_id}`
                     WHERE service_id = '{service_id}'"""
            
            logger.info(f"Querying existing service", extra={
                "request_id": request_id,
                "query": query
            })
            
            results = list(bq_client.query(query).result())
            
            if not results:
                logger.error(f"Service not found", extra={
                    "request_id": request_id,
                    "service_id": service_id
                })
                return json.dumps({"error": f"Service with ID {service_id} not found"}), 404, {'Content-Type': 'application/json'}
            
            # Check if secret needs to be verified
            if 'secret_name' in request_json:
                secret_name = request_json['secret_name']
                secret_version_path = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
                
                logger.info(f"Verifying access to updated secret version", extra={
                    "request_id": request_id,
                    "secret_name": secret_name,
                    "secret_version_path": secret_version_path
                })
                
                try:
                    # Try to access the secret VALUE
                    response = sm_client.access_secret_version(name=secret_version_path)
                    # If we got here, we successfully accessed the secret
                    logger.info(f"Successfully accessed secret '{secret_name}'", extra={
                        "request_id": request_id,
                        "secret_name": secret_name
                    })
                except Exception as e:
                    logger.error(f"Error accessing secret '{secret_name}': {str(e)}", extra={
                        "request_id": request_id,
                        "secret_name": secret_name,
                        "error": str(e),
                        "error_type": type(e).__name__,
                        "secret_version_path": secret_version_path
                    })
                    
                    return json.dumps({
                        "error": f"Error accessing secret '{secret_name}': {str(e)}",
                        "secret_name": secret_name,
                        "secret_version_path": secret_version_path
                    }), 400, {'Content-Type': 'application/json'}
            
            # Update service configuration
            update_query = "UPDATE `{}.{}.{}` SET ".format(project_id, dataset_id, service_config_table_id)
            update_parts = []
            
            # Fields that can be updated
            updatable_fields = [
                'service_name', 'api_type', 'api_base_url', 'data_collection_endpoint',
                'secret_name', 'models', 'adapter_module', 'active', 'data_collection_frequency',
                'additional_config'
            ]
            
            for field in updatable_fields:
                if field in request_json:
                    value = request_json[field]
                    if field in ['models', 'additional_config']:
                        value = json.dumps(value)
                    update_parts.append(f"{field} = '{value}'")
            
            # Add updated_at timestamp
            update_parts.append(f"updated_at = '{datetime.utcnow().isoformat()}'")
            
            if not update_parts:
                logger.error("No fields to update", extra={
                    "request_id": request_id,
                    "service_id": service_id
                })
                return json.dumps({"error": "No fields to update"}), 400, {'Content-Type': 'application/json'}
            
            update_query += ", ".join(update_parts)
            update_query += f" WHERE service_id = '{service_id}'"
            
            logger.info(f"Executing update query", extra={
                "request_id": request_id,
                "query": update_query
            })
            
            # Execute update query
            bq_client.query(update_query).result()
            
            logger.info(f"Service updated successfully", extra={
                "request_id": request_id,
                "service_id": service_id,
                "event_type": "service_updated"
            })
            
            return json.dumps({
                "success": True,
                "message": f"Service {service_id} updated successfully"
            }), 200, {'Content-Type': 'application/json'}
            
        elif action == 'delete_service':
            # Validate service_id
            if 'service_id' not in request_json:
                logger.error("Missing service_id in delete request", extra={
                    "request_id": request_id
                })
                return json.dumps({"error": "Missing service_id"}), 400, {'Content-Type': 'application/json'}
            
            service_id = request_json['service_id']
            logger.info(f"Deleting service", extra={
                "request_id": request_id,
                "service_id": service_id
            })
            
            # Delete service configuration
            delete_query = f"""DELETE FROM `{project_id}.{dataset_id}.{service_config_table_id}`
                          WHERE service_id = '{service_id}'"""
            
            logger.info(f"Executing delete query", extra={
                "request_id": request_id,
                "query": delete_query
            })
            
            bq_client.query(delete_query).result()
            
            logger.info(f"Service deleted successfully", extra={
                "request_id": request_id,
                "service_id": service_id,
                "event_type": "service_deleted"
            })
            
            return json.dumps({
                "success": True,
                "message": f"Service {service_id} deleted successfully"
            }), 200, {'Content-Type': 'application/json'}
            
        elif action == 'list_services':
            logger.info(f"Listing all services", extra={
                "request_id": request_id
            })
            
            # Query all service configurations
            query = f"""SELECT * FROM `{project_id}.{dataset_id}.{service_config_table_id}`"""
            
            logger.info(f"Executing list query", extra={
                "request_id": request_id,
                "query": query
            })
            
            results = list(bq_client.query(query).result())
            
            services = []
            for row in results:
                service_data = dict(row.items())
                
                # Parse JSON fields
                if 'models' in service_data:
                    service_data['models'] = json.loads(service_data['models'])
                if 'additional_config' in service_data and service_data['additional_config']:
                    service_data['additional_config'] = json.loads(service_data['additional_config'])
                
                services.append(service_data)
            
            logger.info(f"Retrieved {len(services)} services", extra={
                "request_id": request_id,
                "service_count": len(services),
                "event_type": "services_listed"
            })
            
            return json.dumps({
                "success": True,
                "services": services
            }), 200, {'Content-Type': 'application/json'}
            
        elif action == 'check_secret':
            # Simple utility to check if a specific secret exists and is accessible
            if 'secret_name' not in request_json:
                logger.error("Missing secret_name in check_secret request", extra={
                    "request_id": request_id
                })
                return json.dumps({"error": "Missing secret_name"}), 400, {'Content-Type': 'application/json'}
            
            secret_name = request_json['secret_name']
            logger.info(f"Checking if secret is accessible", extra={
                "request_id": request_id,
                "secret_name": secret_name
            })
            
            # Construct path to the secret VERSION, not just secret metadata
            secret_version_path = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
            
            try:
                # Try to access the secret VALUE, not just metadata
                response = sm_client.access_secret_version(name=secret_version_path)
                
                # If we got here, secret exists and is accessible
                secret_value = response.payload.data.decode("UTF-8")
                # Don't log actual secret value, just first few chars for validation
                value_preview = secret_value[:3] + "..." if len(secret_value) > 3 else "..."
                
                logger.info(f"Successfully accessed secret '{secret_name}'", extra={
                    "request_id": request_id,
                    "secret_name": secret_name,
                    "value_preview": value_preview
                })
                
                return json.dumps({
                    "success": True,
                    "message": f"Secret '{secret_name}' exists and is accessible",
                    "secret_name": secret_name,
                    "value_preview": value_preview
                }), 200, {'Content-Type': 'application/json'}
                
            except Exception as e:
                logger.error(f"Error accessing secret '{secret_name}': {str(e)}", extra={
                    "request_id": request_id,
                    "secret_name": secret_name,
                    "error": str(e),
                    "error_type": type(e).__name__,
                    "secret_version_path": secret_version_path
                })
                
                return json.dumps({
                    "error": f"Error accessing secret '{secret_name}': {str(e)}",
                    "secret_name": secret_name,
                    "secret_version_path": secret_version_path
                }), 400, {'Content-Type': 'application/json'}
        else:
            logger.error(f"Unknown action", extra={
                "request_id": request_id,
                "action": action
            })
            
            return json.dumps({"error": f"Unknown action: {action}"}), 400, {'Content-Type': 'application/json'}
            
    except Exception as e:
        tb = traceback.format_exc()
        logger.error(f"Unhandled exception in admin handler", extra={
            "request_id": request_id,
            "error": str(e),
            "error_type": type(e).__name__,
            "traceback": tb,
            "event_type": "admin_unhandled_error"
        })
        
        return json.dumps({
            "error": str(e),
            "error_type": type(e).__name__,
            "traceback": tb
        }), 500, {'Content-Type': 'application/json'}
    finally:
        logger.info(f"Completed admin handler", extra={
            "request_id": request_id,
            "event_type": "admin_request_end"
        })