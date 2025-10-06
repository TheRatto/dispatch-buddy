import 'package:flutter/foundation.dart';
import '../services/ai_briefing_service.dart';

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
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
      
      // Get AI response
      final aiService = AIBriefingService();
      final response = await aiService.generateSimpleResponse(message);
      
      // Add AI response
      _addAIMessage(response);
      
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

  /// Add an AI message
  void _addAIMessage(String text) {
    _messages.add(ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
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

  @override
  void dispose() {
    super.dispose();
  }
}
