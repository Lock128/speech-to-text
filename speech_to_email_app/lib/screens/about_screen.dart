import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'images/cropped-logo-maenner-1-150x113.webp',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'HC VfL Speech to Text',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Welcome to the HC VfL Speech to Text application!',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              
              _buildFeatureCard(
                context,
                icon: Icons.mic,
                title: 'Voice Recording',
                description: 'Record your speech messages directly from your device with high-quality audio capture.',
              ),
              const SizedBox(height: 16),
              
              _buildFeatureCard(
                context,
                icon: Icons.text_fields,
                title: 'Transcription',
                description: 'Automatically convert your voice recordings into accurate text transcriptions.',
              ),
              const SizedBox(height: 16),
              
              _buildFeatureCard(
                context,
                icon: Icons.email,
                title: 'Email Delivery',
                description: 'Receive your transcriptions directly via email for easy access and sharing.',
              ),
              const SizedBox(height: 16),
              
              _buildFeatureCard(
                context,
                icon: Icons.picture_as_pdf,
                title: 'PDF Support',
                description: 'Attach PDF files to enhance your reports with additional context.',
              ),
              const SizedBox(height: 32),
              
              Text(
                'How It Works',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildStep(context, 1, 'Navigate to the Upload tab'),
              _buildStep(context, 2, 'Record your message using the microphone'),
              _buildStep(context, 3, 'Review your recording'),
              _buildStep(context, 4, 'Upload and send for transcription'),
              _buildStep(context, 5, 'Receive the transcription via email'),
              
              const SizedBox(height: 32),
              
              const Divider(),
              const SizedBox(height: 16),
              
              Text(
                'Version 1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
