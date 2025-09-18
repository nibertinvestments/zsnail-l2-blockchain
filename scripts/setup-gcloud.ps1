# Google Cloud Setup Script for ZSnail L2 Blockchain
# This script sets up the Google Cloud environment and services

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectId = "zsnail-blockchain",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-central1",
    
    [Parameter(Mandatory=$false)]
    [string]$Zone = "us-central1-a"
)

Write-Host "🚀 Setting up Google Cloud for ZSnail L2 Blockchain" -ForegroundColor Green
Write-Host "Project ID: $ProjectId" -ForegroundColor Yellow
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "Zone: $Zone" -ForegroundColor Yellow

# Check if gcloud CLI is installed
try {
    $gcloudVersion = gcloud version --format="value(Google Cloud SDK)"
    Write-Host "✅ Google Cloud SDK is installed: $gcloudVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Google Cloud SDK is not installed. Please install it from https://cloud.google.com/sdk/docs/install" -ForegroundColor Red
    exit 1
}

# Authenticate with Google Cloud
Write-Host "🔐 Authenticating with Google Cloud..." -ForegroundColor Blue
gcloud auth login

# Set the project
Write-Host "📁 Setting project to $ProjectId..." -ForegroundColor Blue
gcloud config set project $ProjectId

# Set default region and zone
Write-Host "🌍 Setting default region and zone..." -ForegroundColor Blue
gcloud config set compute/region $Region
gcloud config set compute/zone $Zone

# Enable required APIs
Write-Host "🔧 Enabling required Google Cloud APIs..." -ForegroundColor Blue
$apis = @(
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
    "firestore.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "sql.googleapis.com",
    "redis.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudkms.googleapis.com"
)

foreach ($api in $apis) {
    Write-Host "Enabling $api..." -ForegroundColor Yellow
    gcloud services enable $api
}

# Create service account if it doesn't exist
Write-Host "👤 Setting up service accounts..." -ForegroundColor Blue
$serviceAccountEmail = "zsnail-blockchain@$ProjectId.iam.gserviceaccount.com"

try {
    gcloud iam service-accounts describe $serviceAccountEmail 2>$null
    Write-Host "✅ Service account already exists: $serviceAccountEmail" -ForegroundColor Green
} catch {
    Write-Host "Creating service account..." -ForegroundColor Yellow
    gcloud iam service-accounts create zsnail-blockchain `
        --display-name="ZSnail Blockchain Service Account" `
        --description="Service account for ZSnail L2 blockchain operations"
}

# Assign necessary roles to service account
Write-Host "🔑 Assigning IAM roles to service account..." -ForegroundColor Blue
$roles = @(
    "roles/compute.admin",
    "roles/container.admin",
    "roles/storage.admin",
    "roles/datastore.user",
    "roles/logging.admin",
    "roles/monitoring.editor",
    "roles/secretmanager.admin",
    "roles/cloudsql.admin",
    "roles/redis.admin",
    "roles/cloudbuild.builds.editor",
    "roles/run.admin",
    "roles/cloudkms.admin"
)

foreach ($role in $roles) {
    Write-Host "Assigning role: $role" -ForegroundColor Yellow
    gcloud projects add-iam-policy-binding $ProjectId `
        --member="serviceAccount:$serviceAccountEmail" `
        --role="$role"
}

# Create Cloud Storage buckets
Write-Host "🪣 Creating Cloud Storage buckets..." -ForegroundColor Blue
$buckets = @(
    "zsnail-blockchain-storage",
    "zsnail-blockchain-artifacts",
    "zsnail-blockchain-logs",
    "zsnail-blockchain-backups"
)

foreach ($bucket in $buckets) {
    try {
        gsutil ls gs://$bucket 2>$null
        Write-Host "✅ Bucket already exists: $bucket" -ForegroundColor Green
    } catch {
        Write-Host "Creating bucket: $bucket" -ForegroundColor Yellow
        gsutil mb -l $Region gs://$bucket
        
        # Set bucket permissions
        gsutil iam ch serviceAccount:$serviceAccountEmail:roles/storage.admin gs://$bucket
    }
}

# Create Firestore database
Write-Host "🔥 Setting up Firestore database..." -ForegroundColor Blue
try {
    gcloud firestore databases describe --region=$Region 2>$null
    Write-Host "✅ Firestore database already exists" -ForegroundColor Green
} catch {
    Write-Host "Creating Firestore database..." -ForegroundColor Yellow
    gcloud firestore databases create --region=$Region
}

