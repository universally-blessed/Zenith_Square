import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateNomineePage extends StatefulWidget {
  const UpdateNomineePage({super.key});

  @override
  State<UpdateNomineePage> createState() => _UpdateNomineePageState();
}

class _UpdateNomineePageState extends State<UpdateNomineePage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Priya Shah');
  final _relationController = TextEditingController(text: 'Spouse');
  final _phoneController = TextEditingController(text: '9876543211');
  final _addressController = TextEditingController(
    text: 'Satellite Road, Ahmedabad',
  );

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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'Nominee Association & Emergency Core',
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(
                'Nominee Legal Full Name',
                Icons.person_outline_rounded,
              ),
              validator: (val) =>
                  (val == null || val.isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _relationController,
              decoration: _inputDecoration(
                'Relationship (e.g., Spouse, Father)',
                Icons.family_restroom_rounded,
              ),
              validator: (val) => (val == null || val.isEmpty)
                  ? 'Relationship is required'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: _inputDecoration(
                'Emergency Mobile Contact',
                Icons.phone_android_outlined,
              ),
              validator: (val) => (val == null || val.length != 10)
                  ? 'Enter a valid 10-digit number'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: _inputDecoration(
                'Permanent Residential Address',
                Icons.home_work_outlined,
              ),
              validator: (val) =>
                  (val == null || val.isEmpty) ? 'Address is required' : null,
            ),
            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Nominee details successfully synchronized with relational database metrics.',
                          style: GoogleFonts.lexend(fontSize: 13),
                        ),
                        backgroundColor: primaryBlue,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
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
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
