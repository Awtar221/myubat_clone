import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../core/firestore/firestore_fields.dart' as fields;
import '../data/models/app_user.dart';
import '../data/repositories/user_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userRepository = UserRepository();
  
  // Model
  AppUser? _user;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;

  String _selectedGender = 'Male';
  bool _isSaving = false;
  bool _isLoading = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _addressController = TextEditingController();
    _bloodTypeController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _allergiesController = TextEditingController();
    _conditionsController = TextEditingController();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profile = await _userRepository.getUserProfile(user.uid);
    if (profile != null && mounted) {
      setState(() {
        _user = profile;
        _nameController.text = _user!.displayName;
        
        final personal = _user!.personal ?? {};
        _phoneController.text = personal[fields.phoneNumber] ?? '';
        _addressController.text = personal[fields.address] ?? '';
        _selectedGender = personal[fields.gender] ?? 'Male';
        
        if (personal[fields.dateOfBirth] != null) {
          _selectedDate = (personal[fields.dateOfBirth] as Timestamp).toDate();
          _dobController.text = _formatDate(_selectedDate!);
        }

        final health = _user!.health ?? {};
        _bloodTypeController.text = health[fields.bloodType] ?? '';
        _weightController.text = (health[fields.weightKg] ?? '').toString();
        _heightController.text = (health[fields.heightCm] ?? '').toString();
        _allergiesController.text = health[fields.allergies] ?? '';
        _conditionsController.text = health[fields.medicalConditions] ?? '';
        
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _bloodTypeController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    setState(() => _isSaving = true);

    try {
      // Use the AppUser model to bundle updates
      final updatedUser = AppUser(
        uid: _user!.uid,
        email: _user!.email,
        displayName: _nameController.text.trim(),
        profileCompleted: true,
        personal: {
          fields.fullName: _nameController.text.trim(),
          fields.phoneNumber: _phoneController.text.trim(),
          fields.address: _addressController.text.trim(),
          fields.gender: _selectedGender,
          fields.dateOfBirth: _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        },
        health: {
          fields.bloodType: _bloodTypeController.text.trim(),
          fields.weightKg: int.tryParse(_weightController.text),
          fields.heightCm: int.tryParse(_heightController.text),
          fields.allergies: _allergiesController.text.trim(),
          fields.medicalConditions: _conditionsController.text.trim(),
        },
        emergency: _user!.emergency,
        photoURL: _user!.photoURL,
      );

      await _userRepository.updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Personal Information'),
            _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Enter name' : null),
            _buildTextField(controller: TextEditingController(text: _user?.email), label: 'Email', icon: Icons.email_outlined, readOnly: true),
            _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            _buildTextField(
              controller: _dobController,
              label: 'Date of Birth',
              icon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context, 
                  initialDate: _selectedDate ?? DateTime(1990), 
                  firstDate: DateTime(1900), 
                  lastDate: DateTime.now()
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _dobController.text = _formatDate(date);
                  });
                }
              },
            ),
            _buildGenderDropdown(),
            _buildTextField(controller: _addressController, label: 'Address', icon: Icons.location_on_outlined, maxLines: 2),
            const SizedBox(height: 20),
            _buildSectionHeader('Health Information'),
            _buildTextField(controller: _bloodTypeController, label: 'Blood Type', icon: Icons.bloodtype_outlined),
            Row(
              children: [
                Expanded(child: _buildTextField(controller: _weightController, label: 'Weight (kg)', icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(controller: _heightController, label: 'Height (cm)', icon: Icons.height_outlined, keyboardType: TextInputType.number)),
              ],
            ),
            _buildTextField(controller: _allergiesController, label: 'Allergies', icon: Icons.warning_amber_outlined, maxLines: 2),
            _buildTextField(controller: _conditionsController, label: 'Medical Conditions', icon: Icons.medical_information_outlined, maxLines: 2),
            const SizedBox(height: 30),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor)));
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, bool readOnly = false, int maxLines = 1, VoidCallback? onTap, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedGender,
        decoration: InputDecoration(labelText: 'Gender', prefixIcon: const Icon(Icons.wc_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        items: ['Male', 'Female', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => _selectedGender = v!),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
