// main.dart – Dispatch Buddy (Flutter MVP Scaffold)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/input_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/airport_detail_screen.dart';
import 'screens/decoded_screen.dart';
import 'screens/raw_data_screen.dart';
import 'screens/diagram_screen.dart';
import 'providers/flight_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FlightProvider()),
      ],
      child: DispatchBuddyApp(),
    ),
  );
}

class DispatchBuddyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dispatch Buddy',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: Color(0xFF1E3A8A), // Deep Blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF1E3A8A),
          secondary: Color(0xFF3B82F6), // Sky Blue
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'SF Pro Display',
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class RootTabBar extends StatefulWidget {
  @override
  _RootTabBarState createState() => _RootTabBarState();
}

class _RootTabBarState extends State<RootTabBar> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    SummaryScreen(),
    AirportDetailScreen(),
    RawDataScreen(),
    InputScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Summary'),
          BottomNavigationBarItem(icon: Icon(Icons.airplanemode_active), label: 'Airports'),
          BottomNavigationBarItem(icon: Icon(Icons.code), label: 'Raw Data'),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Input'),
        ],
      ),
    );
  }
}
