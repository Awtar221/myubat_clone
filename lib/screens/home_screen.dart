import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/models/appointment.dart';
import '../data/models/app_user.dart';
import '../data/models/today_intake_item.dart';
import '../data/repositories/appointment_repository.dart';
import '../data/repositories/medication_repository.dart';
import '../data/repositories/user_repository.dart';
import '../widgets/feature_card.dart';
import '../widgets/quick_stats_card.dart';
import 'chatbot_screen.dart';
import 'hospital_map_screen.dart';
import 'medication_tracker_screen.dart';
import 'appointments_screen.dart';
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeContent(onNavigateToTab: _onItemTapped),
      const MedicationTrackerScreen(),
      const AppointmentsScreen(),
      const ProfileScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runProfileGateFallback();
    });
  }

  Future<void> _runProfileGateFallback() async {
    if (!mounted || _didRunProfileGate) return;
    _didRunProfileGate = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final repository = UserRepository();
    try {
      final profile = await repository.getUserProfile(user.uid);
      if (!mounted) return;

      if (profile?.profileCompleted == true) return;

      final email = (user.email ?? '').trim();
      final fallbackDisplayName =
          (profile?.displayName.trim().isNotEmpty ?? false)
              ? profile!.displayName
              : (email.isNotEmpty ? email.split('@').first : 'User');

      if (profile == null) {
        await repository.createUserProfile(
            user.uid, email, fallbackDisplayName);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              ProfileSetupScreen(initialDisplayName: fallbackDisplayName),
        ),
      );
    } catch (e) {
      debugPrint('Home profile gate failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.medication_outlined),
                activeIcon: Icon(Icons.medication),
                label: 'Meds'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Schedule'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final Function(int) onNavigateToTab;
  const HomeContent({super.key, required this.onNavigateToTab});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final UserRepository _userRepository = UserRepository();
  final MedicationRepository _medicationRepository = MedicationRepository();
  final AppointmentRepository _appointmentRepository = AppointmentRepository();

  late final DateTime _todayStart;
  late final DateTime _todayEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayStart = DateTime(now.year, now.month, now.day);
    _todayEnd = _todayStart.add(const Duration(days: 1));
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(uid),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onNavigateToTab(1), // Meds tab
                        child: _buildAdherenceCard(uid),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onNavigateToTab(2), // Schedule tab
                        child: _buildNextApptCard(uid),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildGridActions(),
                const SizedBox(height: 30),
                const Text('Today\'s Appointments',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        _buildTodayAppointmentsSliver(uid),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _buildWelcomeHeader(String? uid) {
    if (uid == null) {
      return const Text('Welcome back!',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold));
    }
    return StreamBuilder<AppUser?>(
      stream: _userRepository.userProfileStream(uid),
      builder: (context, snapshot) {
        final name = snapshot.data?.displayName ?? 'User';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back,',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
          ],
        );
      },
    );
  }

  Widget _buildAdherenceCard(String? uid) {
    if (uid == null) {
      return const QuickStatsCard(
          icon: Icons.medication,
          title: 'Adherence',
          value: '-',
          subtitle: 'Sign in');
    }
    return StreamBuilder<List<TodayIntakeItem>>(
      stream:
          _medicationRepository.todayIntakesStream(uid, _todayStart, _todayEnd),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        final taken = list.where((i) => i.taken).length;
        return QuickStatsCard(
            icon: Icons.medication,
            title: 'Adherence',
            value: '$taken/${list.length}',
            subtitle: 'View Meds');
      },
    );
  }

  Widget _buildNextApptCard(String? uid) {
    if (uid == null) {
      return const QuickStatsCard(
          icon: Icons.calendar_today,
          title: 'Next Appt',
          value: '-',
          subtitle: 'Sign in');
    }
    return StreamBuilder<Appointment?>(
      stream: _appointmentRepository.nextUpcomingAppointmentStream(uid),
      builder: (context, snapshot) {
        final appt = snapshot.data;
        return QuickStatsCard(
            icon: Icons.calendar_today,
            title: 'Next Appt',
            value: appt != null ? _formatTime(appt.scheduledAt) : '--:--',
            subtitle: appt != null ? 'View Schedule' : 'No Appts');
      },
    );
  }

  Widget _buildGridActions() {
    return Row(
      children: [
        Expanded(
            child: FeatureCard(
          icon: Icons.smart_toy_outlined,
          title: 'AI Assist',
          subtitle: 'Medical Bot',
          color: AppColors.chatbotColor,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen())),
        )),
        const SizedBox(width: 15),
        Expanded(
            child: FeatureCard(
          icon: Icons.map_outlined,
          title: 'Hospitals',
          subtitle: 'Find Nearest',
          color: AppColors.mapColor,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HospitalMapScreen())),
        )),
      ],
    );
  }

  Widget _buildTodayAppointmentsSliver(String? uid) {
    if (uid == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return StreamBuilder<List<Appointment>>(
      stream: _appointmentRepository.listAppointmentsStream(uid),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final todayAppts = (snapshot.data ?? [])
            .where((a) =>
                a.scheduledAt.toDate().isAfter(startOfDay) &&
                a.scheduledAt.toDate().isBefore(endOfDay))
            .toList();

        if (todayAppts.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('No appointments scheduled for today.',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final appt = todayAppts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color:
                              AppColors.appointmentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.event,
                          color: AppColors.appointmentColor),
                    ),
                    title: Text(appt.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(
                        '${_formatTime(appt.scheduledAt)} • ${appt.locationText ?? 'Location not set'}'),
                    onTap: () => widget.onNavigateToTab(2),
                  ),
                );
              },
              childCount: todayAppts.length,
            ),
          ),
        );
      },
    );
  }
}
