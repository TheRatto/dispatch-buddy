import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import 'summary_screen.dart';
import 'airport_detail_screen.dart';
import 'raw_data_screen.dart';

class BriefingTabsScreen extends StatefulWidget {
  @override
  _BriefingTabsScreenState createState() => _BriefingTabsScreenState();
}

class _BriefingTabsScreenState extends State<BriefingTabsScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    SummaryScreen(),
    AirportDetailScreen(),
    RawDataScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.airplanemode_active),
            label: 'Airports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.code),
            label: 'Raw Data',
          ),
        ],
      ),
    );
  }
} 