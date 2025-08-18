import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:legal_assist/screens/AccessSharedSessionScreen.dart';
// import 'package:legal_assist/screens/change_pw.dart';
import 'package:legal_assist/screens/chat_history_screen.dart';
import 'package:legal_assist/screens/profile_screen.dart';
import 'package:legal_assist/screens/welcome_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDrawer extends StatefulWidget {
  final User? user;
  final Function(String sessionId, List<Map<String, String>> messages)
  onSessionSelected;

  const CustomDrawer({
    super.key,
    required this.user,
    required this.onSessionSelected,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String _version = '';
  final User? user = FirebaseAuth.instance.currentUser;

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    _showToast("Logged out");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  void _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = "v${info.version}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundImage: const AssetImage('assets/images/logo.jpg'),
                  backgroundColor: Colors.grey.shade200,
                ),

                Positioned(
                  bottom: 4,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen()),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16, color: Colors.black),
                    label: Text(
                      "Edit Profile",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          _buildDrawerItem(
            icon: Icons.history,
            text: "Chat History",
            onTap: () async {
              if (user == null) return;
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
              );
              if (result != null && result is Map<String, dynamic>) {
                widget.onSessionSelected(
                  result['sessionId'],
                  List<Map<String, String>>.from(result['messages']),
                );
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.group_outlined,
            text: "View Shared Chat",
            onTap: () {
              Navigator.pop(context); // Close the drawer
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const _ShareAccessBottomSheet(),
                );
              });
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            text: "Log Out",
            textColor: Colors.redAccent,
            iconColor: Colors.redAccent,
            onTap: () => _logout(context),
          ),

          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              _version,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color textColor = Colors.black,
    Color iconColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        text,
        style: GoogleFonts.poppins(color: textColor, fontSize: 15),
      ),
      onTap: onTap,
    );
  }
}

class _ShareAccessBottomSheet extends StatefulWidget {
  const _ShareAccessBottomSheet();

  @override
  State<_ShareAccessBottomSheet> createState() =>
      _ShareAccessBottomSheetState();
}

class _ShareAccessBottomSheetState extends State<_ShareAccessBottomSheet> {
  final _shareIdController = TextEditingController();
  final _pinController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _submit() async {
    final shareId = _shareIdController.text.trim();
    final pin = _pinController.text.trim();

    if (shareId.isEmpty || pin.isEmpty) {
      setState(() => _error = "Please fill both fields");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Dio().get(
        "https://voice-intelligence-app.azurewebsites.net/view_shared_session/$shareId",
        queryParameters: {"pin": pin},
      );

      final data = response.data;
      final sessionName = data['session_name'];
      final List<dynamic> rawMessages = data['messages'];

      final formattedMessages =
          rawMessages
              .map(
                (msg) => {
                  'role': msg['role'].toString(),
                  'text': msg['text'].toString(),
                },
              )
              .toList();

      if (!context.mounted) return;
      Navigator.pop(context); // close bottom sheet

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => AccessSharedChatScreen(
                sessionName: sessionName,
                messages: List<Map<String, String>>.from(formattedMessages),
              ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = "❌ Invalid Share ID or PIN";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            const Text(
              "🔓 Access Shared Session",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _shareIdController,
              decoration: const InputDecoration(labelText: "Share ID"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(labelText: "PIN"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: const Icon(Icons.lock_open),
              label: const Text("Unlock Chat"),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
