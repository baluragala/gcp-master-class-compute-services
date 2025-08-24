# High Availability Web Infrastructure on GCP

This project creates a highly available web infrastructure on Google Cloud Platform using Terraform, featuring load balancing, auto-scaling, and fault tolerance.

## 🏗️ Architecture Overview

The infrastructure consists of the following components:

```
Internet
    ↓
[Global Load Balancer] ← Static IP Address
    ↓
[Backend Service] ← Health Checks
    ↓
[Managed Instance Group]
    ↓
[Instance Template] → [VM Instance 1] [VM Instance 2]
    ↓                      ↓              ↓
[Custom VPC Network] → [Subnet] ← [Firewall Rules]
```

### 📊 Detailed Architecture Diagrams

For comprehensive visual documentation of the infrastructure, see the interactive diagrams in the [`diagrams/`](./diagrams/) directory:

- **[Architecture Overview](./diagrams/architecture-overview.mmd)** - Complete infrastructure flowchart showing all components and relationships
- **[Request Flow Sequence](./diagrams/request-flow-sequence.mmd)** - Step-by-step request processing and load balancing flow

These Mermaid diagrams can be viewed directly on GitHub or rendered using tools like [mermaid.live](https://mermaid.live).

### Key Components

1. **VPC Network & Subnet**: Custom network with controlled IP ranges
2. **Firewall Rules**: Security rules for HTTP, HTTPS, and SSH traffic
3. **Instance Template**: Defines VM configuration with nginx and custom HTML
4. **Managed Instance Group**: Auto-scaling group managing 2 VM instances
5. **Health Checks**: Monitors instance health for automatic failover
6. **Backend Service**: Manages traffic distribution to healthy instances
7. **HTTP Load Balancer**: Global load balancer with static IP
8. **Service Account**: IAM service account for instance permissions

## 🚀 Features

- **High Availability**: Multi-zone deployment with automatic failover
- **Auto-scaling**: Managed instance group with configurable scaling policies
- **Load Balancing**: Global HTTP load balancer distributing traffic
- **Health Monitoring**: Automatic health checks and instance replacement
- **Custom Web Pages**: Each instance serves unique content showing server info
- **Security**: VPC with firewall rules and service account permissions
- **Monitoring**: Load balancer access logs and health check logging

## 📋 Prerequisites

1. **Google Cloud Platform Account**: Active GCP account with billing enabled
2. **GCP Project**: A GCP project with the following APIs enabled:
   - Compute Engine API
   - Cloud Resource Manager API
3. **Terraform**: Version >= 1.0 installed locally
4. **gcloud CLI**: Installed and authenticated
5. **Permissions**: Your account needs the following IAM roles:
   - Compute Admin
   - Service Account Admin
   - Project IAM Admin

## 🛠️ Setup Instructions

### 1. Clone and Configure

```bash
# Navigate to the project directory
cd /Users/balakrishna/Training/cloud/gcp/gcp-master-class-compute-services

# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your project details
nano terraform.tfvars
```

### 2. Configure Variables

Update `terraform.tfvars` with your values:

```hcl
project_id   = "your-gcp-project-id"
region       = "us-central1"
zone         = "us-central1-a"
machine_type = "e2-micro"
environment  = "dev"
```

### 3. Authenticate with GCP

```bash
# Authenticate with gcloud
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

### 5. Access Your Application

After deployment, Terraform will output the load balancer IP address:

```bash
# Get the load balancer URL
terraform output load_balancer_url

# Test the application
curl $(terraform output -raw load_balancer_url)
```

## 🔧 Configuration Details

### Instance Template Configuration

- **Base Image**: Ubuntu 22.04 LTS
- **Machine Type**: e2-micro (configurable)
- **Disk**: 20GB persistent disk
- **Network**: Custom VPC with public IP
- **Startup Script**: Installs nginx and creates custom HTML

### Load Balancer Configuration

- **Type**: Global HTTP Load Balancer
- **Protocol**: HTTP (port 80)
- **Backend**: Managed instance group
- **Health Check**: HTTP health check on port 80
- **Static IP**: Reserved external IP address

### Security Configuration

- **Firewall Rules**:
  - HTTP (port 80): Open to internet
  - HTTPS (port 443): Open to internet
  - SSH (port 22): Open to internet (restrict in production)
- **Service Account**: Custom service account with minimal permissions
- **Network**: Private subnet with controlled access

## 📊 Monitoring and Logging

### Health Checks

- **Check Interval**: 10 seconds
- **Timeout**: 5 seconds
- **Healthy Threshold**: 2 consecutive successes
- **Unhealthy Threshold**: 3 consecutive failures

### Load Balancer Logs

- **Access Logs**: Enabled with 100% sampling rate
- **Log Location**: Cloud Logging under "GCE Load Balancer"

### Instance Monitoring

- **Startup Logs**: Available in `/var/log/startup-script.log`
- **Nginx Logs**: Standard nginx access and error logs
- **Health Status**: Visible in GCP Console under Load Balancing

## 🔄 Scaling and Updates

### Manual Scaling

```bash
# Scale the instance group
gcloud compute instance-groups managed resize web-instance-group \
    --size=4 --region=us-central1
```

### Rolling Updates

```bash
# Update instance template and perform rolling update
terraform apply
```

### Auto-healing

- Instances are automatically replaced if they fail health checks
- Initial delay: 300 seconds after instance creation
- Replacement strategy: Proactive with zero downtime

## 🧪 Testing High Availability

### Test Load Balancing

```bash
# Make multiple requests to see different servers
for i in {1..10}; do
  curl -s $(terraform output -raw load_balancer_url) | grep "Server:"
done
```

### Test Failover

1. Stop an instance in the GCP Console
2. Watch the instance group automatically replace it
3. Verify traffic continues to flow to healthy instances

### Test Health Checks

```bash
# Check health check status
gcloud compute backend-services get-health web-backend-service \
    --global
```

## 🗂️ File Structure

```
.
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── startup-script.sh          # VM initialization script
├── terraform.tfvars.example   # Example variables file
├── terraform.tfvars          # Your variables (create from example)
├── deploy.sh                 # Automated deployment script
├── README.md                 # This documentation
├── ARCHITECTURE.md           # Detailed technical architecture
├── PLAN.md                   # Original project plan
├── .gitignore               # Git ignore rules for Terraform files
└── diagrams/                # Architecture diagrams
    ├── README.md            # Diagram documentation
    ├── architecture-overview.mmd    # Infrastructure flowchart
    └── request-flow-sequence.mmd    # Request processing sequence
```

## 🔧 Customization Options

### Machine Types

- `e2-micro`: 1 vCPU, 1GB RAM (free tier eligible)
- `e2-small`: 1 vCPU, 2GB RAM
- `e2-medium`: 1 vCPU, 4GB RAM
- `n1-standard-1`: 1 vCPU, 3.75GB RAM

### Regions and Zones

- Update `region` and `zone` variables
- Ensure zone is within the selected region
- Consider latency to your users

### Instance Count

- Modify `target_size` in the instance group manager
- Minimum recommended: 2 instances for HA
- Maximum depends on quotas and requirements

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources created by this configuration.

## 💰 Cost Considerations

### Estimated Monthly Costs (us-central1)

- **2x e2-micro instances**: ~$12-15/month
- **Load Balancer**: ~$18/month
- **Static IP**: ~$3/month
- **Network egress**: Variable based on traffic
- **Total**: ~$35-40/month

### Cost Optimization Tips

1. Use preemptible instances for non-production
2. Implement auto-scaling based on CPU utilization
3. Use committed use discounts for predictable workloads
4. Monitor and optimize network egress

## 🔍 Troubleshooting

### Common Issues

1. **Permission Denied**

   - Ensure your account has required IAM roles
   - Check that APIs are enabled

2. **Quota Exceeded**

   - Check GCP quotas in the console
   - Request quota increases if needed

3. **Health Check Failures**

   - Verify nginx is running on instances
   - Check firewall rules allow port 80
   - Review startup script logs

4. **Load Balancer Not Accessible**
   - Wait 5-10 minutes for propagation
   - Check backend service health
   - Verify DNS resolution

### Debugging Commands

```bash
# Check instance group status
gcloud compute instance-groups managed describe web-instance-group \
    --region=us-central1

# View instance logs
gcloud compute instances get-serial-port-output INSTANCE_NAME \
    --zone=us-central1-a

# Check load balancer backend health
gcloud compute backend-services get-health web-backend-service \
    --global
```

## 📚 Additional Resources

- [GCP Load Balancing Documentation](https://cloud.google.com/load-balancing/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Instance Groups](https://cloud.google.com/compute/docs/instance-groups)
- [GCP Health Checks](https://cloud.google.com/load-balancing/docs/health-checks)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
