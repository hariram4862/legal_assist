// In pubspec.yaml, make sure you have:
// shimmer: ^3.0.0
// google_fonts: ^6.1.0

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legal_assist/screens/change_pw.dart';
import 'package:shimmer/shimmer.dart';

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
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();

  Future<Map<String, String>?> fetchUserDetails(String email) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        "https://voice-intelligence-app.azurewebsites.net/get_user_details/$email",
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserProfile() async {
    try {
      final dio = Dio();

      final response = await dio.post(
        "https://voice-intelligence-app.azurewebsites.net/update_user_details/",
        data: FormData.fromMap({
          "email": _userEmail,
          "full_name": _nameController.text,
        }),
      );

      if (response.statusCode == 200 &&
          response.data['message'].toString().contains("updated")) {
        _showToast("Username updated");
        setState(() {
          _originalUserName = _nameController.text;
          _showUpdateButton = false;
        });
      } else {
        throw Exception("Update failed");
      }
    } catch (e) {
      _showToast("❌ Update failed: $e");
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
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.poppins(color: Colors.black);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? _buildShimmer()
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/images/logo.jpg'),
                      ),
                      const SizedBox(height: 30),

                      // Name Field
                      TextField(
                        controller: _nameController,
                        style: textStyle,
                        onChanged: _onNameChanged,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.grey[700],
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email Field (Read-only with controller)
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(text: _userEmail),
                        style: textStyle,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.grey[700],
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Change Password as TextButton
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Change Password?",
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Update Button Always Visible
                      ElevatedButton.icon(
                        onPressed:
                            _showUpdateButton ? _updateUserProfile : null,
                        // icon: const Icon(Icons.save),
                        label: const Text("Update Profile"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ).copyWith(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color?>(
                                (states) =>
                                    _showUpdateButton
                                        ? Colors.black
                                        : Colors.grey.shade400,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: const CircleAvatar(radius: 50),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 50,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 50,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 50,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
