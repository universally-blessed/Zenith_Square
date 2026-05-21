import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_services.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for extracting user text inputs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  static const Color primaryBlue = Color(0xFF1A237E);

  // Dynamic state hooks connected straight to the backend
  String? selectedSocietyId;
  String? selectedBlockId;

  List<dynamic> societiesList = [];
  List<dynamic> blocksList = [];

  @override
  void initState() {
    super.initState();
    _loadInitialSocieties();
  }

  Future<void> _loadInitialSocieties() async {
    final data = await ApiService.fetchPublicSocieties();
    setState(() {
      societiesList = data;
    });
  }

  Future<void> _loadDependentBlocks(String societyId) async {
    final data = await ApiService.fetchPublicBlocks(societyId);
    setState(() {
      blocksList = data;
      selectedBlockId = null; // Flush old blocks when switching society context
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _flatController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    setState(() => _isLoading = true);

    const String url = "http://10.0.2.2:8000/api/auth/register/";

    final Map<String, dynamic> registrationData = {
      "user_name": _nameController.text.trim(),
      "user_phone": _phoneController.text.trim(),
      "user_email": _emailController.text.trim(),
      "password": _passController.text,
      "society_id": selectedSocietyId,
      // For presentation safety, we pass the text entry flat mapped directly to your tables
      "flat_id": _flatController.text.trim().toUpperCase(),
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(registrationData),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          _showSnackBar("Profile registered successfully! OTP code generated.");
          Navigator.pushReplacementNamed(
            context,
            '/otp_verify',
            arguments: _emailController.text
                .trim(), // Passes tracking address context to OTP verification screen
          );
        }
      } else {
        if (mounted) {
          _showSnackBar(
            responseData['error'] ?? "Registration failed. Try again.",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          "Could not establish communication with backend API port.",
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.lexend(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final bool emailValid = RegExp(
      r"^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+",
    ).hasMatch(value);
    return emailValid ? null : "Enter a valid email format pattern";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SignUp',
                style: GoogleFonts.lexend(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 25),

              _buildField(
                "Full Name",
                Icons.person_outline,
                (v) => v!.isEmpty ? "Required field text missing" : null,
                controller: _nameController,
              ),
              _buildField(
                "Contact Number",
                Icons.phone_android,
                (v) => (v == null || v.length != 10)
                    ? "Requires a valid 10-digit phone"
                    : null,
                type: TextInputType.phone,
                maxLength: 10,
                controller: _phoneController,
              ),
              _buildField(
                "Email Address",
                Icons.email_outlined,
                _validateEmail,
                type: TextInputType.emailAddress,
                controller: _emailController,
              ),

              // --- Dynamic Society Dropdown ---
              _buildDropdown(
                label: "Select Society",
                icon: Icons.location_city,
                value: selectedSocietyId,
                items: societiesList.map((soc) {
                  return DropdownMenuItem<String>(
                    value: soc['id']?.toString(),
                    child: Text(soc['name']?.toString() ?? ''),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedSocietyId = val;
                    });
                    _loadDependentBlocks(
                      val,
                    ); // Dynamically queries blocks for this society
                  }
                },
              ),

              // --- Dynamic Block Dropdown ---
              _buildDropdown(
                label: "Select Block",
                icon: Icons.business,
                value: selectedBlockId,
                items: blocksList.map((blk) {
                  return DropdownMenuItem<String>(
                    value: blk['id']?.toString(),
                    child: Text(blk['name']?.toString() ?? ''),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedBlockId = val),
              ),

              _buildField(
                "Flat Number",
                Icons.door_front_door_outlined,
                (v) => v!.isEmpty ? "Required mapping missing" : null,
                controller: _flatController,
              ),
              _buildField(
                "Password",
                Icons.lock_outline,
                (v) => (v == null || v.isEmpty)
                    ? "Password configuration is required"
                    : null,
                isPass: true,
                controller: _passController,
              ),
              _buildField(
                "Confirm Password",
                Icons.lock_reset,
                (v) => v != _passController.text ? "Passwords mismatch" : null,
                isPass: true,
                controller: _confirmPassController,
              ),

              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            if (selectedSocietyId == null ||
                                selectedBlockId == null) {
                              _showSnackBar(
                                "Please specify structural residential attributes.",
                              );
                              return;
                            }
                            _registerUser();
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
                          'SignUp',
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildField(
    String label,
    IconData icon,
    String? Function(String?)? validator, {
    bool isPass = false,
    TextInputType type = TextInputType.text,
    int? maxLength,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: isPass,
        validator: validator,
        keyboardType: type,
        maxLength: maxLength,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryBlue, size: 20),
          labelText: label,
          counterText: "",
          labelStyle: GoogleFonts.inter(color: Colors.black38, fontSize: 13.5),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        validator: (v) => v == null ? "Selection required" : null,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryBlue, size: 20),
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.black38, fontSize: 13.5),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
          ),
        ),
      ),
    );
  }
}
