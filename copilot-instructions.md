# Copilot Instructions for ZSnail L2 Blockchain Project

## 🚨 CRITICAL DEVELOPMENT PRINCIPLES

### ⛔ DO NOT ASSUME
**NEVER make assumptions about user intentions, project direction, or technical decisions without explicit confirmation.**
- Always ASK before suggesting architectural changes or technology switches
- Do NOT suggest replacing existing systems without user request
- Do NOT assume what infrastructure the user wants to implement
- ALWAYS clarify requirements before proceeding with research or implementation
- If uncertain about user goals, ASK SPECIFIC QUESTIONS before taking action

### PROJECT STATUS UPDATE - September 2025
**COMPLETED INFRASTRUCTURE**: ZSnail L2 now has a complete, production-ready blockchain ecosystem:
- **✅ 16 Custom ZSnail Library Contracts**: Complete replacement of OpenZeppelin with L2-optimized implementations
- **✅ 4 L2 Core Infrastructure Contracts**: Full optimistic rollup with fraud proofs, cross-layer bridge, and state management
- **✅ Google Cloud Storage Integration**: All contracts stored exclusively in `gs://zsnail-blockchain-storage/contracts/`
- **✅ Production Security**: Economic incentives, staking mechanisms, and challenge systems operational
- **✅ 2025 Technology Stack**: Hardhat v3.0.6, Ethers v6.15.0, Node.js LTS 2025, zero vulnerabilities

### 2025 SOFTWARE STANDARDS
- **YEAR: 2025** - Always use the latest 2025 versions of all software, frameworks, and dependencies
- Use Node.js LTS 2025, npm 10+, and latest stable package versions to avoid deprecation warnings
- Avoid deprecated packages and legacy code patterns from 2024 and earlier
- Prioritize ES2025+ features and modern JavaScript/TypeScript syntax
- Use the latest versions of React 19+, Express.js 5+, and all major frameworks
- Update all dependencies to their 2025 stable releases to prevent compatibility issues
- Check package.json for deprecated warnings and update accordingly

### REAL PRODUCTION CODE ONLY
- **NO EXAMPLE CODE**: Do not use placeholder, example, or demonstration code
- **NO FAKE DATA**: All variables, URLs, addresses, and configuration must be real or left blank
- **NO MADE-UP VALUES**: Never use placeholder numbers, fake API keys, or dummy addresses
- **NO FAKE DEPENDENCIES**: Never install or reference packages that don't exist in npm registry
- **NO FAKE DIRECTORIES**: Only reference actual directories that exist in the project
- **ERROR-DRIVEN DEVELOPMENT**: If something is missing, let it error so we can properly configure it
- **PRODUCTION-READY**: Every line of code must be production-quality and functional
- **NO LINT ERRORS ARE ACCEPTABLE**: Use best practices for everything - proper markdown formatting, correct syntax, professional standards at all times. Zero tolerance for any formatting issues, linting errors, or code quality problems.

### ZSNAIL CONTRACT ECOSYSTEM PRINCIPLES
- **CLOUD-ONLY STORAGE**: All smart contracts are stored exclusively in Google Cloud Storage
- **CUSTOM LIBRARY PRIORITY**: Always use ZSnail custom contracts instead of OpenZeppelin
- **GAS OPTIMIZATION**: Prioritize gas efficiency with individual contract deployments
- **L2 SPECIFIC**: All contracts are optimized for Layer 2 scaling and performance
- **SECURITY FIRST**: Production-ready security with fraud proofs and economic incentives

### CODE INTEGRITY RULES
1. **Real APIs Only**: Use actual service endpoints or leave blank for configuration
2. **Actual Dependencies**: Only include dependencies that are actually used
3. **Working Configurations**: All config files must be functional or explicitly marked as needing setup
4. **No Placeholders**: Remove any "your_key_here", "example.com", or similar placeholders
5. **Explicit Errors**: Prefer configuration errors over silent placeholder failures

---

