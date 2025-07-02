import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'message_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String currentMessage = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadMessageCycle();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadMessageCycle() async {
    final now = DateTime.now();
    final hour = now.hour;
    final minutes = now.minute;
    final prefs = await SharedPreferences.getInstance();

    final bool morningEnabled = prefs.getBool('reminder_morning') ?? true;
    final bool afternoonEnabled = prefs.getBool('reminder_afternoon') ?? true;
    final bool eveningEnabled = prefs.getBool('reminder_evening') ?? true;

    bool shouldUpdate = false;

    if (hour == prefs.getInt('morning_hour') && minutes == prefs.getInt('morning_minute') && morningEnabled) {
      shouldUpdate = true;
    } else if (hour == prefs.getInt('afternoon_hour') && minutes == prefs.getInt('afternoon_minute') && afternoonEnabled) {
      shouldUpdate = true;
    } else if (hour == prefs.getInt('evening_hour') && minutes == prefs.getInt('evening_minute') && eveningEnabled) {
      shouldUpdate = true;
    }

    if (shouldUpdate) {
      MessageStorage.updateMessage().then((message) {
        setState(() {
          currentMessage = message;
        });
      });
    }
  }

  void _goToSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Slime Reminder"),
        centerTitle: true,
        backgroundColor: Colors.green.shade300,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Image.asset(
                'assets/slime_idle/idle000.png',
                width: 160,
                height: 160,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              currentMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _goToSettings,
              child: const Text("Go to Settings"),
            ),
          ],
        ),
      ),
    );
  }
}
