import 'package:flutter/foundation.dart';

class PerformanceConfig {
  // Network optimization
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 120);
  
  // Cache configuration
  static const Duration apiCacheTtl = Duration(minutes: 5);
  static const Duration statusCacheTtl = Duration(seconds: 30);
  static const int maxCacheSize = 10 * 1024 * 1024; // 10MB
  
  // Upload optimization
  static const int uploadChunkSize = 1024 * 1024; // 1MB chunks
  static const int maxConcurrentUploads = 3;
  static const Duration uploadRetryDelay = Duration(seconds: 2);
  
  // UI performance
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Duration debounceDelay = Duration(milliseconds: 300);
  static const int maxHistoryItems = 50;
  
  // Audio recording optimization
  static const int optimalSampleRate = kIsWeb ? 22050 : 44100;
  static const int optimalBitRate = kIsWeb ? 64000 : 128000;
  static const bool useMonoAudio = true; // Better for speech
  
  // Memory management
  static const int maxAudioFileSize = 50 * 1024 * 1024; // 50MB
  static const Duration tempFileCleanupInterval = Duration(hours: 1);
  
  // Platform-specific optimizations
  static bool get useNativeCompression => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  static bool get enableBackgroundProcessing => !kIsWeb;
  static bool get useHardwareAcceleration => !kIsWeb;
  
  // Development vs Production settings
  static bool get isDebugMode => kDebugMode;
  static Duration get logFlushInterval => isDebugMode ? Duration(seconds: 1) : Duration(minutes: 5);
  static bool get enableDetailedLogging => isDebugMode;
  
  // Feature flags for performance testing
  static const bool enableAudioCompression = true;
  static const bool enableProgressiveUpload = true;
  static const bool enableOfflineMode = true;
  static const bool enablePredictivePreloading = false; // Experimental
}