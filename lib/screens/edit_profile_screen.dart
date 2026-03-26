import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../core/firestore/firestore_fields.dart' as fields;
import '../data/models/app_user.dart';
import '../data/repositories/user_repository.dart';
import '../l10n/app_strings.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const List<String> _genderOptions = <String>[
    'male',
    'female',
    'other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _userRepository = UserRepository();

  AppUser? _user;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _dobController;
  late final TextEditingController _addressController;
  late final TextEditingController _bloodTypeController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _conditionsController;

  String _selectedGender = 'male';
  bool _isSaving = false;
  bool _isLoading = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
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
    if (user == null) {
      return;
    }

    final profile = await _userRepository.getUserProfile(user.uid);
    if (profile == null || !mounted) {
      return;
    }

    final personal = profile.personal ?? <String, dynamic>{};
    final health = profile.health ?? <String, dynamic>{};

    setState(() {
      _user = profile;
      _nameController.text = profile.displayName;
      _emailController.text = profile.email;
      _phoneController.text = personal[fields.phoneNumber] ?? '';
      _addressController.text = personal[fields.address] ?? '';
      _selectedGender = _normalizeGender(personal[fields.gender]);

      final dateOfBirth = personal[fields.dateOfBirth];
      if (dateOfBirth is Timestamp) {
        _selectedDate = dateOfBirth.toDate();
        _dobController.text = _formatDate(_selectedDate!);
      }

      _bloodTypeController.text = health[fields.bloodType] ?? '';
      _weightController.text = (health[fields.weightKg] ?? '').toString();
      _heightController.text = (health[fields.heightCm] ?? '').toString();
      _allergiesController.text = health[fields.allergies] ?? '';
      _conditionsController.text = health[fields.medicalConditions] ?? '';
      _isLoading = false;
    });
  }

  String _normalizeGender(dynamic value) {
    final gender = value?.toString().trim().toLowerCase() ?? '';
    if (_genderOptions.contains(gender)) {
      return gender;
    }
    return 'male';
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
    if (!_formKey.currentState!.validate() || _user == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
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
          fields.dateOfBirth:
              _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
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

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.strings.text('profileUpdated')),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.strings.text('profileUpdateFailed')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.text('editProfile'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(strings.text('personalInformation')),
            _buildTextField(
              controller: _nameController,
              label: strings.text('fullName'),
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.text('enterName');
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _emailController,
              label: strings.text('email'),
              icon: Icons.email_outlined,
              readOnly: true,
            ),
            _buildTextField(
              controller: _phoneController,
              label: strings.text('phoneNumber'),
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _dobController,
              label: strings.text('dateOfBirth'),
              icon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime(1990),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _dobController.text = _formatDate(date);
                  });
                }
              },
            ),
            _buildGenderDropdown(strings),
            _buildTextField(
              controller: _addressController,
              label: strings.text('address'),
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(strings.text('healthInformation')),
            _buildTextField(
              controller: _bloodTypeController,
              label: strings.text('bloodType'),
              icon: Icons.bloodtype_outlined,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _weightController,
                    label: strings.text('weightKg'),
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _heightController,
                    label: strings.text('heightCm'),
                    icon: Icons.height_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            _buildTextField(
              controller: _allergiesController,
              label: strings.text('allergies'),
              icon: Icons.warning_amber_outlined,
              maxLines: 2,
            ),
            _buildTextField(
              controller: _conditionsController,
              label: strings.text('medicalConditions'),
              icon: Icons.medical_information_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(strings.text('saveChanges')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedGender,
        decoration: InputDecoration(
          labelText: strings.text('gender'),
          prefixIcon: const Icon(Icons.wc_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: _genderOptions
            .map(
              (value) => DropdownMenuItem<String>(
                value: value,
                child: Text(strings.genderLabel(value)),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() => _selectedGender = value);
        },
      ),
    );
  }
}