# Create Secret Manager secrets
Write-Host "🔐 Setting up Secret Manager..." -ForegroundColor Blue
$secrets = @(
    "blockchain-private-key",
    "blockchain-mnemonic",
    "api-keys",
    "database-credentials"
)

foreach ($secret in $secrets) {
    try {
        gcloud secrets describe $secret 2>$null
        Write-Host "✅ Secret already exists: $secret" -ForegroundColor Green
    } catch {
        Write-Host "Creating secret: $secret" -ForegroundColor Yellow
        # Create empty secret that must be populated later
        gcloud secrets create $secret --data-file=NUL
    }
}

# Set up Cloud SQL instance for PostgreSQL
Write-Host "🐘 Setting up Cloud SQL PostgreSQL instance..." -ForegroundColor Blue
$sqlInstanceName = "zsnail-blockchain-db"

try {
    gcloud sql instances describe $sqlInstanceName 2>$null
    Write-Host "✅ Cloud SQL instance already exists: $sqlInstanceName" -ForegroundColor Green
} catch {
    Write-Host "Creating Cloud SQL instance..." -ForegroundColor Yellow
    gcloud sql instances create $sqlInstanceName `
        --database-version=POSTGRES_15 `
        --tier=db-n1-standard-2 `
        --region=$Region `
        --storage-type=SSD `
        --storage-size=100GB `
        --backup-start-time=03:00 `
        --enable-bin-log `
        --maintenance-release-channel=production `
        --maintenance-window-day=SUN `
        --maintenance-window-hour=04
    
    # Create database
    gcloud sql databases create blockchain_db --instance=$sqlInstanceName
    
    # Create user
    gcloud sql users create blockchain_user --instance=$sqlInstanceName
}

# Set up Redis instance
Write-Host "🔴 Setting up Redis instance..." -ForegroundColor Blue
$redisInstanceName = "zsnail-blockchain-cache"

try {
    gcloud redis instances describe $redisInstanceName --region=$Region 2>$null
    Write-Host "✅ Redis instance already exists: $redisInstanceName" -ForegroundColor Green
} catch {
    Write-Host "Creating Redis instance..." -ForegroundColor Yellow
    gcloud redis instances create $redisInstanceName `
        --size=1 `
        --region=$Region `
        --redis-version=redis_7_0
}

# Create GKE cluster for blockchain nodes
Write-Host "☸️ Setting up GKE cluster..." -ForegroundColor Blue
$clusterName = "zsnail-blockchain-cluster"

try {
    gcloud container clusters describe $clusterName --zone=$Zone 2>$null
    Write-Host "✅ GKE cluster already exists: $clusterName" -ForegroundColor Green
} catch {
    Write-Host "Creating GKE cluster..." -ForegroundColor Yellow
    gcloud container clusters create $clusterName `
        --zone=$Zone `
        --machine-type=n1-standard-4 `
        --num-nodes=3 `
        --enable-autorepair `
        --enable-autoupgrade `
        --enable-autoscaling `
        --min-nodes=1 `
        --max-nodes=10 `
        --disk-size=100GB `
        --disk-type=pd-ssd `
        --enable-ip-alias `
        --enable-network-policy
    
    # Get cluster credentials
    gcloud container clusters get-credentials $clusterName --zone=$Zone
}

# Set up Cloud Build triggers
Write-Host "🔨 Setting up Cloud Build..." -ForegroundColor Blue
# This would typically connect to your GitHub repository
Write-Host "Cloud Build setup requires repository connection - configure manually" -ForegroundColor Yellow

# Create monitoring workspace
Write-Host "📊 Setting up monitoring..." -ForegroundColor Blue
Write-Host "Monitoring workspace will be created automatically with first metrics" -ForegroundColor Yellow

Write-Host ""
Write-Host "🎉 Google Cloud setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "1. Update database credentials in Secret Manager"
Write-Host "2. Configure monitoring alerts"
Write-Host "3. Set up Cloud Build triggers for CI/CD"
Write-Host "4. Configure custom domains and SSL certificates"
Write-Host "5. Review and adjust IAM permissions as needed"
Write-Host ""
Write-Host "🔗 Useful commands:" -ForegroundColor Cyan
Write-Host "gcloud config list                    # View current configuration"
Write-Host "gcloud projects list                  # List available projects"
Write-Host "gcloud services list --enabled        # List enabled APIs"
Write-Host "kubectl get nodes                     # Check GKE cluster status"
Write-Host "gsutil ls                            # List storage buckets"