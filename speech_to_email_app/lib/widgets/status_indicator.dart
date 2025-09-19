import 'package:flutter/material.dart';
import '../providers/recording_provider.dart';

class StatusIndicator extends StatelessWidget {
  final RecordingState state;

  const StatusIndicator({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(width: 12),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getTextColor(),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    switch (state) {
      case RecordingState.idle:
        return Icon(Icons.mic_none, color: _getIconColor(), size: 20);
      case RecordingState.recording:
        return _buildPulsingIcon();
      case RecordingState.stopped:
        return Icon(Icons.stop, color: _getIconColor(), size: 20);
      case RecordingState.uploading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getIconColor()),
          ),
        );
      case RecordingState.processing:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getIconColor()),
          ),
        );
      case RecordingState.completed:
        return Icon(Icons.check_circle, color: _getIconColor(), size: 20);
      case RecordingState.error:
        return Icon(Icons.error, color: _getIconColor(), size: 20);
    }
  }

  Widget _buildPulsingIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Icon(
            Icons.fiber_manual_record,
            color: Colors.red.withValues(alpha: value),
            size: 20,
          ),
        );
      },
      onEnd: () {
        // This will restart the animation automatically
      },
    );
  }

  Color _getBackgroundColor() {
    switch (state) {
      case RecordingState.idle:
        return Colors.blue.shade50;
      case RecordingState.recording:
        return Colors.red.shade50;
      case RecordingState.stopped:
        return Colors.orange.shade50;
      case RecordingState.uploading:
        return Colors.purple.shade50;
      case RecordingState.processing:
        return Colors.indigo.shade50;
      case RecordingState.completed:
        return Colors.green.shade50;
      case RecordingState.error:
        return Colors.red.shade50;
    }
  }

  Color _getBorderColor() {
    switch (state) {
      case RecordingState.idle:
        return Colors.blue.shade200;
      case RecordingState.recording:
        return Colors.red.shade200;
      case RecordingState.stopped:
        return Colors.orange.shade200;
      case RecordingState.uploading:
        return Colors.purple.shade200;
      case RecordingState.processing:
        return Colors.indigo.shade200;
      case RecordingState.completed:
        return Colors.green.shade200;
      case RecordingState.error:
        return Colors.red.shade200;
    }
  }

  Color _getTextColor() {
    switch (state) {
      case RecordingState.idle:
        return Colors.blue.shade700;
      case RecordingState.recording:
        return Colors.red.shade700;
      case RecordingState.stopped:
        return Colors.orange.shade700;
      case RecordingState.uploading:
        return Colors.purple.shade700;
      case RecordingState.processing:
        return Colors.indigo.shade700;
      case RecordingState.completed:
        return Colors.green.shade700;
      case RecordingState.error:
        return Colors.red.shade700;
    }
  }

  Color _getIconColor() {
    return _getTextColor();
  }

  String _getStatusText() {
    switch (state) {
      case RecordingState.idle:
        return 'Ready to Record';
      case RecordingState.recording:
        return 'Recording...';
      case RecordingState.stopped:
        return 'Recording Stopped';
      case RecordingState.uploading:
        return 'Uploading...';
      case RecordingState.processing:
        return 'Processing Speech...';
      case RecordingState.completed:
        return 'Email Sent!';
      case RecordingState.error:
        return 'Error Occurred';
    }
  }
}