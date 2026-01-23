import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(userProvider),
            const SizedBox(height: 16),
            _buildPersonalInfo(userProvider),
            const SizedBox(height: 16),
            _buildMenuSection(),
            const SizedBox(height: 16),
            _buildSupportSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProvider userProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:1.0),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Text(
                userProvider.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userProvider.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userProvider.icNumber,
            style: TextStyle(
              color: Colors.white.withValues(alpha:9.0),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: userProvider.healthStatusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userProvider.healthStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(UserProvider userProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.phone, 'Phone Number', userProvider.phoneNumber),
          const Divider(height: 24),
          _buildInfoRow(Icons.email, 'Email', userProvider.email),
          const Divider(height: 24),
          _buildInfoRow(Icons.location_on, 'Address', userProvider.address),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withValues(alpha:1.0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            Icons.edit,
            'Edit Profile',
            'Update your personal information',
                () {},
          ),
          const Divider(height: 1),
          _buildMenuItem(
            Icons.lock,
            'Privacy & Security',
            'Manage your privacy settings',
                () {},
          ),
          const Divider(height: 1),
          _buildMenuItem(
            Icons.notifications,
            'Notifications',
            'Manage notification preferences',
                () {},
          ),
          const Divider(height: 1),
          _buildMenuItem(
            Icons.language,
            'Language',
            'Change app language',
                () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            Icons.help,
            'Help & Support',
            'FAQs and customer support',
                () {},
          ),
          const Divider(height: 1),
          _buildMenuItem(
            Icons.info,
            'About MySejahtera',
            'App version and information',
                () {},
          ),
          const Divider(height: 1),
          _buildMenuItem(
            Icons.description,
            'Terms & Conditions',
            'Read our terms of service',
                () {},
          ),
          const Divider(height: 1),
          _buildMenuItem(
            Icons.policy,
            'Privacy Policy',
            'How we handle your data',
                () {},
          ),
          const Divider(height: 1),
          _buildMenuItem(
            Icons.logout,
            'Logout',
            'Sign out of your account',
                () {},
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withValues(alpha:1.0)
                    : const Color(0xFF1E3A8A).withValues(alpha:1.0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF1E3A8A),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}