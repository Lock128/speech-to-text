import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recording_provider.dart';
import '../services/audio_recording_service.dart';
import '../widgets/recording_button.dart';
import '../widgets/recording_timer.dart';
import '../widgets/status_indicator.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late AudioRecordingService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = AudioRecordingService();
    _setupListeners();
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
        provider.updateState(RecordingState.stopped);
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
      await _audioService.cancelRecording();
      provider.reset();
    } catch (e) {
      provider.setError('Error canceling recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Email'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<RecordingProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status indicator
                StatusIndicator(state: provider.state),
                
                const SizedBox(height: 40),
                
                // Recording timer
                RecordingTimer(
                  duration: provider.recordingDuration,
                  isRecording: provider.isRecording,
                ),
                
                const SizedBox(height: 60),
                
                // Recording button
                RecordingButton(
                  state: provider.state,
                  onStartRecording: _startRecording,
                  onStopRecording: _stopRecording,
                  onCancelRecording: _cancelRecording,
                ),
                
                const SizedBox(height: 40),
                
                // Error message
                if (provider.hasError) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.errorMessage ?? 'An error occurred',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.reset(),
                    child: const Text('Try Again'),
                  ),
                ],
                
                // Upload progress
                if (provider.isUploading) ...[
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Text(
                        'Uploading... ${(provider.uploadProgress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: provider.uploadProgress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Processing indicator
                if (provider.isProcessing) ...[
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Processing your speech...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                
                // Completion message
                if (provider.isCompleted) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Email sent successfully!',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (provider.transcriptionText != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              provider.transcriptionText!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.reset(),
                    child: const Text('Record Another'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}