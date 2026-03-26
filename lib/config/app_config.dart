class AppConfig {
  static const String _geminiApiKeyName = 'GEMINI_API_KEY';
  static const String _googleMapsApiKeyName = 'GOOGLE_MAPS_API_KEY';

  static const String geminiApiKey =
      String.fromEnvironment(_geminiApiKeyName, defaultValue: '');
  static const String googleMapsApiKey =
      String.fromEnvironment(_googleMapsApiKeyName, defaultValue: '');

  static bool get hasGeminiApiKey => geminiApiKey.trim().isNotEmpty;
  static bool get hasGoogleMapsApiKey => googleMapsApiKey.trim().isNotEmpty;

  static String get missingGeminiApiKeyMessage =>
      'Gemini AI is not configured. Start the app with --dart-define=$_geminiApiKeyName=your_key.';

  static String get missingGoogleMapsApiKeyMessage =>
      'Google Maps is not configured. Start the app with --dart-define=$_googleMapsApiKeyName=your_key.';
}

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}
