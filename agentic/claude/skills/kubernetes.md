# Kubernetes Resources Management Skill

## Purpose
Best practices for managing Kubernetes resources following GitOps principles and platform architecture conventions.

## Repository Structure Conventions

### Standard Component Layout
```
component-name/
├── chart-name/
│   ├── Chart.yaml
│   ├── values.yaml           # Base values
│   ├── defaults/
│   │   └── values.yaml       # Default values for all environments
│   ├── dev/
│   │   └── values.yaml       # Development-specific values
│   ├── testing/
│   │   └── values.yaml       # Testing-specific values
│   ├── prod/
│   │   └── values.yaml       # Production-specific values
│   ├── templates/
│   │   ├── _helpers.tpl
│   │   └── *.yaml            # Kubernetes manifests
│   └── README.md
```

### Multi-Environment Strategy
- **Base values**: Common configuration across all environments
- **Defaults**: Sensible defaults that can be overridden
- **Environment-specific**: Override defaults for each environment (dev, testing, prod)
- **Values hierarchy**: `values.yaml` → `defaults/values.yaml` → `{env}/values.yaml`

## GitOps with ArgoCD

### Sync Wave Strategy
Use ArgoCD sync waves to control deployment order:

| Wave | Tier | Purpose | Examples |
|------|------|---------|----------|
| -10 | Absolute Prerequisites | CRDs that must exist first | datadog-crds |
| -8 | Security Foundations | Security and secrets | external-secrets, vault |
| -5 | Networking Essentials | Network and certificates | cert-manager, external-dns, gateway CRDs |
| 0 | Core Operators | Database and data operators | cnpg, kafka, clickhouse |
| 3 | Monitoring Stack | Observability components | datadog, trivy, grafana |
| 5 | Platform Tools | Supporting utilities | reloader, kubescape, velero |
| 10+ | Workloads/Applications | Actual applications | User applications |

### ApplicationSet Pattern
Use ApplicationSets for managing multiple similar applications:
- Group related applications together
- Apply consistent patterns across environments
- Reduce duplication in ArgoCD configuration
- Enable dynamic application generation

## Helm Chart Best Practices

