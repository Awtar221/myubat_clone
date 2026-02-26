import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/navigation/app_navigator.dart';
import 'screens/appointments_screen.dart';
import 'screens/home_screen.dart';
import 'screens/medication_tracker_screen.dart';
import 'screens/splash_screen.dart';
import 'constants/app_colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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

  static State<MyUbatApp>? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyUbatAppState>();

  @override
  State<MyUbatApp> createState() => _MyUbatAppState();
}

class _MyUbatAppState extends State<MyUbatApp> {
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.handleInitialNotificationTap();
    });
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyUbat',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      locale: _locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ms'),
        Locale('zh'),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primaryColor,
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
      ),
      home: const SplashScreen(),
    );
  }
}
