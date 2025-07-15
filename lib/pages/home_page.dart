import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    // firstName: "Voice Intelligence Engine",
    profileImage: "assets/images/logo.jpg",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A40),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.black,
        title: Shimmer.fromColors(
          baseColor: Colors.blue.shade100,
          highlightColor: Colors.blue.shade300,
          child: const Text(
            "ThetaZero",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white70,
            ),
            tooltip: "Clear Chat",
            onPressed: _clearChat,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildUI(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2A2A40),
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.grey.shade800),
            child: const Text(
              "Menu",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.white)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUI() {
    return Container(
      color: const Color(0xFF1E1E2C),
      child: DashChat(
        currentUser: currentUser,
        messages: messages,
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2A2A40),
            hintText: "Type your message...",
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          inputTextStyle: const TextStyle(color: Colors.white),
          sendButtonBuilder:
              (send) => IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                onPressed: send,
              ),
          trailing: [
            IconButton(
              onPressed: _sendMediaMessage,
              icon: const Icon(Icons.mic, color: Colors.white54),
            ),
          ],
        ),
        messageOptions: MessageOptions(
          containerColor: const Color(0xFF32324D),
          currentUserContainerColor: const Color(0xFF4C4C8A),
          textColor: Colors.white,
          currentUserTextColor: Colors.white,
        ),
        onSend: _sendMessage,
      ),
    );
  }

  void _clearChat() {
    setState(() {
      messages.clear();
    });
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    String userPrompt = chatMessage.text;

    gemini
        .prompt(parts: [Part.text(userPrompt)])
        .then((value) {
          String responseText = value?.output ?? "No response received.";

          ChatMessage botMessage = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: responseText,
          );

          setState(() {
            messages = [botMessage, ...messages];
          });
        })
        .catchError((e) {
          print("Gemini error: $e");
        });
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this picture?",
        medias: [
          ChatMedia(url: file.path, fileName: "", type: MediaType.image),
        ],
      );
      _sendMessage(chatMessage);
    }
  }
}
