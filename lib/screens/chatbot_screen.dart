import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/chat_message_bubble.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedLanguage = 'English'; //will me used in the fucntional model later on

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! I\'m your MyUbat AI Assistant. How can I help you today?',
      'isUser': false,
      'timestamp': '10:30 AM',
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _messageController.text,
        'isUser': true,
        'timestamp': TimeOfDay.now().format(context),
      });
    });

    _messageController.clear();

    // Auto scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Simulate bot response
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add({
          'text': 'This is a placeholder response. In the actual app, I would provide helpful information about your medications, dosages, and health queries.',
          'isUser': false,
          'timestamp': TimeOfDay.now().format(context),
        });
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppColors.chatbotColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Color.fromARGB(179, 255, 255, 255)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: 'Select Language',
            onSelected: (String value) {
              setState(() {
                _selectedLanguage = value;
              });
              _addLanguageChangeMessage(value);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'English',
                child: Row(
                  children: [
                    Text('🇬🇧', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Text('English'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Bahasa Melayu',
                child: Row(
                  children: [
                    Text('🇲🇾', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Text('Bahasa Melayu'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: '中文',
                child: Row(
                  children: [
                    Text('🇨🇳', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Text('中文 (Chinese)'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'தமிழ்',
                child: Row(
                  children: [
                    Text('🇮🇳', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Text('தமிழ் (Tamil)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
        backgroundColor: AppColors.chatbotColor,
      ),
      body: Column(
        children: [
          // Quick Suggestions
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            color: AppColors.lightGreen,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSuggestionChip('Medication info'),
                  _buildSuggestionChip('Side effects'),
                  _buildSuggestionChip('Dosage guide'),
                  _buildSuggestionChip('Interactions'),
                ],
              ),
            ),
          ),

          // Messages List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(15),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatMessageBubble(
                    text: message['text'],
                    isUser: message['isUser'],
                    timestamp: message['timestamp'],
                  );
                },
              ),
            ),
          ),

          // Input Area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(13, 0, 0, 0),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.chatbotColor,
                    onPressed: () {
                      // Show attachment options
                    },
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.chatbotColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      color: Colors.white,
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addLanguageChangeMessage(String language) {
    final greetings = {
      'English': 'Language changed to English. How can I help you?',
      'Bahasa Melayu': 'Bahasa telah ditukar ke Bahasa Melayu. Bagaimana saya boleh membantu anda?',
      '中文': '语言已更改为中文。我能帮您什么？',
      'தமிழ்': 'மொழி தமிழுக்கு மாற்றப்பட்டது. நான் உங்களுக்கு எப்படி உதவ முடியும்?',
    };

    setState(() {
      _messages.add({
        'text': greetings[language] ?? 'Language changed.',
        'isUser': false,
        'timestamp': TimeOfDay.now().format(context),
      });
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildSuggestionChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: () {
          _messageController.text = label;
          _sendMessage();
        },
        backgroundColor: Colors.white,
        labelStyle: const TextStyle(
          color: AppColors.chatbotColor,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}