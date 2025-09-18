# ZSnail L2 Blockchain Quick Start Script
# This script sets up the development environment and runs initial setup

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipGcloud = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipInstall = $false
)

Write-Host "🚀 ZSnail L2 Blockchain Quick Start" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Blue

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js is installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js is not installed. Please install Node.js 18+ from https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# Check npm
try {
    $npmVersion = npm --version
    Write-Host "✅ npm is installed: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ npm is not installed. Please install npm." -ForegroundColor Red
    exit 1
}

# Check Git
try {
    $gitVersion = git --version
    Write-Host "✅ Git is installed: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git is not installed. Please install Git from https://git-scm.com/" -ForegroundColor Red
    exit 1
}

# Check Docker
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker is installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Docker is not installed. Some features may not work. Install from https://docker.com/" -ForegroundColor Yellow
}

Write-Host ""

# Setup Google Cloud (optional)
if (-not $SkipGcloud) {
    Write-Host "🌐 Setting up Google Cloud..." -ForegroundColor Blue
    try {
        & ".\setup-gcloud.ps1"
        Write-Host "✅ Google Cloud setup completed" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Google Cloud setup failed. You can run it manually later." -ForegroundColor Yellow
    }
    Write-Host ""
}

# Install dependencies
if (-not $SkipInstall) {
    Write-Host "📦 Installing dependencies..." -ForegroundColor Blue
    
    # Install root dependencies
    Write-Host "Installing root dependencies..."
    npm install
    
    # Create workspace structure if it doesn't exist
    $workspaces = @("contracts", "backend", "frontend", "sequencer", "validator", "bridge", "rollup", "l2-core")
    
    foreach ($workspace in $workspaces) {
        if (-not (Test-Path $workspace)) {
            Write-Host "Creating workspace: $workspace"
            New-Item -ItemType Directory -Path $workspace -Force
        }
        
        if (-not (Test-Path "$workspace/package.json")) {
            Write-Host "Initializing $workspace package.json"
            Set-Location $workspace
            npm init -y
            Set-Location ..
        }
    }
    
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
    Write-Host ""
}

# Initialize environment
Write-Host "🔧 Setting up environment..." -ForegroundColor Blue

# Check if .env exists and has required variables
if (Test-Path ".env") {
    Write-Host "✅ .env file exists" -ForegroundColor Green
    
    # Validate required environment variables
    $envContent = Get-Content ".env" -Raw
    $requiredVars = @(
        "GOOGLE_CLOUD_PROJECT_ID",
        "GOOGLE_APPLICATION_CREDENTIALS",
        "L2_CHAIN_ID"
    )
    
    foreach ($var in $requiredVars) {
        if ($envContent -match "$var=") {
            Write-Host "✅ $var is configured" -ForegroundColor Green
        } else {
            Write-Host "⚠️ $var is not configured in .env" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "❌ .env file not found. Please create it with required variables." -ForegroundColor Red
}

Write-Host ""

# Initialize Git repository
Write-Host "📝 Initializing Git repository..." -ForegroundColor Blue
if (-not (Test-Path ".git")) {
    git init
    git add .
    git commit -m "Initial commit: ZSnail L2 Blockchain project setup"
    Write-Host "✅ Git repository initialized" -ForegroundColor Green
} else {
    Write-Host "✅ Git repository already exists" -ForegroundColor Green
}

Write-Host ""

# Create initial smart contract setup
Write-Host "📋 Setting up smart contracts..." -ForegroundColor Blue
Set-Location contracts

if (-not (Test-Path "package.json")) {
    npm init -y
}

# Install Hardhat and dependencies
$contractDeps = @(
    "@openzeppelin/contracts",
    "hardhat",
    "@nomicfoundation/hardhat-toolbox",
    "@nomicfoundation/hardhat-verify",
    "hardhat-gas-reporter",
    "solidity-coverage",
    "dotenv"
)

Write-Host "Installing smart contract dependencies..."
npm install --save-dev $contractDeps

# Initialize Hardhat if not exists
if (-not (Test-Path "hardhat.config.js")) {
    npx hardhat init --yes
}

Set-Location ..

Write-Host "✅ Smart contracts setup completed" -ForegroundColor Green
Write-Host ""

# Display next steps
Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review and update the .env file with your specific configuration"
Write-Host "2. Configure your Google Cloud credentials"
Write-Host "3. Set up your blockchain network parameters"
Write-Host "4. Deploy smart contracts: npm run deploy:local"
Write-Host "5. Start the sequencer: npm run sequencer:dev"
Write-Host "6. Start the validator: npm run validator:dev"
Write-Host "7. Start the frontend: npm run dev:frontend"
Write-Host ""
Write-Host "🔗 Useful Commands:" -ForegroundColor Cyan
Write-Host "npm run dev                    # Start all services"
Write-Host "npm run build                  # Build all components"
Write-Host "npm run test                   # Run all tests"
Write-Host "npm run deploy:testnet         # Deploy to testnet"
Write-Host ".\scripts\setup-gcloud.ps1     # Setup Google Cloud"
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "README.md                      # Main documentation"
Write-Host "copilot-instructions.md        # Development guidelines"
Write-Host "docs/                          # Detailed documentation"
Write-Host ""
Write-Host "🆘 Support:" -ForegroundColor Cyan
Write-Host "[To be configured]"
Write-Host "[To be configured]"
Write-Host "[To be configured]"
Write-Host ""
Write-Host "Happy coding! 🚀" -ForegroundColor Green