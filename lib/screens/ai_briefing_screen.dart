import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_briefing_provider.dart';
import '../widgets/ai_briefing_widget.dart';

/// AI Briefing Screen
/// 
/// This screen demonstrates the AI briefing functionality
/// and provides a testing interface for the Foundation Models integration
class AIBriefingScreen extends StatefulWidget {
  const AIBriefingScreen({Key? key}) : super(key: key);

  @override
  State<AIBriefingScreen> createState() => _AIBriefingScreenState();
}

class _AIBriefingScreenState extends State<AIBriefingScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the AI briefing provider when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIBriefingProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Flight Briefing'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showInfoDialog(context),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.blue, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'AI-Powered Flight Briefing',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Generate intelligent flight briefings using Apple\'s Foundation Models framework. '
                      'The AI analyzes your weather data, NOTAMs, and airport information to create '
                      'comprehensive, safety-focused briefings.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // AI Briefing Widget
            Expanded(
              child: SingleChildScrollView(
                child: AIBriefingWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('AI Briefing Information'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Foundation Models Integration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This screen demonstrates the integration with Apple\'s Foundation Models framework for on-device AI processing.',
              ),
              SizedBox(height: 16),
              Text(
                'Current Status:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('• Mock implementation for testing'),
              Text('• Ready for Foundation Models integration'),
              Text('• On-device processing for privacy'),
              Text('• Aviation-specific prompt templates'),
              SizedBox(height: 16),
              Text(
                'Next Steps:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('• Integrate actual Foundation Models API'),
              Text('• Enhance aviation-specific prompts'),
              Text('• Add structured output formatting'),
              Text('• Implement briefing customization'),
            ],
          ),
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

}
