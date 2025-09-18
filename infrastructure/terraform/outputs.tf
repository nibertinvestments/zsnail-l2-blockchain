# Terraform Outputs for ZSnail L2 Blockchain Infrastructure

# Project Information
output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "environment" {
  description = "The deployment environment"
  value       = var.environment
}

# Network Information
output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.blockchain_network.name
}

output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.blockchain_network.id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.blockchain_subnet.name
}

output "subnet_cidr" {
  description = "CIDR block of the subnet"
  value       = google_compute_subnetwork.blockchain_subnet.ip_cidr_range
}

# GKE Cluster Information
output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.blockchain_cluster.name
}

output "gke_cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.blockchain_cluster.endpoint
  sensitive   = true
}

output "gke_cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.blockchain_cluster.location
}

output "gke_cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = google_container_cluster.blockchain_cluster.master_auth.0.cluster_ca_certificate
  sensitive   = true
}

# Service Account Information
output "blockchain_service_account_email" {
  description = "Email of the blockchain service account"
  value       = google_service_account.blockchain_sa.email
}

output "blockchain_service_account_id" {
  description = "ID of the blockchain service account"
  value       = google_service_account.blockchain_sa.id
}

# Cloud Storage Information
output "storage_bucket_name" {
  description = "Name of the main storage bucket"
  value       = google_storage_bucket.blockchain_storage.name
}

output "storage_bucket_url" {
  description = "URL of the main storage bucket"
  value       = google_storage_bucket.blockchain_storage.url
}

output "artifacts_bucket_name" {
  description = "Name of the artifacts storage bucket"
  value       = google_storage_bucket.blockchain_artifacts.name
}

output "artifacts_bucket_url" {
  description = "URL of the artifacts storage bucket"
  value       = google_storage_bucket.blockchain_artifacts.url
}

# Database Information
output "database_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.blockchain_db.name
}

output "database_instance_connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.blockchain_db.connection_name
}

output "database_instance_ip" {
  description = "IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.blockchain_db.private_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Name of the database"
  value       = google_sql_database.blockchain_db.name
}

output "database_user" {
  description = "Database user name"
  value       = google_sql_user.blockchain_user.name
}

# Redis Information
output "redis_instance_name" {
  description = "Name of the Redis instance"
  value       = google_redis_instance.blockchain_cache.name
}

output "redis_instance_host" {
  description = "Host of the Redis instance"
  value       = google_redis_instance.blockchain_cache.host
  sensitive   = true
}

output "redis_instance_port" {
  description = "Port of the Redis instance"
  value       = google_redis_instance.blockchain_cache.port
}

# Load Balancer Information
output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = google_compute_global_address.blockchain_ip.address
}

output "load_balancer_name" {
  description = "Name of the load balancer IP"
  value       = google_compute_global_address.blockchain_ip.name
}

# Secret Manager Information
output "secret_manager_secrets" {
  description = "List of Secret Manager secret IDs"
  value       = [for secret in google_secret_manager_secret.blockchain_secrets : secret.secret_id]
}

# Cloud Build Information
output "cloud_build_trigger_name" {
  description = "Name of the Cloud Build trigger"
  value       = google_cloudbuild_trigger.blockchain_trigger.name
}

output "cloud_build_trigger_id" {
  description = "ID of the Cloud Build trigger"
  value       = google_cloudbuild_trigger.blockchain_trigger.trigger_id
}

# Monitoring Information
output "monitoring_alert_policy_name" {
  description = "Name of the monitoring alert policy"
  value       = google_monitoring_alert_policy.high_cpu.display_name
}

output "notification_channel_name" {
  description = "Name of the notification channel"
  value       = google_monitoring_notification_channel.email.display_name
}

# Security Information
output "security_policy_name" {
  description = "Name of the Cloud Armor security policy"
  value       = google_compute_security_policy.blockchain_security_policy.name
}

# Connection Commands
output "kubectl_connection_command" {
  description = "Command to connect to the GKE cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.blockchain_cluster.name} --zone ${google_container_cluster.blockchain_cluster.location} --project ${var.project_id}"
}

output "database_connection_command" {
  description = "Command to connect to the database"
  value       = "gcloud sql connect ${google_sql_database_instance.blockchain_db.name} --user=${google_sql_user.blockchain_user.name} --database=${google_sql_database.blockchain_db.name}"
  sensitive   = true
}

# Environment Variables for Application Configuration
output "env_vars" {
  description = "Environment variables for application configuration"
  value = {
    GOOGLE_CLOUD_PROJECT_ID           = var.project_id
    GKE_CLUSTER_NAME                 = google_container_cluster.blockchain_cluster.name
    DATABASE_CONNECTION_NAME         = google_sql_database_instance.blockchain_db.connection_name
    DATABASE_NAME                    = google_sql_database.blockchain_db.name
    DATABASE_USER                    = google_sql_user.blockchain_user.name
    REDIS_HOST                       = google_redis_instance.blockchain_cache.host
    REDIS_PORT                       = google_redis_instance.blockchain_cache.port
    STORAGE_BUCKET                   = google_storage_bucket.blockchain_storage.name
    ARTIFACTS_BUCKET                 = google_storage_bucket.blockchain_artifacts.name
    LOAD_BALANCER_IP                 = google_compute_global_address.blockchain_ip.address
    SERVICE_ACCOUNT_EMAIL            = google_service_account.blockchain_sa.email
    VPC_NETWORK                      = google_compute_network.blockchain_network.name
    SUBNET_NAME                      = google_compute_subnetwork.blockchain_subnet.name
  }
  sensitive = true
}

# URLs and Endpoints
output "application_urls" {
  description = "Application URLs and endpoints"
  value = {
    rpc_endpoint = "https://${google_compute_global_address.blockchain_ip.address}:8545"
    ws_endpoint  = "wss://${google_compute_global_address.blockchain_ip.address}:8546"
    explorer_url = "https://${google_compute_global_address.blockchain_ip.address}/explorer"
    api_url      = "https://${google_compute_global_address.blockchain_ip.address}/api"
  }
}