import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/route_strings.dart';
import '../../core/networks/auth_api_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final responseData = await AuthApiService.login(
        _phoneController.text.trim(),
        _passwordController.text,
      );

      if (responseData['success'] == true) {
        String assignedRole = responseData['role'] ?? 'resident';
        String userName = responseData['user_name'] ?? 'Member';

        if (mounted) {
          _showSnackBar("Welcome back, $userName!");

          // 🔀 Role-Based Access Control (RBAC) Split Router Mapping Pipeline
          if (assignedRole == 'chairman') {
            Navigator.pushReplacementNamed(context, RouteStrings.chairmanHome);
          } else if (assignedRole == 'resident') {
            Navigator.pushReplacementNamed(context, RouteStrings.residentHome);
          } else if (assignedRole == 'security') {
            Navigator.pushReplacementNamed(context, '/security_dashboard');
          } else {
            _showSnackBar("Access authorization tier mismatch.");
          }
        }
      } else {
        if (mounted) {
          _showSnackBar(responseData['error'] ?? "Login credentials rejected.");
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Could not establish a clean connection interface.");
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                height: 260,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                  vertical: 40.0,
                ),
                child: Column(
                  children: [
                    _loginInput(
                      "Contact Phone Number",
                      Icons.phone_android_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Phone parameter required";
                        }
                        if (v.trim().length != 10) {
                          return "Must be exactly 10 digits";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _loginInput(
                      "Password",
                      Icons.lock_outline,
                      isPassword: true,
                      controller: _passwordController,
                      validator: (v) => (v == null || v.isEmpty)
                          ? "Please enter your password"
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          RouteStrings.forgotPassword,
                        ),
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.inter(
                            color: primaryBlue.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
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
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RouteStrings.registration,
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            color: Colors.black38,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          children: const [
                            TextSpan(text: "New to Zenith Square? "),
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
      style: GoogleFonts.inter(
        fontSize: 15,
        color: darkText,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: "",
        prefixIcon: Icon(icon, color: primaryBlue, size: 20),
        hintStyle: GoogleFonts.inter(
          color: Colors.black38,
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
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
