import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/api_models.dart';
import 'demo_service.dart';

class StatusService {
  final Dio _dio = Dio();
  Timer? _pollingTimer;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const Duration _maxPollingDuration = Duration(minutes: 10);
  
  // Stream controller for retry count updates
  final StreamController<int> _retryCountController = StreamController<int>.broadcast();
  
  // Getter for retry count stream
  Stream<int> get retryCountStream => _retryCountController.stream;

  /// Poll status for a specific record ID
  Stream<StatusResponse> pollStatus(String recordId) {
    // Use demo mode if enabled or if this is a demo record
    if (AppConfig.isDemoMode || recordId.startsWith('demo-record-')) {
      return DemoService.simulateStatusPolling(recordId);
    }
    
    final controller = StreamController<StatusResponse>();
    
    _startPolling(recordId, controller);
    
    // Set a shorter polling duration - assume success if backend doesn't respond
    Timer(Duration(minutes: 2), () {
      if (!controller.isClosed) {
        _stopPolling();
        controller.addError('Backend communication timeout - your recording is likely processed successfully. Please check your email.');
        controller.close();
      }
    });
    
    return controller.stream;
  }

  /// Start polling for status updates
  void _startPolling(String recordId, StreamController<StatusResponse> controller) {
    _retryCount = 0;
    _retryCountController.add(0);
    
    _pollingTimer = Timer.periodic(AppConfig.statusPollingInterval, (timer) async {
      try {
        final status = await getStatus(recordId);
        controller.add(status);
        _retryCount = 0; // Reset retry count on successful request
        
        // Stop polling if processing is complete or failed
        if (status.status == ProcessingStatus.emailSent || 
            status.status == ProcessingStatus.failed) {
          debugPrint('Processing completed with status: ${status.status}');
          timer.cancel();
          if (!controller.isClosed) {
            controller.close();
          }
        }
      } catch (e) {
        _retryCount++;
        _retryCountController.add(_retryCount);
        
        if (_retryCount >= _maxRetries) {
          timer.cancel();
          if (!controller.isClosed) {
            controller.addError('Unable to connect to server after $_maxRetries attempts. Your recording may still be processing - please check your email.');
            controller.close();
          }
        }
        // Continue polling on error if under retry limit
      }
    });
  }

  /// Get current status for a record ID
  Future<StatusResponse> getStatus(String recordId) async {
    try {
      debugPrint('Checking status for record: $recordId');
      
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/status/$recordId',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return StatusResponse.fromJson(response.data);
      } else if (response.statusCode == 404) {
        // Record not found, might still be processing
        return StatusResponse(
          recordId: recordId,
          status: ProcessingStatus.uploaded,
        );
      } else {
        throw Exception('Failed to get status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting status: $e');
      // Return a default status to keep polling
      return StatusResponse(
        recordId: recordId,
        status: ProcessingStatus.uploaded,
        errorMessage: 'Failed to check status: $e',
      );
    }
  }

  /// Stop polling
  void stopPolling() {
    _stopPolling();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _retryCount = 0;
  }

  /// Dispose resources
  void dispose() {
    stopPolling();
    _retryCountController.close();
    _dio.close();
  }
}