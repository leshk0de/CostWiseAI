import functions_framework
import os
import json
from datetime import datetime
import google.cloud.bigquery as bigquery
import google.cloud.secretmanager as secretmanager

@functions_framework.http
def admin_handler(request):
    """HTTP Cloud Function for administrative operations.
    Args:
        request (flask.Request): The request object.
    Returns:
        The response text, or any set of values that can be turned into a
        Response object using `make_response`
    """
    try:
        # Get environment variables
        project_id = os.environ.get('PROJECT_ID')
        dataset_id = os.environ.get('DATASET_ID')
        service_config_table_id = os.environ.get('SERVICE_CONFIG_TABLE_ID')
        
        # Initialize clients
        bq_client = bigquery.Client(project=project_id)
        sm_client = secretmanager.SecretManagerServiceClient()
        
        # Extract request data
        request_json = request.get_json(silent=True)
        if not request_json or 'action' not in request_json:
            return json.dumps({"error": "Invalid request: missing action"}), 400, {'Content-Type': 'application/json'}
        
        action = request_json['action']
        
        # Handle different administrative actions
        if action == 'add_service':
            # Validate required fields
            required_fields = ['service_name', 'service_id', 'api_type', 'api_base_url', 
                             'data_collection_endpoint', 'secret_name', 'models', 'adapter_module']
            
            for field in required_fields:
                if field not in request_json:
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
            
            # Check if the secret exists
            secret_path = f"projects/{project_id}/secrets/{service_config['secret_name']}"
            try:
                sm_client.get_secret(name=secret_path)
            except Exception:
                return json.dumps({"error": f"Secret {service_config['secret_name']} does not exist"}), 400, {'Content-Type': 'application/json'}
            
            # Insert into BigQuery
            table_ref = bq_client.dataset(dataset_id).table(service_config_table_id)
            errors = bq_client.insert_rows_json(table_ref, [service_config])
            
            if errors:
                return json.dumps({"error": f"Error inserting service configuration: {errors}"}), 500, {'Content-Type': 'application/json'}
            
            return json.dumps({
                "success": True,
                "message": f"Service {service_config['service_name']} added successfully",
                "service_id": service_config['service_id']
            }), 200, {'Content-Type': 'application/json'}
            
        elif action == 'update_service':
            # Validate service_id
            if 'service_id' not in request_json:
                return json.dumps({"error": "Missing service_id"}), 400, {'Content-Type': 'application/json'}
            
            service_id = request_json['service_id']
            
            # Get existing service configuration
            query = f"""SELECT * FROM `{project_id}.{dataset_id}.{service_config_table_id}`
                     WHERE service_id = '{service_id}'"""
            results = list(bq_client.query(query).result())
            
            if not results:
                return json.dumps({"error": f"Service with ID {service_id} not found"}), 404, {'Content-Type': 'application/json'}
            
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
                return json.dumps({"error": "No fields to update"}), 400, {'Content-Type': 'application/json'}
            
            update_query += ", ".join(update_parts)
            update_query += f" WHERE service_id = '{service_id}'"
            
            # Execute update query
            bq_client.query(update_query).result()
            
            return json.dumps({
                "success": True,
                "message": f"Service {service_id} updated successfully"
            }), 200, {'Content-Type': 'application/json'}
            
        elif action == 'delete_service':
            # Validate service_id
            if 'service_id' not in request_json:
                return json.dumps({"error": "Missing service_id"}), 400, {'Content-Type': 'application/json'}
            
            service_id = request_json['service_id']
            
            # Delete service configuration
            delete_query = f"""DELETE FROM `{project_id}.{dataset_id}.{service_config_table_id}`
                          WHERE service_id = '{service_id}'"""
            
            bq_client.query(delete_query).result()
            
            return json.dumps({
                "success": True,
                "message": f"Service {service_id} deleted successfully"
            }), 200, {'Content-Type': 'application/json'}
            
        elif action == 'list_services':
            # Query all service configurations
            query = f"""SELECT * FROM `{project_id}.{dataset_id}.{service_config_table_id}`"""
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
            
            return json.dumps({
                "success": True,
                "services": services
            }), 200, {'Content-Type': 'application/json'}
            
        else:
            return json.dumps({"error": f"Unknown action: {action}"}), 400, {'Content-Type': 'application/json'}
            
    except Exception as e:
        return json.dumps({"error": str(e)}), 500, {'Content-Type': 'application/json'}
