# Infrastructure Architecture Documentation

## 🏛️ High-Level Architecture

This document provides detailed technical documentation of the high-availability web infrastructure deployed on Google Cloud Platform.

## 📐 Architecture Diagram

```
                                    Internet Users
                                          │
                                          ▼
                              ┌─────────────────────┐
                              │   Global Load       │
                              │   Balancer          │
                              │   (Static IP)       │
                              └─────────┬───────────┘
                                        │
                              ┌─────────▼───────────┐
                              │   HTTP Target       │
                              │   Proxy             │
                              └─────────┬───────────┘
                                        │
                              ┌─────────▼───────────┐
                              │   URL Map           │
                              │   (Routing Rules)   │
                              └─────────┬───────────┘
                                        │
                              ┌─────────▼───────────┐
                              │   Backend Service   │
                              │   (Load Balancing)  │
                              └─────────┬───────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
          ┌─────────▼─────────┐ ┌─────────▼─────────┐ ┌─────────▼─────────┐
          │   Health Check    │ │   Health Check    │ │   Health Check    │
          │   Instance 1      │ │   Instance 2      │ │   Instance N      │
          │   (us-central1-a) │ │   (us-central1-b) │ │   (us-central1-c) │
          └─────────┬─────────┘ └─────────┬─────────┘ └─────────┬─────────┘
                    │                     │                     │
          ┌─────────▼─────────┐ ┌─────────▼─────────┐ ┌─────────▼─────────┐
          │   VM Instance 1   │ │   VM Instance 2   │ │   VM Instance N   │
          │   nginx + HTML    │ │   nginx + HTML    │ │   nginx + HTML    │
          └─────────┬─────────┘ └─────────┬─────────┘ └─────────┬─────────┘
                    │                     │                     │
                    └─────────┬───────────┼───────────┬─────────┘
                              │           │           │
                    ┌─────────▼───────────▼───────────▼─────────┐
                    │           VPC Network                     │
                    │           (ha-web-vpc)                    │
                    │                                           │
                    │  ┌─────────────────────────────────────┐  │
                    │  │        Subnet                       │  │
                    │  │        (10.0.1.0/24)               │  │
                    │  │        us-central1                  │  │
                    │  └─────────────────────────────────────┘  │
                    │                                           │
                    │  ┌─────────────────────────────────────┐  │
                    │  │        Firewall Rules               │  │
                    │  │        - HTTP (80)                  │  │
                    │  │        - HTTPS (443)                │  │
                    │  │        - SSH (22)                   │  │
                    │  └─────────────────────────────────────┘  │
                    └───────────────────────────────────────────┘
```

## 🔧 Component Details

### 1. Network Layer

#### VPC Network (`ha-web-vpc`)

- **Type**: Custom VPC network
- **Auto-create subnets**: Disabled (manual subnet control)
- **Purpose**: Isolated network environment for all resources

#### Subnet (`ha-web-subnet`)

- **IP Range**: 10.0.1.0/24 (254 available IPs)
- **Region**: us-central1
- **Purpose**: Houses all compute instances

#### Firewall Rules

```hcl
# HTTP Traffic
Rule: allow-http
- Protocol: TCP
- Ports: 80
- Source: 0.0.0.0/0 (Internet)
- Targets: web-server tag

# HTTPS Traffic
Rule: allow-https
- Protocol: TCP
- Ports: 443
- Source: 0.0.0.0/0 (Internet)
- Targets: web-server tag

# SSH Access
Rule: allow-ssh
- Protocol: TCP
- Ports: 22
- Source: 0.0.0.0/0 (Internet)
- Targets: web-server tag
```

### 2. Compute Layer

#### Instance Template (`web-template`)

```yaml
Configuration:
  - Base Image: ubuntu-os-cloud/ubuntu-2204-lts
  - Machine Type: e2-micro (1 vCPU, 1GB RAM)
  - Boot Disk: 20GB persistent SSD
  - Network Tags: ["web-server"]
  - Service Account: web-server-sa
  - Startup Script: Custom nginx installation
  - Metadata: Server identification
```

