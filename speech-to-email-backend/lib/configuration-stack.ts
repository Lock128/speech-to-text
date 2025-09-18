import * as cdk from 'aws-cdk-lib';
import * as s3n from 'aws-cdk-lib/aws-s3-notifications';
import { Construct } from 'constructs';
import { StorageStack } from './storage-stack';
import { ProcessingStack } from './processing-stack';

interface ConfigurationStackProps extends cdk.StackProps {
  storageStack: StorageStack;
  processingStack: ProcessingStack;
}

export class ConfigurationStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: ConfigurationStackProps) {
    super(scope, id, props);

    const { storageStack, processingStack } = props;

    // S3 bucket notification to trigger upload handler
    storageStack.audioStorageBucket.addEventNotification(
      cdk.aws_s3.EventType.OBJECT_CREATED,
      new s3n.LambdaDestination(processingStack.uploadHandler)
    );
  }
}