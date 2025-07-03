import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'message_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    debugPrint("App crash: $error");
    debugPrint(stack.toString());
  });
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String currentMessage = "Loading...";
  bool isJumping = false;
  int currentFrame = 0;
  late Timer frameTimer;
  late List<String> idleFrames;
  late List<String> jumpFrames;

  @override
  void initState() {
    super.initState();
    idleFrames = List.generate(10, (i) => 'assets/slime_idle/idle00${i}.png');
    jumpFrames = List.generate(5, (i) => 'assets/slime_jump/jump00${i}.png');
    jumpFrames.add('assets/slime_jump/jump005.png'); // More airtime
    jumpFrames.add('assets/slime_jump/jump006.png'); 
    jumpFrames.add('assets/slime_jump/jump005.png'); 
    jumpFrames.add('assets/slime_jump/jump006.png'); 

    _loadMessageCycle();

    frameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (isJumping) {
          currentFrame++;
          if (currentFrame >= jumpFrames.length) {
            isJumping = false;
            currentFrame = 3; // landing frame
          }
        } else {
          currentFrame = (currentFrame + 1) % idleFrames.length;
        }
      });
    });
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

    bool shouldUpdate = (hour == morningHour && minute == morningMinute && morningEnabled) ||
        (hour == afternoonHour && minute == afternoonMinute && afternoonEnabled) ||
        (hour == eveningHour && minute == eveningMinute && eveningEnabled);

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

  void _triggerJump() {
    if (!isJumping) {
      setState(() {
        isJumping = true;
        currentFrame = 0;
      });
    }
  }

  @override
  void dispose() {
    frameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final framePath = isJumping
        ? jumpFrames[currentFrame.clamp(0, jumpFrames.length - 1)]
        : idleFrames[currentFrame % idleFrames.length];

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
            GestureDetector(
              onTap: _triggerJump,
              child: Image.asset(
                framePath,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
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