### Chart Structure
- **Chart.yaml**: Define chart metadata, version, dependencies
- **values.yaml**: User-facing configuration options
- **templates/**: Kubernetes resource templates
- **_helpers.tpl**: Reusable template functions
- **README.md**: Chart documentation and usage

### Values File Organization
```yaml
# Resource configuration
resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Replica configuration
replicaCount: 2

# Security context
podSecurityContext:
  fsGroup: 99
  runAsUser: 99
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

### Template Helpers
Create reusable template functions in `_helpers.tpl`:
- Chart name and fullname
- Label selectors
- Service account names
- Image pull secrets
- Common annotations

## Kubernetes Resource Standards

### Security Best Practices

#### Pod Security Context
Always define security contexts:
```yaml
podSecurityContext:
  fsGroup: 101
  runAsUser: 101
  runAsGroup: 101
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true  # When possible
```

#### RBAC
- Use least privilege principle
- Create dedicated ServiceAccounts
- Define specific Role/ClusterRole permissions
- Avoid cluster-admin unless absolutely necessary

### Resource Management

#### Resource Requests and Limits
Always specify for all containers:
```yaml
resources:
  limits:
    cpu: "1"
    memory: 2Gi
  requests:
    cpu: 100m
    memory: 128Mi
```

#### Storage
- Use PersistentVolumes for stateful workloads
- Specify appropriate StorageClass (e.g., `linstor-csi-lvm`)
- Set realistic size requirements
- Consider tiered storage for data-intensive applications

### High Availability

#### Pod Anti-Affinity
Spread pods across nodes and zones:
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: myapp
          topologyKey: kubernetes.io/hostname
```

#### Topology Spread Constraints
Ensure even distribution across zones:
```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
```

#### Pod Disruption Budgets
Protect availability during disruptions:
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: myapp
```

#### Rack Awareness
For distributed systems (Kafka, databases):
```yaml
rackAwareness:
  enabled: true
  nodeAnnotation: topology.kubernetes.io/zone
```

### Health Checks

#### Liveness Probes
Detect when to restart containers:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

#### Readiness Probes
Detect when pods are ready for traffic:
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

#### Startup Probes
For slow-starting applications:
```yaml
startupProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 30
```

## Operator-Based Resources

### Custom Resources
When deploying operator-managed resources:
- Use the operator's CRDs (e.g., Redpanda, CNPG, Kafka)
- Follow operator-specific best practices
- Leverage operator features (auto-scaling, backup, monitoring)
- Set appropriate `cluster.redpanda.com/managed: "true"` annotations

### Database Operators

#### CloudNative PostgreSQL (CNPG)
- Use `Cluster` CRD for PostgreSQL clusters
- Configure backup and recovery
- Set resource limits appropriately
- Enable monitoring integration

#### ClickHouse Operator
- Use `ClickHouseInstallation` CRD
- Configure sharding and replication
- Set up distributed tables correctly
- Plan storage requirements

### Data Streaming

#### Kafka/Redpanda
- Use operator CRDs (`Kafka`, `Redpanda`)
- Configure SASL authentication (SCRAM-SHA-256)
- Enable TLS for all listeners
- Configure tiered storage for large deployments
- Set appropriate retention policies
- Use separate CRDs for Topics and Users

Example Kafka Topic:
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: my-topic
  labels:
    strimzi.io/cluster: my-cluster
spec:
  partitions: 6
  replicas: 3
  config:
    retention.ms: 604800000  # 7 days
    segment.bytes: 1073741824
    compression.type: producer
```

## Platform Integration

### TLS/Certificates
- Use cert-manager for certificate management
- Define Certificate resources for custom domains
- Use Let's Encrypt for public certificates
- Internal certificates via internal CA

### Secrets Management
- Use external-secrets operator for secret synchronization
- Never commit secrets to git
- Reference secrets from external sources (Vault, AWS Secrets Manager)
- Use RBAC to restrict secret access

### DNS Management
- Use external-dns for automatic DNS record creation
- Annotate Services/Ingress for DNS automation
- Follow DNS naming conventions

### Monitoring Integration
- Add Prometheus annotations for metrics scraping
- Use ServiceMonitor CRDs when available
- Configure DataDog integration
- Export meaningful metrics
- Set up appropriate alerts

### Networking
- Use Gateway API for advanced routing
- Configure NetworkPolicies for pod-to-pod security
- Use appropriate Service types (ClusterIP, NodePort, LoadBalancer)
- Leverage service mesh when needed

## Development Workflow

### Local Development
1. Create or modify chart in appropriate directory
2. Update values in `defaults/values.yaml` for common config
3. Add environment-specific overrides in `{env}/values.yaml`
4. Test with `helm template` or `just template-{component}`

### Templating Charts
Use justfile recipes for templating:
```bash
# Template single component
just template-cert-manager dev 1.33

# Template all components for an environment
just template dev 1.33
```

### Helm Template Command Structure
```bash
helm template RELEASE ./namespace/chart \
  --namespace NAMESPACE \
  --include-crds \
  --output-dir .argo/namespace \
  --kube-version 1.33 \
  --api-versions monitoring.coreos.com/v1 \
  --values namespace/chart/values.yaml \
  --values namespace/chart/defaults/values.yaml \
  --values namespace/chart/{env}/values.yaml
```

### Validation Checklist
Before committing changes:

- [ ] Chart templates successfully with `helm template`
- [ ] All required values are documented
- [ ] Security contexts are properly configured
- [ ] Resource limits and requests are set
- [ ] Health checks are configured
- [ ] High availability settings are appropriate
- [ ] Environment-specific values are correct
- [ ] README is updated with any changes
- [ ] CRDs are included if needed
- [ ] Dependencies are documented in Chart.yaml

### Deployment Process
1. Commit changes to git repository
2. ArgoCD detects changes automatically
3. ArgoCD syncs in order based on sync waves
4. Monitor deployment in ArgoCD UI or CLI
5. Verify resources are healthy
6. Check logs and metrics

## Troubleshooting

### Common Issues

#### Pods Not Starting
- [ ] Check resource availability on nodes
- [ ] Verify image pull secrets
- [ ] Check PVC binding status
- [ ] Review security context restrictions
- [ ] Examine pod events: `kubectl describe pod`

#### Sync Failures in ArgoCD
- [ ] Check sync wave ordering
- [ ] Verify CRDs are installed first
- [ ] Review resource dependencies
- [ ] Check RBAC permissions
- [ ] Examine ArgoCD application events

#### Storage Issues
- [ ] Verify StorageClass exists
- [ ] Check PVC status and events
- [ ] Ensure sufficient storage capacity
- [ ] Review volume provisioner logs
- [ ] Check node storage availability

#### Networking Issues
- [ ] Verify Service selectors match pod labels
- [ ] Check NetworkPolicy rules
- [ ] Review DNS resolution
- [ ] Test connectivity between pods
- [ ] Examine ingress/gateway configuration

### Debugging Commands
```bash
# Check pod status and events
kubectl get pods -n NAMESPACE
kubectl describe pod POD_NAME -n NAMESPACE

# View logs
kubectl logs POD_NAME -n NAMESPACE
kubectl logs POD_NAME -c CONTAINER -n NAMESPACE --previous

# Check resource status
kubectl get all -n NAMESPACE
kubectl get pvc -n NAMESPACE

# Debug with ephemeral container
kubectl debug POD_NAME -it --image=busybox -n NAMESPACE

# Port forward for testing
kubectl port-forward svc/SERVICE_NAME 8080:80 -n NAMESPACE

# Check ArgoCD application
kubectl get application -n argocd
kubectl describe application APP_NAME -n argocd
```

## Platform-Specific Patterns

### Node Selection
Use node selectors for workload placement:
```yaml
nodeSelector:
  node.kubernetes.io/type: state  # For stateful workloads
```

### Priority Classes
Set appropriate priority for critical workloads:
```yaml
priorityClassName: high  # For critical platform components
```

### Schedulers
Use custom schedulers when needed:
```yaml
schedulerName: linstor-scheduler  # For storage-aware scheduling
```

## Documentation Requirements

### Chart README Template
- **Description**: What the chart deploys
- **Prerequisites**: Required dependencies or setup
- **Installation**: How to deploy the chart
- **Configuration**: Key values and their purpose
- **Upgrading**: Upgrade procedures and considerations
- **Uninstalling**: How to remove the chart
- **Troubleshooting**: Common issues and solutions

### Values Documentation
Document all values with:
- Description of purpose
- Default value
- Type (string, int, bool, object)
- Required vs optional
- Valid options or constraints

## Security Considerations

### Secrets
- Use external-secrets operator
- Rotate credentials regularly
- Limit secret access via RBAC
- Audit secret usage

### Network Security
- Implement NetworkPolicies
- Use TLS for all communication
- Require authentication (SASL, mTLS)
- Isolate sensitive workloads

### RBAC
- Follow least privilege
- Use dedicated service accounts
- Regular RBAC audits
- Document permission requirements

### Image Security
- Use specific image tags (not `latest`)
- Scan images for vulnerabilities
- Use trusted registries
- Implement image pull policies

## Best Practices Summary

1. **Always use GitOps**: All changes via git, synced by ArgoCD
2. **Multi-environment support**: Separate values for dev/testing/prod
3. **Security first**: SecurityContext, RBAC, NetworkPolicies
4. **High availability**: Replicas, anti-affinity, PDBs
5. **Resource management**: Set limits and requests
6. **Health checks**: Liveness, readiness, startup probes
7. **Observability**: Metrics, logs, traces
8. **Documentation**: README, values documentation
9. **Testing**: Template locally before committing
10. **Monitoring**: Watch deployments and set up alerts