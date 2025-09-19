# GitHub Actions OIDC Setup for AWS

This document explains how to set up OpenID Connect (OIDC) authentication between GitHub Actions and AWS, eliminating the need for long-lived access keys.

## Benefits of OIDC over Access Keys

- ✅ **Enhanced Security**: No long-lived credentials stored in GitHub
- ✅ **Automatic Rotation**: Tokens are short-lived and automatically rotated
- ✅ **Fine-grained Control**: Restrict access to specific repositories and branches
- ✅ **Audit Trail**: Better tracking of which workflows accessed AWS resources

## AWS Setup

### 1. Create OIDC Identity Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 2. Create IAM Role for Production

Create a file `github-actions-trust-policy.json`:

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

Create the role:

```bash
aws iam create-role \
  --role-name GitHubActions-SpeechToEmail-Prod \
  --assume-role-policy-document file://github-actions-trust-policy.json
```

### 3. Create IAM Role for Development

Create a similar role for development:

```bash
# Update the trust policy to be more restrictive for dev
aws iam create-role \
  --role-name GitHubActions-SpeechToEmail-Dev \
  --assume-role-policy-document file://github-actions-trust-policy-dev.json
```

### 4. Attach Policies to Roles

For CDK deployments, attach these policies:

```bash
# Production role
aws iam attach-role-policy \
  --role-name GitHubActions-SpeechToEmail-Prod \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Development role  
aws iam attach-role-policy \
  --role-name GitHubActions-SpeechToEmail-Dev \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

For Flutter web deployment, create a custom policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-web-bucket-name",
        "arn:aws:s3:::your-web-bucket-name/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations"
      ],
      "Resource": "arn:aws:cloudfront::YOUR-ACCOUNT-ID:distribution/YOUR-DISTRIBUTION-ID"
    }
  ]
}
```

## GitHub Secrets Configuration

Add these secrets to your GitHub repository:

### Required for CDK Deployment:
- `AWS_ROLE_TO_ASSUME`: `arn:aws:iam::YOUR-ACCOUNT-ID:role/GitHubActions-SpeechToEmail-Prod`
- `AWS_ROLE_TO_ASSUME_DEV`: `arn:aws:iam::YOUR-ACCOUNT-ID:role/GitHubActions-SpeechToEmail-Dev`
- `AWS_REGION`: `us-east-1` (or your preferred region)

### Required for Flutter Deployment:
- `S3_WEB_BUCKET_NAME`: Your S3 bucket name for web hosting
- `CLOUDFRONT_DISTRIBUTION_ID`: Your CloudFront distribution ID
- `CLOUDFRONT_DOMAIN_NAME`: Your CloudFront domain name
- `API_BASE_URL`: Your backend API URL

### Optional for Mobile Deployment:
- `FIREBASE_ANDROID_APP_ID`: Firebase app ID for Android
- `FIREBASE_SERVICE_ACCOUNT`: Firebase service account JSON

## Testing the Setup

1. Push a commit to the `develop` branch to test development deployment
2. Push a commit to the `main` branch to test production deployment
3. Check the Actions tab in GitHub to verify successful authentication

## Troubleshooting

### Common Issues:

1. **"No permission to assume role"**
   - Verify the trust policy includes your repository
   - Check that the role ARN is correct in GitHub secrets

2. **"Invalid identity token"**
   - Ensure the OIDC provider is created correctly
   - Verify the thumbprint is correct

3. **"Access denied for AWS operations"**
   - Check that the role has the necessary policies attached
   - Verify the resource ARNs in custom policies

### Debugging Commands:

```bash
# Check if OIDC provider exists
aws iam list-open-id-connect-providers

# Check role trust policy
aws iam get-role --role-name GitHubActions-SpeechToEmail-Prod

# List attached policies
aws iam list-attached-role-policies --role-name GitHubActions-SpeechToEmail-Prod
```

## Security Best Practices

1. **Principle of Least Privilege**: Only grant the minimum permissions needed
2. **Branch Restrictions**: Limit role assumption to specific branches
3. **Repository Restrictions**: Restrict access to your specific repository
4. **Regular Audits**: Periodically review and rotate roles
5. **Monitoring**: Set up CloudTrail to monitor role usage

## Migration from Access Keys

If you're migrating from access keys:

1. Set up OIDC as described above
2. Test the new setup thoroughly
3. Remove the old access key secrets from GitHub
4. Delete the old IAM users and access keys from AWS

This ensures a smooth transition with no downtime.