#### Managed Instance Group (`web-instance-group`)

```yaml
Configuration:
  - Type: Regional managed instance group
  - Region: us-central1
  - Target Size: 2 instances
  - Base Instance Name: web-server
  - Distribution: Multi-zone (automatic)
  - Named Ports: http:80

Auto-healing:
  - Health Check: web-health-check
  - Initial Delay: 300 seconds
  - Replacement Policy: Proactive

Update Policy:
  - Type: Proactive
  - Max Surge: 2 instances
  - Max Unavailable: 0 instances
  - Minimal Action: Replace
```

### 3. Load Balancing Layer

#### Health Check (`web-health-check`)

```yaml
Configuration:
  - Type: HTTP health check
  - Port: 80
  - Request Path: /
  - Check Interval: 10 seconds
  - Timeout: 5 seconds
  - Healthy Threshold: 2 consecutive successes
  - Unhealthy Threshold: 3 consecutive failures
```

#### Backend Service (`web-backend-service`)

```yaml
Configuration:
  - Protocol: HTTP
  - Port Name: http
  - Load Balancing Scheme: EXTERNAL
  - Timeout: 30 seconds
  - Health Checks: [web-health-check]

Backend Configuration:
  - Group: web-instance-group
  - Balancing Mode: UTILIZATION
  - Capacity Scaler: 1.0

Logging:
  - Enable: true
  - Sample Rate: 100%
```

#### URL Map (`web-url-map`)

```yaml
Configuration:
  - Default Service: web-backend-service
  - Host Rules: None (catch-all)
  - Path Matchers: Default routing
```

#### HTTP Target Proxy (`web-http-proxy`)

```yaml
Configuration:
  - URL Map: web-url-map
  - Protocol: HTTP
```

#### Global Forwarding Rule (`web-forwarding-rule-static`)

```yaml
Configuration:
  - Target: web-http-proxy
  - Port Range: 80
  - IP Protocol: TCP
  - IP Address: Static reserved IP
  - Load Balancing Scheme: EXTERNAL
```

#### Static IP Address (`web-static-ip`)

```yaml
Configuration:
  - Type: Global external IP
  - Address Type: EXTERNAL
  - Purpose: Load balancer frontend
```

### 4. Security Layer

#### Service Account (`web-server-sa`)

```yaml
Configuration:
  - Account ID: web-server-sa
  - Display Name: Web Server Service Account
  - Scopes: ["cloud-platform"]
  - Purpose: Instance-level permissions
```

#### IAM Permissions

- Compute Engine default service account permissions
- Cloud logging write access
- Metadata server access

## 🔄 Traffic Flow

### Request Processing Flow

1. **Client Request**: User makes HTTP request to static IP
2. **Global Load Balancer**: Receives request at edge location
3. **Target Proxy**: Routes request based on URL map
4. **Backend Service**: Selects healthy backend instance
5. **Health Check**: Verifies instance health status
6. **Instance Selection**: Routes to available instance using round-robin
7. **Response**: Instance processes request and returns response
8. **Logging**: Request logged for monitoring and analysis

### Load Balancing Algorithm

- **Primary**: Round-robin distribution
- **Fallback**: Least connections when utilization is high
- **Health-aware**: Only routes to healthy instances
- **Session Affinity**: None (stateless application)

## 🔍 Monitoring and Observability

### Health Check Monitoring

```yaml
Metrics Collected:
  - Instance health status
  - Health check latency
  - Success/failure rates
  - Instance replacement events

Alerting Thresholds:
  - Unhealthy instance count > 0
  - Health check failure rate > 10%
  - Instance replacement frequency > normal
```

### Load Balancer Monitoring

