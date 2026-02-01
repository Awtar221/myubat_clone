import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _medicationReminders = true;
  bool _appointmentReminders = true;
  bool _biometricAuth = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your security credentials',
            onTap: () {},
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

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingTile(
            icon: Icons.notifications_outlined,
            title: 'Enable Notifications',
            subtitle: 'Receive app notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
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
              onChanged: _notificationsEnabled
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
              onChanged: _notificationsEnabled
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

          // Appearance Section
          _buildSectionHeader('Appearance'),
          _buildSettingTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English',
            onTap: _showLanguageDialog,
          ),

          const Divider(height: 30),

          // Privacy & Security
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

          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Get help and support',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.bug_report_outlined,
            title: 'Report a Bug',
            subtitle: 'Help us improve the app',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts with us',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.star_outline,
            title: 'Rate MyUbat',
            subtitle: 'Rate us on the app store',
            onTap: () {},
          ),

          const Divider(height: 30),

          // About Section
          _buildSectionHeader('About'),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: 'About MyUbat',
            subtitle: 'Version 1.0.0',
            onTap: _showAboutDialog,
          ),
          _buildSettingTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            onTap: () {},
          ),
          _buildSettingTile(
            icon: Icons.people_outline,
            title: 'Open Source Licenses',
            subtitle: 'View third-party licenses',
            onTap: () {},
          ),

          const SizedBox(height: 20),

          // Logout Button
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
      ),
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
        child: Icon(
          icon,
          color: AppColors.primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text('English'),
                value: 'en',
                groupValue: 'en',
                onChanged: (value) {
                  Navigator.pop(context);
                },
                activeColor: AppColors.primaryColor,
              ),
              RadioListTile(
                title: const Text('Bahasa Melayu'),
                value: 'ms',
                groupValue: 'en',
                onChanged: (value) {
                  Navigator.pop(context);
                },
                activeColor: AppColors.primaryColor,
              ),
              RadioListTile(
                title: const Text('中文'),
                value: 'zh',
                groupValue: 'en',
                onChanged: (value) {
                  Navigator.pop(context);
                },
                activeColor: AppColors.primaryColor,
              ),
            ],
          ),
        );
      },
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
                'MyUbat is your comprehensive medication tracking and health management companion. Track your medications, schedule appointments, find nearby hospitals, and get AI-powered health assistance.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 15),
              Text(
                '© 2026 Ministry of Health Malaysia',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
              onPressed: () {
                Navigator.pop(context);
                // Handle logout
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}