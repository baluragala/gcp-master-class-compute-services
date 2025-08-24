#!/bin/bash

# High Availability Web Infrastructure Deployment Script
# This script automates the deployment of the GCP infrastructure

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install Terraform >= 1.0"
        exit 1
    fi
    
    # Check terraform version
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    print_status "Terraform version: $TERRAFORM_VERSION"
    
    # Check if gcloud is installed
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install Google Cloud SDK"
        exit 1
    fi
    
    # Check if jq is installed
    if ! command_exists jq; then
        print_warning "jq is not installed. Some features may not work properly"
    fi
    
    print_success "Prerequisites check completed"
}

# Function to check GCP authentication
check_gcp_auth() {
    print_status "Checking GCP authentication..."
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 > /dev/null; then
        print_error "No active GCP authentication found. Please run 'gcloud auth login'"
        exit 1
    fi
    
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1)
    print_success "Authenticated as: $ACTIVE_ACCOUNT"
}

# Function to check if terraform.tfvars exists
check_terraform_vars() {
    print_status "Checking Terraform variables..."
    
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        if [ -f "terraform.tfvars.example" ]; then
            cp terraform.tfvars.example terraform.tfvars
            print_warning "Please edit terraform.tfvars with your project details before continuing"
            print_warning "Required: Update project_id in terraform.tfvars"
            read -p "Press Enter after updating terraform.tfvars to continue..."
        else
            print_error "terraform.tfvars.example not found"
            exit 1
        fi
    fi
    
    # Check if project_id is set
    if grep -q "your-gcp-project-id" terraform.tfvars; then
        print_error "Please update project_id in terraform.tfvars with your actual GCP project ID"
        exit 1
    fi
    
    print_success "Terraform variables configured"
}

# Function to enable required APIs
enable_apis() {
    print_status "Enabling required GCP APIs..."
    
    # Get project ID from terraform.tfvars
    PROJECT_ID=$(grep '^project_id' terraform.tfvars | cut -d'"' -f2)
    
    if [ -z "$PROJECT_ID" ]; then
        print_error "Could not extract project_id from terraform.tfvars"
        exit 1
    fi
    
    print_status "Using project: $PROJECT_ID"
    gcloud config set project "$PROJECT_ID"
    
    # Enable required APIs
    APIS=(
        "compute.googleapis.com"
        "cloudresourcemanager.googleapis.com"
        "iam.googleapis.com"
    )
    
    for api in "${APIS[@]}"; do
        print_status "Enabling $api..."
        gcloud services enable "$api"
    done
    
    print_success "Required APIs enabled"
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    terraform init
    
    if [ $? -eq 0 ]; then
        print_success "Terraform initialized successfully"
    else
        print_error "Terraform initialization failed"
        exit 1
    fi
}

# Function to validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    terraform validate
    
    if [ $? -eq 0 ]; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform configuration validation failed"
        exit 1
    fi
}

# Function to plan Terraform deployment
plan_terraform() {
    print_status "Creating Terraform execution plan..."
    
    terraform plan -out=tfplan
    
    if [ $? -eq 0 ]; then
        print_success "Terraform plan created successfully"
        print_status "Plan saved to tfplan file"
    else
        print_error "Terraform planning failed"
        exit 1
    fi
}

# Function to apply Terraform configuration
apply_terraform() {
    print_status "Applying Terraform configuration..."
    
    terraform apply tfplan
    
    if [ $? -eq 0 ]; then
        print_success "Infrastructure deployed successfully!"
    else
        print_error "Terraform apply failed"
        exit 1
    fi
}

# Function to display outputs
show_outputs() {
    print_status "Deployment completed! Here are the details:"
    echo
    
    LOAD_BALANCER_IP=$(terraform output -raw load_balancer_ip 2>/dev/null || echo "Not available")
    LOAD_BALANCER_URL=$(terraform output -raw load_balancer_url 2>/dev/null || echo "Not available")
    
    echo "🌐 Load Balancer IP: $LOAD_BALANCER_IP"
    echo "🔗 Load Balancer URL: $LOAD_BALANCER_URL"
    echo
    
    print_status "Testing the deployment..."
    if [ "$LOAD_BALANCER_URL" != "Not available" ]; then
        echo "⏳ Waiting for load balancer to be ready (this may take 5-10 minutes)..."
        sleep 30
        
        # Test the endpoint
        if command_exists curl; then
            print_status "Testing HTTP endpoint..."
            if curl -s --connect-timeout 10 "$LOAD_BALANCER_URL" > /dev/null; then
                print_success "✅ Load balancer is responding!"
                echo "🎉 You can now access your application at: $LOAD_BALANCER_URL"
            else
                print_warning "⚠️  Load balancer is not responding yet. It may take a few more minutes."
                echo "💡 Try accessing $LOAD_BALANCER_URL in a few minutes."
            fi
        fi
    fi
    
    echo
    print_status "Next steps:"
    echo "1. Wait 5-10 minutes for full propagation"
    echo "2. Access your application at the URL above"
    echo "3. Refresh the page multiple times to see load balancing in action"
    echo "4. Check the GCP Console for monitoring and logs"
    echo
    print_status "To destroy the infrastructure later, run: terraform destroy"
}

# Function to cleanup on error
cleanup_on_error() {
    print_error "Deployment failed. Cleaning up..."
    if [ -f "tfplan" ]; then
        rm tfplan
        print_status "Removed tfplan file"
    fi
}

# Main deployment function
main() {
    echo "🚀 High Availability Web Infrastructure Deployment"
    echo "=================================================="
    echo
    
    # Set trap for cleanup on error
    trap cleanup_on_error ERR
    
    # Run all checks and deployment steps
    check_prerequisites
    check_gcp_auth
    check_terraform_vars
    enable_apis
    init_terraform
    validate_terraform
    
    # Ask for confirmation before applying
    echo
    print_warning "Ready to deploy infrastructure. This will create resources in GCP."
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        plan_terraform
        apply_terraform
        show_outputs
    else
        print_status "Deployment cancelled by user"
        exit 0
    fi
    
    # Remove trap
    trap - ERR
    
    print_success "🎉 Deployment completed successfully!"
}

# Run main function
main "$@"
