import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_chat_provider.dart';

/// AI Test Chat Screen
/// 
/// This screen provides a chat-like interface to test Apple Foundation Models
/// integration and validate AI functionality on different iOS versions
class AITestChatScreen extends StatefulWidget {
  const AITestChatScreen({Key? key}) : super(key: key);

  @override
  State<AITestChatScreen> createState() => _AITestChatScreenState();
}

class _AITestChatScreenState extends State<AITestChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize the AI chat provider when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIChatProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<AIChatProvider>().sendMessage(message);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showTestPrompts() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Prompts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPromptButton('Hello, can you help me?'),
            _buildPromptButton('What can you do?'),
            _buildPromptButton('Generate a flight briefing for YSCB to YSSY'),
            _buildPromptButton('Tell me about aviation weather'),
            _buildPromptButton('What are NOTAMs?'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptButton(String prompt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _messageController.text = prompt;
            _sendMessage();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade50,
            foregroundColor: Colors.blue.shade700,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            prompt,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Test Chat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showTestPrompts,
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Test Prompts',
          ),
        ],
      ),
      body: Consumer<AIChatProvider>(
        builder: (context, chatProvider, child) {
          return Column(
            children: [
              // Status indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: _getStatusColor(chatProvider.status),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(chatProvider.status),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getStatusText(chatProvider.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              
              // Input area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: chatProvider.status == AIChatStatus.ready,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: chatProvider.status == AIChatStatus.ready
                            ? Colors.blue
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: chatProvider.status == AIChatStatus.ready
                            ? _sendMessage
                            : null,
                        icon: chatProvider.status == AIChatStatus.processing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.smart_toy,
                size: 20,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade200,
              child: Icon(
                Icons.person,
                size: 20,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(AIChatStatus status) {
    switch (status) {
      case AIChatStatus.ready:
        return Colors.green;
      case AIChatStatus.processing:
        return Colors.orange;
      case AIChatStatus.notAvailable:
        return Colors.red;
      case AIChatStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(AIChatStatus status) {
    switch (status) {
      case AIChatStatus.ready:
        return Icons.check_circle;
      case AIChatStatus.processing:
        return Icons.hourglass_empty;
      case AIChatStatus.notAvailable:
        return Icons.cancel;
      case AIChatStatus.error:
        return Icons.error;
    }
  }

  String _getStatusText(AIChatStatus status) {
    switch (status) {
      case AIChatStatus.ready:
        return 'Foundation Models Ready - AI Chat Available';
      case AIChatStatus.processing:
        return 'Processing your message...';
      case AIChatStatus.notAvailable:
        return 'Foundation Models Not Available - Using Fallback';
      case AIChatStatus.error:
        return 'Error - Check iOS version and Apple Intelligence settings';
    }
  }
}
