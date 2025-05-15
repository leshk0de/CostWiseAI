import functions_framework
import os
import json
import importlib
from datetime import datetime
import google.cloud.bigquery as bigquery
import google.cloud.secretmanager as secretmanager

@functions_framework.http
def collect_data(request):
    """HTTP Cloud Function to collect data from AI service APIs.
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
        cost_data_table_id = os.environ.get('COST_DATA_TABLE_ID')
        
        # Initialize clients
        bq_client = bigquery.Client(project=project_id)
        sm_client = secretmanager.SecretManagerServiceClient()
        
        # Query service configurations from BigQuery
        query = f"""SELECT * FROM `{project_id}.{dataset_id}.{service_config_table_id}`
                  WHERE active = TRUE"""
        service_configs = list(bq_client.query(query).result())
        
        results = []
        for service_config in service_configs:
            # Import the appropriate service adapter module dynamically
            try:
                adapter_module_name = service_config['adapter_module']
                adapter_module = importlib.import_module(f"adapters.{adapter_module_name}")
                adapter_class = getattr(adapter_module, "ServiceAdapter")
                
                # Get API credentials from Secret Manager
                secret_name = service_config['secret_name']
                secret_path = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
                response = sm_client.access_secret_version(name=secret_path)
                api_key = response.payload.data.decode('UTF-8')
                
                # Initialize the service adapter
                adapter = adapter_class(
                    api_key=api_key,
                    api_base_url=service_config['api_base_url'],
                    models=service_config['models']
                )
                
                # Collect data using the adapter
                service_data = adapter.collect_data(
                    endpoint=service_config['data_collection_endpoint'],
                    additional_config=service_config.get('additional_config', {})
                )
                
                # Transform data to standard format
                for item in service_data:
                    item['service_name'] = service_config['service_name']
                    item['timestamp'] = datetime.utcnow().isoformat()
                
                # Insert data into BigQuery
                table_ref = bq_client.dataset(dataset_id).table(cost_data_table_id)
                errors = bq_client.insert_rows_json(table_ref, service_data)
                
                if errors:
                    raise Exception(f"Error inserting rows for {service_config['service_name']}: {errors}")
                
                results.append({
                    "service": service_config['service_name'],
                    "records_collected": len(service_data),
                    "status": "success"
                })
                
            except Exception as e:
                results.append({
                    "service": service_config['service_name'],
                    "status": "error",
                    "error": str(e)
                })
        
        return json.dumps({"results": results}), 200, {'Content-Type': 'application/json'}
        
    except Exception as e:
        return json.dumps({"error": str(e)}), 500, {'Content-Type': 'application/json'}
