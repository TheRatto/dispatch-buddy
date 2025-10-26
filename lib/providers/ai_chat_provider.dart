import 'package:flutter/foundation.dart';
import '../services/ai_briefing_service.dart';
import '../services/aviation_prompt_template.dart';
import '../models/flight_context.dart';
import 'flight_provider.dart';

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final bool isPrompt; // Flag for displaying full prompts
  final ResourceMetrics? metrics; // Resource usage metrics

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.isPrompt = false,
    this.metrics,
  });
}

/// Resource metrics for AI requests
class ResourceMetrics {
  final int promptTokens;
  final int responseTokens;
  final int totalTokens;
  final Duration processingTime;
  final int promptCharacters;
  final int responseCharacters;

  ResourceMetrics({
    required this.promptTokens,
    required this.responseTokens,
    required this.totalTokens,
    required this.processingTime,
    required this.promptCharacters,
    required this.responseCharacters,
  });

  /// Estimated cost (for reference, based on typical LLM pricing)
  /// Note: Foundation Models is free/on-device, but this helps understand scale
  double get estimatedCost {
    // Example: $0.03 per 1K prompt tokens, $0.06 per 1K completion tokens
    final promptCost = (promptTokens / 1000) * 0.03;
    final responseCost = (responseTokens / 1000) * 0.06;
    return promptCost + responseCost;
  }

