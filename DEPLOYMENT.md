# ZSnail L2 Blockchain - Deployment Guide

## Current Deployment Status 🚀

**Status:** ✅ LIVE AND OPERATIONAL  
**Deployment Date:** September 19, 2025  
**External IP:** `34.122.156.185:8545`  
**Chain ID:** `66875` (0x1053b)  

## Infrastructure Overview

### Kubernetes Cluster

- **Cluster:** `gke-zsnail-l2-cluster-upgraded-pool`
- **Zone:** `us-central1-a`
- **Hardware:** `n2-standard-4` (4 vCPUs, 16GB RAM)
- **Namespace:** `zsnail-l2`
- **Load Balancer:** Active with external IP

### Deployment Architecture

```text
Google Cloud Platform
├── Kubernetes Engine
│   ├── zsnail-l2 namespace
│   │   ├── zsnail-sequencer deployment
│   │   ├── zsnail-sequencer-service (LoadBalancer)
│   │   └── zsnail-config ConfigMap
│   └── Container Registry (gcr.io/zsnail-blockchain)
├── Cloud Storage
│   └── zsnail-blockchain-storage bucket
└── Service Account Authentication
```

## Configuration Management

### Environment Variables Deployment

The blockchain configuration is managed through Kubernetes ConfigMaps:

1. **Create ConfigMap from .env file:**

   ```bash
   kubectl create configmap zsnail-config --from-file=.env -n zsnail-l2
   ```

2. **Update deployment to use ConfigMap:**

   ```bash
   kubectl patch deployment zsnail-sequencer -n zsnail-l2 -p '{"spec":{"template":{"spec":{"containers":[{"name":"sequencer","envFrom":[{"configMapRef":{"name":"zsnail-config"}}]}]}}}}'
   ```

3. **Apply configuration changes:**

   ```bash
   kubectl rollout restart deployment zsnail-sequencer -n zsnail-l2
   ```

### Configuration Update Process

1. Update the `.env` file with new configuration
2. Delete existing ConfigMap: `kubectl delete configmap zsnail-config -n zsnail-l2`
3. Create new ConfigMap from updated file
4. Restart deployment to apply changes
5. Verify deployment: `kubectl rollout status deployment zsnail-sequencer -n zsnail-l2`

## Current Configuration Status

### ✅ Successfully Deployed

- Kubernetes cluster and networking
- Load balancer with external IP
- ConfigMap with environment variables
- Container deployment and scaling
- Health checks and monitoring

### ⚠️ Configuration Mismatch

Current blockchain values may not reflect .env configuration:

- **Expected:** Block reward `25T ZSNAIL`, Gas price `1.388T wei`
- **Actual:** Block reward `1 ETH`, Gas price `1 Gwei`

This suggests the sequencer code may have hardcoded defaults that override environment variables.

## Verification Commands

### Check Deployment Status

```bash
kubectl get pods -n zsnail-l2
kubectl get services -n zsnail-l2
kubectl describe deployment zsnail-sequencer -n zsnail-l2
```

### Monitor Rollouts

```bash
kubectl rollout status deployment zsnail-sequencer -n zsnail-l2
kubectl rollout history deployment zsnail-sequencer -n zsnail-l2
```

### Check Configuration

```bash
kubectl get configmap zsnail-config -n zsnail-l2 -o yaml
kubectl describe configmap zsnail-config -n zsnail-l2
```

### Test Blockchain Endpoints

```bash
curl http://34.122.156.185:8545/health
curl http://34.122.156.185:8545/info
curl http://34.122.156.185:8545/gas/rate
```

## Troubleshooting

### Common Issues

1. **Configuration not applied:** Restart deployment after ConfigMap update
2. **External IP not accessible:** Check LoadBalancer service status
3. **Pod not starting:** Check logs with `kubectl logs deployment/zsnail-sequencer -n zsnail-l2`

### Debug Commands

```bash
# Check pod logs
kubectl logs deployment/zsnail-sequencer -n zsnail-l2 --follow

# Exec into pod
kubectl exec -it deployment/zsnail-sequencer -n zsnail-l2 -- /bin/bash

# Check environment variables in pod
kubectl exec deployment/zsnail-sequencer -n zsnail-l2 -- env | grep ZSNAIL
```

## Security Best Practices

### Environment Variables

- ✅ `.env` file is gitignored for security
- ✅ Sensitive data stored in Kubernetes secrets
- ✅ Service account authentication configured
- ✅ Template `.env.example` provided for documentation

### Access Control

- ✅ Kubernetes RBAC configured
- ✅ Google Cloud IAM permissions set
- ✅ Network security groups configured
- ✅ Load balancer with health checks

## Next Steps

### Immediate

1. Investigate configuration mismatch between .env and live blockchain
2. Consider updating sequencer code to properly read environment variables
3. Implement proper configuration validation

### Future Enhancements

1. Implement blue-green deployments
2. Add monitoring and alerting
3. Set up automated backups
4. Configure horizontal pod autoscaling

## Support & Maintenance

For deployment issues or questions:

1. Check the troubleshooting section above
2. Review Kubernetes logs and events
3. Verify configuration files and environment variables
4. Test individual components (networking, storage, authentication)

---

*Last updated: September 19, 2025*  
*Deployment managed via Kubernetes ConfigMaps*
