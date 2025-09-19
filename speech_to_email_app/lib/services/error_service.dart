import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

enum ErrorType {
  network,
  permission,
  fileSystem,
  validation,
  server,
  timeout,
  cancelled,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? details;
  final String? code;
  final bool isRetryable;

  AppError({
    required this.type,
    required this.message,
    this.details,
    this.code,
    this.isRetryable = false,
  });

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, code: $code)';
  }
}

class ErrorService {
  static AppError handleError(dynamic error) {
    debugPrint('Handling error: $error');

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is AppError) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    // Permission errors
    if (errorString.contains('permission') || errorString.contains('denied')) {
      return AppError(
        type: ErrorType.permission,
        message: 'Permission denied. Please grant microphone access.',
        details: error.toString(),
        isRetryable: true,
      );
    }

    // File system errors
    if (errorString.contains('file') || errorString.contains('directory')) {
      return AppError(
        type: ErrorType.fileSystem,
        message: 'File system error. Please try again.',
        details: error.toString(),
        isRetryable: true,
      );
    }

    // Network errors
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return AppError(
        type: ErrorType.network,
        message: 'Network error. Please check your connection.',
        details: error.toString(),
        isRetryable: true,
      );
    }

    // Validation errors
    if (errorString.contains('validation') || 
        errorString.contains('invalid') ||
        errorString.contains('format')) {
      return AppError(
        type: ErrorType.validation,
        message: 'Invalid file or data. Please try again.',
        details: error.toString(),
        isRetryable: false,
      );
    }

    // Cancelled operations
    if (errorString.contains('cancel')) {
      return AppError(
        type: ErrorType.cancelled,
        message: 'Operation cancelled.',
        details: error.toString(),
        isRetryable: false,
      );
    }

    // Default unknown error
    return AppError(
      type: ErrorType.unknown,
      message: 'An unexpected error occurred. Please try again.',
      details: error.toString(),
      isRetryable: true,
    );
  }

  static AppError _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          type: ErrorType.timeout,
          message: 'Request timed out. Please try again.',
          details: error.message,
          code: error.response?.statusCode?.toString(),
          isRetryable: true,
        );

      case DioExceptionType.connectionError:
        return AppError(
          type: ErrorType.network,
          message: 'Connection error. Please check your internet connection.',
          details: error.message,
          isRetryable: true,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        String message;
        bool isRetryable = false;

        switch (statusCode) {
          case 400:
            message = 'Invalid request. Please check your input.';
            break;
          case 401:
            message = 'Authentication failed. Please try again.';
            isRetryable = true;
            break;
          case 403:
            message = 'Access denied. Please check your permissions.';
            break;
          case 404:
            message = 'Resource not found.';
            break;
          case 413:
            message = 'File too large. Please use a smaller file.';
            break;
          case 429:
            message = 'Too many requests. Please wait and try again.';
            isRetryable = true;
            break;
          case 500:
          case 502:
          case 503:
          case 504:
            message = 'Server error. Please try again later.';
            isRetryable = true;
            break;
          default:
            message = 'Server error (${statusCode ?? 'unknown'}). Please try again.';
            isRetryable = true;
        }

        return AppError(
          type: ErrorType.server,
          message: message,
          details: error.response?.data?.toString() ?? error.message,
          code: statusCode?.toString(),
          isRetryable: isRetryable,
        );

      case DioExceptionType.cancel:
        return AppError(
          type: ErrorType.cancelled,
          message: 'Request cancelled.',
          details: error.message,
          isRetryable: false,
        );

      case DioExceptionType.unknown:
      default:
        return AppError(
          type: ErrorType.unknown,
          message: 'Network error. Please try again.',
          details: error.message,
          isRetryable: true,
        );
    }
  }

  static String getRetryMessage(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Check your internet connection and try again.';
      case ErrorType.permission:
        return 'Grant the required permissions and try again.';
      case ErrorType.timeout:
        return 'The request timed out. Try again with a better connection.';
      case ErrorType.server:
        return 'Server is temporarily unavailable. Try again in a few minutes.';
      case ErrorType.fileSystem:
        return 'Check available storage space and try again.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      default:
        return 'Please try again.';
    }
  }

  static bool shouldShowRetryButton(ErrorType type) {
    return type != ErrorType.cancelled && type != ErrorType.validation;
  }
}