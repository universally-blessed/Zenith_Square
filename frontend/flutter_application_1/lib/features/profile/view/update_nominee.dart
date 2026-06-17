import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart'; // 🔄 Linked to split operational api wrapper

class UpdateNomineePageContent extends StatefulWidget {
  const UpdateNomineePageContent();

  @override
  State<UpdateNomineePageContent> createState() =>
      UpdateNomineePageContentState();
}

class UpdateNomineePageContentState extends State<UpdateNomineePageContent> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isInitLoading = true;
  bool _isProcessing = false;

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  @override
  void initState() {
    super.initState();
    _loadExistingNomineeRow();
  }

  Future<void> _loadExistingNomineeRow() async {
    try {
      final data = await OperationalApiService.fetchNomineeDetails(
        _sessionToken,
      );
      if (data['no_nominee'] == false) {
        _nameController.text = data['nominee_name'] ?? '';
        _relationController.text = data['relation'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
      }
    } catch (_) {
      _showNotification(
        "Failed to resolve existing historical nominee rows.",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isInitLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _commitNomineeChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    bool success =
        await OperationalApiService.saveNomineeDetails(_sessionToken, {
          'nominee_name': _nameController.text.trim(),
          'relation': _relationController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
        });

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        _showNotification(
          "Nominee records successfully synchronized.",
          isError: false,
        );
        Navigator.pop(context, true);
      } else {
        _showNotification(
          "Server rejected nominee row transaction updates.",
          isError: true,
        );
      }
    }
  }

  void _showNotification(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.lexend(fontSize: 13)),
        backgroundColor: isError ? Colors.red.shade800 : primaryBlue,
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
          'Manage Nominee Details',
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
      body: _isInitLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    'Nominee Association & Emergency Core',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                    decoration: _inputDecoration(
                      'Nominee Legal Full Name',
                      Icons.person_outline_rounded,
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _relationController,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                    decoration: _inputDecoration(
                      'Relationship (e.g., Spouse, Father)',
                      Icons.family_restroom_rounded,
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'Relationship description required'
                        : null,
                  ),
                  const SizedBox(height: 16),
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
                      'Emergency Mobile Contact',
                      Icons.phone_android_outlined,
                    ),
                    validator: (val) => (val == null || val.trim().length != 10)
                        ? 'Enter a valid 10-digit number'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: darkText,
                    ),
                    decoration: _inputDecoration(
                      'Permanent Residential Address',
                      Icons.home_work_outlined,
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'Address parameter required'
                        : null,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _commitNomineeChanges,
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
                              'Save Nominee Logs',
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
      counterText: "",
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
      labelStyle: GoogleFonts.inter(fontSize: 13.5, color: Colors.black45),
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
    );
  }
}
