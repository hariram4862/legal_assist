import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _originalUserName = '';
  String _userEmail = '';
  bool _showUpdateButton = false;

  final TextEditingController _nameController = TextEditingController();

  Future<Map<String, String>?> fetchUserDetails(String email) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        "https://refined-able-grouper.ngrok-free.app/get_user_details/$email",
      );

      if (response.statusCode == 200 &&
          response.data['message'].toString().contains('✅')) {
        return {
          "email": response.data["email"],
          "full_name": response.data["full_name"],
        };
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
    return null;
  }

  void _loadUserData() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      final data = await fetchUserDetails(email);
      if (data != null) {
        setState(() {
          _userName = data["full_name"] ?? "N/A";
          _originalUserName = _userName;
          _userEmail = data["email"] ?? "N/A";
          _nameController.text = _userName;
        });
      }
    }
  }

  Future<void> _updateUserProfile() async {
    try {
      final dio = Dio();

      final response = await dio.post(
        "https://refined-able-grouper.ngrok-free.app/update_user_details/",
        data: FormData.fromMap({
          "email": _userEmail,
          "full_name": _nameController.text,
        }),
      );

      if (response.statusCode == 200 &&
          response.data['message'].toString().contains("updated")) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ Profile updated")));
        setState(() {
          _originalUserName = _nameController.text;
          _showUpdateButton = false;
        });
      } else {
        throw Exception("Update failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Update failed: $e")));
    }
  }

  void _onNameChanged(String newName) {
    setState(() {
      _showUpdateButton = newName.trim() != _originalUserName.trim();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // or center if needed
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/logo.jpg'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: _onNameChanged,
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: _userEmail,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: _userEmail,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password reset link sent")),
                  );
                },
                child: const Text("Change Password"),
              ),
              if (_showUpdateButton) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _updateUserProfile,
                  icon: const Icon(Icons.save),
                  label: const Text("Update Profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
