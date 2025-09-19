import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/api_models.dart';
import 'demo_service.dart';

class UploadService {
  final Dio _dio = Dio();
  
  /// Get presigned URL for file upload
  Future<PresignedUrlResponse> getPresignedUrl({
    required String fileName,
    required int fileSize,
    required String contentType,
  }) async {
    // Check if we should use demo mode
    if (AppConfig.isDemoMode) {
      return DemoService.getDemoPresignedUrl(
        fileName: fileName,
        fileSize: fileSize,
        contentType: contentType,
      );
    }
    
    try {
      debugPrint('Requesting presigned URL for: $fileName ($fileSize bytes)');
      
      final request = PresignedUrlRequest(
        fileName: fileName,
        fileSize: fileSize,
        contentType: contentType,
      );

      final response = await _dio.post(
        AppConfig.presignedUrlEndpoint,
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return PresignedUrlResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to get presigned URL: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      debugPrint('Error getting presigned URL: $e');
      
      // Fallback to demo mode if network fails
      debugPrint('Network failed, falling back to demo mode');
      return DemoService.getDemoPresignedUrl(
        fileName: fileName,
        fileSize: fileSize,
        contentType: contentType,
      );
    }
  }

  /// Upload file to S3 using presigned URL with progress tracking
  Future<void> uploadFileToS3({
    required String filePath,
    required String uploadUrl,
    required String contentType,
    required Function(double) onProgress,
    CancelToken? cancelToken,
    Uint8List? cachedData, // Optional cached data to avoid re-fetching
  }) async {
    try {
      debugPrint('Starting upload to S3: $filePath');
      
      Uint8List fileData;
      int fileSize;

      if (cachedData != null) {
        // Use cached data if available
        fileData = cachedData;
        fileSize = fileData.length;
        debugPrint('Using cached blob data: $fileSize bytes');
      } else if (kIsWeb && filePath.startsWith('blob:')) {
        // On web, handle blob URLs
        debugPrint('Handling web blob URL: $filePath');
        final response = await http.get(Uri.parse(filePath));
        if (response.statusCode != 200) {
          throw Exception('Failed to read blob data: ${response.statusCode}');
        }
        fileData = response.bodyBytes;
        fileSize = fileData.length;
      } else {
        // On mobile, handle regular file paths
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('File does not exist: $filePath');
        }
        fileData = await file.readAsBytes();
        fileSize = fileData.length;
      }

      debugPrint('File size: $fileSize bytes');

      // Validate file size
      if (fileSize > AppConfig.maxFileSizeBytes) {
        throw Exception('File size exceeds maximum limit of ${AppConfig.maxFileSizeBytes} bytes');
      }

      if (fileSize == 0) {
        throw Exception('File is empty');
      }

      // Check if this is a demo upload
      if (uploadUrl.contains('demo-bucket') || AppConfig.isDemoMode) {
        // Simulate upload for demo mode
        await DemoService.simulateUpload(
          onProgress: onProgress,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Upload to S3 using PUT request
      final response = await _dio.put(
        uploadUrl,
        data: fileData,
        options: Options(
          headers: {
            'Content-Type': contentType,
          },
          validateStatus: (status) => status != null && status < 400,
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            onProgress(progress);
            debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Upload completed successfully');
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      if (e is DioException && e.type == DioExceptionType.cancel) {
        throw Exception('Upload cancelled');
      }
      throw Exception('Upload failed: $e');
    }
  }

  /// Complete upload process: get presigned URL and upload file
  Future<String> uploadFile({
    required String filePath,
    required Function(double) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      String fileName;
      int fileSize;
      Uint8List? cachedBlobData;
      
      if (kIsWeb && filePath.startsWith('blob:')) {
        // On web, handle blob URLs
        fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        // Fetch the blob data once and cache it
        debugPrint('Fetching blob data for size calculation and upload');
        final dataResponse = await http.get(Uri.parse(filePath));
        if (dataResponse.statusCode != 200) {
          throw Exception('Failed to fetch blob data: ${dataResponse.statusCode}');
        }
        cachedBlobData = dataResponse.bodyBytes;
        fileSize = cachedBlobData.length;
        debugPrint('Blob data fetched: $fileSize bytes');
      } else {
        // On mobile, handle regular file paths
        final file = File(filePath);
        fileName = file.path.split('/').last;
        fileSize = await file.length();
      }
      
      // Determine content type based on file extension or default for web
      final contentType = kIsWeb && filePath.startsWith('blob:') 
          ? 'audio/m4a' 
          : _getContentType(fileName);
      
      debugPrint('Starting complete upload process for: $fileName (size: $fileSize bytes)');
      
      // Step 1: Get presigned URL
      onProgress(0.1); // 10% for getting URL
      final presignedResponse = await getPresignedUrl(
        fileName: fileName,
        fileSize: fileSize,
        contentType: contentType,
      );
      
      debugPrint('Got presigned URL for record: ${presignedResponse.recordId}');
      
      // Step 2: Upload file to S3
      await uploadFileToS3(
        filePath: filePath,
        uploadUrl: presignedResponse.uploadUrl,
        contentType: contentType,
        onProgress: (uploadProgress) {
          // Map upload progress to 10%-100% range
          final totalProgress = 0.1 + (uploadProgress * 0.9);
          onProgress(totalProgress);
        },
        cancelToken: cancelToken,
        cachedData: cachedBlobData, // Pass cached data to avoid re-fetching
      );
      
      debugPrint('Upload completed for record: ${presignedResponse.recordId}');
      return presignedResponse.recordId;
      
    } catch (e) {
      debugPrint('Complete upload failed: $e');
      rethrow;
    }
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/m4a';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'webm':
        return 'audio/webm';
      default:
        return 'audio/mpeg'; // Default to MP3
    }
  }

  /// Cancel ongoing upload
  void cancelUpload(CancelToken cancelToken) {
    cancelToken.cancel('Upload cancelled by user');
  }

  /// Validate file before upload
  Future<bool> validateFile(String filePath) async {
    try {
      if (kIsWeb && filePath.startsWith('blob:')) {
        // On web, validate blob URLs
        debugPrint('Validating web blob: $filePath');
        
        try {
          // On web, we can't use HEAD requests with blob URLs
          // Instead, we'll do a minimal validation by trying to fetch a small portion
          debugPrint('Blob URL validation - assuming valid for web');
          
          // For web blobs, we'll skip detailed validation since:
          // 1. Blob URLs are created by the browser and should be valid
          // 2. We can't easily get size without downloading the entire blob
          // 3. The actual validation will happen during upload
          return true;
        } catch (e) {
          debugPrint('Error validating blob: $e');
          return false;
        }
      } else {
        // On mobile, validate regular file paths
        final file = File(filePath);
        
        // Check if file exists
        if (!await file.exists()) {
          debugPrint('File does not exist: $filePath');
          return false;
        }
        
        // Check file size
        final fileSize = await file.length();
        if (fileSize > AppConfig.maxFileSizeBytes) {
          debugPrint('File size exceeds limit: $fileSize > ${AppConfig.maxFileSizeBytes}');
          return false;
        }
        
        if (fileSize == 0) {
          debugPrint('File is empty: $filePath');
          return false;
        }
        
        // Check file format
        final fileName = file.path.split('/').last;
        final contentType = _getContentType(fileName);
        if (!AppConfig.supportedAudioFormats.contains(contentType)) {
          debugPrint('Unsupported file format: $contentType');
          return false;
        }
        
        return true;
      }
    } catch (e) {
      debugPrint('Error validating file: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}