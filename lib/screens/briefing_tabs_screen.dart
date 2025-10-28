import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'summary_screen.dart';
import 'airport_detail_screen.dart';
import 'raw_data_screen.dart';
import '../widgets/more_sheet.dart';

class BriefingTabsScreen extends StatefulWidget {
  final int initialTabIndex;
  const BriefingTabsScreen({super.key, this.initialTabIndex = 1}); // Default to Raw Data tab (index 1)

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
    const RawDataScreen(),
    const AirportDetailScreen(),
    const SummaryScreen(),
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
          // If user taps the More tab, open modal sheet instead of switching page
          const moreTabIndex = 4; // last item
          if (index == moreTabIndex) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => const MoreSheet(),
            );
            return;
          }

          // Save current system page state before switching tabs
          if (_currentIndex == 2) {
            // AirportDetailScreen can persist its state on tab change
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
            icon: Icon(Icons.code),
            label: 'Raw Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.airplanemode_active),
            label: 'Airports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
} 