# ECS Fargate CI/CD Pipeline

![CI Pipeline](https://github.com/sh3r44z/fastapi-cicd/actions/workflows/ci.yml/badge.svg)

A production-style deployment pipeline that takes a containerised Python API from a code push to a live URL on AWS — automatically, with zero downtime.

Infrastructure is provisioned entirely with Terraform. Every push to main triggers a GitHub Actions pipeline that runs tests, builds a Docker image, pushes it to ECR, and kicks off a rolling deploy on ECS Fargate.

**Live URL:** http://fastapi-cicd-alb-1905129174.af-south-1.elb.amazonaws.com

---

## Stack

| Tool | Purpose |
|---|---|
| Terraform | Infrastructure as code |
| AWS ECS Fargate | Serverless container runtime |
| AWS ALB | Load balancing and health checks |
| AWS ECR | Container image registry |
| AWS VPC | Networking, subnets, security groups |
| AWS IAM | Least-privilege task execution roles |
| AWS CloudWatch | Container log aggregation |
| GitHub Actions | CI/CD pipeline |
| FastAPI | The application being deployed |

---

## Architecture

```
Developer pushes to main
        │
        ▼
┌─────────────────────────────────┐
│         GitHub Actions          │
│                                 │
│  1. pytest (tests must pass)    │
│  2. docker buildx (linux/amd64) │
│  3. push to ECR                 │
│  4. ecs update-service          │
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│            AWS ECS              │
│                                 │
│  Rolling deploy                 │
│  New task starts → health check │
│  passes → old task drained      │
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│     Application Load Balancer   │
│     af-south-1 (Cape Town)      │
│                                 │
│  Routes traffic across 2 AZs    │
│  Health check: GET /health      │
└─────────────────────────────────┘
```

---

## Terraform Infrastructure

```
terraform/
├── main.tf                  Root module, wires everything together
├── variables.tf             Input variables with defaults
├── outputs.tf               ALB DNS name, cluster and service names
├── backend.tf               Remote state in S3 with locking
└── modules/
    ├── vpc/                 VPC, public subnets, IGW, route tables
    ├── alb/                 ALB, target group, listener, security group
    └── ecs/                 ECS cluster, task definition, service, IAM role
```

### Resources created

| Resource | Details |
|---|---|
| VPC | 10.0.0.0/16 with DNS hostnames enabled |
| Subnets | 2 public subnets across af-south-1a and af-south-1b |
| ALB | Internet-facing, HTTP on port 80 |
| Target group | IP-based, health check on /health |
| ECS cluster | Fargate launch type |
| Task definition | 256 CPU units, 512MB memory |
| IAM role | AmazonECSTaskExecutionRolePolicy only |
| CloudWatch | Log group with 7 day retention |

---

## Pipeline

```
push to main
    → pytest
        → docker buildx build --platform linux/amd64
            → push to ECR (commit SHA tag + latest)
                → aws ecs update-service --force-new-deployment
                    → rolling deploy with zero downtime
```

The deploy step only runs if tests pass and the image pushes successfully. If tests fail, nothing gets deployed.

---

## Deploying from scratch

**Prerequisites:** Terraform, AWS CLI configured, Docker

```bash
# Clone the repo
git clone git@github.com:sh3r44z/ecs-fargate-cicd.git
cd ecs-fargate-cicd/terraform

# Initialise and apply
terraform init
terraform plan
terraform apply
```

Terraform will output the ALB DNS name once everything is created.

Then push any commit to the `fastapi-cicd` repo to trigger a full pipeline run.

To tear down all infrastructure when done:

```bash
terraform destroy
```

---

## Key design decisions

**Fargate over EC2** — no servers to manage, patch, or scale manually. Define the task, AWS runs it.

**Multi-AZ subnets** — the ALB spans two availability zones so the app stays up if one AZ has issues.

**Rolling deploy** — ECS is configured with `minimum_healthy_percent = 50` and `maximum_percent = 200`, meaning new containers start before old ones are drained. No downtime during deployments.

**linux/amd64 build** — explicitly targeting amd64 at build time to avoid platform mismatch errors when running on ARM Macs.

**Remote Terraform state** — state lives in S3 with locking so it is safe, versioned, and shareable.

**Least-privilege IAM** — the ECS task execution role has only the permissions needed to pull images from ECR and write logs to CloudWatch.

---

## What I learned

- Writing modular Terraform with reusable modules for VPC, ALB and ECS
- How ECS Fargate pulls images, runs tasks, and integrates with an ALB
- Rolling deploy mechanics and how health checks gate traffic switching
- Remote state management with S3 and DynamoDB locking
- Why platform architecture matters when building Docker images on Apple Silicon
- Wiring GitHub Actions to AWS using IAM credentials stored as encrypted secrets

---

## Related projects

- [fastapi-cicd](https://github.com/sh3r44z/fastapi-cicd) — the application this pipeline deploys
- [homelab-monitoring](https://github.com/sh3r44z/homelab-monitoring) — observability stack running on my home server