## Project Overview
ZSnail L2 is a production-ready, EVM-compatible Layer 2 blockchain with a complete custom contract ecosystem. The project has successfully implemented:

- **Complete L2 Infrastructure**: Optimistic rollup with fraud proofs, cross-layer bridge, state management
- **Custom ZSnail Library**: 16 production-ready contracts replacing OpenZeppelin with L2 optimizations
- **Google Cloud Integration**: Service account authentication with cloud-native contract storage
- **Economic Security**: Staking mechanisms, challenge periods, and validator incentives
- **Modern Tech Stack**: 2025-standard tools (Hardhat v3, Ethers v6, Node.js LTS)

## Core Technologies & Current Implementation

### Smart Contract Ecosystem
- **Custom ZSnail Library**: 16 contracts in `gs://zsnail-blockchain-storage/contracts/libraries/`
  - Math, Crypto, Security, Access Control, Token Standards (ERC20/721/1155)
  - Governance (Timelock, Multicall), Upgradeable patterns, Signature verification
- **L2 Core Infrastructure**: 4 contracts implementing complete optimistic rollup
  - ZSnailSequencer.sol (15.8 KiB) - Transaction processing and L2 block production
  - ZSnailBridge.sol (20.1 KiB) - Cross-layer asset transfers for all token types
  - ZSnailStateManager.sol (19.9 KiB) - State root management and account tracking
  - ZSnailRollup.sol (19.8 KiB) - L1 assertion management and fraud proof validation

### Technology Stack (2025 Standards)
- **Blockchain**: Custom optimistic rollup with fraud proof system
- **Smart Contracts**: Solidity ^0.8.20 with gas-optimized L2 implementations  
- **Development**: Hardhat v3.0.6, Ethers.js v6.15.0, TypeScript with ES2025+
- **Backend**: Node.js LTS 2025, Express.js v5+, production API architecture
- **Cloud**: Google Cloud Platform with service account `zsnail-blockchain@zsnail-blockchain.iam.gserviceaccount.com`
- **Storage**: Exclusive Google Cloud Storage at `gs://zsnail-blockchain-storage`
- **Security**: Production fraud proofs, economic incentives, comprehensive access controls

## Current Project Status & Development Guidelines

## Coding Standards & Best Practices

### 1. Smart Contract Development (ZSnail Ecosystem)
- **Custom Library Priority**: Always use ZSnail contracts from `gs://zsnail-blockchain-storage/contracts/libraries/`
- **L2 Optimization**: Prioritize gas efficiency and Layer 2 scaling patterns
- **Cloud Storage**: All contracts stored exclusively in Google Cloud Storage, never locally
- **Production Security**: Use ZSnailSecurity.sol, ZSnailAccessControl.sol, and ZSnailReentrancyGuard.sol
- **Economic Mechanisms**: Implement staking, challenge periods, and fraud proof systems
- **Solidity Standards**: Use ^0.8.20, optimize for 200 runs, comprehensive NatSpec documentation
- **Testing**: Minimum 95% coverage with fraud proof scenario testing

### 2. Backend Development (Production API)
- **Architecture**: Clean architecture with dependency injection for L2 services
- **API Design**: RESTful APIs supporting L2 transaction processing and bridge operations
- **Error Handling**: Comprehensive fraud proof and challenge handling with proper HTTP codes
- **L2 Integration**: Direct integration with ZSnail sequencer, bridge, and state manager
- **Performance**: Batch processing, efficient state queries, L2-optimized endpoints
- **Security**: Rate limiting, validator authentication, secure bridge operations

### 3. Google Cloud Platform Integration (Production)

#### Current Infrastructure Status
- **Service Account**: `zsnail-blockchain@zsnail-blockchain.iam.gserviceaccount.com` (Active)
- **Storage Bucket**: `gs://zsnail-blockchain-storage` (20+ contracts deployed)
- **Contract Organization**:
  ```bash
  contracts/
  ├── libraries/        # 16 ZSnail library contracts
  ├── l1-contracts/     # L1 rollup contracts  
  ├── l2-contracts/     # L2 infrastructure contracts
  ├── governance/       # DAO governance
  └── interfaces/       # Contract interfaces
  ```

