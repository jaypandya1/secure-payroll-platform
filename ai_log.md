## Entry 1 — VPC Module (Task 1, Step 1)

**Prompt:** I'm building AWS infrastructure for a UK payroll platform handling highly sensitive data — employee bank details, NI numbers, payroll records. I need a Terraform module for the VPC layer.
Requirements:

1 VPC across 2 availability zones (eu-west-2a and eu-west-2b)
2 public subnets (one per AZ) — for NAT Gateway only, no EC2 here
6 private subnets (one per tenant per AZ) — Companies, Bureaus, Employees each get their own private subnet pair for compute isolation
1 Internet Gateway attached to the VPC
1 NAT Gateway in a public subnet so private instances can reach the internet outbound
Proper route tables — public subnets route to IGW, private subnets route to NAT
All resources tagged with Environment, Project, and Tenant where applicable

Use Terraform. Output the VPC ID, all subnet IDs, and the NAT Gateway ID. Use variables for CIDR blocks, region, and AZ names — no hardcoded values. Follow AWS naming conventions and structure it as a reusable module.

**AI Output Summary:** Generated a VPC module with IGW, NAT Gateway, 
6 private subnets across 2 AZs, and route tables.

**What I took:** The overall module structure, route table associations, 
and output blocks.

**What I rejected:** AI initially placed the NAT Gateway in the first 
private subnet — this is wrong, NAT Gateways must live in a public subnet 
to route outbound traffic through the IGW. Corrected this manually.

**Follow-up prompt:** [paste the security auditor prompt]

**AI response:** Flagged missing VPC Flow Logs — added a flow log resource 
pointing to a CloudWatch log group as a result.

## Entry 2 — Project Completion Sweep

**Prompt:** I am working on this project make sure my terraform aligns with this instructions and also create all files required to finish this project

**AI Output Summary:** Reviewed the Terraform modules, existing docs, and repo structure to identify missing project artifacts and the biggest gaps against the assignment.

**What I took:** The existing VPC, EC2, RDS, IAM, S3, and security group structure; the project already had the core AWS foundations in place.

**What I rejected:** Empty or placeholder files were not enough to count as complete project deliverables, so I did not stop at structural presence alone.

**Follow-up prompt:** can you check whats left in implementing the whole project and implement those actions

**AI response:** Identified the VPC Flow Logs gap, added missing documentation files, and created a usable tfvars example for the repo.

## Entry 3 — Architecture Diagram and Workflow Completion

**Prompt:** can you draw me the complete architecture that my current terraform state trying to create

**AI Output Summary:** Produced a full architecture diagram description covering the VPC, subnets, NAT, EC2, RDS, S3, IAM, and monitoring flow.

**What I took:** The full-stack dependency map and the tenant-isolated network shape.

**What I rejected:** A diagram that omitted the security and monitoring layers was not sufficient for the assignment.

**Follow-up prompt:** I am drawing manually on eraser.io

**AI response:** Converted the architecture explanation into step-by-step connection guidance for manual drawing.

## Entry 4 — PDF Review and Finalization

**Prompt:** Review the pdf Project.pdf and compare that with current project and finish project

**AI Output Summary:** Compared the PDF requirements against the repository and finished the missing deliverables.

**What I took:** The required task areas: Terraform infra, multi-tenancy, security, CI/CD, monitoring, compliance, architecture diagram, and AI usage log.

**What I rejected:** A repository with only Terraform without the documentation, workflows, and monitoring pieces was not complete enough for submission.

**Follow-up prompt:** Review the pdf Project.pdf and compare that with current project and finish project

**AI response:** Added network ACLs, monitoring alarms, SNS alerts, an architecture diagram file, a compliance section in the README, and a runbook focused on accidental public RDS exposure.