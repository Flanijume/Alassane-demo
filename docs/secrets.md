# Secrets Management

## Recommended
- **AWS Secrets Manager** for application/database credentials.
- **AWS SSM Parameter Store (SecureString)** for non-rotating config values.
- **KMS** customer-managed keys for encryption.

## Access Pattern
- CI assumes a minimal IAM role via OIDC to fetch secrets for deploy time OR
- Use **external-secrets** controller on EKS to sync AWS Secrets → Kubernetes Secrets.

## Kubernetes Usage (example)
```bash
kubectl create secret generic db-credentials   --from-literal=DB_HOST=mydb.abcxyz.us-east-1.rds.amazonaws.com   --from-literal=DB_USER=appuser   --from-literal=DB_PASSWORD='change-me'
```

Then wire them into the Deployment as env vars (see Helm chart templates).

## GitHub Secrets (minimum)
- `AWS_ROLE_TO_ASSUME` (ARN for deploy role)
- `AWS_REGION`
- `EKS_CLUSTER_NAME`
- `REGISTRY` (e.g., ECR repo URI) (optional if pulling locally-built images)
- (If not using OIDC): temporary fallback AWS key/secret with principle of least privilege