#### Required GCP Services for L2 Operations
- **Cloud Storage**: Contract artifacts, state snapshots, fraud proof data
- **Compute Engine**: Sequencer nodes, validator infrastructure
- **Cloud SQL**: Transaction indexing, state history, bridge records  
- **Cloud Functions**: Event processing, challenge automation, proof generation
- **Cloud Run**: L2 API services, bridge interfaces, governance endpoints
- **Cloud Monitoring**: L2 performance metrics, fraud proof system health
- **Cloud Logging**: Transaction logs, validator events, challenge tracking

## ZSnail L2 Directory Structure (Current Implementation)

```bash
zsnail-l2/                    # Root project directory
├── .env                      # Production environment configuration with Google Cloud integration
├── package.json              # 2025-standard dependencies (Hardhat v3, Ethers v6, Node.js LTS)
├── hardhat.config.ts         # Hardhat configuration for L2 contract deployment
├── copilot-instructions.md   # This file - development guidelines and current status
├── README.md                 # Comprehensive project documentation
├── backend/                  # L2 API backend services
│   ├── src/                  # TypeScript source code for L2 operations
│   │   ├── controllers/      # API controllers for sequencer, bridge, governance
│   │   ├── services/         # Business logic for L2 transaction processing
│   │   ├── middleware/       # Authentication, rate limiting, validation
│   │   └── routes/           # REST API routes for L2 functionality
│   ├── package.json          # Backend-specific dependencies
│   └── tsconfig.json         # TypeScript configuration
├── config/                   # Configuration files
│   └── zsnail-blockchain-5e515e80fbb0.json  # Google Cloud service account (production)
├── scripts/                  # Deployment and utility scripts
│   ├── deploy-l2.ts          # L2 infrastructure deployment
│   ├── bridge-setup.ts       # Cross-layer bridge configuration
│   └── governance-init.ts    # DAO governance initialization
├── tests/                    # Comprehensive test suite
│   ├── unit/                 # Unit tests for individual contracts
│   ├── integration/          # L2 infrastructure integration tests
│   └── fraud-proofs/         # Fraud proof system tests
└── docs/                     # Project documentation
    ├── architecture.md       # L2 architecture and design decisions
    ├── contracts.md          # ZSnail contract library documentation
    └── deployment.md         # Production deployment guides

# Google Cloud Storage Structure (Exclusive Contract Storage)
gs://zsnail-blockchain-storage/contracts/
├── libraries/                # Custom ZSnail Library (16 contracts)
│   ├── ZSnailMath.sol       # Advanced mathematical operations
│   ├── ZSnailSecurity.sol   # Security patterns and access controls
│   ├── ZSnailCrypto.sol     # Cryptographic utilities
│   ├── ZSnailUtils.sol      # Core utility functions
│   ├── ZSnailAccessControl.sol  # Role-based access control
│   ├── ZSnailERC20.sol      # Gas-optimized ERC-20 implementation
│   ├── ZSnailERC721.sol     # Enhanced NFT standard
│   ├── ZSnailERC1155.sol    # Multi-token standard
│   ├── ZSnailTimelock.sol   # Governance delay system
│   ├── ZSnailMulticall.sol  # Batch transaction execution
│   ├── ZSnailUpgradeable.sol    # Secure proxy upgrade patterns
│   ├── ZSnailSignatureChecker.sol   # Advanced signature validation
│   ├── ZSnailMerkleProof.sol        # Efficient merkle tree verification
│   ├── ZSnailOwnable.sol            # Enhanced ownership management
│   ├── ZSnailPausable.sol           # Emergency pause functionality
│   └── ZSnailReentrancyGuard.sol    # Reentrancy attack protection
├── l1-contracts/             # L1 Rollup Infrastructure
│   ├── ZSnailRollup.sol     # L1 assertion management and fraud proofs
│   └── ZSnailSequencerInbox.sol # L1 message routing to L2
├── l2-contracts/             # L2 Core Infrastructure  
│   ├── ZSnailSequencer.sol  # Transaction sequencing and L2 block production
│   ├── ZSnailBridge.sol     # Cross-layer asset transfers
│   └── ZSnailStateManager.sol   # State root management and tracking
├── governance/               # DAO Governance Contracts
│   └── ZSnailGovernance.sol # DAO governance system
└── interfaces/               # Contract Interface Definitions
    └── IZSnailL2.sol        # Core L2 interface definitions
```

