/**
 * # CostWise AI - Cloud Functions Module
 *
 * This module deploys the Cloud Functions for AI cost data collection and processing.
 */

# Create source code directories for Cloud Functions
resource "null_resource" "create_source_dirs" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/src/data_collection ${path.module}/src/data_transformation ${path.module}/src/admin"
  }
}

# Generate random suffix for function names
resource "random_id" "function_suffix" {
  byte_length = 4
}

# Archive source code for the data collection function
data "archive_file" "data_collection_source" {
  type        = "zip"
  source_dir  = "${path.module}/src/data_collection"
  output_path = "${path.module}/archives/data_collection_${random_id.function_suffix.hex}.zip"

  depends_on = [null_resource.create_source_dirs]
}

# Upload the data collection function source code
resource "google_storage_bucket_object" "data_collection_archive" {
  name   = "source/data_collection_${random_id.function_suffix.hex}.zip"
  bucket = var.function_source_bucket_name
  source = data.archive_file.data_collection_source.output_path
}

# Deploy the data collection Cloud Function
resource "google_cloudfunctions2_function" "data_collection" {
  name        = "costwise-ai-data-collection"
  location    = var.region
  description = "Collects usage and cost data from AI service APIs"

  build_config {
    runtime     = "python39"
    entry_point = "collect_data"  # Set the entry point 
    source {
      storage_source {
        bucket = var.function_source_bucket_name
        object = google_storage_bucket_object.data_collection_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 10
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      PROJECT_ID           = var.project_id
      DATASET_ID           = var.dataset_id
      COST_DATA_TABLE_ID   = var.cost_data_table_id
      SERVICE_CONFIG_TABLE_ID = var.service_config_table_id
    }
    service_account_email = var.service_account_email
  }
}

# Archive source code for the data transformation function
data "archive_file" "data_transformation_source" {
  type        = "zip"
  source_dir  = "${path.module}/src/data_transformation"
  output_path = "${path.module}/archives/data_transformation_${random_id.function_suffix.hex}.zip"

  depends_on = [null_resource.create_source_dirs]
}

# Upload the data transformation function source code
resource "google_storage_bucket_object" "data_transformation_archive" {
  name   = "source/data_transformation_${random_id.function_suffix.hex}.zip"
  bucket = var.function_source_bucket_name
  source = data.archive_file.data_transformation_source.output_path
}

# Deploy the data transformation Cloud Function
resource "google_cloudfunctions2_function" "data_transformation" {
  name        = "costwise-ai-data-transformation"
  location    = var.region
  description = "Transforms raw AI service data into unified format"

  build_config {
    runtime     = "python39"
    entry_point = "transform_data"  # Set the entry point
    source {
      storage_source {
        bucket = var.function_source_bucket_name
        object = google_storage_bucket_object.data_transformation_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 5
    available_memory   = "512M"
    timeout_seconds    = 120
    environment_variables = {
      PROJECT_ID           = var.project_id
      DATASET_ID           = var.dataset_id
      COST_DATA_TABLE_ID   = var.cost_data_table_id
      SERVICE_CONFIG_TABLE_ID = var.service_config_table_id
    }
    service_account_email = var.service_account_email
  }
}

# Archive source code for the admin function
data "archive_file" "admin_source" {
  type        = "zip"
  source_dir  = "${path.module}/src/admin"
  output_path = "${path.module}/archives/admin_${random_id.function_suffix.hex}.zip"

  depends_on = [null_resource.create_source_dirs]
}

# Upload the admin function source code
resource "google_storage_bucket_object" "admin_archive" {
  name   = "source/admin_${random_id.function_suffix.hex}.zip"
  bucket = var.function_source_bucket_name
  source = data.archive_file.admin_source.output_path
}

# Deploy the admin Cloud Function
resource "google_cloudfunctions2_function" "admin" {
  name        = "costwise-ai-admin"
  location    = var.region
  description = "Administrative function for managing service configurations"

  build_config {
    runtime     = "python39"
    entry_point = "admin_handler"  # Set the entry point
    source {
      storage_source {
        bucket = var.function_source_bucket_name
        object = google_storage_bucket_object.admin_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      PROJECT_ID           = var.project_id
      DATASET_ID           = var.dataset_id
      COST_DATA_TABLE_ID   = var.cost_data_table_id
      SERVICE_CONFIG_TABLE_ID = var.service_config_table_id
    }
    service_account_email = var.service_account_email
  }
}

# Create local directory for Cloud Function archives
resource "null_resource" "create_archives_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/archives"
  }
}

# Create function source files with sample code
resource "null_resource" "create_sample_code" {
  provisioner "local-exec" {
    command = <<EOT
    mkdir -p ${path.module}/src/data_collection ${path.module}/src/data_transformation ${path.module}/src/admin
    cat > ${path.module}/src/data_collection/main.py << 'EOF'
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
EOF

    cat > ${path.module}/src/data_collection/requirements.txt << 'EOF'
functions-framework==3.0.0
google-cloud-bigquery==2.34.4
google-cloud-secretmanager==2.12.4
requests==2.28.1
EOF

    cat > ${path.module}/src/data_transformation/main.py << 'EOF'
import functions_framework
import os
import json
from datetime import datetime
import google.cloud.bigquery as bigquery

@functions_framework.http
def transform_data(request):
    """HTTP Cloud Function to transform AI service data.
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
        cost_data_table_id = os.environ.get('COST_DATA_TABLE_ID')
        
        # Initialize BigQuery client
        bq_client = bigquery.Client(project=project_id)
        
        # Extract and validate request data
        request_json = request.get_json(silent=True)
        if not request_json or 'service_name' not in request_json:
            return json.dumps({"error": "Invalid request: missing service_name"}), 400, {'Content-Type': 'application/json'}
        
        service_name = request_json['service_name']
        raw_data = request_json.get('data', [])
        
        if not raw_data:
            return json.dumps({"error": "No data provided for transformation"}), 400, {'Content-Type': 'application/json'}
        
        # Transform data based on service type
        transformed_data = []
        
        for item in raw_data:
            # Apply common transformations
            transformed_item = {
                "timestamp": datetime.utcnow().isoformat(),
                "service_name": service_name,
                "model": item.get('model', 'unknown'),
                "feature": item.get('feature', 'chat'),
                "request_id": item.get('request_id', None),
                "input_tokens": item.get('input_tokens', 0),
                "output_tokens": item.get('output_tokens', 0),
                "total_tokens": item.get('input_tokens', 0) + item.get('output_tokens', 0),
                "input_cost": item.get('input_cost', 0.0),
                "output_cost": item.get('output_cost', 0.0),
                "cost": item.get('input_cost', 0.0) + item.get('output_cost', 0.0),
                "response_time_ms": item.get('response_time_ms', 0),
                "project": item.get('project', None),
                "user_id": item.get('user_id', None),
                "raw_response": json.dumps(item.get('raw_response', {})),
                "metadata": json.dumps(item.get('metadata', {}))
            }
            
            transformed_data.append(transformed_item)
        
        # Insert transformed data into BigQuery
        table_ref = bq_client.dataset(dataset_id).table(cost_data_table_id)
        errors = bq_client.insert_rows_json(table_ref, transformed_data)
        
        if errors:
            return json.dumps({"error": f"Error inserting rows: {errors}"}), 500, {'Content-Type': 'application/json'}
        
        return json.dumps({
            "success": True,
            "records_transformed": len(transformed_data),
            "service": service_name
        }), 200, {'Content-Type': 'application/json'}
        
    except Exception as e:
        return json.dumps({"error": str(e)}), 500, {'Content-Type': 'application/json'}
EOF

    cat > ${path.module}/src/data_transformation/requirements.txt << 'EOF'
functions-framework==3.0.0
google-cloud-bigquery==2.34.4
EOF

    cat > ${path.module}/src/admin/main.py << 'EOF'
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
EOF

    cat > ${path.module}/src/admin/requirements.txt << 'EOF'
functions-framework==3.0.0
google-cloud-bigquery==2.34.4
google-cloud-secretmanager==2.12.4
EOF
    EOT
  }

  depends_on = [null_resource.create_source_dirs]
}
