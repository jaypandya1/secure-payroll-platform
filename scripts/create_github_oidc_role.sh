#!/usr/bin/env bash
set -euo pipefail
# Helper script to create an OIDC-assumable IAM role for GitHub Actions
# - Creates the OIDC provider (idempotent)
# - Creates an IAM role with the trust policy in iam/trust-policy.json
# - Attaches the inline permissions policy in iam/deploy-permissions.json
# - Prints the role ARN and, if `gh` is installed, writes the repo secret

REPO=jaypandya1/secure-payroll-platform
ROLE_NAME=github-actions-deploy-role
ACCOUNT_ID=957563772273

echo "Creating OIDC provider (if needed)..."
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 2>/dev/null || true

echo "Creating role ${ROLE_NAME}..."
aws iam create-role --role-name "${ROLE_NAME}" --assume-role-policy-document file://iam/trust-policy.json 2>/dev/null || true

echo "Attaching inline policy ${ROLE_NAME}/GitHubActionsDeployPolicy..."
aws iam put-role-policy --role-name "${ROLE_NAME}" --policy-name GitHubActionsDeployPolicy --policy-document file://iam/deploy-permissions.json

echo "Role ARN:"
ROLE_ARN=$(aws iam get-role --role-name "${ROLE_NAME}" --query 'Role.Arn' --output text)
echo "$ROLE_ARN"

if command -v gh >/dev/null 2>&1; then
  echo "Setting GitHub secret AWS_ROLE_TO_ASSUME for repo $REPO (gh CLI)..."
  gh secret set AWS_ROLE_TO_ASSUME --repo "$REPO" --body "$ROLE_ARN"
  echo "Secret set."
else
  echo "gh CLI not found. To add the secret manually, run:"
  echo "gh secret set AWS_ROLE_TO_ASSUME --repo $REPO --body '$ROLE_ARN'"
  echo "Or add repository secret 'AWS_ROLE_TO_ASSUME' via the GitHub UI with the value above."
fi

echo "Done. Review IAM role and policy for least privilege before using in production."