  String toDisplayString() {
    final seconds = processingTime.inMilliseconds / 1000;
    return '📊 Prompt: ${_formatNumber(promptTokens)} tokens (${_formatNumber(promptCharacters)} chars) • '
           'Response: ${_formatNumber(responseTokens)} tokens (${_formatNumber(responseCharacters)} chars) • '
           'Total: ${_formatNumber(totalTokens)} tokens • '
           'Time: ${seconds.toStringAsFixed(2)}s';
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// AI Chat status enum
enum AIChatStatus {
  ready,
  processing,
  notAvailable,
  error,
}

/// AI Chat Provider
/// 
/// Manages chat state and integrates with AI Briefing Service
/// for testing Foundation Models functionality
class AIChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  AIChatStatus _status = AIChatStatus.notAvailable;
  bool _isInitialized = false;
  String? _lastError;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  AIChatStatus get status => _status;
  String? get lastError => _lastError;

  /// Initialize the chat provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('AIChatProvider: Initializing...');
      
      // Add welcome message
      _addSystemMessage('Welcome to AI Test Chat! This interface helps test Apple Foundation Models integration.');
      
      // Check AI service availability
      final aiService = AIBriefingService();
      final isAvailable = await aiService.isFoundationModelsAvailable();
      
      if (isAvailable) {
        _status = AIChatStatus.ready;
        _addSystemMessage('✅ Foundation Models detected! AI chat is ready.');
        debugPrint('AIChatProvider: Foundation Models available');
      } else {
        _status = AIChatStatus.notAvailable;
        _addSystemMessage('⚠️ Foundation Models not available. Using fallback responses for testing.');
        debugPrint('AIChatProvider: Foundation Models not available');
      }
      
      _isInitialized = true;
      notifyListeners();
      
    } catch (e) {
      debugPrint('AIChatProvider: Initialization error: $e');
      _status = AIChatStatus.error;
      _lastError = e.toString();
      _addSystemMessage('❌ Error initializing AI chat: ${e.toString()}');
      notifyListeners();
    }
  }

  /// Send a message to the AI
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    try {
      // Add user message
      _addUserMessage(message);
      
      // Set processing status
      _status = AIChatStatus.processing;
      notifyListeners();
      
      // Get AI response with timing
      final stopwatch = Stopwatch()..start();
      final aiService = AIBriefingService();
      final response = await aiService.generateSimpleResponse(message);
      stopwatch.stop();
      
      // Create metrics (using message as prompt for simple queries)
      final metrics = _createMetrics(
        prompt: message,
        response: response,
        processingTime: stopwatch.elapsed,
      );
      
      // Add AI response with metrics
      _addAIMessageWithMetrics(response, metrics);
      
      // Set ready status
      _status = AIChatStatus.ready;
      notifyListeners();
      
    } catch (e) {
      debugPrint('AIChatProvider: Error sending message: $e');
      _status = AIChatStatus.error;
      _lastError = e.toString();
      _addErrorMessage('Error: ${e.toString()}');
      notifyListeners();
    }
  }

  /// Add a user message
  void _addUserMessage(String text) {
    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Add an AI message (without metrics - used for system messages)
  // ignore: unused_element
  void _addAIMessage(String text) {
    _messages.add(ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Add an AI message with resource metrics
  void _addAIMessageWithMetrics(String text, ResourceMetrics metrics) {
    _messages.add(ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      metrics: metrics,
    ));
    notifyListeners();
  }

  /// Add a system message
  void _addSystemMessage(String text) {
    _messages.add(ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Add an error message
  void _addErrorMessage(String text) {
    _messages.add(ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    ));
    notifyListeners();
  }

  /// Add a prompt message (full prompt sent to AI)
  void _addPromptMessage(String text) {
    _messages.add(ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      isPrompt: true,
    ));
    notifyListeners();
  }

  /// Estimate prompt length for display
  int _estimatePromptLength(String prompt) {
    return prompt.length;
  }

  /// Estimate token count from text
  /// Rough approximation: 1 token ≈ 4 characters for English text
  /// More accurate would use a tokenizer, but this is good enough for estimates
  int _estimateTokenCount(String text) {
    // Average token length is about 4 characters
    // Adjust for aviation text which has more abbreviations and codes
    return (text.length / 3.5).round();
  }

  /// Create resource metrics from prompt and response
  ResourceMetrics _createMetrics({
    required String prompt,
    required String response,
    required Duration processingTime,
  }) {
    final promptTokens = _estimateTokenCount(prompt);
    final responseTokens = _estimateTokenCount(response);
    
    return ResourceMetrics(
      promptTokens: promptTokens,
      responseTokens: responseTokens,
      totalTokens: promptTokens + responseTokens,
      processingTime: processingTime,
      promptCharacters: prompt.length,
      responseCharacters: response.length,
    );
  }

  /// Clear chat history
  void clearChat() {
    _messages.clear();
    _addSystemMessage('Chat cleared. Ready for new conversation.');
    notifyListeners();
  }

  /// Retry last failed operation
  Future<void> retry() async {
    if (_lastError != null) {
      _lastError = null;
      _status = AIChatStatus.ready;
      notifyListeners();
    }
  }

  /// Load current flight data and generate aviation briefing
  Future<void> loadFlightDataAndGenerateBriefing(FlightProvider flightProvider) async {
    try {
      _addSystemMessage('🛩️ Loading current flight data...');
      
      // Set processing status
      _status = AIChatStatus.processing;
      notifyListeners();
      
      // Get current flight data
      final weatherData = flightProvider.currentFlight?.weather ?? [];
      final notams = flightProvider.currentFlight?.notams ?? [];
      final airports = flightProvider.currentFlight?.airports ?? [];
      
      // Create flight context from current data
      final flightContext = _createFlightContextFromProvider(flightProvider);
      
      if (weatherData.isEmpty && notams.isEmpty) {
        _addSystemMessage('⚠️ No flight data available. Please load weather and NOTAMs first.');
        _status = AIChatStatus.ready;
        notifyListeners();
        return;
      }
      
      _addSystemMessage('📊 Flight data loaded:');
      _addSystemMessage('• Weather stations: ${weatherData.length}');
      _addSystemMessage('• NOTAMs: ${notams.length}');
      _addSystemMessage('• Airports: ${airports.length}');
      _addSystemMessage('• Route: ${flightContext.departureIcao} → ${flightContext.destinationIcao}');
      
      // Generate the full prompt that will be sent to the AI
      final fullPrompt = AviationPromptTemplate.generateBriefingPrompt(
        flightContext: flightContext,
        weatherData: weatherData,
        notams: notams,
        airports: airports,
        briefingStyle: BriefingStyle.comprehensive.name,
      );
      
      // Display the full prompt in a collapsible format
      _addSystemMessage('📝 Full Prompt Generated (${_estimatePromptLength(fullPrompt)} chars)');
      _addPromptMessage(fullPrompt);
      
      // Generate aviation briefing with timing
      _addSystemMessage('🤖 Sending to Foundation Models...');
      final stopwatch = Stopwatch()..start();
      
      final aiService = AIBriefingService();
      final briefing = await aiService.generateAviationBriefing(
        flightContext: flightContext,
        weatherData: weatherData,
        notams: notams,
        airports: airports,
        briefingStyle: BriefingStyle.comprehensive,
      );
      
      stopwatch.stop();
      
      // Create metrics
      final metrics = _createMetrics(
        prompt: fullPrompt,
        response: briefing,
        processingTime: stopwatch.elapsed,
      );
      
      // Add the briefing as an AI message with metrics
      _addAIMessageWithMetrics(briefing, metrics);
      
      _status = AIChatStatus.ready;
      notifyListeners();
      
    } catch (e) {
      debugPrint('AIChatProvider: Error loading flight data: $e');
      _status = AIChatStatus.error;
      _lastError = e.toString();
      _addErrorMessage('Error loading flight data: ${e.toString()}');
      notifyListeners();
    }
  }

  /// Generate quick aviation response with current flight context
  Future<void> generateQuickAviationResponse(String query, FlightProvider flightProvider) async {
    try {
      _addUserMessage(query);
      
      // Set processing status
      _status = AIChatStatus.processing;
      notifyListeners();
      
      // Get current flight data
      final weatherData = flightProvider.currentFlight?.weather ?? [];
      final notams = flightProvider.currentFlight?.notams ?? [];
      
      // Generate the full prompt that will be sent to the AI
      final fullPrompt = AviationPromptTemplate.generateQuickPrompt(
        query: query,
        weatherData: weatherData.isNotEmpty ? weatherData : null,
        notams: notams.isNotEmpty ? notams : null,
      );
      
      // Display the full prompt
      _addSystemMessage('📝 Full Prompt (${_estimatePromptLength(fullPrompt)} chars)');
      _addPromptMessage(fullPrompt);
      
      // Generate quick aviation response with timing
      _addSystemMessage('🤖 Sending to Foundation Models...');
      final stopwatch = Stopwatch()..start();
      
      final aiService = AIBriefingService();
      final response = await aiService.generateQuickAviationResponse(
        query: query,
        weatherData: weatherData.isNotEmpty ? weatherData : null,
        notams: notams.isNotEmpty ? notams : null,
      );
      
      stopwatch.stop();
      
      // Create metrics
      final metrics = _createMetrics(
        prompt: fullPrompt,
        response: response,
        processingTime: stopwatch.elapsed,
      );
      
      // Add AI response with metrics
      _addAIMessageWithMetrics(response, metrics);
      
      _status = AIChatStatus.ready;
      notifyListeners();
      
    } catch (e) {
      debugPrint('AIChatProvider: Error generating aviation response: $e');
      _status = AIChatStatus.error;
      _lastError = e.toString();
      _addErrorMessage('Error generating aviation response: ${e.toString()}');
      notifyListeners();
    }
  }

  /// Create flight context from FlightProvider data
  FlightContext _createFlightContextFromProvider(FlightProvider flightProvider) {
    // Get departure and destination from current flight
    final flight = flightProvider.currentFlight;
    final departureIcao = flight?.departure ?? 'YPPH';
    final destinationIcao = flight?.destination ?? 'YSSY';
    
    // Create a realistic flight context
    final now = DateTime.now().toUtc();
    final departureTime = now.add(const Duration(hours: 2));
    final arrivalTime = departureTime.add(const Duration(hours: 3));
    
    return FlightContext(
      departureIcao: departureIcao,
      destinationIcao: destinationIcao,
      alternateIcaos: ['YBBN', 'YMML'], // Default alternates
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      aircraftType: 'B737-800', // Default aircraft
      flightRules: 'IFR',
      pilotExperience: 'ATP',
      briefingStyle: 'comprehensive',
      route: 'Direct',
      altitude: 'FL370',
    );
  }

  /// Test different briefing styles with current data
  Future<void> testBriefingStyles(FlightProvider flightProvider) async {
    try {
      _addSystemMessage('🧪 Testing different briefing styles...');
      
      final weatherData = flightProvider.currentFlight?.weather ?? [];
      final notams = flightProvider.currentFlight?.notams ?? [];
      final airports = flightProvider.currentFlight?.airports ?? [];
      final flightContext = _createFlightContextFromProvider(flightProvider);
      
      if (weatherData.isEmpty && notams.isEmpty) {
        _addSystemMessage('⚠️ No flight data available for testing.');
        return;
      }
      
      final aiService = AIBriefingService();
      final styles = [
        BriefingStyle.quick,
        BriefingStyle.standard,
        BriefingStyle.comprehensive,
        BriefingStyle.safetyFocus,
        BriefingStyle.operational,
      ];
      
      for (final style in styles) {
        _addSystemMessage('📝 Testing ${style.displayName}...');
        
        // Generate and show the full prompt
        final fullPrompt = AviationPromptTemplate.generateBriefingPrompt(
          flightContext: flightContext,
          weatherData: weatherData,
          notams: notams,
          airports: airports,
          briefingStyle: style.name,
        );
        
        _addSystemMessage('📝 Prompt for ${style.displayName} (${_estimatePromptLength(fullPrompt)} chars)');
        _addPromptMessage(fullPrompt);
        
        _status = AIChatStatus.processing;
        notifyListeners();
        
        // Generate with timing
        final stopwatch = Stopwatch()..start();
        final briefing = await aiService.generateAviationBriefing(
          flightContext: flightContext,
          weatherData: weatherData,
          notams: notams,
          airports: airports,
          briefingStyle: style,
        );
        stopwatch.stop();
        
        // Create metrics
        final metrics = _createMetrics(
          prompt: fullPrompt,
          response: briefing,
          processingTime: stopwatch.elapsed,
        );
        
        _addAIMessageWithMetrics('## ${style.displayName}\n\n$briefing', metrics);
        
        _status = AIChatStatus.ready;
        notifyListeners();
        
        // Small delay between tests
        await Future.delayed(const Duration(seconds: 1));
      }
      
    } catch (e) {
      debugPrint('AIChatProvider: Error testing briefing styles: $e');
      _status = AIChatStatus.error;
      _lastError = e.toString();
      _addErrorMessage('Error testing briefing styles: ${e.toString()}');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
