import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
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
    _currentPasswordController.addListener(() => setState(() {}));
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    final email = user?.email;
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (email == null) {
      _showToast("No user is logged in.");

      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user!.reauthenticateWithCredential(cred);

      await user.updatePassword(newPassword);
      _showToast("Password updated successfully.");

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showToast("Incorrect current password.");
      } else if (e.code == 'weak-password') {
        _showToast("New password is too weak.");
      } else {
        _showToast(e.message ?? "Something went wrong.");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Change Password",
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_showCurrentPassword,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: inputDecoration.copyWith(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock, color: Colors.black),
                  suffixIcon:
                      _currentPasswordController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              _showCurrentPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black,
                            ),
                            onPressed:
                                () => setState(
                                  () =>
                                      _showCurrentPassword =
                                          !_showCurrentPassword,
                                ),
                          )
                          : null,
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter current password'
                            : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: inputDecoration.copyWith(
                  labelText: 'New Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.black,
                  ),
                  suffixIcon:
                      _newPasswordController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              _showNewPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black,
                            ),
                            onPressed:
                                () => setState(
                                  () => _showNewPassword = !_showNewPassword,
                                ),
                          )
                          : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Enter new password';
                  if (value.length < 6)
                    return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: inputDecoration.copyWith(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_reset, color: Colors.black),
                  suffixIcon:
                      _confirmPasswordController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black,
                            ),
                            onPressed:
                                () => setState(
                                  () =>
                                      _showConfirmPassword =
                                          !_showConfirmPassword,
                                ),
                          )
                          : null,
                ),
                validator: (value) {
                  if (value != _newPasswordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      "Update Password",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
