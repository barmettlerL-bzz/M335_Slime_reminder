import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class MessageStorage {
  static const _key = 'slime_messages';

  static Future<List<String>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messages = prefs.getStringList(_key);
    
    final currentMessage = prefs.getString('slime_current_message');
    if (currentMessage != null && !messages!.contains(currentMessage)) {
      messages.add(currentMessage);
      await prefs.setStringList(_key, messages);
    }

    return messages ?? [
      "You're doing great!",
        "Time to hydrate",
        "Keep going!!",
        "Slime loves you!",
        "Don't forget to stretch!",
        "Get yourself a snack, you deserve it!",
    ];

  }

  static Future<void> saveMessages(List<String> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, messages);
  }

  static Future<void> addMessage(String newMessage) async {
    final messages = await loadMessages();
    messages.add(newMessage);
    await saveMessages(messages);
  }

  static Future<void> deleteMessageAt(int index) async {
    final messages = await loadMessages();
    if (index >= 0 && index < messages.length) {
      messages.removeAt(index);
      await saveMessages(messages);
    }
  }

  static Future<void> updateMessageAt(int index, String newMessage) async {
    final messages = await loadMessages();
    if (index >= 0 && index < messages.length) {
      messages[index] = newMessage;
      await saveMessages(messages);
    }
  }

  static Future<String> updateMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final messages = await MessageStorage.loadMessages();
    late String currentMessage;

    if (messages.isNotEmpty) {
      final rand = Random();
      currentMessage = messages[rand.nextInt(messages.length)];
      prefs.setString('slime_current_message', currentMessage);
      return currentMessage;
    }
    return prefs.getString('slime_current_message') ?? "Hi there! Add messages in settings!";
  }
}
