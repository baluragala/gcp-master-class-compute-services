# Configure the Google Cloud Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Create VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "ha-web-vpc"
  auto_create_subnetworks = false
  description             = "VPC network for high availability web infrastructure"
}

# Create Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "ha-web-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  description   = "Subnet for web servers"
}

# Create Firewall Rules
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  description   = "Allow HTTP traffic to web servers"
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  description   = "Allow HTTPS traffic to web servers"
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  description   = "Allow SSH access to web servers"
}

# Health Check for Load Balancer
resource "google_compute_health_check" "web_health_check" {
  name                = "web-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/"
  }

  description = "Health check for web servers"
}

# Instance Template
resource "google_compute_instance_template" "web_template" {
  name_prefix  = "web-template-"
  machine_type = var.machine_type
  region       = var.region

  tags = ["web-server"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    server_name = "Server-${random_id.server_id.hex}"
  })

  service_account {
    email  = google_service_account.web_server_sa.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Random ID for unique server identification
resource "random_id" "server_id" {
  byte_length = 4
}

# Service Account for instances
resource "google_service_account" "web_server_sa" {
  account_id   = "web-server-sa"
  display_name = "Web Server Service Account"
  description  = "Service account for web server instances"
}

# Managed Instance Group
resource "google_compute_region_instance_group_manager" "web_igm" {
  name   = "web-instance-group"
  region = var.region

  version {
    instance_template = google_compute_instance_template.web_template.id
  }

  target_size        = 2
  base_instance_name = "web-server"

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.web_health_check.id
    initial_delay_sec = 300
  }

  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
    max_unavailable_fixed        = 0
  }
}

# Backend Service
resource "google_compute_backend_service" "web_backend" {
  name                  = "web-backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.web_health_check.id]
  
  depends_on = [
    google_compute_health_check.web_health_check,
    google_compute_region_instance_group_manager.web_igm
  ]

  backend {
    group           = google_compute_region_instance_group_manager.web_igm.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL Map
resource "google_compute_url_map" "web_url_map" {
  name            = "web-url-map"
  default_service = google_compute_backend_service.web_backend.id

  description = "URL map for web application load balancer"
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "web_http_proxy" {
  name    = "web-http-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

# Global Forwarding Rule (Load Balancer Frontend)
resource "google_compute_global_forwarding_rule" "web_forwarding_rule" {
  name                  = "web-forwarding-rule"
  target                = google_compute_target_http_proxy.web_http_proxy.id
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
}

# Reserve static IP for load balancer
resource "google_compute_global_address" "web_ip" {
  name         = "web-static-ip"
  address_type = "EXTERNAL"
  description  = "Static IP for web application load balancer"
}

# Update forwarding rule to use static IP
resource "google_compute_global_forwarding_rule" "web_forwarding_rule_static" {
  name                  = "web-forwarding-rule-static"
  target                = google_compute_target_http_proxy.web_http_proxy.id
  port_range            = "80"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.web_ip.address
  load_balancing_scheme = "EXTERNAL"
}
