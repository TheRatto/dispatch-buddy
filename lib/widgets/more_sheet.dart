import 'package:flutter/material.dart';
import '../screens/charts_screen.dart';
import '../screens/weather_radar_screen.dart';
import '../screens/ai_test_chat_screen.dart';

class MoreSheet extends StatelessWidget {
  const MoreSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.more_horiz, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text('More', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.map, color: Color(0xFF3B82F6)),
              title: const Text('Charts'),
              subtitle: const Text('NAIPS graphical charts (MSL, SIGWX, SIGMET, SATPIC, Winds)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChartsScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.radar, color: Color(0xFF3B82F6)),
              title: const Text('Weather Radar'),
              subtitle: const Text('Live BOM radar imagery and loops'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeatherRadarScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF3B82F6)),
              title: const Text('AI Test Chat'),
              subtitle: const Text('Test Apple Foundation Models integration'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AITestChatScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.pending, color: Colors.grey),
              title: const Text('More coming soon'),
              subtitle: const Text('ERSA tools, NAIPS utilities, shortcuts'),
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }
}


