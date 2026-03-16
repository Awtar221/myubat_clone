import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/app_colors.dart';
import 'core/navigation/app_navigator.dart';
import 'data/repositories/settings_repository.dart';
import 'firebase_options.dart';
import 'l10n/app_strings.dart';
import 'screens/appointments_screen.dart';
import 'screens/home_screen.dart';
import 'screens/medication_tracker_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.instance.init();
  NotificationService.instance.setTapHandler((type, eventId) async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    switch (type) {
      case NotificationService.typeMedication:
        navigator.push(
          MaterialPageRoute(builder: (_) => const MedicationTrackerScreen()),
        );
        return;
      case NotificationService.typeAppointment:
      case NotificationService.legacyTypeSchedule:
        navigator.push(
          MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
        );
        return;
      default:
        navigator.push(MaterialPageRoute(builder: (_) => const HomeScreen()));
        return;
    }
  });

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyUbatApp());
}

class MyUbatApp extends StatefulWidget {
  const MyUbatApp({super.key});

  static _MyUbatAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyUbatAppState>();

  @override
  State<MyUbatApp> createState() => _MyUbatAppState();
}

class _MyUbatAppState extends State<MyUbatApp> {
  static const String _localePreferenceKey = 'app_locale';

  final SettingsRepository _settingsRepository = SettingsRepository();

  Locale _locale = const Locale('en');
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadPreferredLocale();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
          _syncLocaleForUser,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.handleInitialNotificationTap();
    });
  }

  Future<void> _loadPreferredLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final localeCode = preferences.getString(_localePreferenceKey);
    if (!mounted || localeCode == null || localeCode.trim().isEmpty) {
      return;
    }

    setState(() {
      _locale = Locale(localeCode);
    });
  }

  Future<void> _syncLocaleForUser(User? user) async {
    if (user == null) {
      return;
    }

    try {
      final settings = await _settingsRepository.getSettingsOnce(user.uid);
      final localeCode = settings?.language;
      if (localeCode == null || localeCode.trim().isEmpty) {
        return;
      }
      await setLocale(Locale(localeCode));
    } catch (e) {
      debugPrint('Unable to sync locale: $e');
    }
  }

  Future<void> setLocale(Locale value) async {
    final localeCode = AppStrings.supportedLocales
            .any((locale) => locale.languageCode == value.languageCode)
        ? value.languageCode
        : 'en';

    if (mounted) {
      setState(() {
        _locale = Locale(localeCode);
      });
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localePreferenceKey, localeCode);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyUbat',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      locale: _locale,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppStrings.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
          error: AppColors.error,
          surface: AppColors.cardBackground,
        ),
        scaffoldBackgroundColor: AppColors.backgroundColor,
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.primaryColor,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
