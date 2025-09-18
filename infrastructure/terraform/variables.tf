# Terraform Variables for ZSnail L2 Blockchain Infrastructure

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "zsnail-blockchain"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# GKE Cluster Variables
variable "node_count" {
  description = "Number of nodes in the GKE cluster"
  type        = number
  default     = 3
}

variable "min_node_count" {
  description = "Minimum number of nodes in the GKE cluster"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the GKE cluster"
  type        = number
  default     = 10
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "n1-standard-4"
}

# Database Variables
variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-n1-standard-2"
}

variable "db_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 100
}

# Redis Variables
variable "redis_memory_size" {
  description = "Redis memory size in GB"
  type        = number
  default     = 2
}

# GitHub Variables
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

# Monitoring Variables
variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
  default     = ""
}

# Network Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.0.0/24"
}

# Security Variables
variable "allowed_ips" {
  description = "List of allowed IP addresses for admin access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Blockchain Specific Variables
variable "sequencer_replicas" {
  description = "Number of sequencer replicas"
  type        = number
  default     = 2
}

variable "validator_replicas" {
  description = "Number of validator replicas"
  type        = number
  default     = 3
}

variable "rpc_port" {
  description = "Port for blockchain RPC"
  type        = number
  default     = 8545
}

variable "ws_port" {
  description = "Port for blockchain WebSocket"
  type        = number
  default     = 8546
}

variable "p2p_port" {
  description = "Port for blockchain P2P communication"
  type        = number
  default     = 30303
}

# Storage Variables
variable "blockchain_data_size" {
  description = "Size of blockchain data storage in GB"
  type        = number
  default     = 500
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

# Feature Flags
variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "enable_ssl" {
  description = "Enable SSL certificates"
  type        = bool
  default     = true
}

variable "enable_cdn" {
  description = "Enable CDN for static assets"
  type        = bool
  default     = false
}