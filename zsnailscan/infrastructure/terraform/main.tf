# ZSnail L2 Blockchain Infrastructure
# Google Cloud Platform Terraform Configuration

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
  
  backend "gcs" {
    bucket = "zsnail-blockchain-terraform-state"
    prefix = "terraform/state"
  }
}

# Provider Configuration
provider "google" {
  credentials = file("../../config/zsnail-blockchain-5e515e80fbb0.json")
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

provider "google-beta" {
  credentials = file("../../config/zsnail-blockchain-5e515e80fbb0.json")
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# Local Variables
locals {
  common_labels = {
    project     = "zsnail-l2"
    environment = var.environment
    managed_by  = "terraform"
    team        = "blockchain"
  }
}

# Data Sources
data "google_project" "project" {
  project_id = var.project_id
}

data "google_client_config" "default" {}

# VPC Network
resource "google_compute_network" "blockchain_network" {
  name                    = "zsnail-blockchain-network"
  auto_create_subnetworks = false
  description             = "VPC network for ZSnail L2 blockchain infrastructure"
  
  labels = local.common_labels
}

# Subnet for blockchain nodes
resource "google_compute_subnetwork" "blockchain_subnet" {
  name          = "zsnail-blockchain-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.blockchain_network.id
  description   = "Subnet for blockchain nodes and services"
  
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }
  
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Firewall Rules
resource "google_compute_firewall" "blockchain_firewall" {
  name    = "zsnail-blockchain-firewall"
  network = google_compute_network.blockchain_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8545", "8546", "30303"]
  }

  allow {
    protocol = "udp"
    ports    = ["30303"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["blockchain-node"]
}

# Cloud NAT for outbound internet access
resource "google_compute_router" "blockchain_router" {
  name    = "zsnail-blockchain-router"
  region  = var.region
  network = google_compute_network.blockchain_network.id
}

resource "google_compute_router_nat" "blockchain_nat" {
  name                               = "zsnail-blockchain-nat"
  router                            = google_compute_router.blockchain_router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# GKE Cluster
resource "google_container_cluster" "blockchain_cluster" {
  name     = "zsnail-blockchain-cluster"
  location = var.zone
  
  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = google_compute_network.blockchain_network.name
  subnetwork = google_compute_subnetwork.blockchain_subnet.name
  
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
  
  network_policy {
    enabled = true
  }
  
  addons_config {
    http_load_balancing {
      disabled = false
    }
    
    horizontal_pod_autoscaling {
      disabled = false
    }
    
    network_policy_config {
      disabled = false
    }
  }
  
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  labels = local.common_labels
}

# Node Pool for blockchain services
resource "google_container_node_pool" "blockchain_nodes" {
  name       = "zsnail-blockchain-nodes"
  location   = var.zone
  cluster    = google_container_cluster.blockchain_cluster.name
  node_count = var.node_count

  node_config {
    preemptible  = var.environment == "dev"
    machine_type = var.machine_type
    disk_size_gb = 100
    disk_type    = "pd-ssd"
    
    service_account = google_service_account.blockchain_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = merge(local.common_labels, {
      role = "blockchain-node"
    })
    
    tags = ["blockchain-node"]
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
  
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Service Account for blockchain operations
resource "google_service_account" "blockchain_sa" {
  account_id   = "zsnail-blockchain-sa"
  display_name = "ZSnail Blockchain Service Account"
  description  = "Service account for ZSnail L2 blockchain operations"
}

# IAM bindings for service account
resource "google_project_iam_member" "blockchain_sa_bindings" {
  for_each = toset([
    "roles/storage.admin",
    "roles/datastore.user",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.client"
  ])
  
  role    = each.value
  member  = "serviceAccount:${google_service_account.blockchain_sa.email}"
  project = var.project_id
}

# Cloud Storage buckets
resource "google_storage_bucket" "blockchain_storage" {
  name     = "zsnail-blockchain-storage-${random_id.bucket_suffix.hex}"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
  
  labels = local.common_labels
}

resource "google_storage_bucket" "blockchain_artifacts" {
  name     = "zsnail-blockchain-artifacts-${random_id.bucket_suffix.hex}"
  location = var.region
  
  uniform_bucket_level_access = true
  
  labels = local.common_labels
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "blockchain_db" {
  name             = "zsnail-blockchain-db-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.region
  
  settings {
    tier              = var.db_tier
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = var.db_disk_size
    disk_autoresize   = true
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.blockchain_network.id
      require_ssl     = true
    }
    
    database_flags {
      name  = "log_statement"
      value = "all"
    }
    
    user_labels = local.common_labels
  }
  
  deletion_protection = var.environment == "prod"
  
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Database
resource "google_sql_database" "blockchain_db" {
  name     = "blockchain_db"
  instance = google_sql_database_instance.blockchain_db.name
}

# Database user
resource "google_sql_user" "blockchain_user" {
  name     = "blockchain_user"
  instance = google_sql_database_instance.blockchain_db.name
  password = random_password.db_password.result
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Private service connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.blockchain_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.blockchain_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Redis instance
resource "google_redis_instance" "blockchain_cache" {
  name           = "zsnail-blockchain-cache"
  tier           = "STANDARD_HA"
  memory_size_gb = var.redis_memory_size
  region         = var.region
  
  authorized_network = google_compute_network.blockchain_network.id
  redis_version      = "REDIS_7_0"
  
  labels = local.common_labels
}

# Secret Manager secrets
resource "google_secret_manager_secret" "blockchain_secrets" {
  for_each = toset([
    "blockchain-private-key",
    "blockchain-mnemonic", 
    "api-keys",
    "database-password"
  ])
  
  secret_id = each.value
  
  replication {
    auto {}
  }
  
  labels = local.common_labels
}

# Store database password in Secret Manager
resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.blockchain_secrets["database-password"].id
  secret_data = random_password.db_password.result
}

# Cloud Build trigger for CI/CD
resource "google_cloudbuild_trigger" "blockchain_trigger" {
  name        = "zsnail-blockchain-trigger"
  description = "Trigger for ZSnail L2 blockchain CI/CD"
  
  github {
    owner = var.github_owner
    name  = var.github_repo
    push {
      branch = "^main$"
    }
  }
  
  filename = "cloudbuild.yaml"
  
  substitutions = {
    _ENVIRONMENT = var.environment
    _PROJECT_ID  = var.project_id
  }
}

# Load balancer for blockchain RPC endpoints
resource "google_compute_global_address" "blockchain_ip" {
  name = "zsnail-blockchain-ip"
}

# Monitoring and Alerting
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "High CPU Usage - ZSnail Blockchain"
  combiner     = "OR"
  
  conditions {
    display_name = "CPU usage above 80%"
    
    condition_threshold {
      filter          = "resource.type=\"gke_container\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.8
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  
  notification_channels = [google_monitoring_notification_channel.email.name]
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification"
  type         = "email"
  
  labels = {
    email_address = var.alert_email
  }
}

# Cloud Armor security policy
resource "google_compute_security_policy" "blockchain_security_policy" {
  name = "zsnail-blockchain-security-policy"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Allow all traffic"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule"
  }
}