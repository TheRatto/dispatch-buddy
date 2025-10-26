import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:version/version.dart';
import 'foundation_models_bridge.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../models/airport.dart';
import '../models/flight_context.dart';
import 'prompt_template_engine.dart';
import 'aviation_prompt_template.dart';

/// AI Briefing Service using Apple's Foundation Models framework
/// 
/// This service provides on-device AI processing for generating
/// intelligent flight briefings from weather and NOTAM data.
class AIBriefingService {
  static const String _tag = 'AIBriefingService';
  
  final PromptTemplateEngine _promptEngine = PromptTemplateEngine();
  
  /// Initialize the AI briefing service
  /// 
  /// This method sets up the Foundation Models framework
  /// for on-device AI processing
  Future<void> initialize() async {
    try {
      debugPrint('$_tag: Initializing AI Briefing Service...');
      
      // Check if Foundation Models is available
      if (!await _isFoundationModelsAvailable()) {
        throw Exception('Foundation Models framework not available on this device');
      }
      
      // Initialize the language model session
      await _initializeLanguageModel();
      
      debugPrint('$_tag: AI Briefing Service initialized successfully');
    } catch (e) {
      debugPrint('$_tag: Failed to initialize AI Briefing Service: $e');
      rethrow;
    }
  }

  /// Check if Foundation Models is available on this device
  /// 
  /// This method performs comprehensive checks for iOS version,
  /// hardware capability, and Apple Intelligence availability
  Future<bool> isFoundationModelsAvailable() async {
    return await _isFoundationModelsAvailable();
  }

  /// Generate a simple AI response for testing purposes
  /// 
  /// This method provides a simple interface for testing Foundation Models
  /// without requiring complex flight data
  Future<String> generateSimpleResponse(String prompt) async {
    try {
      debugPrint('$_tag: Generating simple response for prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...');
      
      // Check if Foundation Models is available
      if (!await _isFoundationModelsAvailable()) {
        debugPrint('$_tag: Foundation Models not available, using fallback response');
        return _generateSimpleFallbackResponse();
      }
      
      // Initialize if needed
      await _initializeLanguageModel();
      
      // Process with Foundation Models
      final response = await _processWithFoundationModels(prompt);
      
      debugPrint('$_tag: Simple response generated successfully');
      return response;
      
    } catch (e) {
      debugPrint('$_tag: Error generating simple response: $e');
      return _generateErrorBriefing('Failed to generate response: ${e.toString()}');
    }
  }

  /// Generate an aviation-specific flight briefing
  /// 
  /// This method creates a comprehensive flight briefing using real aviation data
  /// and the structured prompt template for optimal AI processing.
  Future<String> generateAviationBriefing({
    required FlightContext flightContext,
    required List<Weather> weatherData,
    required List<Notam> notams,
    required List<Airport> airports,
    BriefingStyle briefingStyle = BriefingStyle.comprehensive,
  }) async {
    try {
      debugPrint('$_tag: Generating aviation briefing for ${flightContext.departureIcao} → ${flightContext.destinationIcao}');
      
      // Check if Foundation Models is available
      if (!await _isFoundationModelsAvailable()) {
        debugPrint('$_tag: Foundation Models not available, using fallback briefing');
        return _generateOfflineBriefing(
          flightContext: flightContext,
          weatherData: weatherData,
          notams: notams,
          airports: airports,
        );
      }
      
      // Initialize if needed
      await _initializeLanguageModel();
      
      // Generate structured prompt
      final prompt = AviationPromptTemplate.generateBriefingPrompt(
        flightContext: flightContext,
        weatherData: weatherData,
        notams: notams,
        airports: airports,
        briefingStyle: briefingStyle.displayName,
      );
      
      debugPrint('$_tag: Generated structured prompt (${prompt.length} characters)');
      
      // Process with Foundation Models
      final response = await _processWithFoundationModels(prompt);
      
      debugPrint('$_tag: Aviation briefing generated successfully');
      return response;
      
    } catch (e) {
      debugPrint('$_tag: Error generating aviation briefing: $e');
      return _generateErrorBriefing('Failed to generate aviation briefing: ${e.toString()}');
    }
  }

