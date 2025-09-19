# OIDC Troubleshooting Guide

## Common Issues and Solutions

### 1. **"No permission to assume role" Error**

This is the most common issue. Here are the steps to fix it:

#### Check 1: Verify OIDC Provider Exists
```bash
aws iam list-open-id-connect-providers
```

If it doesn't exist, create it:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 1c58a3a8518e8759bf075b76b750d4f2df264fcd
```

#### Check 2: Verify Trust Policy Format
Your IAM role trust policy should look EXACTLY like this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR-ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:YOUR-ORG/YOUR-REPO:ref:refs/heads/main",
            "repo:YOUR-ORG/YOUR-REPO:ref:refs/heads/develop"
          ]
        }
      }
    }
  ]
}
```

**CRITICAL**: Replace `YOUR-ACCOUNT-ID`, `YOUR-ORG`, and `YOUR-REPO` with your actual values!

#### Check 3: Verify Role ARN Format
Your role ARN should be:
```
arn:aws:iam::123456789012:role/YourRoleName
```

#### Check 4: Test Trust Policy
Create a test script to verify the trust policy:

```bash
#!/bin/bash
# test-oidc.sh

ROLE_ARN="arn:aws:iam::YOUR-ACCOUNT-ID:role/YOUR-ROLE-NAME"
REPO="YOUR-ORG/YOUR-REPO"

echo "Testing OIDC trust policy for role: $ROLE_ARN"
echo "Repository: $REPO"

# This should show your role's trust policy
aws iam get-role --role-name YOUR-ROLE-NAME --query 'Role.AssumeRolePolicyDocument'
```

### 2. **"Invalid identity token" Error**

This usually means the OIDC provider configuration is wrong.

#### Solution:
1. Delete the existing OIDC provider:
```bash
aws iam delete-open-id-connect-provider \
  --open-id-connect-provider-arn arn:aws:iam::YOUR-ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com
```

2. Recreate with correct thumbprints:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 1c58a3a8518e8759bf075b76b750d4f2df264fcd
```

### 3. **Repository/Branch Mismatch**

The trust policy must match EXACTLY:

#### For repository `myorg/myrepo`:
```json
"token.actions.githubusercontent.com:sub": [
  "repo:myorg/myrepo:ref:refs/heads/main",
  "repo:myorg/myrepo:ref:refs/heads/develop"
]
```

#### Common mistakes:
- ❌ `repo:MyOrg/MyRepo` (wrong case)
- ❌ `repo:myorg/myrepo:main` (missing `ref:refs/heads/`)
- ❌ `repo:myorg/myrepo:refs/heads/main` (missing `ref:`)

### 4. **Missing Permissions in Workflow**

Ensure your workflow has these permissions:

```yaml
permissions:
  id-token: write
  contents: read
```

### 5. **Account ID Mismatch**

Get your account ID:
```bash
aws sts get-caller-identity --query Account --output text
```

Make sure it matches in:
- OIDC provider ARN
- Role ARN
- Trust policy

## Step-by-Step Debugging

### Step 1: Verify Your Setup
Run these commands and verify the output:

```bash
# 1. Get your account ID
aws sts get-caller-identity

# 2. Check OIDC provider exists
aws iam list-open-id-connect-providers

# 3. Check your role exists
aws iam get-role --role-name YOUR-ROLE-NAME

# 4. Check role trust policy
aws iam get-role --role-name YOUR-ROLE-NAME --query 'Role.AssumeRolePolicyDocument'
```

### Step 2: Create Correct Trust Policy
Save this as `trust-policy.json` (replace the placeholders):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR-ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:YOUR-ORG/YOUR-REPO:ref:refs/heads/main",
            "repo:YOUR-ORG/YOUR-REPO:ref:refs/heads/develop"
          ]
        }
      }
    }
  ]
}
```

Update the role:
```bash
aws iam update-assume-role-policy \
  --role-name YOUR-ROLE-NAME \
  --policy-document file://trust-policy.json
```

### Step 3: Test with AWS CLI
You can't directly test OIDC from CLI, but you can verify the role works:

```bash
# Test assuming the role (this won't work from CLI, but will show if role exists)
aws sts assume-role \
  --role-arn arn:aws:iam::YOUR-ACCOUNT-ID:role/YOUR-ROLE-NAME \
  --role-session-name test-session
```

## Quick Fix Checklist

- [ ] OIDC provider exists with correct thumbprints
- [ ] Role exists and has correct ARN
- [ ] Trust policy uses exact repository name (case-sensitive)
- [ ] Trust policy includes `ref:refs/heads/` prefix
- [ ] Account ID matches everywhere
- [ ] Workflow has `id-token: write` permission
- [ ] GitHub secrets contain correct role ARN

## Example Working Configuration

### OIDC Provider:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 1c58a3a8518e8759bf075b76b750d4f2df264fcd
```

### Trust Policy (for repo `johndoe/speech-to-text`):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:johndoe/speech-to-text:ref:refs/heads/main",
            "repo:johndoe/speech-to-text:ref:refs/heads/develop"
          ]
        }
      }
    }
  ]
}
```

### GitHub Secrets:
- `AWS_ROLE_TO_ASSUME`: `arn:aws:iam::123456789012:role/GitHubActions-SpeechToEmail-Prod`
- `AWS_REGION`: `us-east-1`

## Still Having Issues?

If you're still having problems, run the debug step in your workflow and check:

1. The exact repository name in the GitHub token claims
2. The exact branch reference format
3. Whether your role ARN is correct
4. Whether your account ID matches

The debug output will show you exactly what GitHub is sending, which you can compare against your trust policy.