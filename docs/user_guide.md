# CostWise AI - User Guide

This guide explains how to use the CostWise AI system for monitoring and analyzing your AI service costs.

## Overview

CostWise AI provides comprehensive cost monitoring for multiple AI services (Claude, ChatGPT, Perplexity, etc.). It collects usage data from each service's API, transforms it into a standardized format, and makes it available for analysis and visualization.

## Accessing the Dashboard

The primary interface for CostWise AI is the Grafana dashboard:

1. Open your Grafana instance (the URL will be provided by your administrator)
2. Log in with your credentials
3. Navigate to the "CostWise AI - Cost Overview" dashboard

## Dashboard Sections

### Cost Overview

![Cost Overview](images/dashboard_overview.png)

The top row of the dashboard shows:

- **Total AI Costs**: The total cost across all services for the selected time period
- **Total Tokens**: The number of tokens consumed across all services
- **Total API Requests**: The number of requests made to all services

### Cost Trends

![Cost Trends](images/dashboard_trends.png)

The cost trends graph shows:

- Daily costs broken down by service
- Trends in usage over time
- Patterns in spending across different services

Hover over any point to see detailed information for that day.

### Cost Distribution

![Cost Distribution](images/dashboard_distribution.png)

The pie charts show:

- **Costs by Service**: Proportion of spending across different AI providers
- **Costs by Model**: Breakdown of costs by specific AI models

This helps identify which services and models are driving your costs.

### Model Efficiency

![Model Efficiency](images/dashboard_efficiency.png)

The model efficiency table shows:

- **Cost per 1K Tokens**: Efficiency metric for each model
- **Response Time**: Average response time in milliseconds
- **Total Costs and Tokens**: Usage metrics for each model

This helps identify the most cost-effective models for your use cases.

### Project Attribution

![Project Attribution](images/dashboard_projects.png)

The project attribution chart shows:

- Costs broken down by project or team
- Service usage within each project
- Relative spending across different projects

## Analyzing Costs

### Filtering Data

You can filter the dashboard data using:

1. **Time Range Selector**: Change the time period at the top right
2. **Variables**: Use the dropdown selectors at the top of the dashboard
3. **Panel Filters**: Click on legends to hide/show specific data series

### Identifying Cost Drivers

To identify what's driving your AI costs:

1. Check the "Costs by Service" pie chart to see which services cost the most
2. Look at the "Costs by Model" breakdown to identify expensive models
3. Use the "Model Efficiency" table to find models with high cost per token
4. Review the "Project Attribution" chart to see which teams are spending the most

### Spotting Trends and Anomalies

To identify trends and anomalies:

1. Use the "Daily Costs by Service" graph to spot unusual spikes
2. Compare weekday vs. weekend usage patterns
3. Look for sudden changes in the cost trend lines
4. Check for unusual increases in specific models or services

## Managing Services

### Viewing Configured Services

To see all configured services:

1. Use the admin API endpoint:
```bash
curl -X POST https://your-admin-function-url \
     -H "Content-Type: application/json" \
     -d '{"action": "list_services"}'
```

2. The response will show all configured services and their details

### Adding a New Service

To add a new service (admin users only):

1. Ensure you have the API key for the service
2. Store the API key in Secret Manager
3. Configure the service using the admin API:
```bash
curl -X POST https://your-admin-function-url \
     -H "Content-Type: application/json" \
     -d '{
           "action": "add_service",
           "service_name": "ServiceName",
           "service_id": "service-id",
           "api_type": "REST",
           "api_base_url": "https://api.example.com/v1",
           "data_collection_endpoint": "usage",
           "secret_name": "costwise-ai-servicename-api-key",
           "models": {
             "model-name-1": {
               "input_price_per_1k": 5.0,
               "output_price_per_1k": 15.0
             }
           },
           "adapter_module": "service_adapter"
         }'
```

### Updating a Service

To update an existing service (admin users only):

```bash
curl -X POST https://your-admin-function-url \
     -H "Content-Type: application/json" \
     -d '{
           "action": "update_service",
           "service_id": "service-id",
           "models": {
             "model-name-1": {
               "input_price_per_1k": 6.0,
               "output_price_per_1k": 16.0
             }
           }
         }'
```

### Disabling a Service

To temporarily disable a service:

```bash
curl -X POST https://your-admin-function-url \
     -H "Content-Type: application/json" \
     -d '{
           "action": "update_service",
           "service_id": "service-id",
           "active": false
         }'
```

## Using the Data for Cost Optimization

### 1. Model Selection

Use the "Model Efficiency" table to:
- Identify the most cost-effective models for your use cases
- Compare response times versus costs
- See which models provide the best value

### 2. Project Analysis

Use the "Project Attribution" chart to:
- Identify high-spending projects or teams
- Track project spending over time
- Set budgets and monitor compliance

### 3. Usage Patterns

Look for usage patterns to optimize:
- Time-of-day patterns: Are there peak usage times?
- Weekend vs. weekday: Is there unnecessary usage during off-hours?
- Spikes: Are there sudden increases that might indicate inefficient use?

### 4. Custom Queries

For advanced analysis, you can query the BigQuery dataset directly:

1. Open the Google Cloud Console
2. Navigate to BigQuery
3. Query the dataset (typically `ai_cost_monitoring` or `ai_cost_monitoring_dev`)

Example queries:

```sql
-- Find the most expensive requests in the last 7 days
SELECT
  timestamp,
  service_name,
  model,
  feature,
  input_tokens,
  output_tokens,
  cost
FROM
  `your-project.ai_cost_monitoring.usage_costs`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
ORDER BY
  cost DESC
LIMIT 100;

-- Compare cost efficiency by time of day
SELECT
  EXTRACT(HOUR FROM timestamp) as hour_of_day,
  AVG(cost / total_tokens * 1000) as avg_cost_per_1k_tokens,
  COUNT(*) as request_count
FROM
  `your-project.ai_cost_monitoring.usage_costs`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY
  hour_of_day
ORDER BY
  hour_of_day;
```

## Setting Up Alerts

You can set up alerts in Grafana to notify you of:
- Cost thresholds being exceeded
- Unusual spikes in usage
- Service failures or data collection issues

To create an alert:
1. Hover over the panel you want to alert on
2. Click the panel title and select "Edit"
3. Go to the "Alert" tab
4. Configure alert conditions and notifications

## Getting Help

If you encounter issues or have questions:

1. Check the logs in Google Cloud Console:
   - Cloud Functions logs for service issues
   - BigQuery logs for data issues
   - Cloud Scheduler logs for scheduling issues

2. Contact your system administrator for assistance

3. Refer to the documentation in the docs directory of the repository