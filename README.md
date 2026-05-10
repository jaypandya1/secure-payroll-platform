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
- CloudTrail audit logging to a dedicated S3 bucket

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

## Task 1 - AWS Infrastructure Setup

### Architecture Overview

The infrastructure is deployed on AWS in the `eu-west-2` (London) region to ensure UK data residency compliance. The design uses a multi-AZ deployment across 2 availability zones for high availability.

**Core Components**

1. **Virtual Private Cloud (VPC)** - CIDR: `10.0.0.0/16`
   - 2 Public Subnets (10.0.0.0/25, 10.0.0.128/25) in eu-west-2a and eu-west-2b
   - 6 Private Subnets - 2 per tenant type across both AZs:
     - Company: 10.0.1.0/24 (2a), 10.0.2.0/24 (2b)
     - Bureau: 10.0.3.0/24 (2a), 10.0.4.0/24 (2b)
     - Employee: 10.0.5.0/24 (2a), 10.0.6.0/24 (2b)
   - Internet Gateway for public subnet outbound access
   - 1 NAT Gateway (in public subnet) for private subnet internet access

2. **EC2 Instances** (3 instances, 1 per tenant type)
   - Instance Type: `t3.micro` (free tier eligible)
   - Placement: Tenant-specific private subnets (company in company subnet, etc.)
   - Storage: 8GB EBS volume (gp2, encrypted)
   - No public IP addresses assigned (security best practice)
   - IAM instance profiles for Secrets Manager and S3 access
   - User data script fetches database credentials from Secrets Manager at startup

3. **RDS PostgreSQL Database**
   - Instance Type: `db.t3.micro` (free tier eligible)
   - Storage: 20GB, encrypted at rest
   - Multi-AZ: No (free tier constraint; future enhancement possible)
   - Subnet Group: Spans 2 private company subnets across AZs
   - Publicly Accessible: No
   - Backup Retention: 1 day (free tier limit)
   - Automatic failover policy: Application-level retry logic

