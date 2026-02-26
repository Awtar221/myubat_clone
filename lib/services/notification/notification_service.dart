import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

typedef NotificationTapHandler = Future<void> Function(
  String type,
  String eventId,
);

// ignore: constant_identifier_names
const bool DEBUG_REMINDER_SCALE = bool.fromEnvironment(
  'DEBUG_REMINDER_SCALE',
  defaultValue: false,
);

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.instance._cachePendingPayload(response.payload);
}

class ExactAlarmPermissionException implements Exception {
  const ExactAlarmPermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String typeMedication = 'medication';
  static const String typeAppointment = 'appointment';
  static const String legacyTypeSchedule = 'schedule';

  static const String _channelId = 'myubat_reminders';
  static const String _channelName = 'MyUbat Reminders';
  static const String _channelDescription =
      'Medication and appointment reminder notifications.';
  static const String exactAlarmPermissionHint =
      'Exact alarms are not permitted. Enable "Alarms & reminders" permission in system settings.';

  static const List<Duration> _reminderOffsets = <Duration>[
    Duration(hours: 3),
    Duration(hours: 1),
    Duration(minutes: 30),
  ];
  static const List<Duration> _debugScaledReminderOffsets = <Duration>[
    Duration(seconds: 30),
    Duration(seconds: 20),
    Duration(seconds: 10),
  ];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  NotificationTapHandler? _tapHandler;
  String? _pendingLaunchPayload;

  static bool get isDebugReminderScaleEnabled =>
      kDebugMode && DEBUG_REMINDER_SCALE;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    tzdata.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
          ),
        );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _pendingLaunchPayload = launchDetails?.notificationResponse?.payload;
    }

    _initialized = true;
  }

  void setTapHandler(NotificationTapHandler handler) {
    _tapHandler = handler;
  }

  Future<void> handleInitialNotificationTap() async {
    final payload = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    if (payload == null || payload.isEmpty) {
      return;
    }
    await _dispatchPayload(payload);
  }

  Future<bool> requestPermissionsAndroid() async {
    await init();
    if (!Platform.isAndroid) {
      return true;
    }

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final permissionGranted =
        await androidPlugin?.requestNotificationsPermission();

    if (permissionGranted == null) {
      return true;
    }
    return permissionGranted;
  }

  Future<void> scheduleEventReminders({
    required String eventId,
    required String type,
    required String title,
    required String body,
    required DateTime eventTime,
    required bool enabled,
  }) async {
    await init();
    if (!enabled) {
      return;
    }

    final now = DateTime.now();
    final baseId = _baseNotificationId(eventId: eventId, type: type);
    final payload = jsonEncode(<String, dynamic>{
      'type': type,
      'eventId': eventId,
    });

    final activeOffsets = _activeReminderOffsets();
    for (var i = 0; i < activeOffsets.length; i++) {
      final reminderTime = eventTime.subtract(activeOffsets[i]);
      if (!reminderTime.isAfter(now)) {
        continue;
      }

      final reminderId = baseId + i + 1;
      await _zonedScheduleExact(
        id: reminderId,
        title: title,
        body: body,
        scheduleAt: reminderTime,
        payload: payload,
      );
    }
  }

  Future<void> updateEventReminders({
    required String eventId,
    required String type,
    required String title,
    required String body,
    required DateTime? eventTime,
    required bool enabled,
  }) async {
    await cancelEventReminders(eventId, type: type);
    if (eventTime == null) {
      return;
    }
    await scheduleEventReminders(
      eventId: eventId,
      type: type,
      title: title,
      body: body,
      eventTime: eventTime,
      enabled: enabled,
    );
  }

  Future<void> cancelEventReminders(String eventId, {String? type}) async {
    await init();
    if (type == null) {
      await _cancelByType(eventId: eventId, type: typeMedication);
      await _cancelByType(eventId: eventId, type: typeAppointment);
      await _cancelByType(eventId: eventId, type: legacyTypeSchedule);
      return;
    }
    await _cancelByType(eventId: eventId, type: type);
  }

  void _cachePendingPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }
    _pendingLaunchPayload = payload;
  }

  Future<void> _cancelByType({
    required String eventId,
    required String type,
  }) async {
    final baseId = _baseNotificationId(eventId: eventId, type: type);
    for (var i = 0; i < _reminderOffsets.length; i++) {
      await _plugin.cancel(baseId + i + 1);
    }
  }

  Future<void> scheduleDebugReminderExact({
    Duration delay = const Duration(minutes: 1),
  }) async {
    await init();
    final triggerAt = DateTime.now().add(delay);
    await _zonedScheduleExact(
      id: 99991,
      title: 'Debug Reminder',
      body: 'If you see this, local notifications are working.',
      scheduleAt: triggerAt,
      payload: jsonEncode(<String, dynamic>{
        'type': typeAppointment,
        'eventId': 'debug',
      }),
    );
  }

  Future<void> scheduleScaledDebugAppointmentReminders() async {
    if (!isDebugReminderScaleEnabled) {
      throw StateError(
        'DEBUG_REMINDER_SCALE is disabled. Run with --dart-define=DEBUG_REMINDER_SCALE=true',
      );
    }

    await cancelEventReminders('debug_scaled', type: typeAppointment);
    await scheduleEventReminders(
      eventId: 'debug_scaled',
      type: typeAppointment,
      title: 'Scaled Reminder Test',
      body: 'Scaled debug reminder fired.',
      eventTime: DateTime.now().add(const Duration(seconds: 40)),
      enabled: true,
    );
  }

  Future<void> _zonedScheduleExact({
    required int id,
    required String title,
    required String body,
    required DateTime scheduleAt,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduleAt, tz.local),
        _notificationDetails(body),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException catch (e) {
      if (_isExactAlarmsNotPermitted(e)) {
        throw const ExactAlarmPermissionException(exactAlarmPermissionHint);
      }
      rethrow;
    }
  }

  Future<void> _onDidReceiveNotificationResponse(
    NotificationResponse response,
  ) async {
    await _dispatchPayload(response.payload);
  }

  Future<void> _dispatchPayload(String? payload) async {
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final raw = jsonDecode(payload);
      if (raw is! Map) {
        return;
      }

      final parsed = raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final type = parsed['type']?.toString() ?? '';
      final eventId = parsed['eventId']?.toString() ?? '';
      if (type.isEmpty || eventId.isEmpty) {
        return;
      }

      if (_tapHandler != null) {
        await _tapHandler!(type, eventId);
      }
    } catch (e) {
      debugPrint('Notification payload parse failed: $e');
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (e) {
      debugPrint('Timezone setup fallback to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  NotificationDetails _notificationDetails(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'MyUbat Reminder',
        styleInformation: BigTextStyleInformation(body),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  int _baseNotificationId({required String eventId, required String type}) {
    return _stableHash('$type:$eventId') % 100000;
  }

  int _stableHash(String input) {
    var hash = 2166136261;
    for (final code in input.codeUnits) {
      hash ^= code;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  bool _isExactAlarmsNotPermitted(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    return code.contains('exact_alarms_not_permitted') ||
        message.contains('exact alarms are not permitted');
  }

  List<Duration> _activeReminderOffsets() {
    if (isDebugReminderScaleEnabled) {
      return _debugScaledReminderOffsets;
    }
    return _reminderOffsets;
  }
}
