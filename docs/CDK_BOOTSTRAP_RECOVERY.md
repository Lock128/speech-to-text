# CDK Bootstrap Recovery Guide

## Issue: ECR Repository Not Found During Bootstrap

When you see this error:
```
Resource handler returned message: "The repository with name 'cdk-hnb659fds-container-assets-345856669986-***' does not exist in the registry with id '345856669986'"
```

This means the CDK bootstrap is in an inconsistent state.

## Quick Fix Commands

### Option 1: Force Re-bootstrap (Recommended)
```bash
cd speech-to-email-backend
npx cdk bootstrap --force
```

### Option 2: Delete and Recreate Bootstrap Stack
```bash
# 1. Delete the failed CDKToolkit stack
aws cloudformation delete-stack --stack-name CDKToolkit --region YOUR_REGION

# 2. Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name CDKToolkit --region YOUR_REGION

# 3. Bootstrap fresh
cd speech-to-email-backend
npx cdk bootstrap
```

### Option 3: Manual ECR Repository Creation
If the above doesn't work, you can manually create the missing ECR repository:

```bash
# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create the missing ECR repository
aws ecr create-repository \
  --repository-name "cdk-hnb659fds-container-assets-${ACCOUNT_ID}-YOUR_REGION" \
  --region YOUR_REGION

# Then retry bootstrap
cd speech-to-email-backend
npx cdk bootstrap
```

## Prevention

To prevent this issue in the future:

1. Always use `--force` flag when re-bootstrapping
2. Don't manually delete CDK bootstrap resources
3. Use consistent CDK versions across environments
4. Monitor CloudFormation stack status before deployments

## Verification

After fixing, verify the bootstrap worked:

```bash
# Check CDKToolkit stack status
aws cloudformation describe-stacks --stack-name CDKToolkit --region YOUR_REGION

# List ECR repositories to confirm creation
aws ecr describe-repositories --region YOUR_REGION

# Test CDK synth
cd speech-to-email-backend
npx cdk synth --all
```