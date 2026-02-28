import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../core/firestore/firestore_fields.dart' as fields;
import '../data/models/user_settings.dart';
import '../data/repositories/settings_repository.dart';
import '../services/notification/notification_service.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepository _settingsRepository = SettingsRepository();

  String _language = 'en';

  String _languageLabel(String code) {
    switch (code) {
      case 'zh':
        return 'Chinese';
      case 'ms':
        return 'Bahasa Melayu';
      default:
        return 'English';
    }
  }

  Future<void> _saveSetting(String uid, Map<String, dynamic> partial) async {
    try {
      await _settingsRepository.updateSettings(uid, partial);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to save settings'),
            backgroundColor: AppColors.error),
      );
    }
  }

  void _showLanguageDialog(String uid, String currentLanguage) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Language'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageOption('English', 'en', currentLanguage, (v) {
                    Navigator.pop(context);
                    setState(() => _language = v);
                    _saveSetting(uid, {fields.language: v});
                  }),
                  _buildLanguageOption('Bahasa Melayu', 'ms', currentLanguage,
                      (v) {
                    Navigator.pop(context);
                    setState(() => _language = v);
                    _saveSetting(uid, {fields.language: v});
                  }),
                  _buildLanguageOption('Chinese', 'zh', currentLanguage, (v) {
                    Navigator.pop(context);
                    setState(() => _language = v);
                    _saveSetting(uid, {fields.language: v});
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageOption(
      String label, String value, String current, Function(String) onSelect) {
    final isSelected = value == current;
    return ListTile(
      title: Text(label),
      onTap: () => onSelect(value),
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? AppColors.primaryColor : Colors.grey,
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'MyUbat',
      applicationVersion: '1.0.0',
      applicationIcon:
          const Icon(Icons.local_hospital, color: AppColors.primaryColor),
      children: [const Text('MyUbat is your health companion.')],
    );
  }

  Future<void> _scheduleDebugReminder() async {
    try {
      await NotificationService.instance.scheduleDebugReminderExact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug reminder scheduled for 1 minute later.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _scheduleScaledReminders() async {
    try {
      await NotificationService.instance
          .scheduleScaledDebugAppointmentReminders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled 3 scaled reminders: 10s, 20s, 30s'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: StreamBuilder<UserSettings>(
        stream: _settingsRepository.getSettingsStream(uid),
        builder: (context, snapshot) {
          final settings = snapshot.data;
          final language = settings?.language ?? _language;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Account'),
              _buildSettingTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Update info',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EditProfileScreen()));
                  }),
              _buildSettingTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Secure your account',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ChangePasswordScreen()));
                  }),
              const Divider(),
              _buildSectionHeader('Appearance'),
              _buildSettingTile(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: _languageLabel(language),
                  onTap: () => _showLanguageDialog(uid, language)),
              const Divider(),
              _buildSectionHeader('About'),
              _buildSettingTile(
                  icon: Icons.info_outline,
                  title: 'About MyUbat',
                  subtitle: 'Version 1.0.0',
                  onTap: _showAboutDialog),
              if (kDebugMode) ...[
                const Divider(),
                _buildSectionHeader('Developer'),
                _buildSettingTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Test Reminder (1 min)',
                  subtitle: 'Schedules one local notification',
                  onTap: _scheduleDebugReminder,
                ),
                _buildSettingTile(
                  icon: Icons.timer_outlined,
                  title: 'Test 3 reminders (10/20/30s)',
                  subtitle: 'Requires DEBUG_REMINDER_SCALE=true',
                  onTap: _scheduleScaledReminders,
                ),
              ],
              const Divider(),
              _buildSettingTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out from your account',
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor)),
    );
  }

  Widget _buildSettingTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      VoidCallback? onTap,
      Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
