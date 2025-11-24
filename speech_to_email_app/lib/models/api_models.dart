class PresignedUrlRequest {
  final String fileName;
  final int fileSize;
  final String contentType;
  final String? coachName;
  final String? pdfFileName;
  final int? pdfFileSize;

  PresignedUrlRequest({
    required this.fileName,
    required this.fileSize,
    required this.contentType,
    this.coachName,
    this.pdfFileName,
    this.pdfFileSize,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'fileName': fileName,
      'fileSize': fileSize,
      'contentType': contentType,
    };
    
    final coach = coachName;
    final pdfFile = pdfFileName;
    final pdfSize = pdfFileSize;
    
    if (coach != null) json['coachName'] = coach;
    if (pdfFile != null) json['pdfFileName'] = pdfFile;
    if (pdfSize != null) json['pdfFileSize'] = pdfSize;
    
    return json;
  }
}

class PresignedUrlResponse {
  final String uploadUrl;
  final String recordId;
  final int expiresIn;
  final String? pdfUploadUrl;

  PresignedUrlResponse({
    required this.uploadUrl,
    required this.recordId,
    required this.expiresIn,
    this.pdfUploadUrl,
  });

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      uploadUrl: json['uploadUrl'] as String,
      recordId: json['recordId'] as String,
      expiresIn: json['expiresIn'] as int,
      pdfUploadUrl: json['pdfUploadUrl'] as String?,
    );
  }
}

enum ProcessingStatus {
  uploaded,
  transcribing,
  transcriptionCompleted,
  enhancingArticle,
  articleEnhanced,
  emailSent,
  failed,
}

class RecordingHistoryItem {
  final String recordId;
  final ProcessingStatus status;
  final DateTime createdAt;
  final String? transcriptionText;
  final String? enhancedArticleText;
  final String? errorMessage;

  RecordingHistoryItem({
    required this.recordId,
    required this.status,
    required this.createdAt,
    this.transcriptionText,
    this.enhancedArticleText,
    this.errorMessage,
  });

  factory RecordingHistoryItem.fromJson(Map<String, dynamic> json) {
    return RecordingHistoryItem(
      recordId: json['recordId'] as String,
      status: StatusResponse._parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      transcriptionText: json['transcriptionText'] as String?,
      enhancedArticleText: json['enhancedArticleText'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'transcriptionText': transcriptionText,
      'enhancedArticleText': enhancedArticleText,
      'errorMessage': errorMessage,
    };
  }
}

class StatusResponse {
  final String recordId;
  final ProcessingStatus status;
  final String? statusDescription;
  final String? transcriptionText;
  final String? enhancedArticleText;
  final String? errorMessage;
  final double? progress;

  StatusResponse({
    required this.recordId,
    required this.status,
    this.statusDescription,
    this.transcriptionText,
    this.enhancedArticleText,
    this.errorMessage,
    this.progress,
  });

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(
      recordId: json['recordId'] as String,
      status: _parseStatus(json['status'] as String),
      statusDescription: json['statusDescription'] as String?,
      transcriptionText: json['transcriptionText'] as String?,
      enhancedArticleText: json['enhancedArticleText'] as String?,
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
      case 'enhancing_article':
        return ProcessingStatus.enhancingArticle;
      case 'article_enhanced':
        return ProcessingStatus.articleEnhanced;
      case 'email_sent':
        return ProcessingStatus.emailSent;
      case 'failed':
        return ProcessingStatus.failed;
      default:
        return ProcessingStatus.failed;
    }
  }
}