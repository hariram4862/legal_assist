import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
          // _buildDrawerItem(
          //   icon: Icons.lock_outline,
          //   text: "Change Password",
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const ChangePasswordScreen(),
          //       ),
          //     );
          //   },
          // ),
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
