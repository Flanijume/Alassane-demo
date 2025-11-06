# Knova DevOps/Infrastructure Engineer Exercise

This repository contains a **time-boxed** implementation of the requested exercise: minimal cloud infra (Terraform), a simple containerized API, a Helm chart for Kubernetes, and a GitHub Actions pipeline. It focuses on **structure, automation, and documentation** over complete production-hardening.

> ⚠️ Notes & trade-offs:
> - Uses managed AWS services (EKS + RDS) to keep Kubernetes and Postgres realistic but concise via community modules.
> - Security and compliance controls are documented and partially implemented; more hardening would be done with time.
> - Monitoring is optional here with a Prometheus alert example (CPU > 50%).

## Contents
- `terraform/`: VPC, subnets, security groups, bastion, EKS (for K8s), and RDS Postgres.
- `app/`: A tiny Flask "Hello World" API with Dockerfile.
- `charts/hello-api/`: Helm chart with rolling updates, probes, and 2 replicas.
- `.github/workflows/deploy.yml`: Build → test → deploy via Helm to EKS.
- `docs/`: Extra notes (rollback, restore, approvals, secrets).

---

## Quick Start

### 0) Prereqs
- AWS account & credentials with permissions for VPC, EC2, EKS, IAM, RDS, S3, CloudWatch, and ECR (optional).
- CLI tools: `aws`, `kubectl`, `helm`, `terraform`, `docker`, `jq`.
- An S3 bucket (optional) for Terraform remote state (see `terraform/backend.tf.example`).

### 1) Provision Cloud Infra (Terraform)
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -auto-approve
```
**Outputs** will include the EKS cluster name and an RDS endpoint.

### 2) Configure kubectl for the new cluster
```bash
aws eks update-kubeconfig --region $(terraform output -raw region)   --name $(terraform output -raw eks_cluster_name)
kubectl get nodes
```

### 3) Build & push the API image (local or CI)
```bash
cd app
docker build -t hello-api:local .
# Optional: push to ECR (replace with your account/region/repo)
# aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <acct>.dkr.ecr.us-east-1.amazonaws.com
# docker tag hello-api:local <acct>.dkr.ecr.us-east-1.amazonaws.com/hello-api:latest
# docker push <acct>.dkr.ecr.us-east-1.amazonaws.com/hello-api:latest
```

### 4) Deploy with Helm
```bash
cd charts/hello-api
# Update values.yaml image.repository to your ECR/registry if using a remote repo
helm upgrade --install hello-api . -n default
kubectl rollout status deploy/hello-api
kubectl get svc hello-api
```

### 5) Test
```bash
# If using LoadBalancer service, copy EXTERNAL-IP below:
kubectl get svc hello-api -o wide
curl http://<EXTERNAL-IP>/
```

---

## Rollback, Restore & Approvals

- **Helm rollback**: `helm rollback hello-api <REVISION>` (see `helm history hello-api` first).
- **Kubernetes rollback**: `kubectl rollout undo deployment/hello-api`.
- **RDS Restore**: enable automated backups; restore to a point in time; re-point app via secret or env var.
- **Promotion/Approvals**:
  - Use **GitHub Environments** `staging` and `production` with **required reviewers** for prod.
  - The workflow is set to deploy `main` → `dev` automatically and gate `staging`/`prod` with approvals.

---

## Secrets Management

Recommended approaches:
- **AWS Secrets Manager** (preferred) or **SSM Parameter Store** with KMS CMKs.
- App pulls DB creds from the platform (Kubernetes secret synced from AWS via external-secrets or CI injects).
- CI uses OpenID Connect (OIDC) + minimal IAM role to read only the needed secret paths.

See `docs/secrets.md`.

---

## Regulatory & Security (high-level)
- **Audit Logging**: enable CloudTrail; ship EKS audit logs + app logs to CloudWatch or an ELK stack.
- **Backups/DR**: RDS automated backups (7–30 days), snapshots; EKS etcd is managed by AWS.
- **Network Segmentation**: private subnets for app & DB, restricted SGs, bastion for jump access only.
- **Access Reviews**: IAM least privilege, rotate keys, review role trust policies quarterly.
- **TLS**: use ACM for Ingress; enforce HTTPS only (out of scope for this time-box, documented in TODOs).

---

## Future Improvements
- Multi-AZ RDS, RDS Proxy, HPA/Cluster Autoscaler, WAF, service mesh (mTLS), ExternalDNS + ACM.
- Terraform remote state + workspaces for envs; split modules per service; pre-commit hooks & static checks.
- Full observability via Prometheus Operator, Grafana dashboards, Loki logs, and synthetic tests.
