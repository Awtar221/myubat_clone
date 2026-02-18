import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/models/appointment.dart';
import '../data/models/app_user.dart';
import '../data/models/today_intake_item.dart';
import '../data/repositories/appointment_repository.dart';
import '../data/repositories/medication_repository.dart';
import '../data/repositories/user_repository.dart';
import '../widgets/feature_card.dart';
import '../widgets/medication_reminder_card.dart';
import '../widgets/quick_stats_card.dart';
import 'chatbot_screen.dart';
import 'hospital_map_screen.dart';
import 'medication_tracker_screen.dart';
import 'appointments_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'profile_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _didRunProfileGate = false;

  final List<Widget> _screens = [
    const HomeContent(),
    const MedicationTrackerScreen(),
    const AppointmentsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runProfileGateFallback();
    });
  }

  Future<void> _runProfileGateFallback() async {
    if (!mounted || _didRunProfileGate) {
      return;
    }
    _didRunProfileGate = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final repository = UserRepository();
    try {
      final profile = await repository.getUserProfile(user.uid);
      if (!mounted) return;

      if (profile?.profileCompleted == true) {
        return;
      }

      final email = (user.email ?? '').trim();
      final fallbackDisplayName = _fallbackDisplayName(
        profile: profile,
        email: email,
      );

      if (profile == null) {
        await repository.createUserProfile(
            user.uid, email, fallbackDisplayName);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(
            initialDisplayName: fallbackDisplayName,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Home profile gate fallback failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  String _fallbackDisplayName({AppUser? profile, required String email}) {
    final profileName = profile?.displayName.trim() ?? '';
    if (profileName.isNotEmpty) {
      return profileName;
    }

    final profileEmail = profile?.email.trim() ?? '';
    final candidateEmail = profileEmail.isNotEmpty ? profileEmail : email;
    if (candidateEmail.isNotEmpty) {
      return candidateEmail.split('@').first;
    }
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(26, 0, 0, 0),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication_outlined),
              activeIcon: Icon(Icons.medication),
              label: 'Medications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final UserRepository _userRepository = UserRepository();
  final MedicationRepository _medicationRepository = MedicationRepository();
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  final Set<String> _pendingIntakeToggles = <String>{};

  late final DateTime _todayStart;
  late final DateTime _todayEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayStart = DateTime(now.year, now.month, now.day);
    _todayEnd = _todayStart.add(const Duration(days: 1));
  }

  Future<void> _manualTouchLastLogin(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[debug] manual touchLastLogin skipped: currentUser is null');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No signed in user.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await UserRepository().touchLastLogin(user.uid);
      debugPrint('[debug] manual touchLastLogin done for uid=${user.uid}');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('manual touchLastLogin done'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, st) {
      debugPrint('[debug] manual touchLastLogin failed: $e');
      debugPrintStack(stackTrace: st);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('manual touchLastLogin failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleIntake(
    String uid,
    TodayIntakeItem item,
  ) async {
    final toggleKey = '${item.medicationId}:${item.intakeId}';
    if (_pendingIntakeToggles.contains(toggleKey)) {
      return;
    }

    setState(() {
      _pendingIntakeToggles.add(toggleKey);
    });

    try {
      await _medicationRepository.toggleIntakeTaken(
        uid,
        item.medicationId,
        item.intakeId,
        !item.taken,
      );
    } catch (e, st) {
      debugPrint('Failed to toggle intake taken state: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update intake status. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pendingIntakeToggles.remove(toggleKey);
        });
      }
    }
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour24 = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $period';
  }

  Widget _buildDynamicWelcomeBlock(String? uid) {
    if (uid == null || uid.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 16,
              color: Color.fromRGBO(255, 255, 255, 0.7),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'User',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
        ],
      );
    }

    return StreamBuilder<AppUser?>(
      stream: _userRepository.userProfileStream(uid),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final email = (data?.email ?? '').trim();
        final displayName = (data?.displayName ?? '').trim();
        final resolvedName = displayName.isNotEmpty
            ? displayName
            : (email.isNotEmpty ? email.split('@').first : 'User');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 16,
                color: Color.fromRGBO(255, 255, 255, 0.7),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              resolvedName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildNextAppointmentCard(String uid) {
    return StreamBuilder<Appointment?>(
      stream: _appointmentRepository.nextUpcomingAppointmentStream(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const QuickStatsCard(
            icon: Icons.calendar_today,
            title: 'Next',
            value: '--',
            subtitle: 'No upcoming appointment',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const QuickStatsCard(
            icon: Icons.calendar_today,
            title: 'Next',
            value: '...',
            subtitle: 'Loading',
          );
        }

        final appointment = snapshot.data;
        if (appointment == null) {
          return const QuickStatsCard(
            icon: Icons.calendar_today,
            title: 'Next',
            value: '--',
            subtitle: 'No upcoming appointment',
          );
        }

        final summary = (appointment.title.isNotEmpty
                ? appointment.title
                : (appointment.locationName ?? '').trim())
            .trim();

        return QuickStatsCard(
          icon: Icons.calendar_today,
          title: 'Next',
          value: _formatTime(appointment.scheduledAt),
          subtitle: summary.isEmpty ? 'Appointment' : summary,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final todayIntakesStream = uid == null
        ? Stream<List<TodayIntakeItem>>.value(const <TodayIntakeItem>[])
        : _medicationRepository.todayIntakesStream(uid, _todayStart, _todayEnd);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyUbat'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              tooltip: 'Debug touchLastLogin',
              onPressed: () => _manualTouchLastLogin(context),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TodayIntakeItem>>(
        stream: todayIntakesStream,
        builder: (context, intakeSnapshot) {
          final intakes = intakeSnapshot.data ?? const <TodayIntakeItem>[];
          final totalIntakes = intakes.length;
          final takenIntakes = intakes.where((item) => item.taken).length;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDynamicWelcomeBlock(uid),
                          Row(
                            children: [
                              Expanded(
                                child: QuickStatsCard(
                                  icon: Icons.medication,
                                  title: 'Today',
                                  value: '$takenIntakes/$totalIntakes',
                                  subtitle: 'Taken',
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: uid == null
                                    ? const QuickStatsCard(
                                        icon: Icons.calendar_today,
                                        title: 'Next',
                                        value: '--',
                                        subtitle: 'No upcoming appointment',
                                      )
                                    : _buildNextAppointmentCard(uid),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: FeatureCard(
                              icon: Icons.chat_bubble_outline,
                              title: 'AI Assistant',
                              subtitle: 'Chat with AI',
                              color: AppColors.chatbotColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChatbotScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: FeatureCard(
                              icon: Icons.location_on_outlined,
                              title: 'Find Hospital',
                              subtitle: 'Nearest to you',
                              color: AppColors.mapColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HospitalMapScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: FeatureCard(
                              icon: Icons.medical_services_outlined,
                              title: 'My Medications',
                              subtitle: 'Track dosage',
                              color: AppColors.medicationColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const MedicationTrackerScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: FeatureCard(
                              icon: Icons.event_note_outlined,
                              title: 'Appointments',
                              subtitle: 'Schedule visit',
                              color: AppColors.appointmentColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AppointmentsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Today\'s Medications',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MedicationTrackerScreen(),
                                ),
                              );
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (intakeSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          intakes.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (intakes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No medications for today.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ...intakes.map((item) {
                          final toggleKey =
                              '${item.medicationId}:${item.intakeId}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: MedicationReminderCard(
                              medicationName: item.medicationName,
                              time: _formatTime(item.scheduledAt),
                              dosage: item.dosageText,
                              isTaken: item.taken,
                              isUpdating:
                                  _pendingIntakeToggles.contains(toggleKey),
                              onToggle: uid == null
                                  ? null
                                  : () => _toggleIntake(uid, item),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          );
        },
        backgroundColor: AppColors.chatbotColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat),
        label: const Text('Ask AI'),
      ),
    );
  }
}
