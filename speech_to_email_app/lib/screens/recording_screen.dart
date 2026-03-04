import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/recording_provider.dart';
import '../providers/auth_provider.dart';
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
import '../widgets/settings_form.dart';
import '../widgets/team_selector.dart';
import '../services/error_service.dart';
import '../config/app_config.dart';
import 'home_screen.dart';

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
  Timer? _processingTimeoutTimer;
  int _currentRetryCount = 0;

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
        debugPrint('Starting permission request process...');
        
        // First, try the audio service permission check
        final hasPermission = await _audioService.checkPermission();
        debugPrint('Audio service permission result: $hasPermission');
        
        if (!hasPermission && mounted) {
          // If that didn't work, try a direct permission request
          debugPrint('Trying direct permission request...');
          await _requestPermissionDirectly();
        }
      } catch (e) {
        debugPrint('Error requesting permissions: $e');
      }
    });
  }

  /// Try to request permission directly
  Future<void> _requestPermissionDirectly() async {
    try {
      // Import permission_handler directly
      final permission = Permission.microphone;
      final status = await permission.request();
      
      debugPrint('Direct permission request result: $status');
      
      if (!status.isGranted && mounted) {
        _showPermissionDialog();
      }
    } catch (e) {
      debugPrint('Error in direct permission request: $e');
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  /// Show permission dialog to user
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mikrofon-Berechtigung erforderlich'),
          content: const Text(
            'Diese App benötigt Zugriff auf Ihr Mikrofon, um Sprachnachrichten aufzunehmen. '
            'Bitte erteilen Sie die Mikrofon-Berechtigung, um fortzufahren.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final provider = context.read<RecordingProvider>();
                provider.setError('Mikrofon-Berechtigung verweigert. Aufnahme ist nicht verfügbar.');
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _testPermissions();
              },
              child: const Text('Berechtigung erteilen'),
            ),
          ],
        );
      },
    );
  }

  /// Test permissions with detailed logging
  Future<void> _testPermissions() async {
    try {
      debugPrint('=== Testing Permissions ===');
      
      // Test 1: Check current status
      final currentStatus = await Permission.microphone.status;
      debugPrint('Current status: $currentStatus');
      
      // Test 2: Request permission
      final requestResult = await Permission.microphone.request();
      debugPrint('Request result: $requestResult');
      
      // Test 3: Check status after request
      final newStatus = await Permission.microphone.status;
      debugPrint('Status after request: $newStatus');
      
      // Test 4: Try audio service check
      final audioServiceResult = await _audioService.checkPermission();
      debugPrint('Audio service result: $audioServiceResult');
      
      if (mounted) {
        final provider = context.read<RecordingProvider>();
        if (requestResult.isGranted || audioServiceResult) {
          provider.setError('Berechtigung erteilt! Sie können jetzt aufnehmen.');
        } else {
          provider.setError('Berechtigung weiterhin verweigert. Status: $newStatus');
        }
      }
      
    } catch (e) {
      debugPrint('Error in permission test: $e');
      if (mounted) {
        final provider = context.read<RecordingProvider>();
        provider.setError('Berechtigungstest fehlgeschlagen: $e');
      }
    }
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
    
    // Listen to retry count updates
    _statusService.retryCountStream.listen((retryCount) {
      if (mounted) {
        setState(() {
          _currentRetryCount = retryCount;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioService.dispose();
    _uploadService.dispose();
    _statusService.dispose();
    _uploadCancelToken?.cancel();
    _processingTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final provider = context.read<RecordingProvider>();
    
    try {
      final success = await _audioService.startRecording();
      if (!success) {
        provider.setError('Aufnahme konnte nicht gestartet werden. Bitte überprüfen Sie die Mikrofon-Berechtigungen.');
      }
    } catch (e) {
      provider.setError('Fehler beim Starten der Aufnahme: $e');
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
        provider.setError('Aufnahme konnte nicht gestoppt werden');
      }
    } catch (e) {
      provider.setError('Fehler beim Stoppen der Aufnahme: $e');
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
      _processingTimeoutTimer?.cancel();
      setState(() {
        _currentRetryCount = 0;
      });
      provider.reset();
    } catch (e) {
      provider.setError('Fehler beim Abbrechen der Aufnahme: $e');
    }
  }

  Future<void> _uploadRecording() async {
    final provider = context.read<RecordingProvider>();
    
    if (provider.recordingPath == null) {
      provider.setError('Keine Aufnahme zum Hochladen vorhanden');
      return;
    }

    try {
      // Validate file before upload
      final isValid = await _uploadService.validateFile(provider.recordingPath!);
      if (!isValid) {
        provider.setError('Ungültige Audiodatei. Bitte nehmen Sie erneut auf.');
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
        coachName: provider.coachName,
        pdfFileData: provider.selectedPdfFile?.bytes,
        pdfFileName: provider.selectedPdfFile?.name,
        teamName: provider.selectedTeam?.displayName,
        playerNames: provider.getEffectivePlayerList(),
      );

      provider.setRecordId(recordId);
      provider.updateState(RecordingState.processing);

      // Start polling for status updates
      _startStatusPolling(recordId);
      
      // Set a reasonable timeout to complete processing - assume success if polling fails
      _processingTimeoutTimer = Timer(Duration(seconds: 90), () {
        if (mounted) {
          final provider = context.read<RecordingProvider>();
          if (provider.state == RecordingState.processing) {
            _statusService.stopPolling();
            provider.updateState(RecordingState.completed);
            provider.setTranscriptionText('Verarbeitung erfolgreich abgeschlossen! Überprüfen Sie Ihre E-Mail für die Transkription.');
          }
        }
      });

    } catch (e) {
      if (e.toString().contains('cancelled')) {
        provider.updateState(RecordingState.reviewing);
      } else {
        provider.setError('Upload fehlgeschlagen: $e');
        // Note: setError preserves the recording path so user can still review audio
      }
    }
  }

  void _startStatusPolling(String recordId) {
    final provider = context.read<RecordingProvider>();
    
    _statusService.pollStatus(recordId).listen(
      (status) {
        if (!mounted) return;
        
        switch (status.status) {
          case ProcessingStatus.uploaded:
          case ProcessingStatus.transcribing:
          case ProcessingStatus.enhancingArticle:
            provider.updateState(RecordingState.processing);
            break;
          case ProcessingStatus.transcriptionCompleted:
          case ProcessingStatus.articleEnhanced:
            provider.updateState(RecordingState.processing);
            if (status.transcriptionText != null) {
              provider.setTranscriptionText(status.transcriptionText!);
            }
            break;
          case ProcessingStatus.emailSent:
            _processingTimeoutTimer?.cancel();
            provider.updateState(RecordingState.completed);
            if (status.transcriptionText != null) {
              provider.setTranscriptionText(status.transcriptionText!);
            }
            break;
          case ProcessingStatus.failed:
            _processingTimeoutTimer?.cancel();
            provider.setError('Verarbeitung fehlgeschlagen: ${status.errorMessage ?? 'Unbekannter Fehler'}');
            break;
        }
      },
      onError: (error) {
        if (!mounted) return;
        
        // Show error to user if polling fails
        _processingTimeoutTimer?.cancel();
        provider.setError('Status der Verarbeitung kann nicht überprüft werden. Ihre Aufnahme wird möglicherweise noch im Hintergrund verarbeitet. Bitte überprüfen Sie Ihre E-Mail.');
      },
      onDone: () {
        if (!mounted) return;
        
        // If polling completes without reaching final state, assume success
        if (provider.state == RecordingState.processing) {
          _processingTimeoutTimer?.cancel();
          provider.updateState(RecordingState.completed);
          provider.setTranscriptionText('Verarbeitung erfolgreich abgeschlossen! Überprüfen Sie Ihre E-Mail für die Transkription.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bericht hochladen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Debug button for testing permissions
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _testPermissions,
              tooltip: 'Berechtigungen testen',
            ),
        ],
      ),
      body: Consumer<RecordingProvider>(
        builder: (context, provider, child) {
          return Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              // Check if user is authenticated
              if (!authProvider.isAuthenticated) {
                return _buildUnauthenticatedView(context, authProvider);
              }

              // Show authenticated recording interface
              return SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 48, // Account for padding
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                        // Logo
                        Image.asset(
                          'images/cropped-logo-maenner-1-150x113.webp',
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                        
                        const SizedBox(height: 24),
                        
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
                        
                        // Team Selection
                        TeamSelector(
                          selectedTeam: provider.selectedTeam,
                          onTeamSelected: (team) {
                            provider.setSelectedTeam(team);
                          },
                          onCoachChanged: (coach) {
                            provider.setCoachName(coach);
                          },
                          onPlayersChanged: (players) {
                            provider.setCustomPlayerList(players);
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Settings Form (Optional)
                        const SettingsForm(),
                        
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
                                label: const Text('Neue Aufnahme'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _uploadRecording,
                                icon: const Icon(Icons.cloud_upload),
                                label: const Text('Hochladen & Senden'),
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
                                icon: const Icon(Icons.refresh),
                                label: const Text('Von vorne beginnen'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                              if (provider.error!.isRetryable) ...[
                                ElevatedButton.icon(
                                  onPressed: _handleErrorRetry,
                                  icon: const Icon(Icons.replay),
                                  label: const Text('Erneut versuchen'),
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
                            retryCount: _currentRetryCount,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Show "Record New" button during processing and "Record Another" when completed
                          if (provider.isProcessing) ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                // Cancel current processing and reset
                                _statusService.stopPolling();
                                provider.reset();
                              },
                              icon: const Icon(Icons.mic),
                              label: const Text('Neue Aufnahme'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                            ),
                          ] else if (provider.isCompleted) ...[
                            ElevatedButton.icon(
                              onPressed: () => provider.reset(),
                              icon: const Icon(Icons.mic),
                              label: const Text('Weitere Aufnahme'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
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
            },
          );
        },
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context, AuthProvider authProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Authentifizierung erforderlich',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              authProvider.selectedOrganization == null
                  ? 'Bitte wählen Sie eine Organisation aus und geben Sie Ihren Zugangscode in den Einstellungen ein, um die Upload-Funktion zu nutzen.'
                  : 'Bitte geben Sie Ihren Zugangscode in den Einstellungen ein, um die Upload-Funktion zu nutzen.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to settings tab
                final homeScreenState = context.findAncestorStateOfType<HomeScreenState>();
                homeScreenState?.navigateToSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Zu Einstellungen'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
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