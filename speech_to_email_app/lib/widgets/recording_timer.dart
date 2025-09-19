import 'package:flutter/material.dart';

class RecordingTimer extends StatelessWidget {
  final Duration duration;
  final bool isRecording;

  const RecordingTimer({
    super.key,
    required this.duration,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Timer display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isRecording 
                ? Colors.red.shade50 
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRecording 
                  ? Colors.red.shade200 
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recording indicator dot
              if (isRecording) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // Timer text
              Text(
                _formatDuration(duration),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: isRecording ? Colors.red.shade700 : null,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Progress bar for maximum duration
        Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _getProgressFactor(),
            child: Container(
              decoration: BoxDecoration(
                color: _getProgressColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Duration info
        Text(
          'Max: 5:00',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  double _getProgressFactor() {
    const maxDurationMinutes = 5;
    const maxDurationSeconds = maxDurationMinutes * 60;
    return (duration.inSeconds / maxDurationSeconds).clamp(0.0, 1.0);
  }

  Color _getProgressColor() {
    final progressFactor = _getProgressFactor();
    
    if (progressFactor < 0.7) {
      return Colors.green;
    } else if (progressFactor < 0.9) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}