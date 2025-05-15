#!/bin/bash
# CostWise AI Environment Initialization Script

set -e

# Default values
ENV="dev"
TFVARS_SOURCE="terraform.tfvars.example"
BACKEND_SOURCE="backend.hcl.example"

# Display usage information
function show_usage {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -e, --environment ENV    Environment to initialize (dev, staging, prod). Default: dev"
  echo "  -t, --tfvars FILE        Source terraform.tfvars file to use. Default: terraform.tfvars.example"
  echo "  -b, --backend FILE       Source backend.hcl file to use. Default: backend.hcl.example"
  echo "  -h, --help               Show this help message"
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--environment)
      ENV="$2"
      shift 2
      ;;
    -t|--tfvars)
      TFVARS_SOURCE="$2"
      shift 2
      ;;
    -b|--backend)
      BACKEND_SOURCE="$2"
      shift 2
      ;;
    -h|--help)
      show_usage
      ;;
    *)
      echo "Unknown option: $1"
      show_usage
      ;;
  esac
done

# Validate environment
if [[ "$ENV" != "dev" && "$ENV" != "staging" && "$ENV" != "prod" ]]; then
  echo "Error: Environment must be one of: dev, staging, prod"
  exit 1
fi

# Set environment directory
ENV_DIR="terraform/environments/$ENV"

# Check if environment directory exists
if [[ ! -d "$ENV_DIR" ]]; then
  echo "Error: Environment directory $ENV_DIR does not exist"
  exit 1
fi

# Check if source files exist
if [[ ! -f "$ENV_DIR/$TFVARS_SOURCE" ]]; then
  echo "Error: Source tfvars file $ENV_DIR/$TFVARS_SOURCE does not exist"
  exit 1
fi

if [[ ! -f "$ENV_DIR/$BACKEND_SOURCE" ]]; then
  echo "Error: Source backend file $ENV_DIR/$BACKEND_SOURCE does not exist"
  exit 1
fi

# Create terraform.tfvars if it doesn't exist
if [[ ! -f "$ENV_DIR/terraform.tfvars" ]]; then
  echo "Creating terraform.tfvars from $TFVARS_SOURCE..."
  cp "$ENV_DIR/$TFVARS_SOURCE" "$ENV_DIR/terraform.tfvars"
  echo "Created $ENV_DIR/terraform.tfvars"
  echo "IMPORTANT: Edit this file to fill in your project-specific values!"
else
  echo "File $ENV_DIR/terraform.tfvars already exists, skipping..."
fi

# Create backend.hcl if it doesn't exist
if [[ ! -f "$ENV_DIR/backend.hcl" ]]; then
  echo "Creating backend.hcl from $BACKEND_SOURCE..."
  cp "$ENV_DIR/$BACKEND_SOURCE" "$ENV_DIR/backend.hcl"
  echo "Created $ENV_DIR/backend.hcl"
  echo "IMPORTANT: Edit this file to fill in your bucket details!"
else
  echo "File $ENV_DIR/backend.hcl already exists, skipping..."
fi

echo "Environment $ENV initialized successfully!"
echo ""
echo "Next steps:"
echo "1. Edit $ENV_DIR/terraform.tfvars to customize your deployment"
echo "2. Edit $ENV_DIR/backend.hcl with your GCS bucket details"
echo "3. Initialize Terraform with: cd $ENV_DIR && terraform init -backend-config=backend.hcl"
echo "4. Apply your configuration with: terraform apply"
echo ""
echo "For CI/CD pipelines, make sure to provide these files securely as part of your pipeline."