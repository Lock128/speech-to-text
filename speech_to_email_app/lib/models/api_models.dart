class PresignedUrlRequest {
  final String fileName;
  final int fileSize;
  final String contentType;

  PresignedUrlRequest({
    required this.fileName,
    required this.fileSize,
    required this.contentType,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'contentType': contentType,
    };
  }
}

class PresignedUrlResponse {
  final String uploadUrl;
  final String recordId;
  final int expiresIn;

  PresignedUrlResponse({
    required this.uploadUrl,
    required this.recordId,
    required this.expiresIn,
  });

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      uploadUrl: json['uploadUrl'] as String,
      recordId: json['recordId'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }
}

enum ProcessingStatus {
  uploaded,
  transcribing,
  transcriptionCompleted,
  emailSent,
  failed,
}

class RecordingHistoryItem {
  final String recordId;
  final ProcessingStatus status;
  final DateTime createdAt;
  final String? transcriptionText;
  final String? errorMessage;

  RecordingHistoryItem({
    required this.recordId,
    required this.status,
    required this.createdAt,
    this.transcriptionText,
    this.errorMessage,
  });

  factory RecordingHistoryItem.fromJson(Map<String, dynamic> json) {
    return RecordingHistoryItem(
      recordId: json['recordId'] as String,
      status: StatusResponse._parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      transcriptionText: json['transcriptionText'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'transcriptionText': transcriptionText,
      'errorMessage': errorMessage,
    };
  }
}

class StatusResponse {
  final String recordId;
  final ProcessingStatus status;
  final String? transcriptionText;
  final String? errorMessage;
  final double? progress;

  StatusResponse({
    required this.recordId,
    required this.status,
    this.transcriptionText,
    this.errorMessage,
    this.progress,
  });

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(
      recordId: json['recordId'] as String,
      status: _parseStatus(json['status'] as String),
      transcriptionText: json['transcriptionText'] as String?,
      errorMessage: json['errorMessage'] as String?,
      progress: json['progress'] as double?,
    );
  }

  static ProcessingStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'uploaded':
        return ProcessingStatus.uploaded;
      case 'transcribing':
        return ProcessingStatus.transcribing;
      case 'transcription_completed':
        return ProcessingStatus.transcriptionCompleted;
      case 'email_sent':
        return ProcessingStatus.emailSent;
      case 'failed':
        return ProcessingStatus.failed;
      default:
        return ProcessingStatus.failed;
    }
  }
}