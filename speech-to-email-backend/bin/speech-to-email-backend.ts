#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { SpeechToEmailStack } from '../lib/speech-to-email-stack';

const app = new cdk.App();

// Environment configuration
const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
};

// Create the main stack
new SpeechToEmailStack(app, 'SpeechToEmailStack', {
  env,
  description: 'Speech to Email application infrastructure',
});