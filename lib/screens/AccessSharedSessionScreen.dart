import 'package:flutter/material.dart';
import 'package:legal_assist/widgets/home_screen/message_bubble.dart';

class AccessSharedChatScreen extends StatelessWidget {
  final String sessionName;
  final List<Map<String, String>> messages;

  const AccessSharedChatScreen({
    super.key,
    required this.sessionName,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🔓 Shared Chat")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🗂️ $sessionName",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(
                    messages[index],
                    isEditable: false,
                    enableTypingAnimation: false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
