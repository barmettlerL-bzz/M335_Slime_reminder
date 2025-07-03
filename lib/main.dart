import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'message_storage.dart';
import 'slime.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
        '/settings': (context) => const Placeholder(), // Replace later
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

  Future<void> _loadMessageCycle() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    final morningEnabled = prefs.getBool('reminder_morning') ?? true;
    final afternoonEnabled = prefs.getBool('reminder_afternoon') ?? true;
    final eveningEnabled = prefs.getBool('reminder_evening') ?? true;

    final morningHour = prefs.getInt('morning_hour') ?? 8;
    final morningMinute = prefs.getInt('morning_minute') ?? 0;
    final afternoonHour = prefs.getInt('afternoon_hour') ?? 13;
    final afternoonMinute = prefs.getInt('afternoon_minute') ?? 0;
    final eveningHour = prefs.getInt('evening_hour') ?? 20;
    final eveningMinute = prefs.getInt('evening_minute') ?? 0;

    bool shouldUpdate =
        (hour == morningHour && minute == morningMinute && morningEnabled) ||
            (hour == afternoonHour &&
                minute == afternoonMinute &&
                afternoonEnabled) ||
            (hour == eveningHour &&
                minute == eveningMinute &&
                eveningEnabled);

    final message = shouldUpdate
        ? await MessageStorage.updateMessage()
        : await MessageStorage.getCurrentMessage();

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Slime(scale: 180), // 👈 Use scale here
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
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84BDFF),
              ),
              onPressed: _goToSettings,
              child: const Text("Go to Settings"),
            ),
          ],
        ),
      ),
    );
  }
}
