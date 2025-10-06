import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
              'Terms of Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 24),
            _Section(
              title: '1. Acceptance of Terms',
              content: 'By downloading, installing, or using Briefing Buddy, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.',
            ),
            _Section(
              title: '2. Description of Service',
              content: 'Briefing Buddy is an AI-powered preflight briefing assistant designed to help pilots access and interpret aviation weather data, NOTAMs, and flight planning information. The app provides data from various aviation sources including FAA APIs, AviationWeather.gov, and NAIPS (when configured).',
            ),
            _Section(
              title: '3. Data Sources and Accuracy',
              content: 'Briefing Buddy aggregates data from multiple aviation data providers. While we strive to provide accurate and up-to-date information, we cannot guarantee the accuracy, completeness, or timeliness of any data. Users are responsible for verifying all information with official sources before making operational decisions.',
            ),
            _Section(
              title: '4. User Responsibilities',
              content: 'Users must:\n• Verify all aviation data with official sources\n• Use the app as a supplementary tool, not as a primary source\n• Comply with all applicable aviation regulations\n• Maintain current and valid pilot certifications\n• Ensure device compatibility and internet connectivity',
            ),
            _Section(
              title: '5. Privacy and Data Collection',
              content: 'Briefing Buddy may collect usage analytics and crash reports to improve the application. Personal information is handled in accordance with our Privacy Policy. NAIPS credentials are stored securely on-device and are not transmitted to our servers.',
            ),
            _Section(
              title: '6. Disclaimers',
              content: 'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. WE DISCLAIM ALL LIABILITY FOR ANY LOSSES OR DAMAGES ARISING FROM USE OF THIS APPLICATION. THIS APP IS NOT CERTIFIED AS AN ELECTRONIC FLIGHT BAG (EFB) AND SHOULD NOT BE USED AS A PRIMARY NAVIGATION OR OPERATIONAL TOOL.',
            ),
            _Section(
              title: '7. Limitations of Liability',
              content: 'In no event shall the developers be liable for any direct, indirect, incidental, special, or consequential damages arising from the use or inability to use this application.',
            ),
            _Section(
              title: '8. Changes to Terms',
              content: 'We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of the new terms.',
            ),
            _Section(
              title: '9. Contact Information',
              content: 'For questions about these Terms of Service, please contact us through the app\'s Help & Support section.',
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
