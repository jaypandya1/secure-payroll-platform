# Incident Runbook

This runbook focuses on one high-risk incident: the RDS PostgreSQL instance being accidentally made public.

## 1. Detect

Signals:
- CloudWatch alarm for unusual RDS connectivity
- Terraform or console change showing `publicly_accessible = true`
- Security scan or manual review noticing public subnet exposure
- Unexpected connection attempts in database logs or VPC Flow Logs

Immediate checks:
- Verify the RDS instance is still in a private subnet group
- Confirm `publicly_accessible` is `false`
- Confirm the RDS security group only allows tenant EC2 security groups on port 5432
- Confirm route tables do not expose the DB subnet directly to the Internet Gateway

## 2. Investigate

Questions to answer:
- Was the change caused by Terraform drift, a manual console edit, or a bad module input?
- Did any security group rules widen access beyond tenant EC2 sources?
- Was any data actually accessed from outside the VPC boundary?

Evidence to review:
- Terraform plan or state history
- CloudTrail console/API events
- RDS events and CloudWatch metrics
- VPC Flow Logs for the DB subnet

## 3. Contain

Actions:
- Revert the RDS instance to `publicly_accessible = false`
- Reapply Terraform immediately if drift caused the exposure
- Narrow the RDS security group to tenant EC2 security groups only
- If needed, temporarily disable application access while restoring the boundary

## 4. Recover

Recovery order:
1. Restore private-only access
2. Validate connections only work from tenant EC2 instances
3. Confirm alarms return to normal
4. Check application logs for failed or suspicious access attempts
5. Record the incident and the fix in the operational log

## 5. Prevent recurrence

- Keep `publicly_accessible = false` in Terraform and review changes through pull requests
- Add a plan check or policy gate to block public RDS settings
- Keep tenant-specific security groups and subnet routing unchanged
- Review CloudWatch alarms and VPC Flow Logs after every infrastructure change
