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
