import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'todo_reminders';
  static const _channelName = 'Task Reminders';
  static const _channelDescription = 'Reminders for your to-do list tasks';

  bool _ready = false;

  // ------------------------------------------------------------
  // INITIALIZE
  // ------------------------------------------------------------

  Future<void> init() async {
    if (_ready) return;

    // Initialize timezone database
    tz_data.initializeTimeZones();

    // Get device timezone
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      // Fallback to UTC
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android initialization
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize plugin
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Ask permissions
    await requestPermissions();

    _ready = true;
  }

  // ------------------------------------------------------------
  // PERMISSIONS
  // ------------------------------------------------------------

  Future<void> requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Android 13+
    await androidImpl?.requestNotificationsPermission();

    // Needed for exact reminders
    await androidImpl?.requestExactAlarmsPermission();

    // iOS
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ------------------------------------------------------------
  // SCHEDULE REMINDER
  // ------------------------------------------------------------

  Future<void> scheduleReminder({
    required String id,
    required String title,
    String? body,
    required DateTime dateTime,
  }) async {
    final scheduled = tz.TZDateTime.from(dateTime, tz.local);

    final now = tz.TZDateTime.now(tz.local);

    // Don't schedule notifications in the past
    if (!scheduled.isAfter(now)) {
      return;
    }

    await _plugin.zonedSchedule(
      _notificationId(id),

      // Notification title
      title,

      // Notification body
      body?.isNotEmpty == true ? body : 'Reminder for your task',

      // When notification should fire
      scheduled,

      // Notification appearance
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),

      // Android exact reminder
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // Required by the version you currently have
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ------------------------------------------------------------
  // CANCEL REMINDER
  // ------------------------------------------------------------

  Future<void> cancelReminder(String id) async {
    await _plugin.cancel(_notificationId(id));
  }

  // ------------------------------------------------------------
  // CREATE NOTIFICATION ID
  // ------------------------------------------------------------

  int _notificationId(String taskId) {
    return taskId.hashCode & 0x7fffffff;
  }
}
