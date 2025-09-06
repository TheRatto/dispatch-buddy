import 'package:flutter/material.dart';

/// AI Briefing Settings Dialog
/// 
/// Allows users to customize the AI briefing generation
/// with different options and preferences
class AIBriefingSettingsDialog extends StatefulWidget {
  final String currentStyle;
  final String currentLength;
  final bool includeWeather;
  final bool includeNotams;
  final bool includeSafety;
  final bool includeAlternates;
  final Function(String style, String length, bool weather, bool notams, bool safety, bool alternates) onSave;

  const AIBriefingSettingsDialog({
    Key? key,
    required this.currentStyle,
    required this.currentLength,
    required this.includeWeather,
    required this.includeNotams,
    required this.includeSafety,
    required this.includeAlternates,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AIBriefingSettingsDialog> createState() => _AIBriefingSettingsDialogState();
}

class _AIBriefingSettingsDialogState extends State<AIBriefingSettingsDialog> {
  late String _selectedStyle;
  late String _selectedLength;
  late bool _includeWeather;
  late bool _includeNotams;
  late bool _includeSafety;
  late bool _includeAlternates;

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.currentStyle;
    _selectedLength = widget.currentLength;
    _includeWeather = widget.includeWeather;
    _includeNotams = widget.includeNotams;
    _includeSafety = widget.includeSafety;
    _includeAlternates = widget.includeAlternates;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.blue),
          SizedBox(width: 8),
          Text('AI Briefing Settings'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Briefing Style
            const Text(
              'Briefing Style',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStyle,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'professional', child: Text('Professional')),
                DropdownMenuItem(value: 'concise', child: Text('Concise')),
                DropdownMenuItem(value: 'detailed', child: Text('Detailed')),
                DropdownMenuItem(value: 'casual', child: Text('Casual')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStyle = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Briefing Length
            const Text(
              'Briefing Length',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLength,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'short', child: Text('Short (1-2 minutes)')),
                DropdownMenuItem(value: 'medium', child: Text('Medium (3-5 minutes)')),
                DropdownMenuItem(value: 'long', child: Text('Long (5+ minutes)')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLength = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Content Options
            const Text(
              'Content Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            CheckboxListTile(
              title: const Text('Include Weather Analysis'),
              subtitle: const Text('Detailed weather conditions and forecasts'),
              value: _includeWeather,
              onChanged: (value) {
                setState(() {
                  _includeWeather = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            CheckboxListTile(
              title: const Text('Include NOTAM Analysis'),
              subtitle: const Text('Operational impacts and restrictions'),
              value: _includeNotams,
              onChanged: (value) {
                setState(() {
                  _includeNotams = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            CheckboxListTile(
              title: const Text('Include Safety Recommendations'),
              subtitle: const Text('Safety-focused guidance and procedures'),
              value: _includeSafety,
              onChanged: (value) {
                setState(() {
                  _includeSafety = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            CheckboxListTile(
              title: const Text('Include Alternate Airports'),
              subtitle: const Text('Alternative routing and diversion options'),
              value: _includeAlternates,
              onChanged: (value) {
                setState(() {
                  _includeAlternates = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              _selectedStyle,
              _selectedLength,
              _includeWeather,
              _includeNotams,
              _includeSafety,
              _includeAlternates,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
