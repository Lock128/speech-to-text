import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_email_app/providers/recording_provider.dart';
import 'package:speech_to_email_app/services/error_service.dart';

void main() {
  group('RecordingProvider', () {
    late RecordingProvider provider;

    setUp(() {
      provider = RecordingProvider();
    });

    group('State Management', () {
      test('should initialize with idle state', () {
        expect(provider.state, RecordingState.idle);
        expect(provider.recordingPath, isNull);
        expect(provider.recordId, isNull);
        expect(provider.recordingDuration, Duration.zero);
        expect(provider.error, isNull);
        expect(provider.uploadProgress, 0.0);
        expect(provider.transcriptionText, isNull);
      });

      test('should update state correctly', () {
        provider.updateState(RecordingState.recording);
        expect(provider.state, RecordingState.recording);
        expect(provider.isRecording, isTrue);
      });

      test('should update recording duration', () {
        const duration = Duration(seconds: 30);
        provider.updateRecordingDuration(duration);
        expect(provider.recordingDuration, duration);
      });

      test('should set recording path', () {
        const path = '/test/recording.m4a';
        provider.setRecordingPath(path);
        expect(provider.recordingPath, path);
      });

      test('should set record ID', () {
        const recordId = 'test-record-id';
        provider.setRecordId(recordId);
        expect(provider.recordId, recordId);
      });
    });

    group('Error Handling', () {
      test('should handle string errors', () {
        const errorMessage = 'Test error message';
        provider.setError(errorMessage);
        
        expect(provider.hasError, isTrue);
        expect(provider.state, RecordingState.error);
        expect(provider.error, isA<AppError>());
        expect(provider.errorMessage, contains('Test error'));
      });

      test('should handle exception errors', () {
        final exception = Exception('Test exception');
        provider.setError(exception);
        
        expect(provider.hasError, isTrue);
        expect(provider.error?.type, ErrorType.unknown);
      });

      test('should clear errors', () {
        provider.setError('Test error');
        expect(provider.hasError, isTrue);
        
        provider.clearError();
        expect(provider.hasError, isFalse);
        expect(provider.error, isNull);
      });
    });

    group('Upload Progress', () {
      test('should update upload progress', () {
        provider.updateUploadProgress(0.5);
        expect(provider.uploadProgress, 0.5);
        
        provider.updateUploadProgress(1.0);
        expect(provider.uploadProgress, 1.0);
      });

      test('should track upload state', () {
        provider.updateState(RecordingState.uploading);
        expect(provider.isUploading, isTrue);
        expect(provider.isProcessing, isFalse);
        expect(provider.isCompleted, isFalse);
      });
    });

    group('Transcription', () {
      test('should set transcription text', () {
        const text = 'This is the transcribed text';
        provider.setTranscriptionText(text);
        expect(provider.transcriptionText, text);
      });

      test('should track processing state', () {
        provider.updateState(RecordingState.processing);
        expect(provider.isProcessing, isTrue);
        expect(provider.isUploading, isFalse);
        expect(provider.isCompleted, isFalse);
      });

      test('should track completed state', () {
        provider.updateState(RecordingState.completed);
        expect(provider.isCompleted, isTrue);
        expect(provider.isProcessing, isFalse);
        expect(provider.isUploading, isFalse);
      });
    });

    group('Reset Functionality', () {
      test('should reset all state to initial values', () {
        // Set up some state
        provider.updateState(RecordingState.completed);
        provider.setRecordingPath('/test/path.m4a');
        provider.setRecordId('test-id');
        provider.updateRecordingDuration(Duration(seconds: 60));
        provider.setError('Test error');
        provider.updateUploadProgress(0.8);
        provider.setTranscriptionText('Test transcription');
        
        // Reset
        provider.reset();
        
        // Verify reset
        expect(provider.state, RecordingState.idle);
        expect(provider.recordingPath, isNull);
        expect(provider.recordId, isNull);
        expect(provider.recordingDuration, Duration.zero);
        expect(provider.error, isNull);
        expect(provider.uploadProgress, 0.0);
        expect(provider.transcriptionText, isNull);
      });
    });

    group('State Queries', () {
      test('should correctly identify recording state', () {
        provider.updateState(RecordingState.recording);
        expect(provider.isRecording, isTrue);
        
        provider.updateState(RecordingState.idle);
        expect(provider.isRecording, isFalse);
      });

      test('should correctly identify error state', () {
        provider.setError('Test error');
        expect(provider.hasError, isTrue);
        
        provider.clearError();
        expect(provider.hasError, isFalse);
      });

      test('should correctly identify upload state', () {
        provider.updateState(RecordingState.uploading);
        expect(provider.isUploading, isTrue);
        
        provider.updateState(RecordingState.processing);
        expect(provider.isUploading, isFalse);
      });
    });
  });
}