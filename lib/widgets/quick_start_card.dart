import 'package:flutter/material.dart';

class QuickStartCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGenerateMockBriefing1;
  final VoidCallback onGenerateMockBriefing2;

  const QuickStartCard({
    super.key,
    required this.isLoading,
    required this.onGenerateMockBriefing1,
    required this.onGenerateMockBriefing2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Start',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Generate a sample briefing with realistic data for testing',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onGenerateMockBriefing1,
                    icon: const Icon(Icons.flight),
                    label: const Text('YPPH → YSSY (Sample)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onGenerateMockBriefing2,
                    icon: const Icon(Icons.flight),
                    label: const Text('YMML → YBBN (Sample)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 