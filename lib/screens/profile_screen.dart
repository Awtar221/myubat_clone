import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../data/models/app_user.dart';
import '../data/repositories/user_repository.dart';
import '../l10n/app_strings.dart';
import '../services/account/account_service.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        return;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
    });
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final strings = context.strings;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.text('logoutQuestion')),
        content: Text(strings.text('logoutDescription')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.text('logout')),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) {
      return;
    }
    await _handleLogout(context);
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AccountService().signOut();
      if (!context.mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      });
    } catch (e) {
      _showSnackBar(context, '${context.strings.text('unableToLogout')} $e');
    }
  }

  String _displayOrDash(dynamic value) {
    if (value == null) {
      return '-';
    }
    if (value is Timestamp) {
      final date = value.toDate();
      final year = date.year.toString().padLeft(4, '0');
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '$year-$month-$day';
    }
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Text(strings.text('pleaseSignInProfile')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<AppUser>(
        stream: UserRepository().userProfileStream(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(strings.text('unableLoadProfile')));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return Center(child: Text(strings.text('profileNotFound')));
          }

          final personal = user.personal ?? const <String, dynamic>{};
          final health = user.health ?? const <String, dynamic>{};
          final emergency = user.emergency ?? const <String, dynamic>{};
          final displayName = user.displayName.trim().isNotEmpty
              ? user.displayName.trim()
              : 'User';
          final email = user.email.trim().isNotEmpty ? user.email.trim() : '-';

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(strings.text('personalInformation')),
                      _buildInfoTile(
                        icon: Icons.badge_outlined,
                        title: strings.text('fullName'),
                        value: _displayOrDash(personal['fullName']),
                      ),
                      _buildInfoTile(
                        icon: Icons.calendar_today_outlined,
                        title: strings.text('dateOfBirth'),
                        value: _displayOrDash(personal['dateOfBirth']),
                      ),
                      _buildInfoTile(
                        icon: Icons.wc_outlined,
                        title: strings.text('gender'),
                        value: personal['gender'] == null
                            ? _displayOrDash(null)
                            : strings.genderLabel(
                                personal['gender'].toString(),
                              ),
                      ),
                      _buildInfoTile(
                        icon: Icons.phone_outlined,
                        title: strings.text('phoneNumber'),
                        value: _displayOrDash(personal['phoneNumber']),
                      ),
                      _buildInfoTile(
                        icon: Icons.location_on_outlined,
                        title: strings.text('address'),
                        value: _displayOrDash(personal['address']),
                      ),
                      _buildSectionTitle(strings.text('healthInformation')),
                      _buildInfoTile(
                        icon: Icons.bloodtype_outlined,
                        title: strings.text('bloodType'),
                        value: _displayOrDash(health['bloodType']),
                      ),
                      _buildInfoTile(
                        icon: Icons.height_outlined,
                        title: strings.text('height'),
                        value: '${_displayOrDash(health['heightCm'])} cm',
                      ),
                      _buildInfoTile(
                        icon: Icons.monitor_weight_outlined,
                        title: strings.text('weight'),
                        value: '${_displayOrDash(health['weightKg'])} kg',
                      ),
                      _buildInfoTile(
                        icon: Icons.warning_amber_outlined,
                        title: strings.text('allergies'),
                        value: _displayOrDash(health['allergies']),
                      ),
                      _buildInfoTile(
                        icon: Icons.medical_information_outlined,
                        title: strings.text('medicalConditions'),
                        value: _displayOrDash(health['medicalConditions']),
                      ),
                      _buildSectionTitle(strings.text('emergencyContact')),
                      _buildInfoTile(
                        icon: Icons.person_outline,
                        title: strings.text('contactName'),
                        value: _displayOrDash(emergency['contactName']),
                      ),
                      _buildInfoTile(
                        icon: Icons.phone_in_talk_outlined,
                        title: strings.text('contactNumber'),
                        value: _displayOrDash(emergency['contactNumber']),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: Text(strings.text('editProfile')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context),
                          icon: const Icon(Icons.logout),
                          label: Text(strings.text('logout')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            side: const BorderSide(
                              color: AppColors.primaryColor,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom +
                            kBottomNavigationBarHeight +
                            24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
