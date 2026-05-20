import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- Controllers for extracting user text input ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  static const Color primaryBlue = Color(0xFF1A237E);

  // --- Dropdown Data ---
  String? selectedSociety;
  String? selectedBlock;

  // Mock data (Can be populated dynamically via a GET request later)
  final Map<String, List<String>> societyData = {
    "Skyline Residency": ["Block A", "Block B", "Block C"],
    "Green Valley": ["Wing 1", "Wing 2"],
    "Zenith Heights": ["Phase I", "Phase II", "Phase III"],
  };

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _flatController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- API Integration Method ---
  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
    });

    // Replace with your local machine IP or 10.0.2.2 for Android Emulator
    const String url = "http://127.0.0.1:8000/api/register/";

    // Inside registration_page.dart -> _registerUser()
    final Map<String, dynamic> registrationData = {
      "full_name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "contact_number": _phoneController.text
          .trim(), // Matches backend models.py
      "society_name": selectedSociety, // Update key name to match models.py
      "block_name": selectedBlock, // Update key name to match models.py
      "flat_number": _flatController.text.trim(),
      "password": _passController.text,
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

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pushNamed(
          context,
          '/otp_verify',
          arguments: _emailController.text.trim(), // Pass the email here
        );
      } else {
        // Handle backend validations/errors (e.g., email already exists)
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        _showSnackBar(
          errorData['message'] ?? "Registration failed. Try again.",
        );
      }
    } catch (e) {
      _showSnackBar("Could not connect to server. Check your network.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Validation Logic ---
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email is required";
    final bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(value);
    return emailValid ? null : "Enter a valid email (e.g. name@gmail.com)";
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 8) return "Must be at least 8 characters";
    if (!RegExp(r'[A-Z]').hasMatch(value))
      return "Must contain an uppercase letter";
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value))
      return "Must contain a special character";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
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
                (v) => v!.isEmpty ? "Required" : null,
                controller: _nameController,
              ),
              _buildField(
                "Contact Number",
                Icons.phone_android,
                (v) => v!.isEmpty ? "Required" : null,
                type: TextInputType.phone,
                controller: _phoneController,
              ),
              _buildField(
                "Email",
                Icons.email_outlined,
                _validateEmail,
                type: TextInputType.emailAddress,
                controller: _emailController,
              ),

              // --- Society Dropdown ---
              _buildDropdown(
                label: "Select Society",
                icon: Icons.location_city,
                value: selectedSociety,
                items: societyData.keys.toList(),
                onChanged: (val) {
                  setState(() {
                    selectedSociety = val;
                    selectedBlock = null;
                  });
                },
              ),

              // --- Block Dropdown (Dependent) ---
              _buildDropdown(
                label: "Select Block",
                icon: Icons.business,
                value: selectedBlock,
                items: selectedSociety != null
                    ? societyData[selectedSociety]!
                    : [],
                onChanged: (val) => setState(() => selectedBlock = val),
              ),

              _buildField(
                "Flat Number",
                Icons.door_front_door_outlined,
                (v) => v!.isEmpty ? "Required" : null,
                type: TextInputType.number,
                controller: _flatController,
              ),

              // --- Password Fields ---
              _buildField(
                "Password",
                Icons.lock_outline,
                _validatePassword,
                isPass: true,
                controller: _passController,
              ),
              _buildField(
                "Confirm Password",
                Icons.lock_reset,
                (v) =>
                    v != _passController.text ? "Passwords do not match" : null,
                isPass: true,
                controller: _confirmPassController,
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
                            if (selectedSociety == null ||
                                selectedBlock == null) {
                              _showSnackBar("Please select Society and Block");
                              return;
                            }
                            _registerUser();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SignUp',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for Input Fields
  Widget _buildField(
    String label,
    IconData icon,
    String? Function(String?)? validator, {
    bool isPass = false,
    TextInputType type = TextInputType.text,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: isPass,
        validator: validator,
        keyboardType: type,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryBlue, size: 20),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Helper for Dropdowns
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? "Required" : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryBlue, size: 20),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
