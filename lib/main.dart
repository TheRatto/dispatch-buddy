// main.dart – Dispatch Buddy (Flutter MVP Scaffold)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'providers/flight_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => FlightProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
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
