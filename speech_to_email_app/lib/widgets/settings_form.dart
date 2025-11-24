import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recording_provider.dart';
import '../services/settings_service.dart';
import '../services/file_picker_service.dart';

class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key});

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final _coachNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final coachName = await SettingsService.getCoachName();
    if (coachName != null) {
      _coachNameController.text = coachName;
      if (mounted) {
        context.read<RecordingProvider>().setCoachName(coachName);
      }
    }
  }

  Future<void> _saveCoachName() async {
    final coachName = _coachNameController.text.trim();
    if (coachName.isNotEmpty) {
      await SettingsService.setCoachName(coachName);
      if (mounted) {
        context.read<RecordingProvider>().setCoachName(coachName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coach name saved')),
        );
      }
    }
  }

  Future<void> _pickPdfFile() async {
    setState(() => _isLoading = true);
    
    try {
      final selectedFile = await FilePickerService.pickPdfFile();
      if (selectedFile != null && mounted) {
        context.read<RecordingProvider>().setSelectedPdfFile(selectedFile);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF selected: ${selectedFile.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting PDF: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removePdfFile() {
    context.read<RecordingProvider>().setSelectedPdfFile(null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordingProvider>(
      builder: (context, provider, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                // Coach Name Field
                TextField(
                  controller: _coachNameController,
                  decoration: InputDecoration(
                    labelText: 'Coach HC VfL',
                    hintText: 'Enter coach name',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveCoachName,
                      tooltip: 'Save coach name',
                    ),
                  ),
                  onSubmitted: (_) => _saveCoachName(),
                ),
                
                const SizedBox(height: 16),
                
                // PDF File Section
                Text(
                  'Spielbericht (PDF)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                
                if (provider.selectedPdfFile != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.selectedPdfFile!.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${(provider.selectedPdfFile!.size / 1024).toStringAsFixed(1)} KB',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _pickPdfFile,
                          tooltip: 'Change PDF',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _removePdfFile,
                          tooltip: 'Remove PDF',
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickPdfFile,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(_isLoading ? 'Selecting...' : 'Select PDF File'),
                  ),
                ],
                
                const SizedBox(height: 8),
                Text(
                  'Optional: Upload a PDF file that will be used by the AI for context',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _coachNameController.dispose();
    super.dispose();
  }
}