  /// Generate a quick aviation response for simple queries
  /// 
  /// This method handles quick aviation-related questions with optional context data.
  Future<String> generateQuickAviationResponse({
    required String query,
    List<Weather>? weatherData,
    List<Notam>? notams,
  }) async {
    try {
      debugPrint('$_tag: Generating quick aviation response for: ${query.substring(0, query.length > 50 ? 50 : query.length)}...');
      
      // Check if Foundation Models is available
      if (!await _isFoundationModelsAvailable()) {
        debugPrint('$_tag: Foundation Models not available, using fallback response');
        return _generateSimpleFallbackResponse();
      }
      
      // Initialize if needed
      await _initializeLanguageModel();
      
      // Generate quick prompt
      final prompt = AviationPromptTemplate.generateQuickPrompt(
        query: query,
        weatherData: weatherData,
        notams: notams,
      );
      
      // Process with Foundation Models
      final response = await _processWithFoundationModels(prompt);
      
      debugPrint('$_tag: Quick aviation response generated successfully');
      return response;
      
    } catch (e) {
      debugPrint('$_tag: Error generating quick aviation response: $e');
      return _generateErrorBriefing('Failed to generate response: ${e.toString()}');
    }
  }

  /// Generate a simple fallback response for testing
  String _generateSimpleFallbackResponse() {
    return """
# AI Test Response (Fallback Mode)

**Status**: Foundation Models not available on this device
**iOS Version**: ${Platform.isIOS ? 'iOS detected' : 'Non-iOS platform'}
**Apple Intelligence**: Not available or not enabled

## Test Response
This is a fallback response generated when Apple Foundation Models is not available. This typically occurs when:

- iOS version is below 26.0
- Apple Intelligence is not enabled in device settings
- Device doesn't support Apple Intelligence
- Foundation Models framework is not fully available

## Next Steps
To test real Foundation Models functionality:
1. Ensure you're running iOS 26.0 or later
2. Enable Apple Intelligence in Settings → Privacy & Security → Apple Intelligence
3. Wait for the model to download and become available

---
*Generated by Briefing Buddy AI Test Chat (Fallback Mode)*
""";
  }

  /// Dispose of resources and clean up Foundation Models session
  /// 
  /// This method properly releases GPU memory allocated by the language model
  Future<void> dispose() async {
    try {
      debugPrint('$_tag: Disposing Foundation Models session...');
      await FoundationModelsBridge.dispose();
      debugPrint('$_tag: Foundation Models session disposed successfully');
    } catch (e) {
      debugPrint('$_tag: Error during cleanup: $e');
    }
  }

  /// Cancel current AI processing task
  /// 
  /// This method allows users to interrupt expensive AI operations
  Future<void> cancelCurrentProcessing() async {
    try {
      debugPrint('$_tag: Cancellation requested');
      await FoundationModelsBridge.cancelCurrentOperation();
      debugPrint('$_tag: AI processing cancellation acknowledged');
    } catch (e) {
      debugPrint('$_tag: Error cancelling AI processing: $e');
    }
  }