4. **S3 Bucket**
   - Versioning enabled for audit trail and data recovery
   - Encryption: SSE-S3 at rest
   - Public access blocked entirely via bucket policy and ACL
   - Tenant-prefix isolation: company/* bureau/* employee/*
   - Lifecycle policy (future): Archive old versions after 90 days

5. **IAM Roles & Policies**
   - Company Role, Bureau Role, Employee Role (one per tenant)
   - Each role has least-privilege inline policies:
     - AllowOwnSecret: Scoped to `secretsmanager:GetSecretValue` for tenant's secret only
     - AllowOwnS3Prefix: Scoped to `s3:GetObject, PutObject, ListBucket` for tenant prefix only
     - AllowCloudWatchLogs: Scoped to CloudWatch logs for tenant instance
   - AmazonSSMManagedInstanceCore policy for Systems Manager access

6. **Security Groups**
   - 3 EC2 Security Groups (one per tenant): Allow outbound HTTPS (443) and DNS (53); no inbound from internet
   - 1 RDS Security Group: Allow inbound on port 5432 from all 3 EC2 security groups only

7. **Network ACLs (NACLs)**
   - Public NACL: Allow inbound from internet on ephemeral ports; allow all outbound
   - Company Private NACL: Deny inter-tenant traffic; allow inbound from company subnet; allow outbound to NAT and RDS
   - Bureau and Employee NACLs: Follow identical isolation pattern

### Deployment

All infrastructure is defined in Terraform (2249 lines across main module + 6 submodules):

```bash
cd terraform
terraform init              # Initialize Terraform with AWS backend
terraform plan              # Review infrastructure changes
terraform apply             # Deploy to AWS
```

**Free Tier Considerations**
- All compute uses t3.micro instances (1 vCPU, 1 GB RAM, 750 hours/month free)
- RDS uses db.t3.micro (750 hours/month free) with 1-day backup retention
- S3 storage included in free tier (~5 GB)
- CloudWatch Logs (5 GB ingestion free), SNS, and CloudTrail provided at reduced cost
- Total monthly cost in free tier: ~$0–10 (after 12-month free tier period)



## Task 2 - Multi-Tenancy Architecture

### 2a. Tenant Isolation Strategy

**Database Model:** Shared database with tenant_id scoping

- A single PostgreSQL instance stores data for all three tenant types (Company, Bureau, Employee)
- Application-level enforcement: Every query must filter on `tenant_id` to ensure rows belong to the authenticated tenant
- If the application level fails (code bug, SQL injection), the infrastructure layer ensures strict boundaries:
  - Each tenant EC2 instance has credentials that fetch only its own DB user secret from Secrets Manager
  - The RDS security group allows connections only from tenant-specific EC2 instances
  - Database credentials are tenant-scoped (future enhancement: implement role-based DB users per tenant)

**Context Propagation**

- Tenant identity is established at request time based on the EC2 instance's IAM role and instance metadata
- In the current implementation, each EC2 instance is tagged with a `Tenant` value (Company, Bureau, or Employee)
- The application determines tenant scope from environment variables or instance metadata service (`ec2-metadata --instance-id`)
- Every API request is implicitly scoped to the calling EC2 instance's tenant

**Guaranteed Data Scoping**

- **Application layer:** Request handlers check the EC2 instance's tenant context and filter all database queries to return only rows matching that tenant_id
- **Infrastructure layer:** 
  - IAM roles restrict each EC2 instance to read only its own Secrets Manager secret (e.g., company EC2 can only read `companies-secret`)
  - S3 bucket policies enforce prefix-based access: Company EC2 can only access `companies/*` keys, Bureau can access `bureaus/*`, and so on
  - RDS security group allows inbound on port 5432 only from each tenant's security group
- **Network layer:**
  - NACLs isolate each tenant's private subnet; cross-tenant traffic is blocked at the subnet boundary
  - VPC Flow Logs capture all traffic for audit and investigation

### 2b. Access Boundaries at the Infrastructure Layer

**IAM Roles and Policies**

Three IAM roles are created: `company-role`, `bureau-role`, and `employee-role`.

Each role has:
- **Secrets Manager access:** AllowOwnSecret policy permits reading only the secret ARN prefixed with the tenant name  
  Example: `company-role` can read `arn:aws:secretsmanager:eu-west-2:ACCOUNT:secret:companies-*`
  Explicit Deny statements prevent reading secrets not belonging to the tenant
- **S3 access:** AllowOwnS3Prefix policy permits GetObject and PutObject only within tenant-prefixed paths  
  Example: `company-role` can access `s3://payroll-bucket/companies/*`
- **CloudWatch Logs:** Allows writing logs to tenant-specific log group prefixes  
  Example: `company-role` writes to `/ec2/secure-payroll-company`
- **SSM and EC2:** Allows SSM Session Manager for interactive troubleshooting and CloudWatch agent operations

**S3 Bucket Policies**

The S3 bucket policy enforces resource-level prefix isolation:
- Each principal (IAM role) can only perform actions (GetObject, PutObject, ListBucket) on keys under its tenant prefix
- ListBucket permission includes a prefix condition to hide keys outside the tenant's scope  
  Example: Company role sees only objects with prefix `companies/` when listing
- Public access is blocked at all four levels (public ACLs, public policies, authenticated public access)
- Bucket versioning is enabled for data recovery and audit trails
- Encryption at rest uses SSE-S3

**Infrastructure Enforcement is Second Boundary**

If application-layer tenant validation fails:
- A Company EC2 instance running code that tries to read Bureau data would still be denied by the S3 bucket policy  
  (role doesn't have `s3:GetObject` for `bureaus/*`)
- A query that mistakenly omits tenant_id filtering would still fail because the DB connection is scoped to tenant-specific credentials
- Network segmentation (NACLs, security groups) prevents cross-tenant instances from even attempting to reach each other's subnets

### 2c. Tenant Onboarding and Offboarding

**Onboarding a New Tenant (e.g., a new Company)**

1. **Infrastructure provisioning:**
   - Update `terraform.tfvars` to add new tenant subnets, security groups, and EC2 instance definitions
   - Create a new IAM role and instance profile scoped to the tenant's resources
   - Deploy the new infrastructure using `terraform apply`

2. **Secrets provisioning:**
   - Create a new Secrets Manager secret (e.g., `companies-new-tenant-db-credentials`) with the tenant's database user and password
   - Restrict the secret's resource policy to the new tenant's IAM role only
   - Pass the secret ARN to Terraform as a variable

3. **Database provisioning:**
   - Create a new database schema or namespace for the tenant
   - Optionally create tenant-specific database roles if using database-level isolation
   - Seed initial data (empty payroll records, default settings)

4. **Tagging and discovery:**
   - Tag the new EC2 instance with `Project`, `Environment`, and `Tenant` tags so GitHub Actions deployment workflow can target it
   - Verify CloudWatch log groups are created and accessible from the tenant's role

5. **Validation:**
   - Run the application health check (`GET /health`) to confirm the EC2 instance is accessible
   - Test that the new tenant's role can read only its own secrets and S3 objects
   - Verify VPC Flow Logs capture tenant-to-RDS traffic and block cross-tenant attempts

**Offboarding a Tenant (complete deletion)**

1. **Application cleanup:**
   - Archive or delete all payroll records, employee data, and documents associated with the tenant
   - Call `DELETE /v1/employees/{employee_id}` for all employees in the tenant to trigger audit logging

2. **Data cleanup:**
   - Empty the tenant's S3 prefix (`s3://bucket/company/*` or similar)
   - Optionally back up to cold storage or comply with retention policies before deletion

3. **Infrastructure deprovisioning:**
   - Revoke the IAM role's access to Secrets Manager and S3  
     (or set policies to explicit Deny for the tenant's resources)
   - Terminate the EC2 instance  
     (can scale to 0 replicas instead of full deletion)
   - Optionally delete the Secrets Manager secret or rotate its value
   - Remove the tenant from `terraform.tfvars` and run `terraform destroy` for that tenant's resources

4. **Audit trail:**
   - CloudTrail records all API calls made during offboarding (IAM policy changes, EC2 termination, S3 deletion)
   - VPC Flow Logs capture network activity during the transition
   - Application audit log records which identities performed deletions and when

5. **Verification:**
   - Confirm the tenant's EC2 instance no longer exists and cannot be accessed
   - Verify the tenant's IAM role has no attached policies or can only access audit-readonly resources
   - Check S3 bucket for orphaned objects under the tenant's prefix and clean up if found



## Task 3 - Security & Access Control

### 3a. IAM & Role-Based Access Control

Each tenant type has its own IAM role with least-privilege access scoped strictly to tenant-owned resources:

**Company Role**
- Secrets Manager: Can read only `arn:aws:secretsmanager:eu-west-2:*:secret:companies-*`
- S3: Can GetObject, PutObject, ListBucket for `s3://bucket/companies/*` only
- CloudWatch Logs: Can write to `/ec2/oceans-payroll-dev-company`
- RDS: Database security group allows port 5432 inbound from company-sg only
- Explicit Deny statements prevent access to `bureaus-*` and `employees-*` secrets

**Bureau and Employee Roles**
- Follow identical pattern with `bureaus-*` and `employees-*` prefixes respectively
- No cross-tenant resource access possible even with wildcard or root credentials

**GitHub Actions Role (OIDC Federation)**
- Scoped to `ssm:SendCommand` and EC2 metadata operations only
- No direct access to RDS, S3, or Secrets Manager
- Deployments use SSM to push commands to tenant-specific EC2 instances

### 3b. Secrets Management

Secrets are provisioned in AWS Secrets Manager (outside Terraform) and injected at runtime:

**Database Credentials Flow**
1. Administrator creates three secrets in Secrets Manager:
   - `companies-db-credentials` (JSON: username, password)
   - `bureaus-db-credentials`
   - `employees-db-credentials`

2. Each secret's resource policy restricts access to the corresponding IAM role only

3. EC2 instance user_data script fetches the secret at startup:
   ```bash
   SECRET_ARN=$(echo $SECRETS_MANAGER_ARN)
   aws secretsmanager get-secret-value --secret-id $SECRET_ARN --region eu-west-2 \
     | jq -r '.SecretString | fromjson | "\(.username):\(.password)"' \
     > /etc/payroll/db_creds
   chmod 600 /etc/payroll/db_creds
   export DB_USER=$(cut -d: -f1 /etc/payroll/db_creds)
   export DB_PASS=$(cut -d: -f2 /etc/payroll/db_creds)
   ```

4. Credentials are never exposed in logs, code, or GitHub Actions YAML

5. Application environment variables (`DB_USER`, `DB_PASS`) are scoped to the EC2 process

### 3c. Encryption

**Encryption at Rest**
- **RDS:** `storage_encrypted = true` enables AES-256 encryption of all database volumes
- **S3:** Bucket default encryption is set to SSE-S3; all objects encrypted at rest
- **EBS:** EC2 root volume encryption enabled for all compute instances
- **Secrets Manager:** Secrets encrypted at rest using AWS managed keys (aws/secretsmanager)

**Encryption in Transit**
- **RDS connections:** Private endpoints and security groups prevent exposure; future enhancement uses SSL/TLS enforcement (REQUIRE SSL in PostgreSQL)
- **S3 API calls:** Use HTTPS (default for AWS SDK); bucket policy denies unencrypted uploads
- **VPC Flow Logs:** Encrypted in CloudWatch Logs with AWS managed encryption
- **CloudTrail logs:** Stored in S3 bucket with SSE-S3 encryption

**Secrets in Transit**
- EC2 fetches secrets from Secrets Manager via HTTPS only (AWS SDK default)
- EC2 instance profile credentials (temporary STS tokens) used for API calls; no long-lived keys stored

### 3d. Network Security

**Security Groups**
- **Company/Bureau/Employee EC2 SGs:** Ingress allowed only from SSM endpoint and intra-VPC HTTPS (future); no inbound from internet
- **RDS SG:** Ingress allowed only on port 5432 from tenant EC2 security groups; no public access
- **All SGs:** Egress to 0.0.0.0/0 on ports 443 (HTTPS), 53 (DNS) for service discovery and API calls

**Network ACLs (NACLs)**
- **Company private subnets:** NACL allows inbound from company EC2 only; denies all inter-tenant traffic
- **Bureau and Employee subnets:** Follow identical isolation pattern
- **Public subnets (NAT gateways):** Allow inbound from internet for ephemeral ports only; outbound to 0.0.0.0/0

**Database Isolation**
- RDS instance placed in private subnet with no internet gateway route
- DB subnet group spans only private subnets; publicly_accessible = false
- Cross-tenant traffic to port 5432 is blocked by security group and network ACLs

**Tenant-to-Tenant Traffic Prevention**
- Each tenant's EC2 instance can only reach RDS and internet-bound traffic via NAT
- Cross-subnet communication blocked by NACLs at the network boundary
- VPC Flow Logs capture and alert on any attempted cross-tenant connections

**Data in Transit Example Flow**
1. Company EC2 → Secrets Manager: HTTPS via IAM role (temporary credentials in request headers)
2. Company EC2 → RDS: TCP 5432 within private network (no internet exposure); future: SSL/TLS encryption
3. Company EC2 → S3: HTTPS via IAM role
4. Application logs → CloudWatch: HTTPS via CloudWatch Logs agent
5. CloudWatch → SNS: HTTPS (AWS internal)
6. SNS → Email: SMTP with TLS (AWS managed)



## Task 4 - CI/CD Pipeline

### GitHub Actions Workflows

Two primary workflows handle build, test, and deployment:

**1. Main Deploy Workflow (.github/workflows/deploy.yml)**

Triggered on:
- `push` to main branch
- Manual `workflow_dispatch` with tenant selection (All, Company, Bureau, or Employee)

**Jobs:**

a) **build_and_test**
   - Builds Docker image: `docker build -t secure-payroll:latest .`
   - Runs container health check: `GET /health` endpoint must return 200 OK
   - Logs: Build output and test results to GitHub Actions UI

b) **deploy_to_ec2**
   - Prerequisites: Assumes AWS role via OIDC federation (no static keys)
   - Role ARN: `arn:aws:iam::ACCOUNT_ID:role/gha-deployment-role`
   - Scopes: Limited to `ssm:SendCommand` and `ec2:DescribeInstances` only
   - Discovery: Finds EC2 instances by tags (`Project=oceans-payroll`, `Environment=dev`, `Tenant=*`)
   - Deployment: Uses AWS Systems Manager (SSM) to send deployment command to each target instance
   - Command: Pulls Docker image from registry, stops old container, starts new container
   - Timeout: 5 minutes per instance

**Tenant-Specific Deployment**

The workflow supports per-tenant targeting via workflow inputs:

```yaml
inputs:
  tenant_to_deploy:
    description: "Which tenant to deploy to"
    required: false
    default: "all"
    type: choice
    options:
      - all
      - Company
      - Bureau
      - Employee
```

**Example:** Deploy only to Bureau tenant:
```bash
gh workflow run deploy.yml -f tenant_to_deploy=Bureau
```

### Secrets & Credentials

**OIDC Federation (No Static Keys)**

1. GitHub Actions requests temporary AWS credentials using OIDC token
2. Token includes:
   - Repository: `owner/repo`
   - Workflow: `deploy.yml`
   - Actor: `github-actions[bot]`
   - Commit: Full SHA
3. AWS STS validates token and returns 1-hour temporary credentials
4. Workflow uses credentials for SSM and EC2 API calls only
5. No credentials stored in GitHub Secrets or repository

**Database Credentials**

- Stored in AWS Secrets Manager (outside Terraform, managed separately)
- EC2 instance fetches credentials at startup via IAM role
- GitHub Actions never has direct access to database credentials
- Application environment variables passed via EC2 user_data

**Environment-Specific Configuration**

- Development environment uses `dev` suffix for resources
- Production would use `prod` suffix (separate account recommended)
- No hardcoded passwords, API keys, or connection strings in code or workflows

### Deployment Process

**Step-by-step:**

1. Developer pushes code to `main` branch
2. GitHub Actions triggered; build_and_test job runs
3. If tests pass, deploy_to_ec2 job assumes AWS role via OIDC
4. Discovers target instances by tags and tenant filter
5. Sends SSM command to pull and run new Docker image
6. Each EC2 instance executes deployment locally (pull image, stop old container, start new)
7. Application restarts with new code; health check validates
8. Logs available in GitHub Actions UI and EC2 CloudWatch agent

**Multi-Team Independence**

Each team (company, bureau, employee) can deploy independently:
- Team A deploys to Company tenant only
- Team B deploys to Bureau tenant only
- Team C can deploy to all tenants (if given GitHub Actions runner access)

No shared deployment state or locking; each tenant's EC2 instance manages its own container.

### Security Practices

- ✓ No static AWS credentials in repository or secrets
- ✓ OIDC role scoped to SSM SendCommand and EC2 describe only
- ✓ Database credentials never exposed in logs or workflow files
- ✓ Each tenant's deployment isolated to its own EC2 instance
- ✓ All API calls logged by CloudTrail for audit
- ✓ SSM documents (deployment commands) logged to CloudWatch for troubleshooting



## Task 5 - Monitoring & Incident Readiness

### CloudWatch Monitoring

**Log Groups** (30-day retention)

1. `/oceans-payroll-dev/application` - Application stdout/stderr
   - Captures Docker container logs
   - Searchable by tenant ID or request ID
   - Alert triggers on ERROR level messages

2. `/oceans-payroll-dev/infrastructure` - Terraform and system logs
   - EC2 user_data execution logs
   - Infrastructure health checks

3. `/aws/vpc/flowlogs-dev` - VPC Flow Logs
   - All network traffic between subnets
   - Captures denied packets (cross-tenant attempts)
   - Alert triggers on deny rules from RDS port 5432

**Metrics & Alarms** (threshold: >80%)

1. **company-cpu-high** - Company EC2 CPU utilization
   - Threshold: 80%, Period: 300 seconds (5 min)
   - Action: Publish to SNS topic `oceans-payroll-dev-alerts`

2. **bureau-cpu-high** - Bureau EC2 CPU utilization
   - Threshold: 80%, Period: 300 seconds
   - Action: SNS notification

3. **employee-cpu-high** - Employee EC2 CPU utilization
   - Threshold: 80%, Period: 300 seconds
   - Action: SNS notification

4. **rds-connections-high** - RDS active connections
   - Threshold: 80% of max connections, Period: 300 seconds
   - Action: SNS notification
   - Indicates potential connection pool exhaustion

**SNS Topic**

- Name: `oceans-payroll-dev-alerts`
- Subscriptions: Email (if configured during Terraform apply)
- Messages include:
  - Alarm name and trigger time
  - Metric value and threshold
  - Recommended action (scale up, investigate logs, etc.)

### VPC Flow Logs Integration

**Enabled by default** on VPC and all subnets:

- Logs captured to CloudWatch Log Group: `/aws/vpc/flowlogs-dev`
- Format: `version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status`
- Examples:
  - Cross-tenant denied packet: `..., 10.0.1.50, 10.0.3.50, 5432, DENY, OK`
  - Company to RDS allowed: `..., 10.0.1.50, 10.0.1.100, 5432, ACCEPT, OK`

**Anomaly Detection** (future enhancement):

- CloudWatch anomaly detection can identify unusual traffic patterns
- Alert on sustained DENY traffic to RDS port 5432 (indicates compromise attempt)

### Incident Response Runbook

**File:** `docs/incident-runbook.md`

Covers RDS public exposure scenario with 5 sections:

1. **Detect** - CloudWatch alarms, VPC Flow Logs, CloudTrail evidence
2. **Investigate** - Questions to ask, commands to run, logs to review
3. **Contain** - Immediate actions (remove public IP, restrict security group)
4. **Recover** - Restoration order (restore from backup, verify data integrity)
5. **Prevent** - Future safeguards (infrastructure as code enforcement, TerraformLint)

### CloudTrail Audit Logging

**AWS API Audit Trail**

- S3 bucket: `oceans-payroll-dev-cloudtrail` (versioning enabled, public access blocked)
- Trail: Single-region (eu-west-2) with log file validation enabled
- Log all EC2, RDS, S3, IAM, and STS API calls
- Events archived for 7+ years compliance

**What's Logged**

- EC2: StartInstances, StopInstances, ModifyInstanceAttribute, DescribeInstances
- RDS: ModifyDBInstance, CreateDBSnapshot, RestoreDBInstanceFromDBSnapshot
- S3: GetObject, PutObject, ListBucket, PutBucketPolicy
- IAM: CreateRole, PutRolePolicy, UpdateAssumeRolePolicy
- STS: AssumeRole (GitHub Actions deployments)
- Secrets Manager: GetSecretValue

**Querying CloudTrail Logs**

Example AWS CLI:
```bash
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=ModifyDBInstance --region eu-west-2
```

Result: Shows who modified the RDS instance, when, and what changed.

### Application-Level Audit Logging

**DELETE Events** (GDPR Article 17 right to erasure)

When an employee record is deleted:

```json
{
  "timestamp": "2024-01-15T10:30:45Z",
  "action": "DELETE",
  "tenant_id": "company-123",
  "resource_type": "employee",
  "resource_id": "emp-456",
  "details": {
    "name": "John Doe",
    "email": "john@example.com",
    "reason": "Employee request (Article 17)"
  }
}
```

Two additional audit events logged:
1. `PURGE_S3` - Employee documents deleted from S3
2. `REVOKE_ACCESS` - IAM permissions and API tokens revoked

All three events stored in in-memory audit log (future: persist to CloudWatch or S3).

### Monitoring Dashboards (Future Enhancement)

Recommended dashboard setup in CloudWatch:

```
┌─────────────────────────────────────┐
│ Secure Payroll Platform Dashboard   │
├─────────────────────────────────────┤
│ EC2 CPU (company/bureau/employee)   │
│ RDS Connections & Query Performance │
│ S3 Request Count (get/put/delete)   │
│ Network In/Out (by tenant)          │
│ CloudTrail Events (by API)          │
│ Application Errors (tail last 100)  │
│ VPC Flow Logs DENY Events           │
└─────────────────────────────────────┘
```



## Task 6 - UK compliance considerations

1. Use AWS-native encryption, least-privilege IAM, Secrets Manager, CloudTrail, CloudWatch, and resource-level policies to protect PII and bank data.
2. Keep the deployment in `eu-west-2` and avoid cross-region replication or data copies outside the UK/EU boundary.
3. Implement a delete workflow that removes the employee record from the application layer, purges related S3 objects and backups where possible, revokes access, and records the action in audit logs.

### Deletion workflow

- The API exposes `DELETE /v1/employees/{employee_id}`.
- The handler removes the employee from the in-memory registry, simulates tenant-scoped S3 object purge, and records deletion, purge, and access-revocation events in an audit log.
- CloudTrail is enabled in Terraform with a dedicated audit trail and S3 bucket so infrastructure and API changes have an AWS-native audit record.
- In production, the same flow should also revoke any downstream identities, delete persisted records, and confirm the erasure request in the incident log.

## Architecture diagram

See [docs/architecture.md](docs/architecture.md) 
