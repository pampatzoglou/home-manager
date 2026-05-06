# Terraform Infrastructure as Code Skill

## Purpose
General methodology and best practices for managing infrastructure as code with Terraform, applicable across any project or cloud provider.

## Core Principles

### Declarative Infrastructure
- Define desired state, not procedural steps
- Terraform handles the "how" of reaching that state
- Infrastructure becomes versionable and reviewable code
- Changes are predictable and reproducible

### Immutability
- Replace rather than modify infrastructure
- Treat servers as cattle, not pets
- Enable easy rollbacks and disaster recovery
- Reduce configuration drift

### Modularity
- Break infrastructure into logical, reusable components
- Single responsibility per module
- Compose complex systems from simple building blocks
- Enable testing and maintenance at module level

## Project Structure Methodology

### Standard Layout
```
terraform-project/
├── main.tf              # Root module orchestration
├── variables.tf         # Input variable definitions
├── outputs.tf           # Output value definitions
├── providers.tf         # Provider configurations
├── versions.tf          # Version constraints
├── backend.tf           # State backend configuration
├── locals.tf            # Local value definitions (optional)
├── data.tf              # Data source definitions (optional)
├── modules/             # Custom reusable modules
│   └── module-name/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── environments/        # Environment-specific configs
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── README.md
```

### File Organization Principles
- **main.tf**: Orchestrates resources and modules
- **variables.tf**: All input variables with types, descriptions, validation
- **outputs.tf**: All outputs with descriptions
- **providers.tf**: Provider version constraints and configuration
- **One resource type per file** (optional): For large projects, split by resource type
- **Module per directory**: Each subdirectory is a self-contained module

## Variable Design

### Type System
Use strong typing for safety and clarity:

```hcl
# Primitive types
variable "instance_count" {
  type        = number
  description = "Number of instances to create"
  default     = 1
}

# Complex types
variable "network_config" {
  type = object({
    cidr_block           = string
    enable_dns_hostnames = bool
    availability_zones   = list(string)
    private_subnets      = list(string)
    public_subnets       = list(string)
  })
  description = "Network configuration settings"
}

# Maps for named resources
variable "instances" {
  type = map(object({
    instance_type = string
    ami           = string
    subnet_id     = string
  }))
  description = "Map of instance configurations by name"
}
```

