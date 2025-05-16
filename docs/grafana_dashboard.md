# Grafana Dashboard Setup for CostWise AI

This document provides detailed instructions on setting up and customizing Grafana dashboards for visualizing your AI cost data.

## Prerequisites

- A running Grafana instance (self-hosted or cloud-hosted)
- Network connectivity between Grafana and your Google Cloud Project
- Service account with BigQuery read permissions for your dataset
- Grafana BigQuery plugin installed and configured

## BigQuery Data Source Configuration

1. **Create a GCP Service Account**:
   ```bash
   gcloud iam service-accounts create grafana-reader \
     --display-name="Grafana Reader"
   ```

2. **Grant BigQuery Access**:
   ```bash
   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:grafana-reader@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/bigquery.dataViewer"

   gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
     --member="serviceAccount:grafana-reader@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/bigquery.jobUser"
   ```

3. **Create and Download Service Account Key**:
   ```bash
   gcloud iam service-accounts keys create grafana-reader-key.json \
     --iam-account=grafana-reader@YOUR_PROJECT_ID.iam.gserviceaccount.com
   ```

4. **Configure Grafana Data Source**:
   - In Grafana, navigate to Configuration > Data Sources > Add data source
   - Select "Google BigQuery"
   - Either:
     - Upload the service account JSON key file, or
     - If using GCE/GKE, use automatic authentication
   - Set the default project to your GCP project ID
   - Test and save the connection

## Dashboard Import

1. **Import the Dashboard**:
   - In Grafana, navigate to Dashboards > Import
   - Click "Upload JSON file" and select `cost_overview_dashboard.json` from the `grafana` directory
   - Alternatively, copy and paste the JSON content
   - Select your BigQuery data source in the dropdown
   - Click "Import"

2. **Configure Dashboard Variables**:
   - The dashboard has several variables you can adjust:
     - `project_id`: Your GCP project ID
     - `dataset_id`: Your BigQuery dataset ID (e.g., `costwise_dev_ai_cost_monitoring`)
     - `time_range`: Default time range for data display

## Dashboard Features

The dashboard includes the following panels:

### Overview Metrics (Last 30 Days)
- **Total AI Costs**: Sum of all AI service costs
- **Total Tokens Used**: Total input and output tokens
- **Total API Requests**: Count of all API calls

### Time-based Analysis
- **Daily Cost Trend**: Line chart showing costs over time
- **Daily Token Usage**: Line chart showing token usage over time
- **Cost by Day of Week**: Heatmap showing cost patterns by day of week

### Cost Breakdown
- **Cost by Service**: Pie chart of costs by AI service provider
- **Cost by Model**: Pie chart of costs by specific models
- **Cost by Project/Team**: Bar chart of costs by internal project or team

### Efficiency Metrics
- **Model Efficiency Table**: Comparison of cost per 1K tokens and average response times
- **Cost vs. Response Time**: Scatter plot comparing cost efficiency with performance

## Customization Options

### Adding New Panels

To add custom panels:

1. Click "Add panel" in the dashboard
2. Select the visualization type
3. Create a custom SQL query for your BigQuery data
4. Format and style as needed

Example SQL for cost by service:
```sql
SELECT 
  service_name,
  SUM(cost) as total_cost
FROM 
  `${project_id}.${dataset_id}.usage_costs`
WHERE
  timestamp BETWEEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY) AND CURRENT_TIMESTAMP()
GROUP BY 
  service_name
ORDER BY 
  total_cost DESC
```

### Setting Up Alerts

Configure alerts to monitor when costs exceed thresholds:

1. Edit the "Total AI Costs" panel
2. Go to "Alert" tab
3. Create a new alert rule 
4. Set conditions like "WHEN last() OF query(A, 1d, now) IS ABOVE 100"
5. Add notification channels (email, Slack, etc.)
6. Save the alert rule

## Advanced Configuration

### Automated Dashboard Deployment

For automated dashboard provisioning:

1. Use Grafana's provisioning feature by placing the dashboard JSON in the provisioning directory
2. For Kubernetes deployments, use ConfigMaps to mount the dashboard JSON
3. Consider using the Grafana Terraform provider for fully automated setup

Example Terraform for Grafana dashboard:
```hcl
provider "grafana" {
  url  = "https://your-grafana-instance.com"
  auth = "admin:password"  # Use environment variables in production
}

resource "grafana_dashboard" "costwise_ai" {
  config_json = file("${path.module}/grafana/cost_overview_dashboard.json")
  folder      = 0  # Default folder
  overwrite   = true
}
```

## Troubleshooting

Common issues and their solutions:

1. **"No data" error**:
   - Verify BigQuery service account has correct permissions
   - Check that the dataset and table names match in queries
   - Ensure time range includes data collection period

2. **Slow dashboard loading**:
   - Consider using materialized views in BigQuery
   - Adjust time range to query less data
   - Optimize SQL queries to use partitioning where possible

3. **Authentication errors**:
   - Verify service account key is valid and not expired
   - Check network connectivity between Grafana and GCP
   - Review IAM permissions for the service account

## Additional Resources

- [Grafana BigQuery Documentation](https://grafana.com/docs/grafana/latest/datasources/google-bigquery/)
- [BigQuery Performance Optimization](https://cloud.google.com/bigquery/docs/best-practices-performance-overview)
- [Grafana Dashboard Variables](https://grafana.com/docs/grafana/latest/variables/)