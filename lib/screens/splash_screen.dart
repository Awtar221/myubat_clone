import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../data/models/app_user.dart';
import '../data/repositories/user_repository.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _navTimer;
  bool _isChecking = false;
  bool _hasNavigated = false;
  String? _gateError;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _scheduleProfileGateCheck();
  }

  void _scheduleProfileGateCheck() {
    _navTimer?.cancel();
    _navTimer = Timer(const Duration(seconds: 1), _checkAndRoute);
  }

  Future<void> _checkAndRoute() async {
    if (!mounted || _isChecking || _hasNavigated) {
      return;
    }

    setState(() {
      _isChecking = true;
      _gateError = null;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    final repository = UserRepository();

    try {
      final profile = await repository.getUserProfile(currentUser.uid);
      if (profile == null) {
        final email = (currentUser.email ?? '').trim();
        final fallbackDisplayName = _fallbackDisplayName(email);
        await repository.createUserProfile(
          currentUser.uid,
          email,
          fallbackDisplayName,
        );
        _navigateTo(
          ProfileSetupScreen(initialDisplayName: fallbackDisplayName),
        );
        return;
      }

      if (profile.profileCompleted) {
        _navigateTo(const HomeScreen());
      } else {
        _navigateTo(
          ProfileSetupScreen(
            initialDisplayName: _bestEffortDisplayName(profile),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Splash profile gate failed: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        setState(() {
          _gateError = 'Unable to verify profile. Please try again.';
        });
      }
    } finally {
      if (mounted && !_hasNavigated) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  String _fallbackDisplayName(String email) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return 'User';
    }
    return trimmedEmail.split('@').first;
  }

  String _bestEffortDisplayName(AppUser profile) {
    final name = profile.displayName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return _fallbackDisplayName(profile.email);
  }

  void _navigateTo(Widget nextScreen) {
    if (!mounted || _hasNavigated) {
      return;
    }
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 1.0),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    size: 70,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'MyUbat',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Medication Companion',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                if (_gateError != null) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _gateError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isChecking ? null : _checkAndRoute,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