  /// Generate a comprehensive AI briefing using enhanced prompt engineering
  /// 
  /// This method uses the PromptTemplateEngine to create sophisticated
  /// aviation-specific prompts that integrate all available data
  Future<String> generateComprehensiveBriefing({
    required FlightContext flightContext,
    required List<Weather> weatherData,
    required List<Notam> notams,
    required List<Airport> airports,
  }) async {
    try {
      debugPrint('$_tag: Generating comprehensive briefing...');
      
      // Check Foundation Models availability first
      if (!await _isFoundationModelsAvailable()) {
        debugPrint('$_tag: Foundation Models not available, using fallback briefing');
        return _generateOfflineBriefing(
          flightContext: flightContext,
          weatherData: weatherData,
          notams: notams,
          airports: airports,
        );
      }
      
      // Create enhanced prompt using the template engine
      final prompt = _promptEngine.buildAviationPrompt(
        departureIcao: flightContext.departureIcao,
        destinationIcao: flightContext.destinationIcao,
        alternateIcaos: flightContext.alternateIcaos,
        departureTime: flightContext.departureTime,
        arrivalTime: flightContext.arrivalTime,
        aircraftType: flightContext.aircraftType,
        flightRules: flightContext.flightRules,
        weatherData: weatherData,
        notams: notams,
        airports: airports,
        briefingStyle: flightContext.briefingStyle,
        pilotExperience: flightContext.pilotExperience,
      );
      
      // Process with Foundation Models
      final response = await _processWithFoundationModels(prompt);
      
      debugPrint('$_tag: Comprehensive briefing generated successfully');
      return response;
    } on FoundationModelsException catch (e) {
      debugPrint('$_tag: Foundation Models error: ${e.message}');
      return _generateFallbackBriefing(
        flightContext: flightContext,
        weatherData: weatherData,
        notams: notams,
        airports: airports,
      );
    } catch (e) {
      debugPrint('$_tag: Unexpected error in comprehensive briefing: $e');
      return _generateErrorBriefing('AI briefing service temporarily unavailable. Please use standard briefing tools.');
    }
  }

  /// Generate a basic AI briefing from weather and NOTAM data
  /// 
  /// This is the initial implementation that will be enhanced
  /// with aviation-specific prompts and data structures
  Future<String> generateBasicBriefing({
    required String weatherData,
    required String notamData,
    required String airportInfo,
  }) async {
    try {
      debugPrint('$_tag: Generating basic briefing...');
      
      // Create a simple prompt for initial testing
      final prompt = _createBasicPrompt(
        weatherData: weatherData,
        notamData: notamData,
        airportInfo: airportInfo,
      );
      
      // For now, return a placeholder response
      // This will be replaced with actual Foundation Models integration
      final response = await _processWithFoundationModels(prompt);
      
      debugPrint('$_tag: Basic briefing generated successfully');
      return response;
    } catch (e) {
      debugPrint('$_tag: Failed to generate basic briefing: $e');
      rethrow;
    }
  }
  
  /// Check if Foundation Models framework is available
  /// 
  /// This method checks if the device supports Foundation Models
  /// and if the framework is properly installed
  Future<bool> _isFoundationModelsAvailable() async {
    try {
      debugPrint('$_tag: Checking Foundation Models availability...');
      
      if (Platform.isIOS) {
        // First check device compatibility
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        final iosVersion = Version.parse(iosInfo.systemVersion);
        final minimumVersion = Version(26, 0, 0); // Updated to iOS 26+ based on Gemini info
        
        final supportsFoundationModels = iosVersion >= minimumVersion;
        
        debugPrint('$_tag: iOS Version: ${iosInfo.systemVersion}');
        debugPrint('$_tag: Minimum required: iOS 26.0+');
        debugPrint('$_tag: Device Model: ${iosInfo.model}');
        
        if (!supportsFoundationModels) {
          debugPrint('$_tag: iOS version ${iosInfo.systemVersion} is below minimum requirement of iOS 26.0');
          return false;
        }
        
        // Additional checks for hardware capability
        final deviceModel = iosInfo.model.toLowerCase();
        if (deviceModel.contains('iphone') && !_supportsHardwareAcceleration(deviceModel)) {
          debugPrint('$_tag: Device model $deviceModel may not support hardware acceleration');
          return false;
        }
        
        // Check Apple Intelligence availability via custom bridge
        try {
          final availability = await FoundationModelsBridge.checkAvailability();
          final isAppleIntelligenceAvailable = availability['available'] as bool? ?? false;
          
          debugPrint('$_tag: Apple Intelligence available: $isAppleIntelligenceAvailable');
          debugPrint('$_tag: iOS Version detected: ${availability['osVersion']}');
          
          return isAppleIntelligenceAvailable;
        } catch (e) {
          debugPrint('$_tag: Error checking Foundation Models availability: $e');
          return false;
        }
      }
      
      debugPrint('$_tag: Foundation Models only supported on iOS platform');
      return false;
    } catch (e) {
      debugPrint('$_tag: Error checking Foundation Models availability: $e');
      return false;
    }
  }
  
