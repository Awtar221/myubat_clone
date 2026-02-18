import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/models/chat_message.dart';
import '../data/models/medication.dart';
import '../data/repositories/appointment_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/medication_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/ai/gemini_service.dart';
import '../widgets/chat_message_bubble.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const String _defaultThreadId = 'default';
  static const String _mockAssistantReply =
      'This is a placeholder response. In the actual app, I would provide helpful information about your medications, dosages, and health queries.';

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _chatRepository = ChatRepository();
  final UserRepository _userRepository = UserRepository();
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final MedicationRepository _medicationRepository = MedicationRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();
  final GeminiService _geminiService = GeminiService();

  bool _isGeneratingResponse = false;
  List<ChatMessage> _latestMessages = const <ChatMessage>[];

  @override
  void initState() {
    super.initState();
    _ensureDefaultThread();
  }

  Future<void> _ensureDefaultThread() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    try {
      await _chatRepository.ensureThread(
        uid,
        _defaultThreadId,
        title: 'Default Chat',
        model: 'gemini-1.5-flash',
      );
    } catch (e, st) {
      debugPrint('Failed to ensure default chat thread: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour24 = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $period';
  }

  String _formatDateTimeCompact(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  String _displayOrDefault(String? value, {String fallback = '-'}) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  bool _isMedicationForToday(Medication medication, DateTime now) {
    if (!medication.isActive) {
      return false;
    }

    final start = medication.startDate?.toDate();
    final end = medication.endDate?.toDate();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    if (start != null && start.isAfter(dayEnd)) {
      return false;
    }
    if (end != null && end.isBefore(dayStart)) {
      return false;
    }
    return true;
  }

  Future<String> _buildUserContext(String uid) async {
    final now = DateTime.now();

    final profileFuture = _userRepository.getUserProfile(uid);
    final appointmentsFuture = _appointmentRepository.listAppointmentsOnce(uid);
    final medicationsFuture = _medicationRepository.listMedicationsOnce(uid);
    final settingsFuture = _settingsRepository.getSettingsOnce(uid);

    final profile = await profileFuture;
    final appointments = await appointmentsFuture;
    final medications = await medicationsFuture;
    await settingsFuture;

    final displayName = _displayOrDefault(
      profile?.displayName,
      fallback: _displayOrDefault(
        profile?.email.split('@').first,
        fallback: 'User',
      ),
    );
    final email = _displayOrDefault(profile?.email, fallback: '-');

    final upcoming = appointments.where((a) {
      final status = a.status.toLowerCase();
      return a.startAt.toDate().isAfter(now) &&
          status != 'completed' &&
          status != 'cancelled';
    }).toList(growable: false)
      ..sort((a, b) => a.startAt.toDate().compareTo(b.startAt.toDate()));
    final nextThree = upcoming.take(3).toList(growable: false);

    final todaysMedLines = <String>[];
    for (final medication in medications) {
      if (!_isMedicationForToday(medication, now)) {
        continue;
      }
      final dosage = _displayOrDefault(medication.dosage, fallback: '-');
      final times = medication.times.isEmpty
          ? const <String>['anytime']
          : medication.times;
      for (final time in times) {
        todaysMedLines.add(
          '- ${medication.name} at $time dosage $dosage',
        );
        if (todaysMedLines.length >= 5) {
          break;
        }
      }
      if (todaysMedLines.length >= 5) {
        break;
      }
    }

    final context = StringBuffer()
      ..writeln('displayName: $displayName')
      ..writeln('email: $email');

    if (nextThree.isEmpty) {
      context.writeln('upcomingAppointments: none');
    } else {
      context.writeln('upcomingAppointments:');
      for (final appt in nextThree) {
        final dateTime = _formatDateTimeCompact(appt.startAt.toDate());
        final title = _displayOrDefault(appt.title, fallback: 'Untitled');
        final location = _displayOrDefault(
          appt.locationText,
          fallback: _displayOrDefault(appt.hospitalName, fallback: '-'),
        );
        context.writeln('- $dateTime | $title | $location');
      }
    }

    if (todaysMedLines.isEmpty) {
      context.writeln('todaysMedications: none');
    } else {
      context.writeln('todaysMedications:');
      for (final line in todaysMedLines) {
        context.writeln(line);
      }
    }

    return context.toString().trimRight();
  }

  Future<void> _sendMessage() async {
    if (_isGeneratingResponse) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final content = _messageController.text.trim();
    if (uid == null || content.isEmpty) {
      return;
    }

    final userMessage = ChatMessage(
      role: 'user',
      content: content,
      createdAt: Timestamp.now(),
    );

    _messageController.clear();
    setState(() {
      _isGeneratingResponse = true;
    });

    try {
      await _chatRepository.addMessage(uid, _defaultThreadId, userMessage);

      final history = <ChatMessage>[
        ..._latestMessages,
        userMessage,
      ];
      final userContext = await _buildUserContext(uid);

      String assistantText;
      try {
        assistantText = await _geminiService.generateReply(
          userText: content,
          userContext: userContext,
          recentMessages: history,
        );
      } catch (e, st) {
        debugPrint('Gemini failed, using fallback: $e');
        debugPrintStack(stackTrace: st);
        assistantText = _mockAssistantReply;
      }

      await _chatRepository.addMessage(
        uid,
        _defaultThreadId,
        ChatMessage(
          role: 'assistant',
          content: assistantText,
          createdAt: Timestamp.now(),
        ),
      );
    } catch (e, st) {
      debugPrint('Failed to send chat message: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send message. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingResponse = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(179, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.chatbotColor,
      ),
      body: Column(
        children: [
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
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[100]),
              child: uid == null
                  ? const Center(
                      child: Text(
                        'Please sign in to start chatting.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : StreamBuilder<List<ChatMessage>>(
                      stream: _chatRepository.streamMessages(
                        uid: uid,
                        threadId: _defaultThreadId,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Unable to load messages.',
                              style: TextStyle(color: AppColors.error),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final messages = snapshot.data ?? const <ChatMessage>[];
                        _latestMessages = messages;

                        if (messages.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToBottom();
                          });
                        }

                        if (messages.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Start the conversation. Messages are stored in Firestore.',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(15),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return ChatMessageBubble(
                              text: message.content,
                              isUser: message.role == 'user',
                              timestamp: _formatTimestamp(message.createdAt),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
          if (_isGeneratingResponse)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Generating reply...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(13, 0, 0, 0),
                  blurRadius: 10,
                  offset: Offset(0, -5),
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
                    onPressed: _isGeneratingResponse ? null : () {},
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isGeneratingResponse,
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
                      icon: _isGeneratingResponse
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send),
                      color: Colors.white,
                      onPressed: _isGeneratingResponse ? null : _sendMessage,
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

  Widget _buildSuggestionChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: _isGeneratingResponse
            ? null
            : () {
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
