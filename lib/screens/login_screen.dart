import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:legal_assist/screens/loading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

final String lastLoginAt = DateFormat(
  'dd-MM-yyyy HH:mm:ss',
).format(DateTime.now());

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _passwordVisible = false;
  bool _showPasswordToggle = false;
  void _handleForgotPassword() {
    if (_emailController.text.trim().isEmpty) {
      _showToast("Please enter your email to reset password.");
      return;
    }

    _auth
        .sendPasswordResetEmail(email: _emailController.text.trim())
        .then((_) {
          _showToast("Password reset link sent to your email.");
        })
        .catchError((error) {
          _showToast("Error: ${error.message}");
        });
  }

  @override
  void initState() {
    super.initState();
    _emailController.clear();
    _passwordController.clear();
    _passwordController.addListener(() {
      setState(() {
        _showPasswordToggle = _passwordController.text.isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sign In',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                  prefixIcon: const Icon(Icons.email, color: Colors.black),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                  prefixIcon: const Icon(Icons.lock, color: Colors.black),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon:
                      _showPasswordToggle
                          ? IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black,
                            ),
                            onPressed:
                                () => setState(() {
                                  _passwordVisible = !_passwordVisible;
                                }),
                          )
                          : null,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
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
                onPressed: _handleLogin,
                child: Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                child: Text(
                  'Create an Account',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showToast("Please fill in all fields.");
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // ✅ Navigate to loading screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoadingScreen(message: 'Logging in...'),
        ),
      );

      Dio dio = Dio();
      final response = await dio.post(
        'https://refined-able-grouper.ngrok-free.app/update_last_login',
        data: FormData.fromMap({
          'email': _emailController.text.trim(),
          'last_login_at': DateFormat(
            'dd-MM-yyyy HH:mm:ss',
          ).format(DateTime.now()),
        }),
      );

      if (response.statusCode == 200) {
        await _saveUserProfile(userCredential.user?.email ?? "");

        if (!mounted) return;

        // ✅ Replace loading screen with home screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (Route<dynamic> route) => false,
        );
      } else {
        Navigator.pop(context); // close LoadingScreen
        _showToast('Server error: ${response.statusCode}');
      }
    } on FirebaseAuthException catch (e) {
      _showToast("Login failed: ${e.message}");
    }
  }

  Future<void> _saveUserProfile(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userEmail', email);
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
}
