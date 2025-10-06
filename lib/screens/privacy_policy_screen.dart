import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 24),
            _Section(
              title: '1. Information We Collect',
              content: 'Briefing Buddy may collect the following information:\n\n• Usage Analytics: App performance metrics, feature usage, and crash reports\n• Device Information: Device type, operating system version, and app version\n• Location Data: Only when you enable location services for weather data\n• NAIPS Credentials: Stored securely on your device, not transmitted to our servers',
            ),
            _Section(
              title: '2. How We Use Information',
              content: 'We use collected information to:\n\n• Improve app performance and user experience\n• Debug issues and fix crashes\n• Analyze feature usage to guide development\n• Provide weather data relevant to your location (when enabled)',
            ),
            _Section(
              title: '3. Data Storage and Security',
              content: '• Personal data is stored securely on your device using industry-standard encryption\n• NAIPS credentials are stored locally and never transmitted to our servers\n• Analytics data is anonymized and aggregated\n• We do not sell or share personal information with third parties',
            ),
            _Section(
              title: '4. Third-Party Services',
              content: 'Briefing Buddy integrates with:\n\n• FAA NOTAM API (aviation data)\n• AviationWeather.gov API (weather data)\n• NAIPS (Airservices Australia) - when you provide credentials\n• Analytics services (crash reporting and usage statistics)\n\nThese services have their own privacy policies and data handling practices.',
            ),
            _Section(
              title: '5. Data Retention',
              content: '• App settings and preferences: Stored locally until you uninstall the app\n• Analytics data: Retained for up to 24 months in anonymized form\n• Crash reports: Retained for up to 12 months for debugging purposes\n• Flight briefing data: Stored locally on your device',
            ),
            _Section(
              title: '6. Your Rights and Controls',
              content: 'You can:\n\n• Disable analytics and crash reporting in Settings\n• Clear stored flight briefing data\n• Disable location services\n• Delete your NAIPS credentials\n• Uninstall the app to remove all local data',
            ),
            _Section(
              title: '7. Children\'s Privacy',
              content: 'Briefing Buddy is not intended for use by children under 13. We do not knowingly collect personal information from children under 13.',
            ),
            _Section(
              title: '8. International Users',
              content: 'If you are using Briefing Buddy outside the United States, please note that your information may be transferred to and processed in the United States where our servers are located.',
            ),
            _Section(
              title: '9. Changes to This Policy',
              content: 'We may update this Privacy Policy from time to time. We will notify users of any material changes through the app or via email if you have provided contact information.',
            ),
            _Section(
              title: '10. Contact Us',
              content: 'If you have questions about this Privacy Policy or our data practices, please contact us through the app\'s Help & Support section.',
            ),
            SizedBox(height: 32),
            Text(
              'Last Updated: January 2025',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
