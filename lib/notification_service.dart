import "package:flutter/material.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import 'package:shared_preferences/shared_preferences.dart';
import "package:slime_reminder/message_storage.dart";
import 'package:timezone/timezone.dart' as tz;
import "package:timezone/timezone.dart";


class NotificationService {
  String currentMessage = "Loading...";

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

 Future<void> initialize() async {
    await MessageStorage.loadMessages();
    const initializationSettingsAndroid =
        AndroidInitializationSettings('idle000'); 
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestExactAlarmPermission() async {
  final androidPlugin = FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();


  if (androidPlugin != null) {
    final isPermitted = await androidPlugin.canScheduleExactNotifications();
    final isNotificationsPermitted = await androidPlugin.areNotificationsEnabled();

    if(isPermitted == false) {
      await androidPlugin.requestExactAlarmsPermission();
    }

    if(isNotificationsPermitted == false) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'slime_channel_2',
        'Slime Messages',
        channelDescription: 'Slime reminder messages',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  TimeOfDay _parseTimeOfDay(String? timeString) {
    if (timeString == null) return TimeOfDay(hour: 0, minute: 0);
    final parts = timeString.split(':');
    if (parts.length != 2) return TimeOfDay(hour: 0, minute: 0);
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<String> _getCurrentMessageForNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    final morningEnabled = prefs.getBool('reminder_morning') ?? true;
    final afternoonEnabled = prefs.getBool('reminder_afternoon') ?? true;
    final eveningEnabled = prefs.getBool('reminder_evening') ?? true;

    final morningTime = _parseTimeOfDay(prefs.getString('morning_time')) ?? TimeOfDay(hour: 8, minute: 0);
    final afternoonTime = _parseTimeOfDay(prefs.getString('afternoon_time')) ?? TimeOfDay(hour: 13, minute: 0);
    final eveningTime = _parseTimeOfDay(prefs.getString('evening_time')) ?? TimeOfDay(hour: 18, minute: 0);

    bool shouldUpdate =
        (morningTime.hour == hour && morningTime.minute == minute && morningEnabled) ||
        (afternoonTime.hour == hour && afternoonTime.minute == minute && afternoonEnabled) ||
        (eveningTime.hour == hour && eveningTime.minute == minute && eveningEnabled);

    String message = shouldUpdate
        ? await MessageStorage.updateMessage()
        : await MessageStorage.getCurrentMessage();

    if (message == "Loading...") {
      message = await MessageStorage.updateMessage();
    }

    return message;
  }

  Future<void> showNotificationNow() async {
    
    final message = await _notificationsPlugin.pendingNotificationRequests();
    /* await _getCurrentMessageForNotification();

    await _notificationsPlugin.show(
      0,
      'Slime Reminder',
      message,
      notificationDetails(),
    );*/

    print(message);
  }

  Future<void> scheduleNotification(int id, DateTime scheduledTime) async {
  final message = await _getCurrentMessageForNotification();

  // Ensure seconds = 0 for precise scheduling
  final scheduledTimeWithSeconds = DateTime(
    scheduledTime.year,
    scheduledTime.month,
    scheduledTime.day,
    scheduledTime.hour,
    scheduledTime.minute,
    1, 
  );
  final tzScheduledDate = tz.TZDateTime.from(scheduledTimeWithSeconds, tz.local);

  await _notificationsPlugin.zonedSchedule(
    id,
    'Slime Reminder',
    message,
    tzScheduledDate,
    notificationDetails(),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time, // daily repeat
  );
}



  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> scheduleAllReminders() async {
    final prefs = await SharedPreferences.getInstance();

    final morningEnabled = prefs.getBool('reminder_morning') ?? true;
    final afternoonEnabled = prefs.getBool('reminder_afternoon') ?? true;
    final eveningEnabled = prefs.getBool('reminder_evening') ?? true;

    final morningTime = _parseTimeOfDay(prefs.getString('morning_time')) ?? TimeOfDay(hour: 8, minute: 0);
    final afternoonTime = _parseTimeOfDay(prefs.getString('afternoon_time')) ?? TimeOfDay(hour: 13, minute: 0);
    final eveningTime = _parseTimeOfDay(prefs.getString('evening_time')) ?? TimeOfDay(hour: 18, minute: 0);

    final now = DateTime.now();

    DateTime toDateTime(TimeOfDay t) {
      final scheduled = DateTime(now.year, now.month, now.day, t.hour, t.minute, 0);
      return scheduled;
    }


    // Id's 1, 2, 3 = morning, afternoon, evening
    if (morningEnabled) {
      await scheduleNotification(1, toDateTime(morningTime));
    } else {
      await cancelNotification(1);
    }

    if (afternoonEnabled) {
      await scheduleNotification(2, toDateTime(afternoonTime));
    } else {
      await cancelNotification(2);
    }

    if (eveningEnabled) {
      await scheduleNotification(3, toDateTime(eveningTime));
    } else {
      await cancelNotification(3);
    }
  }
}