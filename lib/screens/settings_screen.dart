import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../core/firestore/firestore_fields.dart' as fields;
import '../data/models/user_settings.dart';
import '../data/repositories/settings_repository.dart';
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

  bool _notificationsEnabled = true;
  String _language = 'en';

  bool _medicationReminders = true;
  bool _appointmentReminders = true;
  bool _biometricAuth = false;

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
    } catch (e, st) {
      debugPrint('Failed to update settings: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save settings. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLanguageDialog(String uid, String currentLanguage) {
    String selectedLanguage = currentLanguage;

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
                  _buildLanguageOption('English', 'en', selectedLanguage,
                      (value) {
                    setStateDialog(() {
                      selectedLanguage = value;
                    });
                    Navigator.pop(context);
                    setState(() {
                      _language = value;
                    });
                    _saveSetting(
                        uid, <String, dynamic>{fields.language: value});
                  }),
                  _buildLanguageOption(
                    'Bahasa Melayu',
                    'ms',
                    selectedLanguage,
                    (value) {
                      setStateDialog(() {
                        selectedLanguage = value;
                      });
                      Navigator.pop(context);
                      setState(() {
                        _language = value;
                      });
                      _saveSetting(
                          uid, <String, dynamic>{fields.language: value});
                    },
                  ),
                  _buildLanguageOption('Chinese', 'zh', selectedLanguage,
                      (value) {
                    setStateDialog(() {
                      selectedLanguage = value;
                    });
                    Navigator.pop(context);
                    setState(() {
                      _language = value;
                    });
                    _saveSetting(
                        uid, <String, dynamic>{fields.language: value});
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
    String label,
    String value,
    String currentValue,
    Function(String) onSelect,
  ) {
    final isSelected = currentValue == value;

    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(26, 46, 125, 50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : const Color.fromARGB(51, 0, 0, 0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : const Color.fromARGB(153, 0, 0, 0),
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected ? AppColors.primaryColor : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              const Text('MyUbat'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version 1.0.0'),
              SizedBox(height: 15),
              Text(
                'MyUbat is your comprehensive medication tracking and health management companion.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    final rootNavigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  await FirebaseAuth.instance.signOut();
                  final currentUserAfterSignOut =
                      FirebaseAuth.instance.currentUser;
                  debugPrint(
                    'After signOut currentUser = $currentUserAfterSignOut',
                  );
                  if (currentUserAfterSignOut != null) {
                    throw StateError(
                      'Sign out completed but currentUser is not null.',
                    );
                  }
                } catch (e, st) {
                  debugPrint('Sign out failed: $e');
                  debugPrintStack(stackTrace: st);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Logout failed. Please try again.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                if (!mounted) return;
                rootNavigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primaryColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildSettingsBody({
    required String uid,
    required bool notificationsEnabled,
    required String language,
  }) {
    return ListView(
      children: [
        _buildSectionHeader('Account'),
        _buildSettingTile(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          },
        ),
        _buildSettingTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your security credentials',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            );
          },
        ),
        _buildSettingTile(
          icon: Icons.fingerprint,
          title: 'Biometric Authentication',
          subtitle: 'Use fingerprint or face ID',
          trailing: Switch(
            value: _biometricAuth,
            onChanged: (value) {
              setState(() {
                _biometricAuth = value;
              });
            },
            activeThumbColor: AppColors.primaryColor,
          ),
        ),
        const Divider(height: 30),
        _buildSectionHeader('Notifications'),
        _buildSettingTile(
          icon: Icons.notifications_outlined,
          title: 'Enable Notifications',
          subtitle: 'Receive app notifications',
          trailing: Switch(
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveSetting(uid, <String, dynamic>{
                fields.notificationsEnabled: value,
              });
            },
            activeThumbColor: AppColors.primaryColor,
          ),
        ),
        _buildSettingTile(
          icon: Icons.medication_outlined,
          title: 'Medication Reminders',
          subtitle: 'Alerts for medication schedule',
          trailing: Switch(
            value: _medicationReminders,
            onChanged: notificationsEnabled
                ? (value) {
                    setState(() {
                      _medicationReminders = value;
                    });
                  }
                : null,
            activeThumbColor: AppColors.primaryColor,
          ),
        ),
        _buildSettingTile(
          icon: Icons.event_outlined,
          title: 'Appointment Reminders',
          subtitle: 'Alerts for upcoming appointments',
          trailing: Switch(
            value: _appointmentReminders,
            onChanged: notificationsEnabled
                ? (value) {
                    setState(() {
                      _appointmentReminders = value;
                    });
                  }
                : null,
            activeThumbColor: AppColors.primaryColor,
          ),
        ),
        const Divider(height: 30),
        _buildSectionHeader('Appearance'),
        _buildSettingTile(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: _languageLabel(language),
          onTap: () => _showLanguageDialog(uid, language),
        ),
        const Divider(height: 30),
        _buildSectionHeader('Privacy & Security'),
        _buildSettingTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Read our privacy policy',
          onTap: () {},
        ),
        _buildSettingTile(
          icon: Icons.security_outlined,
          title: 'Data Security',
          subtitle: 'How we protect your data',
          onTap: () {},
        ),
        _buildSettingTile(
          icon: Icons.share_outlined,
          title: 'Data Sharing',
          subtitle: 'Manage data sharing preferences',
          onTap: () {},
        ),
        const Divider(height: 30),
        _buildSectionHeader('About'),
        _buildSettingTile(
          icon: Icons.info_outline,
          title: 'About MyUbat',
          subtitle: 'Version 1.0.0',
          onTap: _showAboutDialog,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('Please sign in to view settings.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: StreamBuilder<UserSettings>(
        stream: _settingsRepository.getSettingsStream(uid),
        builder: (context, snapshot) {
          final remote = snapshot.data;
          final notificationsEnabled =
              remote?.notificationsEnabled ?? _notificationsEnabled;
          final language = remote?.language ?? _language;
          return _buildSettingsBody(
            uid: uid,
            notificationsEnabled: notificationsEnabled,
            language: language,
          );
        },
      ),
    );
  }
}
