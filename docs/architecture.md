# CostWise AI - Architecture Documentation

This document describes the architecture of the CostWise AI system, including component interactions, data flows, and security model.

## System Overview

CostWise AI is built on Google Cloud Platform (GCP) using a serverless, event-driven architecture. The system collects usage and cost data from various AI service APIs, transforms it into a standardized format, stores it in BigQuery, and visualizes it through Grafana dashboards.

## Architecture Diagram

![CostWise AI Architecture](images/architecture.png)

## Core Components

### 1. Cloud Functions

The system employs three main Cloud Functions Gen 2:

#### Data Collection Function

- **Purpose**: Collects usage and cost data from AI service APIs
- **Trigger**: Cloud Scheduler (time-based)
- **Operation**:
  1. Retrieves service configurations from BigQuery
  2. For each active service, loads the appropriate service adapter
  3. Retrieves API credentials from Secret Manager
  4. Calls the service's usage API to collect data
  5. Inserts the standardized data into BigQuery

#### Data Transformation Function

- **Purpose**: Transforms raw service data into a standardized format
- **Trigger**: HTTP requests (typically from the Data Collection function)
- **Operation**:
  1. Receives service-specific data in the request
  2. Applies standardized transformations
  3. Calculates costs based on model pricing
  4. Inserts the transformed data into BigQuery

#### Admin Function

- **Purpose**: Manages service configurations
- **Trigger**: HTTP requests (manual or from admin tools)
- **Operation**:
  1. Handles CRUD operations for service configurations
  2. Validates configurations before storage
  3. Updates service information in BigQuery

### 2. BigQuery Data Warehouse

The system uses BigQuery for data storage and analysis:

#### Cost Data Table

- Stores all usage and cost data
- Partitioned by day on the timestamp field
- Clustered by service_name and model for efficient queries

#### Service Config Table

- Stores configuration information for each AI service
- Contains API endpoints, adapter modules, and pricing information

#### Views

- **Cost Summary View**: Daily aggregated costs by service and model
- **Model Comparison View**: Efficiency metrics for different models

### 3. Secret Manager

- Securely stores API credentials for each AI service
- Provides access control through IAM

### 4. Cloud Scheduler

- Triggers the data collection function on a regular schedule
- Configurable frequency (default: every 6 hours)

### 5. Service Adapters

- Implements the adapter pattern for service-specific integrations
- Each adapter handles the unique aspects of a service's API
- Factory pattern allows easy registration of new adapters

## Data Flow

1. **Collection Process**:
   - Scheduler triggers the Data Collection function
   - Function queries service configurations
   - For each service, the appropriate adapter is loaded
   - Adapter collects data from the service's API
   - Collected data is inserted into BigQuery

2. **Transformation Process**:
   - Raw data is transformed into a standardized format
   - Service-specific fields are mapped to common fields
   - Costs are calculated based on model pricing

3. **Analysis Process**:
   - BigQuery views provide common analysis patterns
   - Grafana dashboards visualize the cost data
   - Ad-hoc queries can be run for custom analysis

## Authentication and Security

### Service Account

- A dedicated service account runs all Cloud Functions
- Follows the principle of least privilege
- Has specific roles for BigQuery, Secret Manager, etc.

### Secret Management

- API keys are stored in Secret Manager
- Each service's credentials are stored in a separate secret
- Service account has access only to the necessary secrets

### Network Security

- Cloud Functions are configured with VPC Connector (optional)
- Egress can be restricted to only allowed API domains
- All internal communication uses HTTPS

## Extensibility

The system is designed for easy extension:

### Adding New Services

1. Create a new adapter class that implements the base interface
2. Register the adapter with the factory
3. Add the service configuration through the admin function

### Changing Data Models

1. Update the schema in the BigQuery module
2. Add any new fields to the standardized format
3. Update adapters to populate the new fields

### Scaling

- BigQuery automatically scales with data volume
- Cloud Functions automatically scale with request load
- Partitioning and clustering optimize query performance

## Dependency Diagram

```
Data Collection Function
├── BigQuery Client
├── Secret Manager Client
├── Service Adapters
│   ├── Claude Adapter
│   ├── OpenAI Adapter
│   ├── Perplexity Adapter
│   └── [Additional Adapters]
└── Adapter Factory

Data Transformation Function
└── BigQuery Client

Admin Function
├── BigQuery Client
└── Secret Manager Client
```

## System Interactions

1. **User → Admin Function**: Configure services and view status
2. **Scheduler → Data Collection Function**: Trigger data collection
3. **Data Collection Function → Secret Manager**: Retrieve API keys
4. **Data Collection Function → AI Service APIs**: Collect usage data
5. **Data Collection Function → BigQuery**: Store collected data
6. **Grafana → BigQuery**: Query cost data for visualization

## Disaster Recovery

- **Data**: BigQuery provides automatic replication
- **Configuration**: All resources are defined as Terraform code
- **Credentials**: Secret Manager handles replication of secrets

## Security Model

### Identity and Access Management

- Service account has the minimum required permissions
- API keys are only accessible to the data collection function
- BigQuery data can be restricted with column-level security

### Data Protection

- All data is encrypted at rest and in transit
- PII data can be excluded from collection or pseudonymized
- Raw responses can be optionally truncated

### Audit Trail

- Cloud Audit Logs track all access to secrets and data
- Admin function logs all configuration changes
- BigQuery logs all query activity

## Monitoring and Alerting

- Cloud Monitoring tracks function execution
- Error reporting captures and aggregates errors
- Custom metrics track data collection success rates
- Alerts can be set for cost anomalies and failures

## Development and Deployment

- Infrastructure defined as Terraform code
- CI/CD pipeline for automated deployment
- Development and production environments isolated

## Design Decisions and Trade-offs

### Serverless Architecture

- **Pros**: No infrastructure management, auto-scaling, pay-per-use
- **Cons**: Cold starts, timeout limitations, potential higher costs at large scale

### BigQuery for Storage

- **Pros**: Highly scalable, optimized for analytics, serverless
- **Cons**: Higher cost per GB than raw storage, more complex than simple databases

### Service Adapter Pattern

- **Pros**: Standardized interface, extensible, encapsulates service specifics
- **Cons**: Additional code complexity, potential duplication

### Scheduled Collection vs. Webhooks

- **Pros**: Simpler architecture, works with any service API
- **Cons**: Not real-time, potential for missed data if collection fails

## Performance Considerations

- **Query Optimization**: Tables are partitioned and clustered
- **Cost Efficiency**: Only active services are queried
- **Rate Limiting**: Adapters implement exponential backoff
- **Scalability**: Cloud Functions automatically scale to handle load