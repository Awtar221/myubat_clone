import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../core/firestore/firestore_fields.dart' as fields;
import '../data/models/user_settings.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../services/account/account_service.dart';
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
  final AccountService _accountService = AccountService();

  String _language = 'en';
  bool _isDeletingAccount = false;
  bool _isRoutingToLogin = false;

  void _showSnackBar(String message, {Color color = AppColors.error}) {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
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
            backgroundColor: color,
          ),
        );
    });
  }

  Future<void> _saveSetting(String uid, Map<String, dynamic> partial) async {
    try {
      await _settingsRepository.updateSettings(uid, partial);
    } catch (e) {
      if (mounted) {
        _showSnackBar(context.strings.text('unableToSaveSettings'));
      }
    }
  }

  Future<void> _showLanguageDialog(String uid, String currentLanguage) async {
    final strings = context.strings;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.text('selectLanguage')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                label: strings.languageLabel('en'),
                value: 'en',
                current: currentLanguage,
                onSelect: (value) async {
                  final appState = MedisenseApp.of(context);
                  Navigator.pop(dialogContext);
                  setState(() => _language = value);
                  await _saveSetting(uid, {fields.language: value});
                  await appState?.setLocale(Locale(value));
                },
              ),
              _buildLanguageOption(
                label: strings.languageLabel('ms'),
                value: 'ms',
                current: currentLanguage,
                onSelect: (value) async {
                  final appState = MedisenseApp.of(context);
                  Navigator.pop(dialogContext);
                  setState(() => _language = value);
                  await _saveSetting(uid, {fields.language: value});
                  await appState?.setLocale(Locale(value));
                },
              ),
              _buildLanguageOption(
                label: strings.languageLabel('zh'),
                value: 'zh',
                current: currentLanguage,
                onSelect: (value) async {
                  final appState = MedisenseApp.of(context);
                  Navigator.pop(dialogContext);
                  setState(() => _language = value);
                  await _saveSetting(uid, {fields.language: value});
                  await appState?.setLocale(Locale(value));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required String value,
    required String current,
    required Future<void> Function(String value) onSelect,
  }) {
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

  Future<void> _showAboutSheet() async {
    final strings = context.strings;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: AppColors.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.text('aboutMyUbat'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        strings.text('versionLabel'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                strings.text('aboutHeadline'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.text('aboutDescription'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.text('aboutHighlightsTitle'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildAboutBullet(strings.text('aboutHighlightOne')),
              _buildAboutBullet(strings.text('aboutHighlightTwo')),
              _buildAboutBullet(strings.text('aboutHighlightThree')),
              _buildAboutBullet(strings.text('aboutHighlightFour')),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.text('aboutDisclaimerTitle'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.text('aboutDisclaimerBody'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.text('aboutBuiltFor'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(strings.text('close')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutBullet(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDeleteAccountFlow() async {
    final strings = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.text('deleteAccountPrompt')),
        content: Text(strings.text('deleteAccountDescription')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(strings.text('continue')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final password = await _showPasswordConfirmationDialog();
    if (password == null || !mounted) {
      return;
    }

    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return;
    }
    await _deleteAccount(password);
  }

  Future<String?> _showPasswordConfirmationDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => const _PasswordConfirmationDialog(),
    );
  }

  Future<void> _deleteAccount(String password) async {
    setState(() {
      _isDeletingAccount = true;
    });

    var requestedLoginRoute = false;
    try {
      await _accountService.deleteCurrentAccount(password: password);
      if (!mounted) {
        return;
      }
      setState(() {
        _isRoutingToLogin = true;
      });
      requestedLoginRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      });
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isRoutingToLogin = false;
        });
      }
      final strings = context.strings;
      final message = switch (e.code) {
        'wrong-password' ||
        'invalid-credential' =>
          strings.text('passwordIncorrectDelete'),
        'requires-recent-login' => strings.text('pleaseLoginAgainDelete'),
        _ => e.message ?? strings.text('unableDeleteAccount'),
      };
      _showSnackBar(message);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRoutingToLogin = false;
        });
      }
      _showSnackBar('$e');
    } finally {
      if (mounted && !requestedLoginRoute) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    if (_isRoutingToLogin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(strings.text('pleaseSignIn'))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.text('settings'))),
      body: StreamBuilder<UserSettings>(
        stream: _settingsRepository.getSettingsStream(uid),
        builder: (context, snapshot) {
          final settings = snapshot.data;
          final language = settings?.language ?? _language;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom +
                  kBottomNavigationBarHeight +
                  40,
            ),
            children: [
              _buildSectionHeader(strings.text('account')),
              _buildSettingTile(
                icon: Icons.person_outline,
                title: strings.text('editProfile'),
                subtitle: strings.text('updateInfo'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.lock_outline,
                title: strings.text('changePassword'),
                subtitle: strings.text('secureYourAccount'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildSectionHeader(strings.text('appearance')),
              _buildSettingTile(
                icon: Icons.language_outlined,
                title: strings.text('language'),
                subtitle: strings.languageLabel(language),
                onTap: () => _showLanguageDialog(uid, language),
              ),
              const Divider(),
              _buildSectionHeader(strings.text('about')),
              _buildSettingTile(
                icon: Icons.info_outline,
                title: strings.text('aboutMyUbat'),
                subtitle: strings.text('versionLabel'),
                onTap: _showAboutSheet,
              ),
              const Divider(),
              _buildSectionHeader(strings.text('dangerZone')),
              _buildSettingTile(
                icon: Icons.delete_forever_outlined,
                title: strings.text('deleteAccount'),
                subtitle: _isDeletingAccount
                    ? strings.text('deletingAccount')
                    : strings.text('deleteAccountSubtitle'),
                trailing: _isDeletingAccount
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                onTap: _isDeletingAccount ? null : _startDeleteAccountFlow,
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
      leading: Icon(
        icon,
        color: title == context.strings.text('deleteAccount')
            ? AppColors.error
            : AppColors.primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

class _PasswordConfirmationDialog extends StatefulWidget {
  const _PasswordConfirmationDialog();

  @override
  State<_PasswordConfirmationDialog> createState() =>
      _PasswordConfirmationDialogState();
}

class _PasswordConfirmationDialogState
    extends State<_PasswordConfirmationDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _passwordFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _closeDialog([String? value]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return AlertDialog(
      title: Text(strings.text('confirmPassword')),
      content: TextField(
        controller: _passwordController,
        focusNode: _passwordFocusNode,
        obscureText: _obscureText,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          final value = _passwordController.text.trim();
          if (value.isNotEmpty) {
            _closeDialog(_passwordController.text);
          }
        },
        decoration: InputDecoration(
          labelText: strings.text('password'),
          hintText: strings.text('enterPassword'),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
            icon: Icon(
              _obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _closeDialog,
          child: Text(strings.text('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final value = _passwordController.text.trim();
            if (value.isEmpty) {
              return;
            }
            _closeDialog(_passwordController.text);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: Text(strings.text('delete')),
        ),
      ],
    );
  }
}