**Key Principles**:
- **No Local Contracts**: All smart contracts exist only in Google Cloud Storage
- **Cloud-First Development**: Contract deployment and management through cloud APIs
- **Modular Architecture**: Each contract serves specific L2 operational needs
- **Production Ready**: All contracts are production-quality with comprehensive testing

## ZSnail L2 Security & Production Standards

### 1. Smart Contract Security (Production-Ready)
- **Custom ZSnail Security**: Use ZSnailSecurity.sol instead of OpenZeppelin patterns
- **L2-Specific Protections**: Fraud proof systems, challenge mechanisms, economic incentives
- **Access Control**: ZSnailAccessControl.sol with role-based permissions
- **Economic Security**: Validator staking, sequencer bonds, challenge deposits
- **Fraud Proofs**: 7-day challenge period with automated dispute resolution
- **Bridge Security**: Multi-signature validation, time delays, emergency pause functionality

### 2. L2 Infrastructure Security
- **Sequencer Security**: Staking requirements, slashing conditions, rotation mechanisms
- **State Management**: Merkle proof verification, state root challenges, finality guarantees
- **Bridge Operations**: Asset locking, withdrawal delays, fraud detection systems
- **Validator Network**: Decentralized validation, economic incentives, reputation systems

### 3. Google Cloud Security (Production Configuration)
- **Service Account**: Minimal required permissions for contract storage and deployment
- **IAM Roles**: Restricted access to essential GCP services only
- **Storage Security**: Private bucket with authenticated access, encryption at rest
- **Network Security**: VPC configuration, firewall rules, secure endpoints
- **Audit Logging**: Comprehensive logging of all contract operations and access

### 4. Application Security (2025 Standards)
- **Environment Management**: Secure .env handling, no secrets in version control
- **API Security**: Rate limiting, authentication, input validation, CORS configuration
- **Database Security**: Encrypted connections, parameterized queries, access logging
- **Infrastructure Security**: Container security, dependency scanning, vulnerability management

## L2 Development Workflow (Current Status)

### 1. Contract Development Process
```bash
# Current Status: All core contracts completed and deployed to cloud storage
# Development workflow for new contracts:

# 1. Develop contract locally with ZSnail library imports
# 2. Test with comprehensive fraud proof scenarios  
# 3. Deploy to Google Cloud Storage with versioning
# 4. Update deployment scripts and configuration
# 5. Integrate with L2 infrastructure components
```

### 2. L2 Infrastructure Development
- **Sequencer Development**: Transaction processing, batch creation, fraud proof generation
- **Bridge Development**: Cross-layer message passing, asset transfers, security validations
- **State Management**: State root updates, challenge handling, finality mechanisms
- **Governance Integration**: DAO proposals, voting mechanisms, treasury management

### 3. Testing Strategy (Production Standards)
- **Unit Testing**: Individual contract testing with 95%+ coverage
- **Integration Testing**: L2 infrastructure component interaction testing
- **Fraud Proof Testing**: Challenge scenarios, economic attack simulations
- **Performance Testing**: Gas optimization, throughput testing, scalability validation
- **Security Testing**: Formal verification, audit preparation, penetration testing

## Performance Optimization (L2 Specific)

### 1. Smart Contract Gas Optimization
- **ZSnail Library**: Pre-optimized contracts for L2 gas efficiency
- **Batch Operations**: Multiple transaction processing in single calls
- **State Compression**: Efficient state representation and storage
- **Proof Optimization**: Minimal proof sizes, efficient verification algorithms

