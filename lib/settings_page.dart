import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'slime.dart';
import 'notification_service.dart';
import 'message_manage_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool morningEnabled = false;
  bool afternoonEnabled = false;
  bool eveningEnabled = false;

  TimeOfDay morningTime = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay afternoonTime = TimeOfDay(hour: 13, minute: 0);
  TimeOfDay eveningTime = TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadReminderPrefs();
  }

  void _testNotification() async {
  final nf = NotificationService();
  await nf.showNotificationNow();
}


  Future<void> _loadReminderPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      morningEnabled = prefs.getBool('reminder_morning') ?? true;
      afternoonEnabled = prefs.getBool('reminder_afternoon') ?? true;
      eveningEnabled = prefs.getBool('reminder_evening') ?? true;
      morningTime = _parseTimeOfDay(prefs.getString('morning_time')) ?? TimeOfDay(hour: 8, minute: 0);
      afternoonTime = _parseTimeOfDay(prefs.getString('afternoon_time')) ?? TimeOfDay(hour: 13, minute: 0);
      eveningTime = _parseTimeOfDay(prefs.getString('evening_time')) ?? TimeOfDay(hour: 18, minute: 0);
    });
  }

  Future<void> _saveReminderPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final nf = NotificationService();
    await prefs.setBool('reminder_morning', morningEnabled);
    await prefs.setBool('reminder_afternoon', afternoonEnabled);
    await prefs.setBool('reminder_evening', eveningEnabled);
    await prefs.setString('morning_time', '${morningTime.hour}:${morningTime.minute}');
    await prefs.setString('afternoon_time', '${afternoonTime.hour}:${afternoonTime.minute}');
    await prefs.setString('evening_time', '${eveningTime.hour}:${eveningTime.minute}');
    await nf.scheduleAllReminders();

  }

  TimeOfDay? _parseTimeOfDay(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Widget _buildReminderOption(
  String title,
  bool enabled,
  TimeOfDay time,
  void Function(bool?) onChanged,
  void Function(TimeOfDay) onTimeChanged,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Checkbox(
          value: enabled,
          onChanged: (val) {
            onChanged(val);
            _saveReminderPrefs();
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: enabled ? Colors.black : Colors.grey,
            ),
          ),
        ),
        TextButton(
          onPressed: enabled
              ? () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (pickedTime != null) {
                    onTimeChanged(pickedTime);
                    _saveReminderPrefs();
                  }
                }
              : null, 
          child: Text(
            time.format(context),
            style: TextStyle(
              fontSize: 16,
              color: enabled ? Colors.blue : Colors.grey,
              decoration:
                  enabled ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      ],
    ),
  );
}


  
  void _onAddCustomReminder() {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => ManageMessagePage()),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminder Settings"),
        centerTitle: true,
        backgroundColor: const Color(0xFF93CFF0),
      ),
      backgroundColor: const Color(0xFFEAF6FF),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.05),
            child: Column(
              children: [

                _buildReminderOption(
                  "Morning Reminder",
                  morningEnabled,
                  morningTime,
                  (val) => setState(() => morningEnabled = val ?? false),
                  (newTime) => setState(() => morningTime = newTime),
                ),
                _buildReminderOption(
                  "Afternoon Reminder",
                  afternoonEnabled,
                  afternoonTime,
                  (val) => setState(() => afternoonEnabled = val ?? false),
                  (newTime) => setState(() => afternoonTime = newTime),
                ),
                _buildReminderOption(
                  "Evening Reminder",
                  eveningEnabled,
                  eveningTime,
                  (val) => setState(() => eveningEnabled = val ?? false),
                  (newTime) => setState(() => eveningTime = newTime),
                ),
              ],
            ),
          ),
          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  child: ElevatedButton(
    onPressed: _testNotification,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF93CFF0),
      minimumSize: const Size.fromHeight(50),
    ),
    child: const Text(
      "Test Notification",
      style: TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
    ),
  ),
),
          Expanded(child: Container()),
          
          const Slime(scale: 180),
          const SizedBox(height: 30), 
          
          Padding(
            padding: EdgeInsets.only(
              bottom: screenHeight * 0.08,
              left: 16,
              right: 16,
            ),
            child: ElevatedButton.icon(
              onPressed: _onAddCustomReminder,
              icon: const Icon(Icons.add),
              label: const Text("Add Custom Reminder",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF93CFF0),
              minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}