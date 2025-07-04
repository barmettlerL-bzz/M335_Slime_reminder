import 'package:flutter/material.dart';
import 'package:slime_reminder/slime.dart';
import 'message_storage.dart';

class ManageMessagePage extends StatefulWidget {
  const ManageMessagePage({super.key});

  @override
  _ManageMessagePageState createState() => _ManageMessagePageState();
}

class _ManageMessagePageState extends State<ManageMessagePage> {
  List<String> _messages = [];
  final TextEditingController _controller = TextEditingController();
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final messages = await MessageStorage.loadMessages();
    setState(() => _messages = messages);
  }

  Future<void> _addOrUpdateMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_editingIndex != null) {
      await MessageStorage.updateMessageAt(_editingIndex!, text);
    } else {
      await MessageStorage.addMessage(text);
    }

    _controller.clear();
    setState(() {
      _editingIndex = null;
    });
    await _loadMessages();
  }

  Future<void> _deleteMessage(int index) async {
    await MessageStorage.deleteMessageAt(index);
    if (_editingIndex == index) {
      _controller.clear();
      setState(() {
        _editingIndex = null;
      });
    }
    await _loadMessages();
  }

  void _startEditing(int index) {
    setState(() {
      _controller.text = _messages[index];
      _editingIndex = index;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimary = const Color(0xFF93CFF0);
    final colorSecondary = const Color(0xFF84BDFF);
    final bgLight = const Color(0xFFEAF6FF);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: colorPrimary,
        leading: const BackButton(),
        title: const Text("Add Reminder"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          const Slime(scale: 100),
          Divider(
            color: const Color.fromARGB(255, 16, 32, 70),
            height: 0,
            thickness: 2,
          ),
          Expanded(
            child: Container(
              color: colorPrimary.withOpacity(0.3),
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isEditing = _editingIndex == index;

                  return Card(
                    elevation: isEditing ? 4 : 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      side: isEditing
                          ? BorderSide(color: colorSecondary, width: 2)
                          : BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        '“$msg”',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteMessage(index),
                      ),
                      onTap: () => _startEditing(index),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: colorPrimary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingIndex != null ? 'Editing message:' : 'Message:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Enter some text here',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _editingIndex != null ? colorSecondary : Colors.grey,
                      ),
                    ),
                    suffixIcon: _editingIndex != null
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _cancelEditing,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorSecondary,
                    ),
                    onPressed: _addOrUpdateMessage,
                    child: Text(
                      _editingIndex != null ? 'Update Reminder' : 'Add Reminder',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
