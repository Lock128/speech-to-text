import 'package:flutter/foundation.dart';
import '../services/error_service.dart';
import '../services/file_picker_service.dart';

enum RecordingState {
  idle,
  recording,
  stopped,
  reviewing,
  uploading,
  processing,
  completed,
  error,
}

class RecordingProvider extends ChangeNotifier {
  RecordingState _state = RecordingState.idle;
  String? _recordingPath;
  String? _recordId;
  Duration _recordingDuration = Duration.zero;
  AppError? _error;
  double _uploadProgress = 0.0;
  String? _transcriptionText;
  String? _coachName;
  SelectedFile? _selectedPdfFile;

  // Getters
  RecordingState get state => _state;
  String? get recordingPath => _recordingPath;
  String? get recordId => _recordId;
  Duration get recordingDuration => _recordingDuration;
  AppError? get error => _error;
  String? get errorMessage => _error?.message;
  double get uploadProgress => _uploadProgress;
  String? get transcriptionText => _transcriptionText;
  String? get coachName => _coachName;
  SelectedFile? get selectedPdfFile => _selectedPdfFile;

  bool get isRecording => _state == RecordingState.recording;
  bool get isReviewing => _state == RecordingState.reviewing;
  bool get isUploading => _state == RecordingState.uploading;
  bool get isProcessing => _state == RecordingState.processing;
  bool get hasError => _state == RecordingState.error;
  bool get isCompleted => _state == RecordingState.completed;

  void updateState(RecordingState newState) {
    _state = newState;
    notifyListeners();
  }

  void setRecordingPath(String path) {
    _recordingPath = path;
    notifyListeners();
  }

  void setRecordId(String id) {
    _recordId = id;
    notifyListeners();
  }

  void updateRecordingDuration(Duration duration) {
    _recordingDuration = duration;
    notifyListeners();
  }

  void setError(dynamic error) {
    _error = ErrorService.handleError(error);
    _state = RecordingState.error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void updateUploadProgress(double progress) {
    _uploadProgress = progress;
    notifyListeners();
  }

  void setTranscriptionText(String text) {
    _transcriptionText = text;
    notifyListeners();
  }

  void setCoachName(String? name) {
    _coachName = name;
    notifyListeners();
  }

  void setSelectedPdfFile(SelectedFile? file) {
    _selectedPdfFile = file;
    notifyListeners();
  }

  void reset() {
    _state = RecordingState.idle;
    _recordingPath = null;
    _recordId = null;
    _recordingDuration = Duration.zero;
    _error = null;
    _uploadProgress = 0.0;
    _transcriptionText = null;
    // Keep coach name and PDF file across resets
    notifyListeners();
  }
}