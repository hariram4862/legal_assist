import 'package:flutter/material.dart';
import 'package:legal_assist/widgets/home_screen/message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Map<String, String>> messages;
  // final ScrollController scrollController;

  const MessageList({
    super.key,
    required this.messages,
    // required this.scrollController,
  });
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // controller: scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return MessageBubble(msg);
      },
    );
  }
}
