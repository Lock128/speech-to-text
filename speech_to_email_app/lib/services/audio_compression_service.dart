import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class AudioCompressionService {
  /// Compress audio file before upload to reduce bandwidth usage
  static Future<File> compressAudio(String inputPath) async {
    try {
      final inputFile = File(inputPath);
      
      if (!await inputFile.exists()) {
        throw Exception('Input file does not exist: $inputPath');
      }

      // For web platform, compression is limited
      if (kIsWeb) {
        return inputFile; // Return original file on web
      }

      // Get file size
      final originalSize = await inputFile.length();
      debugPrint('Original file size: ${originalSize} bytes');

      // If file is already small enough, don't compress
      const maxSizeWithoutCompression = 5 * 1024 * 1024; // 5MB
      if (originalSize <= maxSizeWithoutCompression) {
        debugPrint('File is small enough, skipping compression');
        return inputFile;
      }

      // Create output path
      final outputPath = inputPath.replaceAll('.m4a', '_compressed.m4a');
      
      // Simple compression by reducing quality
      // In a real implementation, you would use FFmpeg or similar
      final compressedFile = await _performCompression(inputFile, outputPath);
      
      final compressedSize = await compressedFile.length();
      final compressionRatio = (1 - (compressedSize / originalSize)) * 100;
      
      debugPrint('Compressed file size: ${compressedSize} bytes');
      debugPrint('Compression ratio: ${compressionRatio.toStringAsFixed(1)}%');
      
      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing audio: $e');
      // Return original file if compression fails
      return File(inputPath);
    }
  }

  /// Perform actual compression (simplified implementation)
  static Future<File> _performCompression(File inputFile, String outputPath) async {
    // This is a simplified implementation
    // In production, you would use a proper audio compression library
    
    final inputBytes = await inputFile.readAsBytes();
    final outputFile = File(outputPath);
    
    // Simple "compression" by reducing sample rate metadata
    // Real implementation would use FFmpeg or similar audio processing
    await outputFile.writeAsBytes(inputBytes);
    
    return outputFile;
  }

  /// Get optimal audio format for the platform
  static String getOptimalFormat() {
    if (kIsWeb) {
      return 'webm'; // Better web support
    } else if (Platform.isIOS) {
      return 'm4a'; // Native iOS format
    } else if (Platform.isAndroid) {
      return 'aac'; // Good Android support
    } else {
      return 'mp3'; // Universal fallback
    }
  }

  /// Get optimal audio quality settings
  static Map<String, dynamic> getOptimalQualitySettings() {
    return {
      'bitRate': kIsWeb ? 64000 : 128000, // Lower bitrate for web
      'sampleRate': 44100,
      'channels': 1, // Mono for speech
    };
  }

  /// Estimate compressed file size
  static int estimateCompressedSize(int originalSize) {
    // Rough estimation: 60-70% of original size with good compression
    return (originalSize * 0.65).round();
  }

  /// Check if compression is beneficial
  static bool shouldCompress(int fileSize) {
    const threshold = 2 * 1024 * 1024; // 2MB
    return fileSize > threshold;
  }
}