  /// Check if device hardware supports Foundation Models acceleration
  /// 
  /// This method assesses hardware capability for AI processing
  /// Updated to be less restrictive for iOS 26+ devices
  bool _supportsHardwareAcceleration(String deviceModel) {
    // For iOS 26+, assume most modern iPhones support Foundation Models
    // The actual availability will be checked via the native bridge
    debugPrint('$_tag: Device model: $deviceModel');
    
    // Basic check - if it's an iPhone and iOS 26+, assume it supports Foundation Models
    if (deviceModel.toLowerCase().contains('iphone')) {
      debugPrint('$_tag: iPhone detected - assuming Foundation Models support on iOS 26+');
      return true;
    }
    
    debugPrint('$_tag: Non-iPhone device - Foundation Models not supported');
    return false;
  }
  
  /// Foundation Models bridge instance
  // Using custom bridge instead of package
  
  /// Initialize the language model session
  /// 
  /// This method sets up the Foundation Models language model
  /// for text processing and generation
  Future<void> _initializeLanguageModel() async {
    try {
      debugPrint('$_tag: Initializing Foundation Models session...');
      
      // TODO: Replace with actual Foundation Models SDK when available
      /*
      Create session with OpenELM-V1.7b-Instruct (best for constrained tasks)
      final session = LanguageModelSession(
        model: 'com.apple.ml.OpenELM-OpenELM-V1.7b-Instruct',
        configuration: LanguageModelConfiguration(
          maximumTokenCount: 1500, // Reasonable limit for aviation briefings
          temperature: 0.3, // Low temperature for factual content
          stopPhrases: ['END_OF_BRIEFING', '---'], // Stop conditions
          vocabularyRepetitionPenalty: 1.1, // Reduce repetition slightly
          eosTokenID: nil, // Auto-detect EOS token
        ),
      );
      
      // Configure for our domain (aviation)
      session.system = '''
You are an expert aviation briefing assistant. Generate concise, safety-focused flight briefings using professional aviation terminology. Focus on:

1. Weather conditions and trends
2. Runway/NAVAID availability  
3. Critical operational impacts
4. Safety recommendations
5. Alternate considerations

Keep briefings factual, clear, and actionable. Always prioritize safety-critical information.
''';
      
      // Initialize the session (this pre-loads the model into GPU memory)
      await session.run();
      
      _languageModelSession = session;
      debugPrint('$_tag: Foundation Models session initialized successfully');
      debugPrint('$_tag: Model: OpenELM-V1.7b-Instruct');
      debugPrint('$_tag: Memory allocated (~1GB GPU)');
      */
      
      // Initialize Foundation Models via custom bridge
      await FoundationModelsBridge.initialize();
      
      debugPrint('$_tag: Foundation Models session initialized successfully');
      debugPrint('$_tag: Custom bridge ready for Apple Intelligence');
      
    } catch (e) {
      debugPrint('$_tag: Failed to initialize Foundation Models session: $e');
      throw FoundationModelsException(
        message: 'Failed to initialize AI model: ${e.toString()}',
        errorCode: 'INITIALIZATION_ERROR',
        originalError: e,
      );
    }
  }
  
