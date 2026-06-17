import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/route_strings.dart';
import '../../core/networks/auth_api_services.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF1A237E);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetOtp() async {
    setState(() => _isLoading = true);

    try {
      final responseData = await AuthApiService.requestPasswordReset(
        _emailController.text.trim(),
      );

      if (responseData['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Reset verification code sent to your inbox!",
                style: GoogleFonts.lexend(fontSize: 13),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green.shade800,
            ),
          );

          Navigator.pushNamed(
            context,
            RouteStrings.otpVerify,
            arguments: _emailController.text.trim(),
          );
        }
      } else {
        _showSnackBar(responseData['error'] ?? "Email identity trace missing.");
      }
    } catch (e) {
      _showSnackBar(
        "Could not establish communication with validation servers.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.lexend(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_reset_rounded,
                    size: 100,
                    color: primaryBlue,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Forgot Password?',
                    style: GoogleFonts.lexend(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Enter your registered email address below to receive a 4-digit verification code.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Email parameters required";
                      }
                      if (!v.contains('@')) {
                        return "Enter a valid standard email layout";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      labelStyle: GoogleFonts.inter(
                        color: Colors.black38,
                        fontSize: 13.5,
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: primaryBlue,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _sendPasswordResetOtp();
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
                              'Send Verification OTP',
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: primaryBlue,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
