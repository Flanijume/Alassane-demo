# Rollback & Restore

## App Rollback
- **Helm**: `helm history hello-api` then `helm rollback hello-api <REVISION>`
- **Kubernetes**: `kubectl rollout undo deployment/hello-api`

## Database Restore
- Ensure automated backups are enabled for RDS.
- To restore to point-in-time, create a new instance from snapshot, update `DB_HOST` secret, and restart deployment.

## Infra Rollback
- Use `terraform destroy` to tear down non-persistent resources in dev.
- Use versioned modules and separate state per environment to allow safe rollbacks.