  /// Create a basic prompt for initial testing
  /// 
  /// This method creates a simple prompt that will be enhanced
  /// with aviation-specific templates
  String _createBasicPrompt({
    required String weatherData,
    required String notamData,
    required String airportInfo,
  }) {
    return '''
    You are an expert aviation briefing AI. Please analyze the following data and provide a concise flight briefing:

    AIRPORT INFORMATION:
    $airportInfo

    WEATHER DATA:
    $weatherData

    NOTAMs:
    $notamData

    Please provide:
    1. A brief weather summary
    2. Key operational impacts
    3. Safety recommendations
    4. Any critical information for pilots

    Keep the briefing professional, concise, and safety-focused.
    ''';
  }
  
  /// Process the prompt with Foundation Models
  /// 
  /// This method integrates with the actual Foundation Models
  /// framework for on-device AI processing
  Future<String> _processWithFoundationModels(String prompt) async {
    try {
      debugPrint('$_tag: Processing prompt with Foundation Models...');
      debugPrint('$_tag: Prompt length: ${prompt.length} characters');
      
      // Send prompt to Foundation Models via custom bridge
      final response = await FoundationModelsBridge.generateBriefing(prompt);
      
      debugPrint('$_tag: Generated ${response.length} characters');
      debugPrint('$_tag: Foundation Models completion successful');
      
      return response;
      
    } on FoundationModelsException {
      // Re-throw our custom exceptions
      rethrow;
    } catch (e) {
      debugPrint('$_tag: Foundation Models processing failed: $e');
      
      // Map common Foundation Models errors
      String errorMessage;
      String errorCode;
      
      if (e.toString().contains('GPU') || e.toString().contains('memory')) {
        errorMessage = 'Insufficient GPU memory for AI processing';
        errorCode = 'GPU_MEMORY_ERROR';
      } else {
        errorMessage = 'AI processing failed: ${e.toString()}';
        errorCode = 'PROCESSING_ERROR';
      }
      
      throw FoundationModelsException(
        message: errorMessage,
        errorCode: errorCode,
        originalError: e,
      );
    }
  }
  
  /// Generate a mock response for testing
  /// 
  /// This method provides a sample response for initial testing
  /// and will be removed once Foundation Models is integrated
  
  /// Generate offline briefing when Foundation Models is not available
  /// 
  /// This provides a structured briefing without AI processing
  String _generateOfflineBriefing({
    required FlightContext flightContext,
    required List<Weather> weatherData,
    required List<Notam> notams,
    required List<Airport> airports,
  }) {
    final now = DateTime.now().toUtc();
    final briefingTime = '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}Z';
    
    StringBuffer briefing = StringBuffer();
    
    // Header with offline indication
    briefing.writeln('# FLIGHT BRIEFING - OFFLINE MODE');
    briefing.writeln('**Generated**: $briefingTime');
    briefing.writeln('**Mode**: Standard briefing (AI unavailable)');
    briefing.writeln('**Route**: ${flightContext.departureIcao} → ${flightContext.destinationIcao}');
    briefing.writeln();
    
    // Weather Summary
    briefing.writeln('## 🌤️ WEATHER SUMMARY');
    if (weatherData.isNotEmpty) {
      final departureWeather = weatherData.where((w) => w.icao == flightContext.departureIcao).firstOrNull;
      final destinationWeather = weatherData.where((w) => w.icao == flightContext.destinationIcao).firstOrNull;
      
      if (departureWeather != null) {
        briefing.writeln('**${flightContext.departureIcao}**: ${departureWeather.rawText}');
      }
      if (destinationWeather != null) {
        briefing.writeln('**${flightContext.destinationIcao}**: ${destinationWeather.rawText}');
      }
    } else {
      briefing.writeln('*Weather data not available - verify current conditions*');
    }
    briefing.writeln();
    
    // Critical NOTAMs
    briefing.writeln('## ⚠️ CRITICAL NOTAMs');
    final criticalNotams = notams.where((n) => n.isCritical || n.group == NotamGroup.runways).take(5).toList();
    if (criticalNotams.isNotEmpty) {
      for (final notam in criticalNotams) {
        final description = notam.fieldE.isNotEmpty ? notam.fieldE : notam.rawText;
        briefing.writeln('• **${notam.id}**: ${description.length > 50 ? description.substring(0, 50) + '...' : description}');
      }
    } else {
      briefing.writeln('No critical NOTAMs identified');
    }
    briefing.writeln();
    
    // Safety Considerations
    briefing.writeln('## 🚨 SAFETY CONSIDERATIONS');
    briefing.writeln('1. **Data Verification**: Always verify information with official sources');
    briefing.writeln('2. **Weather**: Check latest METAR/TAF for current conditions');
    briefing.writeln('3. **NOTAMs**: Review all applicable NOTAMs for your route');
    briefing.writeln('4. **Alternates**: Confirm alternate airports and fuel requirements');
    briefing.writeln();
    
    // Footer
    briefing.writeln('---');
    briefing.writeln('*This briefing was generated in offline mode. AI-powered analysis is unavailable.*');
    briefing.writeln('*For optimal briefing, ensure iOS 19.0+ and Foundation Models capability.*');
    
    return briefing.toString();
  }
  
