import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers to track user input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const Color primaryBlue = Color(0xFF1A237E);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- API Integration Method ---
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS
    const String url = "http://10.0.2.2:8000/api/login/";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 1. EXTRACT JWT TOKENS
        // Your backend returns tokens in a nested 'tokens' object
        String accessToken = responseData['tokens']['access'];
        //        String refreshToken = responseData['tokens']['refresh'];

        // 2. TODO: Store tokens securely
        // You can use the 'flutter_secure_storage' package here to keep the user logged in
        print("Access Token: $accessToken");

        if (mounted) {
          _showSnackBar(responseData['message'] ?? "Welcome back!");
          // Navigate to the landing page or dashboard
          Navigator.pushReplacementNamed(context, '/resident_home');
        }
      } else {
        // Backend returns error messages in the 'message' key
        _showSnackBar(
          responseData['message'] ?? "Login failed. Check credentials.",
        );
      }
    } catch (e) {
      _showSnackBar("Could not connect to server. Check your backend.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Blue header area
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(80),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Login',
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        _loginInput(
                          "Email",
                          Icons.email_outlined,
                          controller: _emailController,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return "Please enter email";
                            if (!v.contains('@')) return "Enter a valid email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _loginInput(
                          "Password",
                          Icons.lock_outline,
                          isPassword: true,
                          controller: _passwordController,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return "Please enter password";
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/forgot_password',
                            ),
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.inter(
                                color: primaryBlue.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      _handleLogin();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            '/register',
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(text: "Not have account? "),
                                TextSpan(
                                  text: "Signup here",
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginInput(
    String hint,
    IconData icon, {
    bool isPassword = false,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryBlue),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }
}
