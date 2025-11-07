# Terraform Notes

## Files
- `providers.tf` — providers and versions
- `main.tf` — VPC, Bastion, EKS, RDS, S3
- `variables.tf` — input variables
- `outputs.tf` — handy outputs (EKS name, RDS endpoint)
- `backend.tf.example` — remote state template (optional)
- `terraform.tfvars.example` — sample variables

## Bastion SSH
A keypair is referenced as `bastion_id_rsa.pub` in this directory. Create it:
```bash
ssh-keygen -t rsa -b 4096 -f bastion_id_rsa -N ""
```
Then apply Terraform again if needed.

## After Apply
```bash
aws eks update-kubeconfig --region $(terraform output -raw region)   --name $(terraform output -raw eks_cluster_name)
kubectl get nodes
```
