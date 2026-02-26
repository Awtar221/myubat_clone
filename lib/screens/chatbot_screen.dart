import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../constants/app_colors.dart';
import '../data/models/chat_message.dart';
import '../data/models/medication.dart';
import '../data/models/appointment.dart';
import '../data/models/app_user.dart';
import '../data/models/hospital.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/medication_repository.dart';
import '../data/repositories/appointment_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/ai/gemini_service.dart';
import '../services/hospital_service.dart';
import '../widgets/chat_message_bubble.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const String _defaultThreadId = 'default';
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ChatRepository _chatRepository = ChatRepository();
  final UserRepository _userRepository = UserRepository();
  final MedicationRepository _medicationRepository = MedicationRepository();
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final HospitalService _hospitalService = HospitalService();
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();
  
  // Voice Input
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isTyping = false;

  bool _isGeneratingResponse = false;
  List<ChatMessage> _latestMessages = const <ChatMessage>[];
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _ensureDefaultThread();
    _initSpeech();
    
    _messageFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {
        _isTyping = _messageFocusNode.hasFocus;
      });
    });
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize();
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _isTyping = true;
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _messageController.text = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
        if (!_messageFocusNode.hasFocus) _isTyping = false;
      });
      _speech.stop();
    }
  }

  Future<void> _ensureDefaultThread() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _chatRepository.ensureThread(uid, _defaultThreadId, title: 'Health Assistant', model: 'gemini-1.5-flash');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _sendMessage({String? overrideContent}) async {
    final content = (overrideContent ?? _messageController.text).trim();
    if (content.isEmpty && _selectedImageBytes == null) return;
    if (_isGeneratingResponse) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final imageToUpload = _selectedImageBytes;
    _messageController.clear();
    _messageFocusNode.unfocus();
    
    setState(() {
      _isGeneratingResponse = true;
      _selectedImageBytes = null;
      _isListening = false;
      _isTyping = false;
    });
    _speech.stop();

    final userMessage = ChatMessage(
      role: 'user',
      content: content.isEmpty ? 'Analysing attached image...' : content,
      createdAt: Timestamp.now(),
      imageBase64: imageToUpload != null ? base64Encode(imageToUpload) : null,
    );

    try {
      await _chatRepository.addMessage(uid, _defaultThreadId, userMessage);
      
      final userContext = await _buildUserContext(uid);
      final assistantText = await _geminiService.generateReply(
        userText: content.isEmpty ? 'Please analyze this image for any health concerns.' : content,
        userContext: userContext,
        recentMessages: _latestMessages,
        imageBytes: imageToUpload,
      );

      await _chatRepository.addMessage(
        uid,
        _defaultThreadId,
        ChatMessage(role: 'assistant', content: assistantText, createdAt: Timestamp.now()),
      );
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingResponse = false);
    }
  }

  Future<String> _buildUserContext(String uid) async {
    final AppUser? profile = await _userRepository.getUserProfile(uid);
    final List<Medication> medications = await _medicationRepository.listMedicationsOnce(uid);
    final List<Appointment> appointments = await _appointmentRepository.listAppointmentsOnce(uid);
    
    String hospitalContext = 'Nearby Hospitals: Unable to get location';
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      final List<Hospital> hospitals = await _hospitalService.getNearestHospitals(LatLng(position.latitude, position.longitude));
      if (hospitals.isNotEmpty) {
        hospitalContext = 'Nearby Hospitals:\n${hospitals.map((h) {
          return '- ${h.name} (${h.distance.toStringAsFixed(1)}km) - Busyness: ${h.busyness} - Type: ${h.type}';
        }).join('\n')}';
      }
    } catch (e) {
      debugPrint('Location error for chatbot: $e');
    }

    final activeMeds = medications.where((m) => m.isActive).map((m) {
      return '${m.name} (${m.dosageText ?? 'no dose'}) - ${m.scheduleTimes.join(', ')}';
    }).join(', ');

    final upcomingAppts = appointments.where((a) => a.startAt.toDate().isAfter(DateTime.now())).map((a) {
      return '${a.title} at ${_formatTimestamp(a.startAt)} (${a.locationText ?? 'No location'})';
    }).join(', ');

    return 'User: ${profile?.displayName ?? 'User'}\n'
           'Active Medications: ${activeMeds.isEmpty ? 'None' : activeMeds}\n'
           'Upcoming Appointments: ${upcomingAppts.isEmpty ? 'None' : upcomingAppts}\n'
           '$hospitalContext';
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Widget _buildSuggestionChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: _isGeneratingResponse ? null : () => _sendMessage(overrideContent: label),
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: AppColors.chatbotColor, width: 1),
        labelStyle: const TextStyle(color: AppColors.chatbotColor, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('AI Health Assistant'),
        backgroundColor: AppColors.chatbotColor,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            color: Colors.transparent,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSuggestionChip('Nearest hospital'),
                  _buildSuggestionChip('Appointment status'),
                  _buildSuggestionChip('Medication info'),
                  _buildSuggestionChip('Analyze symptoms'),
                ],
              ),
            ),
          ),
          Expanded(
            child: uid == null
                ? const Center(child: Text('Please sign in'))
                : StreamBuilder<List<ChatMessage>>(
                    stream: _chatRepository.streamMessages(uid: uid, threadId: _defaultThreadId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final messages = snapshot.data!;
                      _latestMessages = messages;
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return ChatMessageBubble(
                            key: ValueKey(msg.createdAt.nanoseconds),
                            text: msg.content,
                            isUser: msg.role == 'user',
                            timestamp: _formatTimestamp(msg.createdAt),
                            imageBase64: msg.imageBase64,
                          );
                        },
                      );
                    },
                  ),
          ),
          if (_selectedImageBytes != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_selectedImageBytes!, height: 60, width: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  const Text('Image attached', style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedImageBytes = null)),
                ],
              ),
            ),
          if (_isGeneratingResponse) const LinearProgressIndicator(minHeight: 2, color: AppColors.chatbotColor),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!_isTyping) ...[
              IconButton(icon: const Icon(Icons.photo_library, color: AppColors.chatbotColor), onPressed: _pickImage),
              IconButton(icon: const Icon(Icons.camera_alt, color: AppColors.chatbotColor), onPressed: _takePhoto),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                decoration: InputDecoration(
                  hintText: _isListening ? 'Listening...' : 'Ask about health...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  fillColor: _isListening ? AppColors.primaryColor.withValues(alpha: 0.05) : Colors.grey[100],
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _toggleListening,
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none, 
                color: _isListening ? Colors.red : AppColors.chatbotColor),
            ),
            IconButton(
              onPressed: _isGeneratingResponse ? null : _sendMessage,
              icon: Icon(Icons.send, color: _isGeneratingResponse ? Colors.grey : AppColors.chatbotColor),
            ),
          ],
        ),
      ),
    );
  }
}
