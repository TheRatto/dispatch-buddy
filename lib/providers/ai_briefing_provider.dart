import 'package:flutter/foundation.dart';
import '../services/ai_briefing_service.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../models/airport.dart';
import '../models/flight_context.dart';

/// AI Briefing Provider for state management
/// 
/// This provider manages the state of AI-generated briefings
/// and handles the integration with the AI Briefing Service
class AIBriefingProvider extends ChangeNotifier {
  static const String _tag = 'AIBriefingProvider';
  
  final AIBriefingService _aiService = AIBriefingService();
  
  // State variables
  bool _isInitialized = false;
  bool _isGenerating = false;
  AIBriefingResponse? _currentBriefing;
  String? _error;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isGenerating => _isGenerating;
  AIBriefingResponse? get currentBriefing => _currentBriefing;
  String? get error => _error;
  bool get hasError => _error != null;
  
  /// Initialize the AI Briefing Provider
  /// 
  /// This method initializes the underlying AI service
  /// and sets up the provider for use
  Future<void> initialize() async {
    try {
      debugPrint('$_tag: Initializing AI Briefing Provider...');
      
      await _aiService.initialize();
      _isInitialized = true;
      _error = null;
      
      debugPrint('$_tag: AI Briefing Provider initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('$_tag: Failed to initialize AI Briefing Provider: $e');
      _error = 'Failed to initialize AI service: $e';
      notifyListeners();
    }
  }
  
  /// Generate a comprehensive AI briefing using enhanced prompt engineering
  /// 
  /// This method uses the new PromptTemplateEngine to create sophisticated
  /// aviation-specific prompts that integrate all available data
  Future<void> generateComprehensiveBriefing({
    required FlightContext flightContext,
    required List<Weather> weatherData,
    required List<Notam> notams,
    required List<Airport> airports,
  }) async {
    if (!_isInitialized) {
      _error = 'AI Briefing Provider not initialized';
      notifyListeners();
      return;
    }
    
    try {
      debugPrint('$_tag: Generating comprehensive AI briefing...');
      
      _isGenerating = true;
      _error = null;
      notifyListeners();
      
      // Generate the comprehensive briefing
      final briefing = await _aiService.generateComprehensiveBriefing(
        flightContext: flightContext,
        weatherData: weatherData,
        notams: notams,
        airports: airports,
      );
      
      // Create the response
      _currentBriefing = AIBriefingResponse(
        briefing: briefing,
        generatedAt: DateTime.now(),
        model: 'Foundation Models (Enhanced)',
        metadata: {
          'notam_count': notams.length,
          'weather_sources': weatherData.length,
          'airports': airports.length,
          'flight_context': flightContext.toJson(),
          'generation_time': DateTime.now().toIso8601String(),
        },
      );
      
      debugPrint('$_tag: Comprehensive AI briefing generated successfully');
    } catch (e) {
      debugPrint('$_tag: Failed to generate comprehensive AI briefing: $e');
      _error = 'Failed to generate briefing: $e';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Generate an AI briefing from weather and NOTAM data
  /// 
  /// This method takes the current weather and NOTAM data
  /// and generates an AI-powered flight briefing
  Future<void> generateBriefing({
    required List<Notam> notams,
    required WeatherData weatherData,
    required String airportInfo,
    String? flightContext,
  }) async {
    if (!_isInitialized) {
      _error = 'AI Briefing Provider not initialized';
      notifyListeners();
      return;
    }
    
    try {
      debugPrint('$_tag: Generating AI briefing...');
      
      _isGenerating = true;
      _error = null;
      notifyListeners();
      
      // Format the data for AI processing
      final formattedWeather = _formatWeatherData(weatherData);
      final formattedNotams = _formatNotamData(notams);
      
      // Generate the briefing
      final briefing = await _aiService.generateBasicBriefing(
        weatherData: formattedWeather,
        notamData: formattedNotams,
        airportInfo: airportInfo,
      );
      
      // Create the response
      _currentBriefing = AIBriefingResponse(
        briefing: briefing,
        generatedAt: DateTime.now(),
        model: 'Foundation Models (Mock)',
        metadata: {
          'notam_count': notams.length,
          'weather_sources': weatherData.sources.length,
          'generation_time': DateTime.now().toIso8601String(),
        },
      );
      
      debugPrint('$_tag: AI briefing generated successfully');
    } catch (e) {
      debugPrint('$_tag: Failed to generate AI briefing: $e');
      _error = 'Failed to generate briefing: $e';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
  
  /// Clear the current briefing
  /// 
  /// This method clears the current briefing and any errors
  void clearBriefing() {
    _currentBriefing = null;
    _error = null;
    notifyListeners();
  }
  
  /// Clear any error state
  /// 
  /// This method clears the current error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Format weather data for AI processing
  /// 
  /// This method converts the weather data into a format
  /// suitable for AI processing
  String _formatWeatherData(WeatherData weatherData) {
    final buffer = StringBuffer();
    
    // Add METAR data
    if (weatherData.metars.isNotEmpty) {
      buffer.writeln('METAR DATA:');
      for (final metar in weatherData.metars) {
        buffer.writeln('- ${metar.icao}: ${metar.rawText}');
      }
      buffer.writeln();
    }
    
    // Add TAF data
    if (weatherData.tafs.isNotEmpty) {
      buffer.writeln('TAF DATA:');
      for (final taf in weatherData.tafs) {
        buffer.writeln('- ${taf.icao}: ${taf.rawText}');
      }
      buffer.writeln();
    }
    
    // Add ATIS data
    if (weatherData.atis.isNotEmpty) {
      buffer.writeln('ATIS DATA:');
      for (final atis in weatherData.atis) {
        buffer.writeln('- ${atis.icao}: ${atis.rawText}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }
  
  /// Format NOTAM data for AI processing
  /// 
  /// This method converts the NOTAM data into a format
  /// suitable for AI processing
  String _formatNotamData(List<Notam> notams) {
    if (notams.isEmpty) {
      return 'No NOTAMs available';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('NOTAM DATA:');
    
    // Group NOTAMs by type for better organization
    final runwayNotams = notams.where((n) => n.group == NotamGroup.runways).toList();
    final navaidNotams = notams.where((n) => n.group == NotamGroup.instrumentProcedures).toList();
    final lightingNotams = notams.where((n) => n.group == NotamGroup.lighting).toList();
    final hazardNotams = notams.where((n) => n.group == NotamGroup.hazards).toList();
    
    if (runwayNotams.isNotEmpty) {
      buffer.writeln('RUNWAY NOTAMs:');
      for (final notam in runwayNotams) {
        buffer.writeln('- ${notam.id}: ${notam.rawText}');
      }
      buffer.writeln();
    }
    
    if (navaidNotams.isNotEmpty) {
      buffer.writeln('NAVAID NOTAMs:');
      for (final notam in navaidNotams) {
        buffer.writeln('- ${notam.id}: ${notam.rawText}');
      }
      buffer.writeln();
    }
    
    if (lightingNotams.isNotEmpty) {
      buffer.writeln('LIGHTING NOTAMs:');
      for (final notam in lightingNotams) {
        buffer.writeln('- ${notam.id}: ${notam.rawText}');
      }
      buffer.writeln();
    }
    
    if (hazardNotams.isNotEmpty) {
      buffer.writeln('HAZARD NOTAMs:');
      for (final notam in hazardNotams) {
        buffer.writeln('- ${notam.id}: ${notam.rawText}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

/// Mock WeatherData class for testing
/// 
/// This is a temporary class for testing the AI integration
/// and will be replaced with the actual WeatherData model
class WeatherData {
  final List<WeatherSource> metars;
  final List<WeatherSource> tafs;
  final List<WeatherSource> atis;
  final List<WeatherSource> sources;
  
  const WeatherData({
    required this.metars,
    required this.tafs,
    required this.atis,
    required this.sources,
  });
}

/// Mock WeatherSource class for testing
class WeatherSource {
  final String icao;
  final String rawText;
  
  const WeatherSource({
    required this.icao,
    required this.rawText,
  });
}
