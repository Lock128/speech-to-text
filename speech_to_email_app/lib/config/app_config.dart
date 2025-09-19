class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod',
  );
  
  static const String presignedUrlEndpoint = '$apiBaseUrl/presigned-url';
  
  // Demo mode for testing without backend
  static const bool isDemoMode = String.fromEnvironment('DEMO_MODE', defaultValue: 'false') == 'true';
  
  // Recording Configuration
  static const int maxRecordingDurationMinutes = 5;
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB
  
  // Supported audio formats
  static const List<String> supportedAudioFormats = [
    'audio/mpeg',
    'audio/mp3',
    'audio/wav',
    'audio/m4a',
    'audio/aac',
    'audio/ogg',
    'audio/webm',
  ];
  
  // UI Configuration
  static const Duration recordingUpdateInterval = Duration(milliseconds: 100);
  static const Duration statusPollingInterval = Duration(seconds: 5);
}