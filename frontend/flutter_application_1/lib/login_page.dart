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

  // Realigned to target user_phone per SQL schema dictionary constraints
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const Color primaryBlue = Color(0xFF1A237E);

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Re-architected API Integration Method ---
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    // 10.0.2.2 points to local loopback port on Android emulator environments
    const String url = "http://10.0.2.2:8000/api/auth/login/";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_phone": _phoneController.text
              .trim(), // Synchronized key matching Django request.data.get()
          "password": _passwordController.text,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Dynamic Role Extraction mapping out Role-Based Access Control paths
        String assignedRole = responseData['role'] ?? 'resident';
        String userName = responseData['user_name'] ?? 'User';

        if (mounted) {
          _showSnackBar("Welcome back, $userName!");

          // Role-Based Access Control (RBAC) routing logic branches
          if (assignedRole == 'resident') {
            // Directs resident into your new BottomNavigationBar frame shell holder
            Navigator.pushReplacementNamed(context, '/home');
          } else if (assignedRole == 'security') {
            Navigator.pushReplacementNamed(context, '/security_dashboard');
          } else {
            _showSnackBar(
              "Access tier not configured for this device layout framework.",
            );
          }
        }
      } else {
        // Captures clean error explanation rows formulated from your views exceptions
        if (mounted) {
          _showSnackBar(
            responseData['error'] ?? "Login rejected. Check entry details.",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Could not establish server connection interface ports.");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.lexend(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF323232),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                  // Premium Brand Header area matching Login template visuals
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
                        const SizedBox(height: 20),
                        // Field modified to gather standard validation phone numbers
                        _loginInput(
                          "Contact Phone Number",
                          Icons.phone_android_outlined,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "Please enter your registered phone number";
                            }
                            if (v.length != 10) {
                              return "Phone number must be exactly 10 digits";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _loginInput(
                          "Password",
                          Icons.lock_outline,
                          isPassword: true,
                          controller: _passwordController,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "Please enter password";
                            }
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
                                color: primaryBlue.withValues(alpha:0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
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
                              disabledBackgroundColor: Colors.grey.shade200,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: GoogleFonts.lexend(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            '/register',
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                color: Colors.black38,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: GoogleFonts.inter(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        counterText:
            "", // Suppresses character counts length indicators below box boundary
        prefixIcon: Icon(icon, color: primaryBlue, size: 22),
        hintStyle: GoogleFonts.inter(color: Colors.black38, fontSize: 14),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
    );
  }
}