  /// Generate fallback briefing when Foundation Models fails
  /// 
  /// This provides enhanced briefing with reduced AI analysis
  String _generateFallbackBriefing({
    required FlightContext flightContext,
    required List<Weather> weatherData,
    required List<Notam> notams,
    required List<Airport> airports,
  }) {
    return _generateOfflineBriefing(
      flightContext: flightContext,
      weatherData: weatherData,
      notams: notams,
      airports: airports,
    ).replaceFirst('OFFLINE MODE', 'FALLBACK MODE')
     .replaceFirst('AI unavailable', 'AI processing encountered an error')
     .replaceFirst('generated in offline mode', 'generated with fallback processing');
  }
  
  /// Generate error briefing when all systems fail
  /// 
  /// This provides minimal briefing with clear error messaging
  String _generateErrorBriefing(String errorMessage) {
    final now = DateTime.now().toUtc();
    final briefingTime = '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}Z';
    
    return '''
# FLIGHT BRIEFING - ERROR STATE
**Generated**: $briefingTime
**Status**: ⚠️ Service Unavailable

## 🚨 IMPORTANT NOTICE
$errorMessage

## 📋 MANUAL BRIEFING REQUIRED
Please use alternative briefing sources:
1. **Official Weather**: Check METAR/TAF from official sources
2. **NOTAM Services**: Verify NOTAMs through official channels  
3. **ATC Communications**: Contact appropriate authorities
4. **Flight Planning**: Use certified flight planning tools

## 🔧 TECHNICAL SUPPORT
- Ensure device meets iOS 19.0+ requirement for Foundation Models
- Check device has sufficient GPU memory (~1GB for AI processing)
- Restart application if issues persist
- Contact technical support if problem continues

---
*Briefing service is temporarily unavailable. Always verify information with official sources.*
''';
  }
}

/// Custom exception for Foundation Models errors
class FoundationModelsException implements Exception {
  final String message;
  final String errorCode;
  final dynamic originalError;
  
  const FoundationModelsException({
    required this.message,
    this.errorCode = 'FOUNDATION_MODELS_ERROR',
    this.originalError,
  });
  
  @override
  String toString() => 'FoundationModelsException: $message (Code: $errorCode)';
}

/// Data class for AI briefing requests
class AIBriefingRequest {
  final String weatherData;
  final String notamData;
  final String airportInfo;
  final String? flightContext;
  
  const AIBriefingRequest({
    required this.weatherData,
    required this.notamData,
    required this.airportInfo,
    this.flightContext,
  });
}

/// Data class for AI briefing responses
class AIBriefingResponse {
  final String briefing;
  final DateTime generatedAt;
  final String model;
  final Map<String, dynamic> metadata;
  
  const AIBriefingResponse({
    required this.briefing,
    required this.generatedAt,
    required this.model,
    required this.metadata,
  });
}
