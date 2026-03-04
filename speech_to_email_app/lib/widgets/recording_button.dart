import 'package:flutter/material.dart';
import '../providers/recording_provider.dart';

class RecordingButton extends StatelessWidget {
  final RecordingState state;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final VoidCallback onUploadRecording;

  const RecordingButton({
    super.key,
    required this.state,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.onUploadRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main recording button
        GestureDetector(
          onTap: _getMainButtonAction(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getMainButtonColor(context),
              boxShadow: [
                BoxShadow(
                  color: _getMainButtonColor(context).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: state == RecordingState.recording ? 10 : 0,
                ),
              ],
            ),
            child: Icon(
              _getMainButtonIcon(),
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Action buttons row (only show during recording, not during review)
        if (state == RecordingState.recording || state == RecordingState.stopped) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cancel button
              if (state == RecordingState.recording || state == RecordingState.stopped)
                _ActionButton(
                  icon: Icons.close,
                  label: 'Abbrechen',
                  color: Colors.grey,
                  onPressed: onCancelRecording,
                ),
              
              // Upload button (only show when stopped, not reviewing)
              if (state == RecordingState.stopped)
                _ActionButton(
                  icon: Icons.cloud_upload,
                  label: 'Hochladen',
                  color: Colors.blue,
                  onPressed: onUploadRecording,
                ),
            ],
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Status text
        Text(
          _getStatusText(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  VoidCallback? _getMainButtonAction() {
    switch (state) {
      case RecordingState.idle:
        return onStartRecording;
      case RecordingState.recording:
        return onStopRecording;
      case RecordingState.stopped:
      case RecordingState.reviewing:
        return onStartRecording; // Start new recording
      default:
        return null; // Disabled during upload/processing
    }
  }

  Color _getMainButtonColor(BuildContext context) {
    switch (state) {
      case RecordingState.idle:
      case RecordingState.stopped:
      case RecordingState.reviewing:
        return Theme.of(context).colorScheme.primary;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.uploading:
      case RecordingState.processing:
        return Colors.grey;
      case RecordingState.completed:
        return Colors.green;
      case RecordingState.error:
        return Colors.red.shade300;
    }
  }

  IconData _getMainButtonIcon() {
    switch (state) {
      case RecordingState.idle:
      case RecordingState.stopped:
      case RecordingState.reviewing:
        return Icons.mic;
      case RecordingState.recording:
        return Icons.stop;
      case RecordingState.uploading:
        return Icons.cloud_upload;
      case RecordingState.processing:
        return Icons.hourglass_empty;
      case RecordingState.completed:
        return Icons.check;
      case RecordingState.error:
        return Icons.error;
    }
  }

  String _getStatusText() {
    switch (state) {
      case RecordingState.idle:
        return 'Tippen Sie, um die Aufnahme zu starten';
      case RecordingState.recording:
        return 'Aufnahme läuft... Tippen Sie zum Stoppen';
      case RecordingState.stopped:
        return 'Aufnahme abgeschlossen';
      case RecordingState.reviewing:
        return 'Überprüfen Sie Ihre Aufnahme';
      case RecordingState.uploading:
        return 'Wird hochgeladen...';
      case RecordingState.processing:
        return 'Sprache wird verarbeitet...';
      case RecordingState.completed:
        return 'E-Mail erfolgreich gesendet!';
      case RecordingState.error:
        return 'Fehler aufgetreten';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label, // Unique hero tag to avoid conflicts
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}