```yaml
Metrics Collected:
  - Request count and rate
  - Response latency (p50, p95, p99)
  - Error rates (4xx, 5xx)
  - Backend utilization
  - Geographic distribution

Log Format:
  - Timestamp
  - Client IP
  - Request method and path
  - Response code and size
  - Backend instance served
  - Processing latency
```

### Instance Monitoring

```yaml
System Metrics:
  - CPU utilization
  - Memory usage
  - Disk I/O
  - Network throughput

Application Metrics:
  - Nginx request count
  - Response times
  - Error logs
  - Process health
```

## 🚀 Scaling Behavior

### Horizontal Scaling

```yaml
Current Configuration:
  - Fixed size: 2 instances
  - Manual scaling via Terraform or gcloud

Auto-scaling (Future Enhancement):
  - CPU utilization target: 60%
  - Min instances: 2
  - Max instances: 10
  - Scale-up cooldown: 60 seconds
  - Scale-down cooldown: 120 seconds
```

### Vertical Scaling

```yaml
Machine Type Options:
  - e2-micro: 1 vCPU, 1GB RAM
  - e2-small: 1 vCPU, 2GB RAM
  - e2-medium: 1 vCPU, 4GB RAM
  - n1-standard-1: 1 vCPU, 3.75GB RAM
  - n2-standard-2: 2 vCPU, 8GB RAM
```

## 🔒 Security Architecture

### Network Security

```yaml
VPC Security:
  - Private subnet with controlled routing
  - Firewall rules with specific port access
  - No default internet gateway (controlled access)

Instance Security:
  - Custom service account with minimal permissions
  - Network tags for firewall targeting
  - Automatic security updates via startup script
```

### Access Control

```yaml
Management Access:
  - SSH access via firewall rules
  - IAM-based access control
  - Service account key rotation

Application Security:
  - HTTP-only (HTTPS can be added)
  - No sensitive data storage
  - Stateless application design
```

## 🔧 Disaster Recovery

### High Availability Features

```yaml
Multi-Zone Deployment:
  - Instances distributed across zones
  - Automatic zone selection
  - Zone failure tolerance

Auto-Healing:
  - Unhealthy instance replacement
  - Health check-driven recovery
  - Zero-downtime replacements

Load Balancer Resilience:
  - Global anycast IP
  - Multiple backend instances
  - Automatic failover
```

### Backup and Recovery

```yaml
Instance Recovery:
  - Automatic instance recreation
  - Stateless application design
  - Configuration via startup script

Data Recovery:
  - No persistent data stored
  - Configuration in version control
  - Infrastructure as Code approach
```

## 📊 Performance Characteristics

### Latency Expectations

```yaml
Global Load Balancer:
  - Edge location latency: 10-50ms
  - Backend selection: <1ms
  - Health check overhead: Minimal

Instance Response:
  - Nginx static content: 1-5ms
  - Dynamic content generation: 10-50ms
  - Network overhead: 1-10ms
```

### Throughput Capacity

```yaml
Per Instance:
  - Concurrent connections: ~1000
  - Requests per second: ~100-500
  - Bandwidth: Limited by machine type

Load Balancer:
  - Global capacity: Unlimited
  - Regional capacity: Very high
  - Automatic scaling: Yes
```

## 🔄 Maintenance Procedures

### Rolling Updates

```bash
# Update instance template
terraform apply

# Monitor update progress
gcloud compute instance-groups managed describe web-instance-group \
    --region=us-central1

# Verify health after update
gcloud compute backend-services get-health web-backend-service \
    --global
```

### Scaling Operations

```bash
# Scale up
gcloud compute instance-groups managed resize web-instance-group \
    --size=4 --region=us-central1

# Scale down
gcloud compute instance-groups managed resize web-instance-group \
    --size=2 --region=us-central1
```

### Health Check Tuning

```bash
# Update health check parameters
gcloud compute health-checks update http web-health-check \
    --check-interval=5s \
    --timeout=3s
```

This architecture provides a robust, scalable, and maintainable foundation for web applications requiring high availability and load distribution.
