import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _durationTimer;
  Duration _recordingDuration = Duration.zero;
  String? _currentRecordingPath;

  // Stream controllers for real-time updates
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<bool> _recordingStateController = StreamController<bool>.broadcast();

  // Getters for streams
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<bool> get recordingStateStream => _recordingStateController.stream;

  // Getters
  Duration get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;
  Future<bool> get isRecording => _recorder.isRecording();

  /// Check and request microphone permission
  Future<bool> checkPermission() async {
    try {
      debugPrint('Checking microphone permission...');
      final status = await Permission.microphone.status;
      debugPrint('Current permission status: $status');
      
      if (status.isGranted) {
        debugPrint('Permission already granted');
        return true;
      }
      
      if (status.isDenied || status.isRestricted) {
        debugPrint('Permission denied/restricted, requesting...');
        final result = await Permission.microphone.request();
        debugPrint('Permission request result: $result');
        
        // On iOS, if permission request doesn't work properly, we'll still try to record
        // The native recording API will handle the permission internally
        if (!result.isGranted && Platform.isIOS) {
          debugPrint('iOS permission request failed, but allowing recording attempt');
          return true; // Allow recording attempt on iOS even if permission_handler fails
        }
        
        return result.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        debugPrint('Permission permanently denied');
        // On iOS, still allow recording attempt as the native API might work
        if (Platform.isIOS) {
          debugPrint('iOS: Allowing recording attempt despite permanently denied status');
          return true;
        }
        // On Android, open settings
        await openAppSettings();
        return false;
      }
      
      // For any other status, try to request
      debugPrint('Unknown status, attempting to request permission');
      final result = await Permission.microphone.request();
      debugPrint('Permission request result: $result');
      
      // On iOS, allow recording attempt even if permission_handler is unclear
      if (!result.isGranted && Platform.isIOS) {
        debugPrint('iOS: Permission unclear, but allowing recording attempt');
        return true;
      }
      
      return result.isGranted;
      
    } catch (e) {
      debugPrint('Error checking microphone permission: $e');
      // On iOS, allow recording attempt even if permission check fails
      if (Platform.isIOS) {
        debugPrint('iOS: Permission check failed, but allowing recording attempt');
        return true;
      }
      return false;
    }
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check permission first (but on iOS, we're lenient about the result)
      final hasPermission = await checkPermission();
      if (!hasPermission && !Platform.isIOS) {
        throw Exception('Microphone permission not granted');
      }

      // Check if already recording
      if (await _recorder.isRecording()) {
        debugPrint('Already recording');
        return false;
      }

      // Generate file path - handle web vs mobile differently
      String recordingPath;
      if (kIsWeb) {
        // On web, we don't need a file path - the record package handles it
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        recordingPath = 'recording_$timestamp.m4a';
        _currentRecordingPath = recordingPath;
      } else {
        // On mobile, use the documents directory
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        recordingPath = '${directory.path}/recording_$timestamp.m4a';
        _currentRecordingPath = recordingPath;
      }

      // Configure recording settings
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      // Start recording - let the native API handle permissions internally
      await _recorder.start(config, path: recordingPath);
      
      // Reset duration and start timer
      _recordingDuration = Duration.zero;
      _startDurationTimer();
      
      _recordingStateController.add(true);
      debugPrint('Recording started: $_currentRecordingPath');
      
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _recordingStateController.add(false);
      
      // If recording fails on iOS due to permissions, show a helpful message
      if (Platform.isIOS && e.toString().contains('permission')) {
        debugPrint('iOS recording failed due to permissions. User should check Settings > Privacy & Security > Microphone');
      }
      
      return false;
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    try {
      if (!await _recorder.isRecording()) {
        debugPrint('Not currently recording');
        return null;
      }

      // Stop recording
      final path = await _recorder.stop();
      
      // Stop duration timer
      _stopDurationTimer();
      
      _recordingStateController.add(false);
      debugPrint('Recording stopped: $path');
      
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _recordingStateController.add(false);
      return null;
    }
  }

  /// Pause recording (if supported)
  Future<bool> pauseRecording() async {
    try {
      if (!await _recorder.isRecording()) {
        return false;
      }

      await _recorder.pause();
      _stopDurationTimer();
      debugPrint('Recording paused');
      
      return true;
    } catch (e) {
      debugPrint('Error pausing recording: $e');
      return false;
    }
  }

  /// Resume recording (if supported)
  Future<bool> resumeRecording() async {
    try {
      if (await _recorder.isRecording()) {
        return false;
      }

      await _recorder.resume();
      _startDurationTimer();
      debugPrint('Recording resumed');
      
      return true;
    } catch (e) {
      debugPrint('Error resuming recording: $e');
      return false;
    }
  }

  /// Cancel current recording and delete file
  Future<bool> cancelRecording() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      
      _stopDurationTimer();
      _recordingDuration = Duration.zero;
      
      // Delete the recording file if it exists (mobile only)
      if (_currentRecordingPath != null && !kIsWeb) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Recording file deleted: $_currentRecordingPath');
        }
      }
      _currentRecordingPath = null;
      
      _recordingStateController.add(false);
      _durationController.add(Duration.zero);
      
      return true;
    } catch (e) {
      debugPrint('Error canceling recording: $e');
      return false;
    }
  }

  /// Get file size of the current recording
  Future<int?> getRecordingFileSize() async {
    if (_currentRecordingPath == null) return null;
    
    try {
      if (kIsWeb) {
        // On web, we can't easily get file size before upload
        // Return null to skip size validation
        return null;
      } else {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          return await file.length();
        }
      }
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
    
    return null;
  }

  /// Check if recording duration exceeds maximum allowed
  bool isRecordingTooLong() {
    return _recordingDuration.inMinutes >= AppConfig.maxRecordingDurationMinutes;
  }

  /// Start the duration timer
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(AppConfig.recordingUpdateInterval, (timer) {
      _recordingDuration = Duration(milliseconds: _recordingDuration.inMilliseconds + 100);
      _durationController.add(_recordingDuration);
      
      // Auto-stop if maximum duration reached
      if (isRecordingTooLong()) {
        stopRecording();
      }
    });
  }

  /// Stop the duration timer
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// Dispose resources
  void dispose() {
    _stopDurationTimer();
    _durationController.close();
    _recordingStateController.close();
    _recorder.dispose();
  }
}