import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Stack(
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
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.secondaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Ahmad Abdullah',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'ahmad.abdullah@email.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard('5', 'Medications'),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withValues(alpha:3.0),
                          ),
                          _buildStatCard('3', 'Appointments'),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withValues(alpha:3.0),
                          ),
                          _buildStatCard('92%', 'Adherence'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Personal Information Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoCard(
                    icon: Icons.badge_outlined,
                    title: 'Full Name',
                    value: 'Ahmad bin Abdullah',
                    onTap: () {},
                  ),
                  _buildInfoCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Date of Birth',
                    value: '15 May 1985',
                    onTap: () {},
                  ),
                  _buildInfoCard(
                    icon: Icons.wc_outlined,
                    title: 'Gender',
                    value: 'Male',
                    onTap: () {},
                  ),
                  _buildInfoCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone Number',
                    value: '+60 12-345 6789',
                    onTap: () {},
                  ),
                  _buildInfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    value: 'Kuala Lumpur, Malaysia',
                    onTap: () {},
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Health Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoCard(
                    icon: Icons.bloodtype_outlined,
                    title: 'Blood Type',
                    value: 'O+',
                    onTap: () {},
                  ),
                  _buildInfoCard(
                    icon: Icons.monitor_weight_outlined,
                    title: 'Weight',
                    value: '75 kg',
                    onTap: () {},
                  ),
                  _buildInfoCard(
                    icon: Icons.height_outlined,
                    title: 'Height',
                    value: '175 cm',
                    onTap: () {},
                  ),
                  _buildInfoCard(
                    icon: Icons.warning_amber_outlined,
                    title: 'Allergies',
                    value: 'Penicillin, Peanuts',
                    onTap: () {},
                  ),
                  _buildInfoCard(
                    icon: Icons.medical_information_outlined,
                    title: 'Medical Conditions',
                    value: 'Type 2 Diabetes',
                    onTap: () {},
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Emergency Contact',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoCard(
                    icon: Icons.person_outline,
                    title: 'Contact Name',
                    value: 'Siti Abdullah (Wife)',
                    onTap: () {},
                  ),
                  _buildInfoCard(
                    icon: Icons.phone_outlined,
                    title: 'Contact Number',
                    value: '+60 12-987 6543',
                    onTap: () {},
                  ),

                  const SizedBox(height: 30),

                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to edit profile
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
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
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
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
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
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }
}