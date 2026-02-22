import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/models/app_user.dart';
import '../data/repositories/user_repository.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _displayOrDash(dynamic value) {
    if (value == null) {
      return '-';
    }
    if (value is Timestamp) {
      final d = value.toDate();
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view profile.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
            return const Center(child: Text('Unable to load profile.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Profile not found.'));
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
                      _buildSectionTitle('Personal Information'),
                      _buildInfoTile(
                        icon: Icons.badge_outlined,
                        title: 'Full Name',
                        value: _displayOrDash(personal['fullName']),
                      ),
                      _buildInfoTile(
                        icon: Icons.calendar_today_outlined,
                        title: 'Date of Birth',
                        value: _displayOrDash(personal['dateOfBirth']),
                      ),
                      _buildInfoTile(
                        icon: Icons.wc_outlined,
                        title: 'Gender',
                        value: _displayOrDash(personal['gender']),
                      ),
                      _buildInfoTile(
                        icon: Icons.phone_outlined,
                        title: 'Phone Number',
                        value: _displayOrDash(personal['phoneNumber']),
                      ),
                      _buildInfoTile(
                        icon: Icons.location_on_outlined,
                        title: 'Address',
                        value: _displayOrDash(personal['address']),
                      ),
                      _buildSectionTitle('Health Information'),
                      _buildInfoTile(
                        icon: Icons.bloodtype_outlined,
                        title: 'Blood Type',
                        value: _displayOrDash(health['bloodType']),
                      ),
                      _buildInfoTile(
                        icon: Icons.height_outlined,
                        title: 'Height',
                        value: '${_displayOrDash(health['heightCm'])} cm',
                      ),
                      _buildInfoTile(
                        icon: Icons.monitor_weight_outlined,
                        title: 'Weight',
                        value: '${_displayOrDash(health['weightKg'])} kg',
                      ),
                      _buildInfoTile(
                        icon: Icons.warning_amber_outlined,
                        title: 'Allergies',
                        value: _displayOrDash(health['allergies']),
                      ),
                      _buildInfoTile(
                        icon: Icons.medical_information_outlined,
                        title: 'Medical Conditions',
                        value: _displayOrDash(health['medicalConditions']),
                      ),
                      _buildSectionTitle('Emergency Contact'),
                      _buildInfoTile(
                        icon: Icons.person_outline,
                        title: 'Contact Name',
                        value: _displayOrDash(emergency['contactName']),
                      ),
                      _buildInfoTile(
                        icon: Icons.phone_in_talk_outlined,
                        title: 'Contact Number',
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
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
