import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'message_storage.dart';
import 'settings_page.dart';
import 'slime.dart';
import 'notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await AndroidAlarmManager.initialize();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.local);

  final nf = NotificationService();
  await nf.initialize();
  await nf.requestExactAlarmPermission();
  nf.scheduleAllReminders();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slime Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF93CFF0),
          primary: const Color(0xFF93CFF0),
          secondary: const Color(0xFF84BDFF),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
String currentMessage = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadMessageCycle();
  }

  TimeOfDay _parseTimeOfDay(String? timeString) {
  if (timeString == null) return TimeOfDay(hour: 0, minute: 0);
  final parts = timeString.split(':');
  if (parts.length != 2) return TimeOfDay(hour: 0, minute: 0);
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour, minute: minute);
}

Future<void> _loadMessageCycle() async {
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

  setState(() {
    currentMessage = message;
  });
}


  void _goToSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFEAF6FF),
    appBar: AppBar(
      title: const Text("Slime Reminder"),
      centerTitle: true,
      backgroundColor: const Color(0xFF93CFF0),
    ),
    body: Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2),
          child: Column(
            children: [
              const Slime(scale: 180),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  currentMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(child: Container()),

        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.08,
            left: 16,
            right: 16,
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84BDFF),
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _goToSettings,
            child: const Text(
              "Go to Settings",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }
}