### 2. L2 Infrastructure Performance  
- **Sequencer Optimization**: High-throughput transaction processing
- **State Sync**: Efficient L1-L2 state synchronization
- **Bridge Performance**: Fast cross-layer asset transfers
- **Fraud Proof Efficiency**: Quick challenge resolution, minimal computation overhead

### 3. Cloud Infrastructure Scaling
- **Auto-scaling**: Dynamic resource allocation based on L2 usage
- **Load Distribution**: Balanced traffic across multiple sequencer nodes
- **Caching Strategy**: Redis caching for frequently accessed state data
- **Storage Optimization**: Efficient contract artifact storage and retrieval

## ZSnail L2 Documentation & Deployment

### 1. Current Documentation Status
- **Architecture Documentation**: Complete L2 infrastructure design and component interaction
- **Contract Documentation**: NatSpec documentation for all 20+ ZSnail contracts
- **API Documentation**: L2-specific endpoints for sequencer, bridge, and governance operations
- **Deployment Guides**: Production deployment procedures for GCP infrastructure
- **Security Documentation**: Fraud proof system, economic security models, challenge mechanisms

### 2. Production Deployment Configuration
- **Environment Variables**: Production .env with real GCP service account credentials
- **Contract Deployment**: All contracts stored in `gs://zsnail-blockchain-storage`
- **Infrastructure**: Google Cloud Platform with service account authentication
- **Monitoring**: L2 performance metrics, fraud proof system health, validator activity
- **Scaling**: Auto-scaling configuration for sequencer and validator infrastructure

### 3. Current Project Status (September 2025)
```bash
# Completed Components (Production Ready):
✅ ZSnail Custom Library (16 contracts) - Complete OpenZeppelin replacement
✅ L2 Core Infrastructure (4 contracts) - Optimistic rollup with fraud proofs  
✅ Google Cloud Integration - Service account authentication and storage
✅ Economic Security - Staking, challenges, and validator incentives
✅ Cross-Layer Bridge - Support for ETH/ERC20/ERC721/ERC1155 assets
✅ State Management - Efficient tracking and fraud proof verification
✅ 2025 Technology Stack - Modern tools with zero vulnerabilities

# Next Development Phases:
🚧 Governance & DAO Contracts - Voting mechanisms and treasury management
📋 DeFi Protocol Integration - DEX, liquidity pools, yield farming
🔮 Advanced Features - ZK proofs, cross-chain bridges, enterprise tools
```

### 4. Code Review & Quality Standards (2025)
- **Smart Contract Reviews**: Security-focused review with fraud proof scenario validation
- **L2 Infrastructure Reviews**: Performance, scalability, and economic security analysis  
- **Google Cloud Reviews**: Security, cost optimization, and compliance validation
- **Production Readiness**: Zero placeholder code, comprehensive testing, audit preparation

### 5. Next Steps & Roadmap Integration
- **Immediate Focus**: Governance contracts and DAO framework implementation
- **Short-term Goals**: DeFi protocol development and testnet deployment
- **Long-term Vision**: Mainnet launch with complete ecosystem and enterprise features
- **Continuous Improvement**: Performance optimization, security enhancements, community building

---

**IMPORTANT REMINDERS FOR DEVELOPMENT**:

1. **Always Use ZSnail Contracts**: Reference custom library from Google Cloud Storage, never OpenZeppelin
2. **Cloud-First Strategy**: All contract operations through Google Cloud APIs and storage
3. **Production Standards**: No placeholder code, real configurations, comprehensive testing
4. **L2 Optimization**: Gas efficiency, fraud proof integration, economic security mechanisms
5. **2025 Technology**: Latest versions, modern patterns, zero deprecated dependencies
6. **Security Priority**: Fraud proofs, economic incentives, comprehensive access controls

**Current Project State**: Complete L2 blockchain infrastructure with custom contract ecosystem, ready for governance layer development and DeFi protocol integration.