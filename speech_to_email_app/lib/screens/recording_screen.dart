import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/recording_provider.dart';
import '../services/audio_recording_service.dart';
import '../services/upload_service.dart';
import '../services/status_service.dart';
import '../models/api_models.dart';
import '../widgets/recording_button.dart';
import '../widgets/recording_timer.dart';
import '../widgets/status_indicator.dart';
import '../widgets/progress_indicator.dart';
import '../widgets/error_display.dart';
import '../widgets/audio_player.dart';
import '../services/error_service.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late AudioRecordingService _audioService;
  late UploadService _uploadService;
  late StatusService _statusService;
  CancelToken? _uploadCancelToken;

  @override
  void initState() {
    super.initState();
    _audioService = AudioRecordingService();
    _uploadService = UploadService();
    _statusService = StatusService();
    _setupListeners();
    _requestPermissions();
  }

  /// Request microphone permissions on app startup
  void _requestPermissions() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final hasPermission = await _audioService.checkPermission();
        if (!hasPermission && mounted) {
          _showPermissionDialog();
        }
      } catch (e) {
        debugPrint('Error requesting permissions: $e');
      }
    });
  }

  /// Show permission dialog to user
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Microphone Permission Required'),
          content: const Text(
            'This app needs access to your microphone to record speech messages. '
            'Please grant microphone permission to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final provider = context.read<RecordingProvider>();
                provider.setError('Microphone permission denied. Recording is not available.');
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final hasPermission = await _audioService.checkPermission();
                if (!hasPermission && mounted) {
                  final provider = context.read<RecordingProvider>();
                  provider.setError('Microphone permission is required. Please grant permission in Settings.');
                }
              },
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );
  }

  void _setupListeners() {
    final provider = context.read<RecordingProvider>();
    
    // Listen to recording duration updates
    _audioService.durationStream.listen((duration) {
      provider.updateRecordingDuration(duration);
    });
    
    // Listen to recording state changes
    _audioService.recordingStateStream.listen((isRecording) {
      if (isRecording) {
        provider.updateState(RecordingState.recording);
      } else if (provider.state == RecordingState.recording) {
        provider.updateState(RecordingState.stopped);
      }
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    _uploadService.dispose();
    _statusService.dispose();
    _uploadCancelToken?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final provider = context.read<RecordingProvider>();
    
    try {
      final success = await _audioService.startRecording();
      if (!success) {
        provider.setError('Failed to start recording. Please check microphone permissions.');
      }
    } catch (e) {
      provider.setError('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    final provider = context.read<RecordingProvider>();
    
    try {
      final recordingPath = await _audioService.stopRecording();
      if (recordingPath != null) {
        provider.setRecordingPath(recordingPath);
        provider.updateState(RecordingState.reviewing);
      } else {
        provider.setError('Failed to stop recording');
      }
    } catch (e) {
      provider.setError('Error stopping recording: $e');
    }
  }

  Future<void> _cancelRecording() async {
    final provider = context.read<RecordingProvider>();
    
    try {
      // Cancel upload if in progress
      if (provider.isUploading && _uploadCancelToken != null) {
        _uploadCancelToken!.cancel();
      }
      
      await _audioService.cancelRecording();
      _statusService.stopPolling();
      provider.reset();
    } catch (e) {
      provider.setError('Error canceling recording: $e');
    }
  }

  Future<void> _uploadRecording() async {
    final provider = context.read<RecordingProvider>();
    
    if (provider.recordingPath == null) {
      provider.setError('No recording to upload');
      return;
    }

    try {
      // Validate file before upload
      final isValid = await _uploadService.validateFile(provider.recordingPath!);
      if (!isValid) {
        provider.setError('Invalid audio file. Please record again.');
        return;
      }

      provider.updateState(RecordingState.uploading);
      _uploadCancelToken = CancelToken();

      // Upload file with progress tracking
      final recordId = await _uploadService.uploadFile(
        filePath: provider.recordingPath!,
        onProgress: (progress) {
          provider.updateUploadProgress(progress);
        },
        cancelToken: _uploadCancelToken,
      );

      provider.setRecordId(recordId);
      provider.updateState(RecordingState.processing);

      // Start polling for status updates
      _startStatusPolling(recordId);

    } catch (e) {
      if (e.toString().contains('cancelled')) {
        provider.updateState(RecordingState.reviewing);
      } else {
        provider.setError('Upload failed: $e');
        // Note: setError preserves the recording path so user can still review audio
      }
    }
  }

  void _startStatusPolling(String recordId) {
    final provider = context.read<RecordingProvider>();
    
    _statusService.pollStatus(recordId).listen(
      (status) {
        switch (status.status) {
          case ProcessingStatus.uploaded:
          case ProcessingStatus.transcribing:
            provider.updateState(RecordingState.processing);
            break;
          case ProcessingStatus.transcriptionCompleted:
            provider.updateState(RecordingState.processing);
            if (status.transcriptionText != null) {
              provider.setTranscriptionText(status.transcriptionText!);
            }
            break;
          case ProcessingStatus.emailSent:
            provider.updateState(RecordingState.completed);
            if (status.transcriptionText != null) {
              provider.setTranscriptionText(status.transcriptionText!);
            }
            break;
          case ProcessingStatus.failed:
            provider.setError(status.errorMessage ?? 'Processing failed');
            break;
        }
      },
      onError: (error) {
        debugPrint('Status polling error: $error');
        // Don't show error to user for polling failures, just log them
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HC VfL Speech to Text'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<RecordingProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom - 
                    kToolbarHeight - 48, // Account for AppBar and padding
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status indicator
                    StatusIndicator(state: provider.state),
                    
                    const SizedBox(height: 32),
                    
                    // Recording timer
                    RecordingTimer(
                      duration: provider.recordingDuration,
                      isRecording: provider.isRecording,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Recording button
                    RecordingButton(
                      state: provider.state,
                      onStartRecording: _startRecording,
                      onStopRecording: _stopRecording,
                      onCancelRecording: _cancelRecording,
                      onUploadRecording: _uploadRecording,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Audio review section
                    if (provider.isReviewing && provider.recordingPath != null) ...[
                      AudioPlayerWidget(
                        audioPath: provider.recordingPath!,
                        duration: provider.recordingDuration,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              provider.reset();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Record New'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _uploadRecording,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Upload & Send'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Error display with audio player if recording exists
                    if (provider.hasError && provider.error != null) ...[
                      ErrorDisplay(
                        error: provider.error!,
                        onRetry: provider.error!.isRetryable ? _handleErrorRetry : null,
                        onDismiss: () => provider.clearError(),
                        showDetails: true,
                      ),
                      const SizedBox(height: 16),
                      
                      // Show audio player even during error if recording exists
                      if (provider.recordingPath != null) ...[
                        AudioPlayerWidget(
                          audioPath: provider.recordingPath!,
                          duration: provider.recordingDuration,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Action buttons for error state
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              provider.reset();
                            },
                            icon: const Icon(Icons.mic),
                            label: const Text('Record New'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                          if (provider.error!.isRetryable) ...[
                            ElevatedButton.icon(
                              onPressed: _handleErrorRetry,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Progress indicator for upload/processing/completion
                    if (provider.isUploading || provider.isProcessing || provider.isCompleted) ...[
                      ProcessingProgressIndicator(
                        state: provider.state,
                        uploadProgress: provider.uploadProgress,
                        transcriptionText: provider.transcriptionText,
                      ),
                      
                      if (provider.isCompleted) ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => provider.reset(),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text('Record Another'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleErrorRetry() {
    final provider = context.read<RecordingProvider>();
    
    if (provider.error == null) return;

    switch (provider.error!.type) {
      case ErrorType.permission:
        // Clear error and try to start recording again (will re-check permissions)
        provider.clearError();
        _startRecording();
        break;
      case ErrorType.network:
        // Retry upload if there's a recording path
        if (provider.recordingPath != null) {
          provider.clearError();
          _uploadRecording();
        } else {
          provider.reset();
        }
        break;
      case ErrorType.fileSystem:
      case ErrorType.server:
      case ErrorType.timeout:
        // Retry the last operation
        if (provider.recordingPath != null && provider.state == RecordingState.error) {
          provider.clearError();
          _uploadRecording();
        } else {
          provider.reset();
        }
        break;
      default:
        // For other errors, just reset
        provider.reset();
        break;
    }
  }
}