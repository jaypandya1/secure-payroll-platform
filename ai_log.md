## AI Usage Log

I used AI as an engineering accelerator, not as an authority. I relied on it to speed up drafting, gap analysis, and alternative design review, then I manually verified the output against the project requirements, corrected incorrect assumptions, and validated the final configuration with Terraform and workflow checks.

## Entry 1 — VPC and network isolation design

**Prompt:** I was building AWS infrastructure for a UK payroll platform handling highly sensitive data and needed a Terraform VPC module with tenant-isolated private subnets, outbound internet access for private resources, and clean tagging/output conventions.

**What AI helped with:** It proposed the initial module structure for the VPC, public/private subnet layout, route tables, NAT gateway placement, and reusable variables/outputs.###

**What I accepted:** The overall module shape, the idea of one public subnet per AZ for egress, and the pattern of exposing subnet IDs and gateway outputs cleanly to the root module.

**What I corrected manually:** I rejected an early placement that put the NAT gateway in a private subnet. I also added VPC Flow Logs and made sure the network model matched the assignment’s security intent, not just the minimum Terraform shape.

**Outcome:** A reusable VPC module with multi-AZ subnetting, internet egress, route tables, flow logs, and the tenant-aware foundation used by the rest of the stack.

## Entry 2 — Project completion and requirements traceability

**Prompt:** I asked AI to compare the repository against the assignment instructions and identify what was still missing.

**What AI helped with:** It surfaced gaps across documentation, monitoring, CI/CD, and operational runbooks, and helped prioritize the work that would matter most for a complete submission.

**What I accepted:** The project needed more than working Terraform; it also needed evidence of monitoring, incident response, deployment automation, and a clear record of design decisions.

**What I rejected:** I did not treat placeholder files as complete deliverables, and I did not rely on AI’s first pass as final without checking the repository state and assignment requirements.

**Outcome:** I added the missing project artifacts, including documentation files, a usable Terraform variables example, and the operational pieces needed to present a finished system rather than a partial prototype.

## Entry 3 — Architecture review and manual diagram support

**Prompt:** I asked AI to describe the full architecture represented by the current Terraform state so I could draw it manually.

**What AI helped with:** It summarized the dependency graph across VPC, subnets, NAT, EC2, RDS, S3, IAM, security groups, and monitoring, then translated that into a step-by-step drawing guide.

**What I accepted:** The dependency ordering and the tenant-isolation model were useful for creating a clean architecture diagram and for explaining the system coherently.

**What I rejected:** I did not use a diagram that omitted security or monitoring. I kept the drawing aligned to the actual deployed topology and the assignment’s privacy expectations.

**Outcome:** I produced a complete architecture view that I could reproduce manually and use in the final project documentation.

## Entry 4 — Final review against Project.pdf

**Prompt:** I asked AI to review the project PDF against the repository and help close the remaining gaps.

**What AI helped with:** It identified missing pieces around monitoring, compliance language, runbook content, and deployment workflow coverage.

**What I accepted:** The final submission should show end-to-end thinking: infrastructure, app delivery, monitoring, incident handling, and compliance awareness.

**What I rejected:** I did not accept a Terraform-only submission. I also corrected any suggestions that were too generic or not specific enough for a security-sensitive payroll system.

**Outcome:** I completed the remaining deliverables, then validated the repository with Terraform validation and workflow syntax checks so the final result was both documented and operationally sound.

## How I used AI responsibly

- I used AI to accelerate exploration, not to replace engineering judgment.
- I manually reviewed and corrected security-sensitive infrastructure decisions.
- I validated the final work with tooling rather than assuming AI output was correct.
- I kept the implementation aligned to the assignment requirements and the behavior of the actual AWS resources.