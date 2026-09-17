import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'todo_reminders';
  static const String _channelName = 'Task Reminders';
  static const String _channelDescription =
      'Reminders for your to-do list tasks';

  bool _ready = false;

  // -------------------------------------------------------------------------
  // INITIALIZE
  // -------------------------------------------------------------------------

  Future<void> init() async {
    if (_ready) return;

    // Initialize timezone database.
    tz_data.initializeTimeZones();

    // Get the device timezone.
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(
        tz.getLocation(tzName),
      );
    } catch (e) {
      // Fallback to UTC if the device timezone cannot be detected.
      tz.setLocalLocation(
        tz.getLocation('UTC'),
      );
    }

    // Android initialization.
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize plugin.
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Create Android notification channel.
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request notification permissions.
    await requestPermissions();

    _ready = true;
  }

  // -------------------------------------------------------------------------
  // PERMISSIONS
  // -------------------------------------------------------------------------

  Future<void> requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Android 13+ notification permission.
    await androidImpl?.requestNotificationsPermission();

    // Permission required for exact scheduled alarms.
    await androidImpl?.requestExactAlarmsPermission();

    // iOS permissions.
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // -------------------------------------------------------------------------
  // SCHEDULE REMINDER
  // -------------------------------------------------------------------------

  Future<void> scheduleReminder({
    required String id,
    required String title,
    String? body,
    required DateTime dateTime,
  }) async {
    // Make sure the notification service is initialized.
    if (!_ready) {
      await init();
    }

    final scheduled = tz.TZDateTime.from(
      dateTime,
      tz.local,
    );

    final now = tz.TZDateTime.now(
      tz.local,
    );

    // Never schedule a notification in the past.
    if (!scheduled.isAfter(now)) {
      return;
    }

    await _plugin.zonedSchedule(
      _notificationId(id),

      title,

      body?.trim().isNotEmpty == true
          ? body!.trim()
          : 'Reminder for your task',

      scheduled,

      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),

      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,

      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // -------------------------------------------------------------------------
  // CANCEL REMINDER
  // -------------------------------------------------------------------------

  Future<void> cancelReminder(String id) async {
    if (!_ready) {
      await init();
    }

    await _plugin.cancel(
      _notificationId(id),
    );
  }

  // -------------------------------------------------------------------------
  // NOTIFICATION ID
  // -------------------------------------------------------------------------

  int _notificationId(String taskId) {
    return taskId.hashCode & 0x7fffffff;
  }
}