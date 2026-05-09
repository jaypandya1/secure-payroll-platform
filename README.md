# Secure Payroll Platform

Terraform infrastructure for a UK payroll platform with tenant-isolated compute, database, and storage.

## What it creates

- One VPC in `eu-west-2`
- Two public subnets across two Availability Zones for NAT Gateway placement
- Private subnet pairs for Company, Bureau, and Employee tenants
- One NAT Gateway for outbound internet access from private subnets
- Tenant-specific EC2 instances in private subnets
- One private PostgreSQL RDS instance
- One S3 bucket for payroll documents with tenant prefix isolation
- IAM roles and instance profiles for each tenant
- Security groups for EC2, RDS, and SSM endpoint traffic
- VPC Flow Logs to CloudWatch Logs

## Repository layout

- `terraform/` - all Terraform code
- `docker/` - application container assets
- `docs/` - operational documentation

## Terraform files you need

- `terraform/main.tf` - root composition of all modules
- `terraform/variables.tf` - root variables and validation
- `terraform/outputs.tf` - root outputs
- `terraform/terraform.tfvars.example` - example variable values

## How to use

1. Copy `terraform/terraform.tfvars.example` to `terraform.tfvars`.
2. Fill in the secret ARNs and a globally unique S3 bucket name.
3. Run `terraform init` inside `terraform/`.
4. Run `terraform plan`.
5. Run `terraform apply` when ready.

## CI/CD

- The repository includes GitHub Actions workflows for Terraform validation and for building, testing, and deploying the Docker app.
- The deployment workflow uses AWS Systems Manager to target EC2 instances by tags so the tenant fleets can be updated independently.
- To enable deployment, set the `AWS_ROLE_TO_ASSUME` GitHub secret to an IAM role that can call `ssm:SendCommand` and read the required metadata.

## Notes

- The configuration is designed so each tenant stays isolated in its own private subnet pair.
- EC2 instances do not receive public IPs.
- The database is not publicly accessible.
- S3 bucket access is controlled by tenant-specific IAM and bucket policy rules.

## Task 6 - UK compliance considerations

1. Use AWS-native encryption, least-privilege IAM, Secrets Manager, CloudTrail, CloudWatch, and resource-level policies to protect PII and bank data.
2. Keep the deployment in `eu-west-2` and avoid cross-region replication or data copies outside the UK/EU boundary.
3. Implement a delete workflow that removes the employee record from the application layer, purges related S3 objects and backups where possible, revokes access, and records the action in audit logs.

## Architecture diagram

See [docs/architecture.md](docs/architecture.md) 
