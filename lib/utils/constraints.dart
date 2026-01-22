class AppConstants {
  static const String appName = 'MySejahtera';
  static const String version = '1.0.0';
  static const String buildNumber = '1';

  // API Configuration
  static const String baseUrl = 'https://api.mysejahtera.example.com';
  static const String aiEndpoint = '/ai/chat';
  static const String riskEndpoint = '/ai/risk-assessment';

  // Feature Flags
  static const bool enableAIFeatures = true;
  static const bool enableQRScanner = true;
  static const bool enableLocationTracking = true;
  static const bool enablePushNotifications = true;

  // App Settings
  static const int maxCheckInHistory = 50;
  static const int riskAssessmentUpdateInterval = 3600; // seconds
  static const int chatMessageLimit = 100;

  // Vaccine Types
  static const List<String> vaccineTypes = [
    'Pfizer-BioNTech',
    'Sinovac',
    'AstraZeneca',
    'Moderna',
    'CanSino',
  ];

  // Appointment Types
  static const List<String> appointmentTypes = [
    'Vaccination',
    'Booster Shot',
    'Health Checkup',
    'COVID-19 Test',
    'Consultation',
  ];

  // Risk Levels
  static const Map<String, String> riskLevels = {
    'low': 'Low Risk',
    'medium': 'Medium Risk',
    'high': 'High Risk',
  };
}