import 'package:flutter/material.dart';
import '../providers/recording_provider.dart';

class ProcessingProgressIndicator extends StatelessWidget {
  final RecordingState state;
  final double uploadProgress;
  final String? transcriptionText;
  final int retryCount;

  const ProcessingProgressIndicator({
    super.key,
    required this.state,
    required this.uploadProgress,
    this.transcriptionText,
    this.retryCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress steps
        _buildProgressSteps(context),
        
        const SizedBox(height: 20),
        
        // Current step details
        _buildCurrentStepDetails(context),
      ],
    );
  }

  Widget _buildProgressSteps(BuildContext context) {
    final steps = [
      _ProgressStep(
        title: 'Recording',
        icon: Icons.mic,
        isCompleted: _isStepCompleted(0),
        isActive: _isStepActive(0),
      ),
      _ProgressStep(
        title: 'Uploading',
        icon: Icons.cloud_upload,
        isCompleted: _isStepCompleted(1),
        isActive: _isStepActive(1),
      ),
      _ProgressStep(
        title: 'Processing',
        icon: Icons.psychology,
        isCompleted: _isStepCompleted(2),
        isActive: _isStepActive(2),
      ),
      _ProgressStep(
        title: 'Email Sent',
        icon: Icons.email,
        isCompleted: _isStepCompleted(3),
        isActive: _isStepActive(3),
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Expanded(
            child: _buildProgressStep(context, steps[i]),
          ),
          if (i < steps.length - 1)
            _buildProgressConnector(context, _isStepCompleted(i)),
        ],
      ],
    );
  }

  Widget _buildProgressStep(BuildContext context, _ProgressStep step) {
    Color color;
    if (step.isCompleted) {
      color = Colors.green;
    } else if (step.isActive) {
      color = Theme.of(context).colorScheme.primary;
    } else {
      color = Colors.grey.shade400;
    }

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: step.isCompleted ? Colors.green : Colors.white,
            border: Border.all(color: color, width: 2),
          ),
          child: step.isActive && !step.isCompleted
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Icon(
                  step.isCompleted ? Icons.check : step.icon,
                  color: step.isCompleted ? Colors.white : color,
                  size: 20,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          step.title,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: step.isActive ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressConnector(BuildContext context, bool isCompleted) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 30),
      color: isCompleted ? Colors.green : Colors.grey.shade300,
    );
  }

  Widget _buildCurrentStepDetails(BuildContext context) {
    switch (state) {
      case RecordingState.uploading:
        return _buildUploadDetails(context);
      case RecordingState.processing:
        return _buildProcessingDetails(context);
      case RecordingState.completed:
        return _buildCompletedDetails(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUploadDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.blue.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Uploading your recording...',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: uploadProgress,
            backgroundColor: Colors.blue.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            '${(uploadProgress * 100).toInt()}% complete',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Converting speech to text...',
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This usually takes 30-60 seconds',
            style: TextStyle(
              color: Colors.purple.shade600,
              fontSize: 12,
            ),
          ),
          if (retryCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Retry attempt $retryCount/5',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Email sent successfully!',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (transcriptionText != null) ...[
            const SizedBox(height: 12),
            Text(
              'Transcription:',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                transcriptionText!,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isStepCompleted(int stepIndex) {
    switch (stepIndex) {
      case 0: // Recording
        return state != RecordingState.idle && state != RecordingState.recording;
      case 1: // Uploading
        return state != RecordingState.idle && 
               state != RecordingState.recording && 
               state != RecordingState.stopped && 
               state != RecordingState.uploading;
      case 2: // Processing
        return state == RecordingState.completed;
      case 3: // Email Sent
        return state == RecordingState.completed;
      default:
        return false;
    }
  }

  bool _isStepActive(int stepIndex) {
    switch (stepIndex) {
      case 0: // Recording
        return state == RecordingState.recording;
      case 1: // Uploading
        return state == RecordingState.uploading;
      case 2: // Processing
        return state == RecordingState.processing;
      case 3: // Email Sent
        return state == RecordingState.completed;
      default:
        return false;
    }
  }
}

class _ProgressStep {
  final String title;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;

  _ProgressStep({
    required this.title,
    required this.icon,
    required this.isCompleted,
    required this.isActive,
  });
}