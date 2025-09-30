import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/api_models.dart';

class DemoService {
  /// Simulate getting a presigned URL
  static Future<PresignedUrlResponse> getDemoPresignedUrl({
    required String fileName,
    required int fileSize,
    required String contentType,
  }) async {
    debugPrint('DEMO MODE: Simulating presigned URL request for $fileName');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return PresignedUrlResponse(
      uploadUrl: 'https://demo-bucket.s3.amazonaws.com/demo-upload-url',
      recordId: 'demo-record-${DateTime.now().millisecondsSinceEpoch}',
      expiresIn: 3600,
    );
  }
  
  /// Simulate uploading to S3
  static Future<void> simulateUpload({
    required Function(double) onProgress,
    required Duration duration,
  }) async {
    debugPrint('DEMO MODE: Simulating file upload');
    
    const totalSteps = 20;
    for (int i = 0; i <= totalSteps; i++) {
      await Future.delayed(duration ~/ totalSteps);
      final progress = i / totalSteps;
      onProgress(progress);
      debugPrint('DEMO MODE: Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
    }
    
    debugPrint('DEMO MODE: Upload completed successfully');
  }
  
  /// Simulate status polling
  static Stream<StatusResponse> simulateStatusPolling(String recordId) async* {
    debugPrint('DEMO MODE: Starting status polling for $recordId');
    
    // Simulate uploaded status
    await Future.delayed(const Duration(seconds: 1));
    yield StatusResponse(
      recordId: recordId,
      status: ProcessingStatus.uploaded,
    );
    
    // Simulate transcribing status
    await Future.delayed(const Duration(seconds: 2));
    yield StatusResponse(
      recordId: recordId,
      status: ProcessingStatus.transcribing,
      progress: 0.3,
    );
    
    // Simulate transcription completed
    await Future.delayed(const Duration(seconds: 3));
    yield StatusResponse(
      recordId: recordId,
      status: ProcessingStatus.transcriptionCompleted,
      statusDescription: 'Transcription complete, enhancing article...',
      transcriptionText: 'This is a demo transcription of your audio recording. In the real app, this would be the actual speech-to-text conversion of your audio.',
      progress: 0.6,
    );
    
    // Simulate article enhancement
    await Future.delayed(const Duration(seconds: 2));
    yield StatusResponse(
      recordId: recordId,
      status: ProcessingStatus.enhancingArticle,
      statusDescription: 'Creating newspaper article with AI...',
      transcriptionText: 'This is a demo transcription of your audio recording. In the real app, this would be the actual speech-to-text conversion of your audio.',
      progress: 0.8,
    );
    
    // Simulate article enhanced
    await Future.delayed(const Duration(seconds: 2));
    yield StatusResponse(
      recordId: recordId,
      status: ProcessingStatus.articleEnhanced,
      statusDescription: 'Article enhanced, sending email...',
      transcriptionText: 'This is a demo transcription of your audio recording. In the real app, this would be the actual speech-to-text conversion of your audio.',
      enhancedArticleText: '<h1>Demo-Zeitungsartikel</h1><p>Dies ist ein Beispiel für einen KI-generierten Zeitungsartikel basierend auf Ihrer Sprachaufnahme. Der echte Artikel würde professionell formatiert und auf Deutsch verfasst sein.</p>',
      progress: 0.9,
    );
    
    // Simulate email sent
    await Future.delayed(const Duration(seconds: 1));
    yield StatusResponse(
      recordId: recordId,
      status: ProcessingStatus.emailSent,
      statusDescription: 'Process complete! Email sent successfully.',
      transcriptionText: 'This is a demo transcription of your audio recording. In the real app, this would be the actual speech-to-text conversion of your audio.',
      enhancedArticleText: '<h1>Demo-Zeitungsartikel</h1><p>Dies ist ein Beispiel für einen KI-generierten Zeitungsartikel basierend auf Ihrer Sprachaufnahme. Der echte Artikel würde professionell formatiert und auf Deutsch verfasst sein.</p>',
      progress: 1.0,
    );
    
    debugPrint('DEMO MODE: Status polling completed');
  }
}