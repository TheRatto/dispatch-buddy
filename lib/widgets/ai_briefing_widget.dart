import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_briefing_provider.dart';
import '../providers/flight_provider.dart';
import 'ai_briefing_settings_dialog.dart';

/// AI Briefing Widget
/// 
/// This widget displays AI-generated flight briefings
/// with a clean, professional interface
class AIBriefingWidget extends StatefulWidget {
  const AIBriefingWidget({Key? key}) : super(key: key);

  @override
  State<AIBriefingWidget> createState() => _AIBriefingWidgetState();
}

class _AIBriefingWidgetState extends State<AIBriefingWidget> {
  // Briefing customization settings
  String _briefingStyle = 'professional';
  String _briefingLength = 'medium';
  bool _includeWeather = true;
  bool _includeNotams = true;
  bool _includeSafety = true;
  bool _includeAlternates = true;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AIBriefingProvider, FlightProvider>(
      builder: (context, aiProvider, flightProvider, child) {
        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(aiProvider),
                const SizedBox(height: 16),
                _buildContent(aiProvider, flightProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AIBriefingProvider aiProvider) {
    return Row(
      children: [
        const Icon(
          Icons.psychology,
          color: Colors.blue,
          size: 24,
        ),
        const SizedBox(width: 8),
        const Text(
          'AI Flight Briefing',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _showSettingsDialog(context),
          icon: const Icon(Icons.settings, color: Colors.blue),
          tooltip: 'Briefing Settings',
        ),
        if (aiProvider.isGenerating)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildContent(AIBriefingProvider aiProvider, FlightProvider flightProvider) {
    if (!aiProvider.isInitialized) {
      return _buildNotInitialized(aiProvider);
    }

    if (aiProvider.hasError) {
      return _buildError(aiProvider);
    }

    if (aiProvider.isGenerating) {
      return _buildGenerating();
    }

    if (aiProvider.currentBriefing == null) {
      return _buildNoBriefing(aiProvider, flightProvider);
    }

    return _buildBriefing(aiProvider, flightProvider);
  }

  Widget _buildNotInitialized(AIBriefingProvider aiProvider) {
    return Column(
      children: [
        const Text(
          'AI Briefing Service not initialized',
          style: TextStyle(
            fontSize: 16,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => aiProvider.initialize(),
          child: const Text('Initialize AI Service'),
        ),
      ],
    );
  }

  Widget _buildError(AIBriefingProvider aiProvider) {
    return Column(
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          'Error: ${aiProvider.error}',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => aiProvider.clearError(),
          child: const Text('Clear Error'),
        ),
      ],
    );
  }

  Widget _buildGenerating() {
    return const Column(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(),
        ),
        SizedBox(height: 16),
        Text(
          'Generating AI briefing...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'This may take a few moments',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildNoBriefing(AIBriefingProvider aiProvider, FlightProvider flightProvider) {
    return Column(
      children: [
        const Icon(
          Icons.flight_takeoff,
          color: Colors.grey,
          size: 48,
        ),
        const SizedBox(height: 8),
        const Text(
          'No AI briefing generated yet',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Generate an AI-powered flight briefing from your weather and NOTAM data',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: aiProvider.isGenerating ? null : () => _generateBriefing(aiProvider, flightProvider),
          icon: aiProvider.isGenerating 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(aiProvider.isGenerating ? 'Generating...' : 'Generate AI Briefing'),
        ),
      ],
    );
  }

  Widget _buildBriefing(AIBriefingProvider aiProvider, FlightProvider flightProvider) {
    final briefing = aiProvider.currentBriefing!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Briefing metadata
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Generated: ${_formatDateTime(briefing.generatedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Model: ${briefing.model}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Briefing content - Make it scrollable
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxHeight: 400, // Limit height to prevent overflow
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              briefing.briefing,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Action buttons
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _copyBriefing(briefing.briefing),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _generateBriefing(aiProvider, flightProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Generate New'),
            ),
          ],
        ),
      ],
    );
  }

  void _generateBriefing(AIBriefingProvider aiProvider, FlightProvider flightProvider) {
    // Get current weather and NOTAM data
    final notams = flightProvider.getAllNotams();
    final weatherData = _createRealWeatherData(flightProvider);
    final airportInfo = _createRealAirportInfo(flightProvider);
    
    // Generate the briefing
    aiProvider.generateBriefing(
      notams: notams,
      weatherData: weatherData,
      airportInfo: airportInfo,
    );
  }

  void _copyBriefing(String briefing) {
    // TODO: Implement clipboard functionality
    debugPrint('Copying briefing to clipboard: $briefing');
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AIBriefingSettingsDialog(
        currentStyle: _briefingStyle,
        currentLength: _briefingLength,
        includeWeather: _includeWeather,
        includeNotams: _includeNotams,
        includeSafety: _includeSafety,
        includeAlternates: _includeAlternates,
        onSave: (style, length, weather, notams, safety, alternates) {
          setState(() {
            _briefingStyle = style;
            _briefingLength = length;
            _includeWeather = weather;
            _includeNotams = notams;
            _includeSafety = safety;
            _includeAlternates = alternates;
          });
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}Z';
  }

  // Real data creation methods using FlightProvider data
  WeatherData _createRealWeatherData(FlightProvider flightProvider) {
    final weather = flightProvider.currentFlight?.weather ?? [];
    final metars = <WeatherSource>[];
    final tafs = <WeatherSource>[];
    final atis = <WeatherSource>[];
    
    // Extract weather data by type
    for (final weatherItem in weather) {
      final source = WeatherSource(
        icao: weatherItem.icao,
        rawText: weatherItem.rawText,
      );
      
      switch (weatherItem.type) {
        case 'METAR':
          metars.add(source);
          break;
        case 'TAF':
          tafs.add(source);
          break;
        case 'ATIS':
          atis.add(source);
          break;
        default:
          break;
      }
    }
    
    return WeatherData(
      metars: metars,
      tafs: tafs,
      atis: atis,
      sources: weather.map((w) => WeatherSource(icao: w.icao, rawText: w.rawText)).toList(),
    );
  }

  String _createRealAirportInfo(FlightProvider flightProvider) {
    final airports = flightProvider.currentFlight?.airports ?? [];
    if (airports.isEmpty) {
      return 'No airport data available';
    }
    
    final buffer = StringBuffer();
    
    if (airports.length == 1) {
      final airport = airports.first;
      buffer.writeln('Airport: ${airport.icao} (${airport.name})');
      buffer.writeln('Location: ${airport.city}');
      buffer.writeln('Coordinates: ${airport.latitude.toStringAsFixed(4)}, ${airport.longitude.toStringAsFixed(4)}');
    } else {
      buffer.writeln('Route: ${airports.map((a) => a.icao).join(' - ')}');
      for (final airport in airports) {
        buffer.writeln('• ${airport.icao}: ${airport.name} (${airport.city})');
      }
    }
    
    buffer.writeln('Flight Rules: IFR');
    buffer.writeln('Aircraft: B737-800');
    buffer.writeln('Generated: ${DateTime.now().toUtc().toIso8601String()}');
    
    return buffer.toString();
  }
}
