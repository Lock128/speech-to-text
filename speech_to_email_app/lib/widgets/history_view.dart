import 'package:flutter/material.dart';
import '../models/api_models.dart';

class HistoryView extends StatelessWidget {
  final List<RecordingHistoryItem> historyItems;
  final VoidCallback onRefresh;

  const HistoryView({
    super.key,
    required this.historyItems,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Text(
                  'Recent Recordings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.grey.shade600),
                  onPressed: onRefresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // History list
          if (historyItems.isEmpty)
            _buildEmptyState(context)
          else
            _buildHistoryList(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.mic_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No recordings yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recording history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: historyItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = historyItems[index];
        return _buildHistoryItem(context, item);
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, RecordingHistoryItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildStatusIcon(item.status),
      title: Text(
        _formatDateTime(item.createdAt),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(_getStatusText(item.status)),
          if (item.transcriptionText != null) ...[
            const SizedBox(height: 4),
            Text(
              item.transcriptionText!.length > 50
                  ? '${item.transcriptionText!.substring(0, 50)}...'
                  : item.transcriptionText!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      trailing: _buildActionButton(context, item),
      onTap: () => _showDetailsDialog(context, item),
    );
  }

  Widget _buildStatusIcon(ProcessingStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case ProcessingStatus.uploaded:
        icon = Icons.cloud_upload;
        color = Colors.blue;
        break;
      case ProcessingStatus.transcribing:
        icon = Icons.psychology;
        color = Colors.orange;
        break;
      case ProcessingStatus.transcriptionCompleted:
        icon = Icons.text_fields;
        color = Colors.purple;
        break;
      case ProcessingStatus.emailSent:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ProcessingStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget? _buildActionButton(BuildContext context, RecordingHistoryItem item) {
    if (item.status == ProcessingStatus.failed) {
      return IconButton(
        icon: const Icon(Icons.refresh, size: 20),
        onPressed: () {
          // TODO: Implement retry functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Retry functionality coming soon')),
          );
        },
        tooltip: 'Retry',
      );
    }
    return null;
  }

  String _getStatusText(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.uploaded:
        return 'Uploaded, waiting for processing';
      case ProcessingStatus.transcribing:
        return 'Converting speech to text...';
      case ProcessingStatus.transcriptionCompleted:
        return 'Transcription complete, sending email...';
      case ProcessingStatus.emailSent:
        return 'Email sent successfully';
      case ProcessingStatus.failed:
        return 'Processing failed';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _showDetailsDialog(BuildContext context, RecordingHistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recording Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', _getStatusText(item.status)),
            _buildDetailRow('Created', item.createdAt.toString()),
            if (item.transcriptionText != null)
              _buildDetailRow('Transcription', item.transcriptionText!),
            if (item.errorMessage != null)
              _buildDetailRow('Error', item.errorMessage!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
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
}