import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 24),
            
            _HelpSection(
              title: 'Getting Started',
              items: [
                _HelpItem(
                  question: 'How do I create a new briefing?',
                  answer: 'Tap "Start New Briefing" on the home screen, then either upload a flight plan PDF or manually enter your route and departure time.',
                ),
                _HelpItem(
                  question: 'What flight plan formats are supported?',
                  answer: 'Briefing Buddy supports ForeFlight PDF exports and NAIPS flight plan PDFs. You can also manually enter route information.',
                ),
                _HelpItem(
                  question: 'How do I add airports to my briefing?',
                  answer: 'Use the "Add Airport" button on the Airport Facilities or Raw Data screens to include additional airports in your briefing.',
                ),
              ],
            ),
            
            _HelpSection(
              title: 'Data Sources',
              items: [
                _HelpItem(
                  question: 'Where does the weather data come from?',
                  answer: 'Weather data is sourced from AviationWeather.gov API for METAR and TAF information. The app also supports NAIPS integration for Australian domestic flights.',
                ),
                _HelpItem(
                  question: 'How do I set up NAIPS integration?',
                  answer: 'Go to Settings > NAIPS Integration, enable NAIPS, and enter your credentials. Use the Test Connection feature to verify your setup.',
                ),
                _HelpItem(
                  question: 'Why is some data missing?',
                  answer: 'Data availability depends on the source APIs and airport coverage. Some smaller airports may have limited data available.',
                ),
              ],
            ),
            
            _HelpSection(
              title: 'Troubleshooting',
              items: [
                _HelpItem(
                  question: 'The app is not loading weather data',
                  answer: 'Check your internet connection and try refreshing. If using NAIPS, verify your credentials are correct using the Test Connection feature.',
                ),
                _HelpItem(
                  question: 'NOTAMs are not showing correctly',
                  answer: 'Ensure you have a stable internet connection. Try switching between FAA API and NAIPS sources in Settings if available.',
                ),
                _HelpItem(
                  question: 'App crashes or freezes',
                  answer: 'Try restarting the app. If the problem persists, check for app updates or contact support with details about when the crash occurs.',
                ),
              ],
            ),
            
            _HelpSection(
              title: 'Features',
              items: [
                _HelpItem(
                  question: 'How do I save a briefing for later?',
                  answer: 'Briefings are automatically saved and appear in the "Previous Briefings" section on the home screen.',
                ),
                _HelpItem(
                  question: 'Can I use this app offline?',
                  answer: 'Previously loaded briefings can be viewed offline, but you need internet connectivity to fetch new weather and NOTAM data.',
                ),
                _HelpItem(
                  question: 'What does the color coding mean?',
                  answer: 'Green indicates normal operations, yellow shows caution/advisory items, and red indicates restrictions or closures.',
                ),
              ],
            ),
            
            SizedBox(height: 32),
            
            _ContactSection(),
            
            SizedBox(height: 32),
            
            Text(
              'Briefing Buddy v1.0.1',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final List<_HelpItem> items;

  const _HelpSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }
}

class _HelpItem extends StatefulWidget {
  final String question;
  final String answer;

  const _HelpItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_HelpItem> createState() => _HelpItemState();
}

class _HelpItemState extends State<_HelpItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.question,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need More Help?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'If you can\'t find the answer you\'re looking for, here are additional resources:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _ContactItem(
              icon: Icons.bug_report,
              title: 'Report a Bug',
              subtitle: 'Help us improve the app',
              onTap: () => _showBugReportDialog(context),
            ),
            _ContactItem(
              icon: Icons.lightbulb,
              title: 'Feature Request',
              subtitle: 'Suggest new features',
              onTap: () => _showFeatureRequestDialog(context),
            ),
            _ContactItem(
              icon: Icons.help_outline,
              title: 'General Support',
              subtitle: 'Get help with the app',
              onTap: () => _showGeneralSupportDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Text(
          'To report a bug, please include:\n\n'
          '• What you were trying to do\n'
          '• What actually happened\n'
          '• Steps to reproduce the issue\n'
          '• Device and app version\n\n'
          'Contact us through the app store or email us directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Request'),
        content: const Text(
          'We love hearing your ideas! Please describe:\n\n'
          '• The feature you\'d like to see\n'
          '• How it would help your workflow\n'
          '• Any specific requirements\n\n'
          'Contact us through the app store or email us directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGeneralSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('General Support'),
        content: const Text(
          'For general support questions:\n\n'
          '• Check the FAQ above first\n'
          '• Contact us through the app store\n'
          '• Email us directly with your question\n\n'
          'We typically respond within 24-48 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
