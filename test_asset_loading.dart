import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AssetTestScreen(),
    );
  }
}

class AssetTestScreen extends StatefulWidget {
  @override
  _AssetTestScreenState createState() => _AssetTestScreenState();
}

class _AssetTestScreenState extends State<AssetTestScreen> {
  String _status = 'Testing...';
  
  @override
  void initState() {
    super.initState();
    _testAssets();
  }
  
  Future<void> _testAssets() async {
    final assets = [
      'assets/radar_layers/sites/sydney/256km/background.png',
      'assets/radar_layers/sites/sydney/256km/locations.png',
      'assets/radar_layers/sites/sydney/256km/topography.png',
      'assets/radar_layers/sites/sydney/128km/background.png',
      'assets/radar_layers/sites/sydney/128km/locations.png',
      'assets/radar_layers/sites/sydney/128km/topography.png',
    ];
    
    String results = 'Asset Test Results:\n\n';
    
    for (String asset in assets) {
      try {
        await rootBundle.load(asset);
        results += '✅ $asset - FOUND\n';
      } catch (e) {
        results += '❌ $asset - ERROR: $e\n';
      }
    }
    
    setState(() {
      _status = results;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Asset Loading Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            _status,
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ),
    );
  }
}
