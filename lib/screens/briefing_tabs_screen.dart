import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'summary_screen.dart';
import 'airport_detail_screen.dart';
import 'raw_data_screen.dart';

class BriefingTabsScreen extends StatefulWidget {
  final int initialTabIndex;
  const BriefingTabsScreen({super.key, this.initialTabIndex = 1}); // Default to Summary tab (index 1)

  // Static method to switch tabs from child widgets
  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_BriefingTabsScreenState>();
    if (state != null) {
      state.setTabIndex(index);
    }
  }

  @override
  _BriefingTabsScreenState createState() => _BriefingTabsScreenState();
}

class _BriefingTabsScreenState extends State<BriefingTabsScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SummaryScreen(),
    const AirportDetailScreen(),
    const RawDataScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args >= 0 && args < _screens.length) {
      setState(() {
        _currentIndex = args;
      });
    }
  }

  void setTabIndex(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Save current system page state before switching tabs
          if (_currentIndex == 2) { // If currently on Airports tab (now index 2)
            // The system page state will be saved by the AirportDetailScreen
            // when it detects the tab change
          }
          
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
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