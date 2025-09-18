# Speech to Email Application

A Flutter application that records speech messages, converts them to text using AWS services, and sends them via email.

## Project Structure

```
├── speech_to_email_app/          # Flutter frontend application
│   ├── lib/
│   │   ├── services/             # Business logic services
│   │   ├── providers/            # State management
│   │   └── screens/              # UI screens
│   ├── android/                  # Android-specific configuration
│   ├── ios/                      # iOS-specific configuration
│   └── web/                      # Web-specific configuration
├── speech-to-email-backend/      # AWS CDK backend infrastructure
│   ├── lib/                      # CDK stack definitions
│   ├── lambda/                   # Lambda function implementations
│   └── bin/                      # CDK app entry point
└── .github/workflows/            # CI/CD pipeline definitions
```

## Features

- Cross-platform Flutter app (Web, iOS, Android)
- Audio recording with platform-specific permissions
- Secure upload to AWS S3
- Speech-to-text conversion using Amazon Transcribe
- Automated email delivery via Amazon SES
- Infrastructure as Code using AWS CDK
- Automated deployment with GitHub Actions

## Development Setup

### Prerequisites

- Flutter SDK 3.16+
- Node.js 18+
- AWS CLI configured
- AWS CDK CLI installed

### Flutter App Setup

```bash
cd speech_to_email_app
flutter pub get
flutter run
```

### Backend Setup

```bash
cd speech-to-email-backend
npm install
npm run build
npx cdk synth
```

## Deployment

The application uses GitHub Actions for automated deployment:

1. **Flutter App**: Deployed to S3 and served via CloudFront
2. **Backend Infrastructure**: Deployed using AWS CDK

### Environment Variables

Configure the following secrets in GitHub:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `S3_BUCKET_NAME`
- `CLOUDFRONT_DISTRIBUTION_ID`

## Architecture

The application follows a serverless, event-driven architecture:

1. User records audio in Flutter app
2. Audio uploaded to S3 with presigned URL
3. S3 upload triggers Lambda function
4. Lambda initiates Transcribe job
5. Transcription completion triggers email handler
6. Email sent via Amazon SES

## Implementation Status

This project is currently in development. See `tasks.md` for detailed implementation plan.

## License

This project is licensed under the MIT License.