### Validation Rules
Add validation for constraints:

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR block"
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}
```

### Default Values Strategy
- **Required variables**: No default (force explicit values)
- **Optional with sensible defaults**: Provide safe defaults
- **Environment-specific**: Use tfvars files, not defaults
- **Sensitive values**: No defaults, use external secret management

## Module Design Patterns

### Module Interface
Every module should have clear inputs and outputs:

```hcl
# Module variables (inputs)
variable "name" {
  type        = string
  description = "Resource name"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

# Module outputs
output "id" {
  description = "Resource identifier"
  value       = resource.example.id
}

output "arn" {
  description = "Resource ARN"
  value       = resource.example.arn
}
```

### Composition Over Inheritance
Build complex modules from simpler ones:

```hcl
module "network" {
  source = "./modules/network"
  
  cidr_block = "10.0.0.0/16"
  name       = var.project_name
}

module "compute" {
  source = "./modules/compute"
  
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids
}

module "database" {
  source = "./modules/database"
  
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.database_subnet_ids
}
```

### Module Versioning
For shared modules, use versioning:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  
  # Configuration...
}
```

## State Management

### Remote State Best Practices
- **Always use remote state** for team collaboration
- **Enable versioning** for rollback capability
- **Enable encryption** at rest for sensitive data
- **Implement state locking** to prevent concurrent modifications
- **Separate states** per environment or logical boundary
- **Backup state files** regularly

### Backend Configuration
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "project/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### State Commands
```bash
# List all resources
terraform state list

# Show specific resource
terraform state show 'resource.name'

# Move resource (refactoring)
terraform state mv 'old.resource' 'new.resource'

# Remove from state (without destroying)
terraform state rm 'resource.name'

# Import existing resource
terraform import 'resource.name' 'resource-id'

# Replace resource (force recreation)
terraform apply -replace='resource.name'
```

## Workflow Methodology

### Development Workflow
1. **Write**: Define infrastructure in .tf files
2. **Initialize**: `terraform init` to download providers
3. **Validate**: `terraform validate` for syntax checking
4. **Format**: `terraform fmt` for consistent style
5. **Plan**: `terraform plan` to preview changes
6. **Review**: Examine plan output carefully
7. **Apply**: `terraform apply` to make changes
8. **Verify**: Check actual infrastructure matches expectations

### Team Workflow
1. Create feature branch
2. Make infrastructure changes
3. Run `terraform plan` and review
4. Commit changes to version control
5. Open pull request
6. Team reviews plan output
7. Merge after approval
8. Apply changes in target environment

### Environment Promotion
```bash
# Development
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# Staging
terraform plan -var-file=environments/staging.tfvars
terraform apply -var-file=environments/staging.tfvars

# Production
terraform plan -var-file=environments/prod.tfvars
# Review plan carefully!
terraform apply -var-file=environments/prod.tfvars
```

## Locals and Data Sources

### Locals for Computed Values
Use locals to avoid repetition and compute derived values:

```hcl
locals {
  # Common tags
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  # Computed values
  environment_prefix = "${var.project_name}-${var.environment}"
  
  # Conditional logic
  enable_monitoring = var.environment == "prod" ? true : false
  
  # Transformations
  subnet_cidrs = [
    for idx, az in var.availability_zones :
    cidrsubnet(var.vpc_cidr, 8, idx)
  ]
}
```

### Data Sources for Discovery
Query existing resources or external data:

```hcl
# Find existing resources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }
}

# Query current state
data "aws_caller_identity" "current" {}

# External data
data "http" "my_ip" {
  url = "https://api.ipify.org"
}
```

## Resource Patterns

### For_each for Multiple Resources
```hcl
variable "users" {
  type = map(object({
    email = string
    role  = string
  }))
}

resource "aws_iam_user" "users" {
  for_each = var.users
  
  name = each.key
  tags = {
    Email = each.value.email
    Role  = each.value.role
  }
}
```

### Count for Conditional Resources
```hcl
resource "aws_instance" "optional" {
  count = var.create_instance ? 1 : 0
  
  ami           = var.ami_id
  instance_type = var.instance_type
}
```

### Dynamic Blocks
```hcl
resource "aws_security_group" "example" {
  name = "example"
  
  dynamic "ingress" {
    for_each = var.ingress_rules
    
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

## Lifecycle Management

### Resource Lifecycle
```hcl
resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  lifecycle {
    # Prevent accidental deletion
    prevent_destroy = true
    
    # Create replacement before destroying
    create_before_destroy = true
    
    # Ignore changes to specific attributes
    ignore_changes = [
      tags["LastModified"],
      user_data,
    ]
  }
}
```

### Depends_on for Explicit Dependencies
```hcl
resource "aws_iam_role_policy" "example" {
  depends_on = [aws_iam_role.example]
  
  role   = aws_iam_role.example.name
  policy = data.aws_iam_policy_document.example.json
}
```

## Secret Management

### External Secret Systems
Never store secrets in Terraform code:

```hcl
# Read from environment variables
variable "api_key" {
  type      = string
  sensitive = true
}

# Read from secret management system
data "aws_secretsmanager_secret_version" "api_key" {
  secret_id = "prod/api/key"
}

# Use in resources
resource "example_resource" "app" {
  api_key = data.aws_secretsmanager_secret_version.api_key.secret_string
}
```

### Sensitive Outputs
```hcl
output "database_password" {
  description = "Database admin password"
  value       = random_password.db.result
  sensitive   = true
}
```

## Testing and Validation

### Pre-deployment Validation
```bash
# Format check
terraform fmt -check -recursive

# Syntax validation
terraform validate

# Security scanning
tfsec .
checkov --directory .

