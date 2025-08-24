output "load_balancer_ip" {
  description = "The external IP address of the load balancer"
  value       = google_compute_global_address.web_ip.address
}

output "load_balancer_url" {
  description = "The URL of the load balancer"
  value       = "http://${google_compute_global_address.web_ip.address}"
}

output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "instance_group_name" {
  description = "The name of the managed instance group"
  value       = google_compute_region_instance_group_manager.web_igm.name
}

output "backend_service_name" {
  description = "The name of the backend service"
  value       = google_compute_backend_service.web_backend.name
}

output "health_check_name" {
  description = "The name of the health check"
  value       = google_compute_health_check.web_health_check.name
}

output "instance_template_name" {
  description = "The name of the instance template"
  value       = google_compute_instance_template.web_template.name
}
