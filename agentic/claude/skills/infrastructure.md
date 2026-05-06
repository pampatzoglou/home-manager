# Infrastructure & DevOps Skill

## Purpose
Best practices for infrastructure as code, deployments, and operations.

## Core Principles
- **Declarative**: Define desired state, let tools converge
- **Immutable**: Replace rather than modify infrastructure
- **Version Controlled**: All configuration in git
- **Automated**: Manual steps are bugs waiting to happen
- **Observable**: Metrics, logs, and traces for all systems
- **Reproducible**: Same inputs produce same outputs

## Terraform Best Practices

### Structure
- Use modules for reusable components
- Separate environments (dev, staging, prod)
- One state file per environment/application
- Directory structure by domain/team

### State Management
- Remote state with locking (S3 + DynamoDB, Terraform Cloud)
- Never commit state files to git
- Use state encryption
- Regular state backups

### Code Quality
- Run `terraform fmt` before commit
- Run `terraform validate` in CI
- Use `tflint` for linting
- Plan before apply, review changes carefully
- Use variables and locals for DRY
- Tag all resources consistently

### Variables & Outputs
- Use `variables.tf` for inputs
- Use `outputs.tf` for exports
- Provide descriptions and types
- Use validation rules where appropriate
- Sensitive variables marked as sensitive

### Security
- Use data sources for sensitive values
- Rotate credentials regularly
- Least privilege IAM policies
- Enable encryption by default
- Review terraform plan for credential exposure

## Kubernetes Best Practices

### Resource Management
- Resource requests and limits on all containers
- Use namespaces for logical separation
- LimitRanges and ResourceQuotas per namespace
- Horizontal Pod Autoscaling (HPA) for scalability
- Pod Disruption Budgets (PDB) for availability

### Health & Reliability
- Liveness probes (is it running?)
- Readiness probes (is it ready for traffic?)
- Startup probes (for slow-starting apps)
- Graceful shutdown handling
- Pod anti-affinity for HA

### Configuration & Secrets
- ConfigMaps for configuration
- Secrets for sensitive data (or external secret managers)
- Use volumes, not environment variables for large configs
- Immutable ConfigMaps/Secrets for safe rollbacks
- Version configuration with releases

### Security
- RBAC for least-privilege access
- Network policies for pod-to-pod communication
- Pod Security Standards (restricted profile)
- Non-root containers
- Read-only root filesystems where possible
- Security Context constraints

### Deployment Strategies
- Rolling updates as default
- Blue/green for critical services
- Canary deployments for risk mitigation
- GitOps for declarative deployments (ArgoCD, Flux)
- Helm for complex application packaging

### Observability
- Structured logging to stdout/stderr
- Prometheus metrics exported
- Distributed tracing for microservices
- Service mesh for advanced traffic management (Istio, Linkerd)

## Monitoring & Observability

### The Three Pillars

#### Metrics
- Prometheus + Grafana stack
- Four Golden Signals: Latency, Traffic, Errors, Saturation
- USE method: Utilization, Saturation, Errors
- RED method: Rate, Errors, Duration
- Business metrics alongside technical metrics

#### Logs
- Structured logging (JSON format)
- Centralized aggregation (ELK, Loki, CloudWatch)
- Correlation IDs for request tracing
- Appropriate log levels
- Log retention policies

#### Traces
- Distributed tracing (Jaeger, Tempo, X-Ray)
- Critical path identification
- Performance bottleneck detection
- Cross-service request flows

### Alerting
- Alert on symptoms, not causes
- Actionable alerts only
- Low false-positive rate
- Clear runbooks for each alert
- Page for user-impacting issues only
- Escalation policies defined

### Dashboards
- Focus on key SLIs/SLOs
- Multiple levels: overview, service, component
- Avoid vanity metrics
- Include deployment markers
- Link to runbooks

## Security

### Secrets Management
- Never commit secrets to git
- Use secret managers (Vault, AWS Secrets Manager, sealed-secrets)
- Rotate secrets regularly
- Audit secret access
- Principle of least privilege

### Network Security
- Network segmentation and policies
- Zero-trust architecture
- TLS everywhere (mTLS between services)
- Private networks for data layers
- DDoS protection at edge

### Vulnerability Management
- Regular security scans (Trivy, Snyk, Grype)
- Dependency updates automated (Dependabot, Renovate)
- Container image scanning in CI/CD
- Runtime security monitoring
- Security patch SLAs

### Access Control
- RBAC and least privilege
- Multi-factor authentication (MFA)
- Regular access reviews
- Audit logging enabled
- Separate admin accounts

### Compliance
- Encryption at rest and in transit
- Data residency requirements
- Audit trails for compliance
- Regular security assessments
- Incident response procedures

## CI/CD Best Practices

### Pipeline Design
- Fast feedback loops
- Fail fast on errors
- Idempotent deployments
- Automated testing gates
- Manual approval for production

### Testing Stages
- Lint and format checks
- Unit tests
- Integration tests
- Security scans
- Performance tests (where applicable)

### Deployment
- Automated deployments to dev/staging
- Approval gates for production
- Rollback capability
- Deployment notifications
- Post-deployment verification

### Artifacts
- Immutable artifact IDs (git SHA, semantic version)
- Artifact signing and verification
- Artifact retention policies
- Promotion between environments

## Disaster Recovery

### Backups
- Regular automated backups
- Test restore procedures regularly
- Off-site backup storage
- Backup encryption
- Document RPO/RTO

### High Availability
- Multi-AZ/region deployments
- Active-active when possible
- Failover procedures documented and tested
- Graceful degradation
- Circuit breakers for dependencies

## Nix-Specific Infrastructure

### NixOS Deployment
- Declarative system configuration
- Atomic updates and rollbacks
- Reproducible system builds
- Use flakes for dependency management
- Remote deployment with NixOps or deploy-rs

### Development Environments
- Use nix-shell or direnv for project environments
- Pin dependencies with flake.lock
- Share development environments across team
- Use cachix for binary caches

## Cost Optimization
- Right-size resources
- Auto-scaling policies
- Reserved instances for stable workloads
- Spot instances for fault-tolerant workloads
- Regular cost reviews
- Tag resources for cost allocation

## Documentation
- Architecture diagrams (C4 model)
- Runbooks for common operations
- Incident response procedures
- Disaster recovery procedures
- Onboarding documentation