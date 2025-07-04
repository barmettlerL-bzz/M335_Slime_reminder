import "package:flutter/material.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import 'package:shared_preferences/shared_preferences.dart';
import "package:slime_reminder/message_storage.dart";
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

@pragma('vm:entry-point')
void alarmCallback() async {
  final plugin = FlutterLocalNotificationsPlugin();

  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('idle000'),
    iOS: DarwinInitializationSettings(),
  );

  await plugin.initialize(initSettings);

  tz.initializeTimeZones();
  
  final message = await MessageStorage.updateMessage();
  await MessageStorage.saveMessages(await MessageStorage.loadMessages()); // Optional if list was modified

  const androidDetails = AndroidNotificationDetails(
    'slime_channel_2',
    'Slime Messages',
    channelDescription: 'Slime reminder messages',
    importance: Importance.max,
    priority: Priority.high,
  );

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'Slime Reminder',
    message,
    NotificationDetails(android: androidDetails),
  );

  print("🔔 Alarm triggered. Message sent: $message");
}


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

  void _scheduleAlarm(int id, TimeOfDay time) {
  final now = DateTime.now();
  var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);

  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  AndroidAlarmManager.periodic(
    const Duration(seconds: 30),
    id,
    alarmCallback,
    startAt: scheduled,
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
  );
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
    
    final message = await _getCurrentMessageForNotification();
    
    //await _notificationsPlugin.pendingNotificationRequests();

    await _notificationsPlugin.show(
      0,
      'Slime Reminder',
      message,
      notificationDetails(),
    );

    print(message);
  }

  Future<void> scheduleAllReminders() async {
  final prefs = await SharedPreferences.getInstance();

  final morningEnabled = prefs.getBool('reminder_morning') ?? true;
  final afternoonEnabled = prefs.getBool('reminder_afternoon') ?? true;
  final eveningEnabled = prefs.getBool('reminder_evening') ?? true;

  final morningTime = _parseTimeOfDay(prefs.getString('morning_time')) ?? TimeOfDay(hour: 8, minute: 0);
  final afternoonTime = _parseTimeOfDay(prefs.getString('afternoon_time')) ?? TimeOfDay(hour: 13, minute: 0);
  final eveningTime = _parseTimeOfDay(prefs.getString('evening_time')) ?? TimeOfDay(hour: 18, minute: 0);

  await AndroidAlarmManager.cancel(1);
  await AndroidAlarmManager.cancel(2);
  await AndroidAlarmManager.cancel(3);

  if (morningEnabled) {
    _scheduleAlarm(1, morningTime);
  }

  if (afternoonEnabled) {
    _scheduleAlarm(2, afternoonTime);
  }

  if (eveningEnabled) {
    _scheduleAlarm(3, eveningTime);
  }
}

}