# Policy as code
terraform plan -out=plan.tfplan
sentinel apply policy.sentinel plan.tfplan
```

### Manual Testing Checklist
- [ ] Code formatted with `terraform fmt`
- [ ] Validation passes
- [ ] Plan output reviewed and understood
- [ ] No unintended resource deletions
- [ ] Security scan passes
- [ ] Compliance checks pass
- [ ] Documentation updated
- [ ] Variables have descriptions
- [ ] Outputs are documented

### Automated Testing
Consider tools like Terratest for integration testing:
- Unit tests for modules
- Integration tests for complete stacks
- Validation tests for compliance
- Cost estimation tests

## Troubleshooting Methodology

### Plan Issues
1. Check provider configuration and authentication
2. Verify variable values are correct
3. Review data source queries
4. Check for circular dependencies
5. Examine provider version compatibility

### Apply Failures
1. Read error message carefully (often very descriptive)
2. Check resource quotas and limits
3. Verify permissions and IAM policies
4. Review resource dependencies
5. Check for naming conflicts
6. Validate input values

### State Issues
1. Ensure backend is accessible
2. Check for state lock (resolve or force-unlock)
3. Verify state file integrity
4. Review recent state modifications
5. Consider state refresh: `terraform refresh`

### Debug Mode
```bash
# Enable verbose logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Run operation
terraform apply

# Review logs
cat terraform.log
```

## Performance Optimization

### Parallelism
```bash
# Increase parallel operations (default: 10)
terraform apply -parallelism=20

# Decrease for rate-limited APIs
terraform apply -parallelism=5
```

### Targeted Operations
```bash
# Target specific resource
terraform apply -target=module.vpc

# Multiple targets
terraform apply -target=module.vpc -target=module.compute
```

### Refresh Control
```bash
# Skip refresh for faster planning
terraform plan -refresh=false

# Refresh specific resources
terraform plan -refresh=true -target=module.vpc
```

## Best Practices Summary

### Code Quality
- Use consistent formatting (`terraform fmt`)
- Implement input validation
- Add comprehensive descriptions
- Follow naming conventions
- Keep modules focused and small
- Document all variables and outputs

### Security
- Never commit secrets to version control
- Use `sensitive = true` for sensitive outputs
- Implement least privilege IAM policies
- Enable encryption for state files
- Regular security scanning (tfsec, checkov)
- Rotate credentials regularly

### Reliability
- Use remote state with locking
- Version provider plugins
- Implement lifecycle rules appropriately
- Plan before every apply
- Test in non-production first
- Have rollback procedures

### Maintainability
- Write clear, descriptive comments
- Use modules for reusable components
- Keep DRY (Don't Repeat Yourself)
- Maintain documentation
- Use workspace or separate states per environment
- Regular dependency updates

### Collaboration
- Code review all changes
- Share plan outputs before applying
- Use consistent environments
- Document decisions and architecture
- Standardize module interfaces
- Version control everything

## Common Pitfalls to Avoid

1. **Hardcoding values**: Use variables instead
2. **No state locking**: Always enable locking for teams
3. **Mixing environments**: Separate states per environment
4. **Ignoring plan output**: Always review before applying
5. **No variable validation**: Add validation rules
6. **Committing secrets**: Use external secret management
7. **No module versioning**: Pin versions for stability
8. **Monolithic configurations**: Break into logical modules
9. **No documentation**: Document complex logic and decisions
10. **Manual changes**: All changes should go through Terraform

## Reference Patterns

### Environment Strategy
- Separate workspaces OR separate state files
- Environment-specific tfvars files
- Consistent module usage across environments
- Environment-specific sizing/scaling

### Module Organization
- Public modules from registry for common patterns
- Private modules for organization-specific needs
- Versioned modules for stability
- Well-documented interfaces

### State Organization
- One state per application/service
- Separate states per environment
- Use remote state data sources to share outputs
- Regular state backups

### CI/CD Integration
- Automated `terraform plan` on pull requests
- Manual approval before `terraform apply`
- Automated testing and validation
- State file access from CI/CD only