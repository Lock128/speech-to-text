import 'package:flutter/material.dart';
import '../services/error_service.dart';

class ErrorDisplay extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showDetails;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error header
          Row(
            children: [
              Icon(
                _getErrorIcon(),
                color: _getIconColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getErrorTitle(),
                      style: TextStyle(
                        color: _getTextColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.message,
                      style: TextStyle(
                        color: _getTextColor(),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: Icon(Icons.close, color: _getIconColor()),
                  onPressed: onDismiss,
                  tooltip: 'Dismiss',
                ),
            ],
          ),

          // Error details (expandable)
          if (showDetails && error.details != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                'Technical Details',
                style: TextStyle(
                  color: _getTextColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    error.details!,
                    style: TextStyle(
                      color: _getTextColor().withValues(alpha: 0.8),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Action buttons
          if (error.isRetryable || onRetry != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (error.isRetryable && onRetry != null) ...[
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getButtonColor(),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    ErrorService.getRetryMessage(error.type),
                    style: TextStyle(
                      color: _getTextColor().withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getErrorTitle() {
    switch (error.type) {
      case ErrorType.network:
        return 'Connection Problem';
      case ErrorType.permission:
        return 'Permission Required';
      case ErrorType.fileSystem:
        return 'File System Error';
      case ErrorType.validation:
        return 'Invalid Input';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.timeout:
        return 'Request Timeout';
      case ErrorType.cancelled:
        return 'Operation Cancelled';
      case ErrorType.unknown:
        return 'Unexpected Error';
    }
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.permission:
        return Icons.security;
      case ErrorType.fileSystem:
        return Icons.folder_off;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.timeout:
        return Icons.access_time;
      case ErrorType.cancelled:
        return Icons.cancel;
      case ErrorType.unknown:
        return Icons.error;
    }
  }

  Color _getBackgroundColor() {
    switch (error.type) {
      case ErrorType.network:
        return Colors.blue.shade50;
      case ErrorType.permission:
        return Colors.orange.shade50;
      case ErrorType.validation:
        return Colors.amber.shade50;
      case ErrorType.cancelled:
        return Colors.grey.shade50;
      default:
        return Colors.red.shade50;
    }
  }

  Color _getBorderColor() {
    switch (error.type) {
      case ErrorType.network:
        return Colors.blue.shade200;
      case ErrorType.permission:
        return Colors.orange.shade200;
      case ErrorType.validation:
        return Colors.amber.shade200;
      case ErrorType.cancelled:
        return Colors.grey.shade300;
      default:
        return Colors.red.shade200;
    }
  }

  Color _getTextColor() {
    switch (error.type) {
      case ErrorType.network:
        return Colors.blue.shade800;
      case ErrorType.permission:
        return Colors.orange.shade800;
      case ErrorType.validation:
        return Colors.amber.shade800;
      case ErrorType.cancelled:
        return Colors.grey.shade700;
      default:
        return Colors.red.shade800;
    }
  }

  Color _getIconColor() {
    return _getTextColor();
  }

  Color _getButtonColor() {
    switch (error.type) {
      case ErrorType.network:
        return Colors.blue.shade600;
      case ErrorType.permission:
        return Colors.orange.shade600;
      case ErrorType.validation:
        return Colors.amber.shade600;
      default:
        return Colors.red.shade600;
    }
  }
}

class ErrorSnackBar {
  static void show(BuildContext context, AppError error, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getSnackBarColor(error.type),
        action: error.isRetryable && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: Duration(seconds: error.isRetryable ? 6 : 4),
      ),
    );
  }

  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.permission:
        return Icons.security;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.cancelled:
        return Icons.info;
      default:
        return Icons.error;
    }
  }

  static Color _getSnackBarColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.blue.shade700;
      case ErrorType.permission:
        return Colors.orange.shade700;
      case ErrorType.validation:
        return Colors.amber.shade700;
      case ErrorType.cancelled:
        return Colors.grey.shade600;
      default:
        return Colors.red.shade700;
    }
  }
}