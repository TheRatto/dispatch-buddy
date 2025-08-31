// main.dart – Dispatch Buddy (Flutter MVP Scaffold)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/airport_detail_screen.dart';
import 'screens/raw_data_screen.dart';
import 'screens/decoded_screen.dart';
import 'providers/flight_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/briefing_tabs_screen.dart';
import 'providers/charts_provider.dart';
import 'providers/weather_radar_provider.dart';
import 'services/naips_charts_service.dart';
import 'services/naips_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => FlightProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          lazy: true,
          create: (context) => ChartsProvider(
            chartsService: NaipsChartsService(naipsService: NAIPSService()),
          ),
        ),
        ChangeNotifierProvider(
          lazy: true,
          create: (context) => WeatherRadarProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dispatch Buddy',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: const Color(0xFF1E3A8A), // Deep Blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF3B82F6), // Sky Blue
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/briefing': (context) => const BriefingTabsScreen(),
        '/summary': (context) => const SummaryScreen(),
        '/airports': (context) => const AirportDetailScreen(),
        '/raw': (context) => const RawDataScreen(),
        '/decoded': (context) => const DecodedScreen(),
      },
      home: const SplashScreen(),
    );
  }
}
