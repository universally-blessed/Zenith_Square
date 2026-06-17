import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart'; // 🔄 Swapped dynamically to operational workspace module

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isProcessing = false;
  bool _isInitialized = false;

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final Map<String, dynamic>? initialData =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      _phoneController = TextEditingController(
        text: initialData?['phone'] ?? '',
      );
      _emailController = TextEditingController(
        text: initialData?['email'] ?? '',
      );
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleProfileMutation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    // 👤 Directly targeting OperationalApiService update routines
    final result = await OperationalApiService.updateProfileData(
      _sessionToken,
      _phoneController.text.trim(),
      _emailController.text.trim(),
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (result['success'] == true) {
        _showNotification(
          'Profile index properties updated successfully.',
          isError: false,
        );
        Navigator.pop(context, true);
      } else {
        _showNotification(
          result['error'] ?? 'Profile modernization failed.',
          isError: true,
        );
      }
    }
  }

  void _showNotification(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.lexend(fontSize: 13)),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Edit Profile Details',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          children: [
            Text(
              'Contact Verification Settings',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
              decoration: _inputDecoration(
                'User Contact Phone',
                Icons.phone_android_outlined,
              ),
              validator: (val) => (val == null || val.trim().length != 10)
                  ? 'Enter valid 10-digit mobile target string'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
              decoration: _inputDecoration(
                'Email Communication Destination',
                Icons.mail_outline_rounded,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Provide accurate verification address pattern';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleProfileMutation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Save Profile Updates',
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
      labelStyle: GoogleFonts.inter(fontSize: 13.5, color: Colors.black45),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }
}
