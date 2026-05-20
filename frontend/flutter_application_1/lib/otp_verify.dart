import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OTPVerificationPage extends StatefulWidget {
  const OTPVerificationPage({super.key});

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  bool _isLoading = false;
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  // Focus nodes and controllers to capture input across the 4 boxes
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // --- API Integration Method ---
  Future<void> _verifyOtp(String email) async {
    String otpCode = _controllers.map((c) => c.text.trim()).join();

    if (otpCode.length < 4) {
      _showMsg("Please enter the complete 4-digit code.");
      return;
    }

    setState(() => _isLoading = true);

    // Points smoothly to your new Django verified POST route destination
    const String url = "http://10.0.2.2:8000/api/auth/verify-otp/";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otpCode}),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          _showMsg(responseData['message'] ?? "Account verified successfully!");

          // Clear navigation historical tracking and lock onto login page route context
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          // Captures custom errors mapping directly from your views response dictionary
          _showMsg(responseData['error'] ?? "Verification code incorrect.");
        }
      }
    } catch (e) {
      if (mounted)
        _showMsg("Could not establish a connection interface with back-end.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.lexend(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safely reads the transactional email pointer arguments dispatched from your registration page
    final String userEmail =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryBlue,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verification',
                style: GoogleFonts.lexend(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter the 4-digit confirmation security token code sent to your registered box:',
                style: GoogleFonts.inter(
                  color: Colors.black45,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                userEmail,
                style: GoogleFonts.inter(
                  color: darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 45),

              // OTP Input Boxes Component Layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => _otpBox(context, index)),
              ),

              const SizedBox(height: 45),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _verifyOtp(userEmail),
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
                          'Verify & Activate Account',
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),
              Center(
                child: TextButton(
                  onPressed: () => _showMsg(
                    "A fresh validation code token has been compiled to your inbox.",
                  ),
                  child: Text(
                    "Resend Code",
                    style: GoogleFonts.lexend(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(BuildContext context, int index) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.lexend(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: const Color(0xFFFBFBFC),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1 && index < 3) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
      ),
    );
  }
}
