# Petclinic Platform — AWS Infrastructure

Production AWS infrastructure for [Spring Petclinic Microservices](https://github.com/spring-petclinic/spring-petclinic-microservices) (8 services, Spring Boot, Spring Cloud).

## Repository Structure

```
petclinic-platform/
│
├── terraform/                    # Infrastructure as Code
│   ├── environments/
│   │   ├── dev/                  # Dev environment root module
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── backend.tf        # S3 state: petclinic/dev/terraform.tfstate
│   │   │   └── terraform.tfvars
│   │   └── prod/                 # Prod environment root module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── backend.tf        # S3 state: petclinic/prod/terraform.tfstate
│   │       └── terraform.tfvars
│   └── modules/                  # Reusable modules
│       ├── vpc/                  # VPC, subnets, IGW, security groups (all-public, no NAT)
│       ├── eks/                  # EKS cluster, node groups, OIDC, IAM
│       ├── ecr/                  # ECR repos (per service per env), lifecycle policies
│       ├── rds/                  # RDS MySQL, subnet group, parameter group
│       ├── dns/                  # Route 53, ACM certificates
│       ├── secrets/              # Secrets Manager resources
│       └── observability/        # Prometheus, Grafana, CloudWatch, FluentBit
│
├── k8s/                          # Kubernetes Manifests
│   ├── base/                     # Base manifests (shared across envs)
│   │   ├── namespaces.yaml
│   │   ├── config-server/        # Deployment, Service, ConfigMap
│   │   ├── discovery-server/
│   │   ├── api-gateway/
│   │   ├── customers-service/
│   │   ├── visits-service/
│   │   ├── vets-service/
│   │   ├── genai-service/
│   │   ├── admin-server/
│   │   ├── ingress/              # ALB Ingress Controller config
│   │   └── external-secrets/     # ExternalSecret resources (AWS Secrets Manager)
│   └── overlays/                 # Environment-specific patches
│       ├── dev/                  # Dev: fewer replicas, smaller resources
│       └── prod/                 # Prod: more replicas, larger resources, HPA
│
├── helm/                            # Helm Charts
│   └── petclinic-service/           # Generic chart (shared by all 8 services)
│
├── helm-values/                     # Per-service YAML + per-env (dev.yaml, prod.yaml)
│
├── .github/workflows/            # CI (GitHub Actions — ArgoCD handles CD)
│   ├── build-push.yml            # Build images, push to ECR
│   └── update-image-tags.yml     # Commit image tag updates → ArgoCD deploys
│
├── scripts/                      # Operational scripts
│   ├── bootstrap-state.sh        # Create S3 bucket + DynamoDB for TF state
│   └── ecr-login.sh              # ECR authentication helper
│
└── docs/                         # Operational Documentation
    ├── architecture.md           # Infrastructure architecture & diagrams
    ├── runbook.md                # Day-2 operations (restart, scale, rollback)
    ├── incident-playbook.md      # Common failures & fixes
    ├── onboarding.md             # New engineer setup guide
    └── adr/                      # Architecture Decision Records
        └── 0001-public-subnets.md  # All-public subnet design decision
```

## Tech Stack

| Layer | Tool | Details |
|-------|------|---------|
| Cloud | AWS | eu-central-1 |
| IaC | Terraform >= 1.6 | AWS provider ~> 5.0, S3 + DynamoDB state |
| Cluster | Amazon EKS | Managed node groups, OIDC |
| Registry | Amazon ECR | One repo per service per env, lifecycle policies, scan-on-push |
| Database | Amazon RDS MySQL | Single-AZ both envs (cost optimization) |
| DNS | Route 53 + ACM | TLS termination at ALB |
| Secrets | AWS Secrets Manager | External Secrets Operator in K8s |
| Ingress | AWS ALB Ingress Controller | Public ALB → API Gateway service |
| Observability | Prometheus + Grafana | Micrometer metrics, dashboards, alerts |
| Logging | FluentBit + CloudWatch | Centralized log aggregation |
| Tracing | Zipkin | Distributed tracing (OpenTelemetry) |
| CI | GitHub Actions | OIDC → AWS, build → push ECR → commit image tag |
| CD | ArgoCD | GitOps — watches Git, auto-sync (dev), manual sync (prod) |
| Packaging | Helm | Generic chart, per-service + per-env values |
| Node Scaling | Karpenter | NodePools, EC2NodeClass, Spot diversification |

## Environments

| Environment | K8s Namespace | RDS | Purpose |
|-------------|---------------|-----|---------|
| dev | `petclinic-dev` | db.t4g.micro, single-AZ (free tier) | Development & testing |
| prod | `petclinic-prod` | db.t4g.micro, single-AZ (free tier) | Production |

---

# Prompts del curso:
## Lección 19:
Usa el MCP server de Atlassian para leer la Epica "EPIC E-1 Foundation & Remote State" del archivo docs/jira-backlog.md. Implementa las 5 historias PETPLAT-1 a PETPLAT-5. Para cada historia lee los criterios de aceptación y las referencias a las especificaciones técnicas en docs/technical-spec.md. Comienza con la estructura de directorios de PETPLAT-1, despues sigue con el script de inicialización de PETPLAT-2, despues con los backends PETPLAT-3 y PETPLAT-4, y por último con los providers y versiones de PETPLAT-5.
## Lección 24:
Lee las siguientes historias de docs/jira-backlog.md:
- PETPLAT-6: Create VPC module — VPC, subnets, IGW
- PETPLAT-8: Create baseline security groups
- PETPLAT-9: Wire VPC module into dev environment
- PETPLAT-10: Wire VPC module into prod environment
Lee las especificaciones técnicas de docs/technical-specs.md, concretamente:
- Sección VPC Network Design
- Sección Security Groups
- Sección Terraform modules
Construye todo lo requerido por las historias. Sigue extrictamente los criterios de aceptación. Cuando termines, ejecuta terraform validate en ambos entornos dev y prod.
Después usa el agente terraform-reviewer para revisar el módulo y el agente security-auditor para la seguridad y buenas prácticas.
Arregla cualquier inicdencia o fallo encontrado por los revisores, después valida de nuevo. 
## Lección 29 - Creación del cluster EKS
Lee las siguientes historias de docs/jira-backlog.md:
- PETPLAT-12: Create EKS module — cluster and IAM roles
- PETPLAT-13: Add managed node group to EKS module
- PETPLAT-14: Create kubectl access configuration
- PETPLAT-15: Wire EKS module into dev environment
- PETPLAT-16: Deploy and verify dev EKS cluster
- PETPLAT-17: Wire EKS module into prod environment
- PETPLAT-84: Manage EKS add-ons via Terraform
Construye todo lo requerido por las historias. Sigue extrictamente los criterios de aceptación. Cuando termines, ejecuta terraform validate en ambos entornos dev y prod.
Después usa el agente terraform-reviewer para revisar el módulo y el agente security-auditor para la seguridad y buenas prácticas.
Arregla cualquier inicdencia o fallo encontrado por los revisores, después valida de nuevo. 