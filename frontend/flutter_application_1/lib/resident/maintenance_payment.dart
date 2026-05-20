// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaintenancePaymentPage extends StatelessWidget {
  const MaintenancePaymentPage({super.key});

  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Maintenance Payment',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Summary Card matching maintenance_bill SQL fields
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Outstanding',
                    style: GoogleFonts.inter(
                      color: Colors.black45,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ 2,500.00',
                    style: GoogleFonts.lexend(
                      color: primaryBlue,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ), // Example value from PPT [cite: 768]
                  const Divider(height: 30, thickness: 1),
                  _buildBillRow(
                    'Bill ID',
                    'MB001',
                  ), // Matches your Data Dictionary fields [cite: 768]
                  const SizedBox(height: 10),
                  _buildBillRow('Billing Period', 'March 2026'),
                  const SizedBox(height: 10),
                  _buildBillRow('Due Date', '2026-03-31'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Select Payment Method',
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 16),
            _buildMethodTile(
              Icons.qr_code_scanner_outlined,
              'UPI (GPay / PhonePe)',
            ),
            const SizedBox(height: 12),
            _buildMethodTile(Icons.credit_card_outlined, 'Credit / Debit Card'),
            const SizedBox(height: 12),
            _buildMethodTile(Icons.account_balance_outlined, 'Net Banking'),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed:
                    () {}, // Triggers your Sequence Flow to the Payment Gateway [cite: 573]
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Proceed to Pay ₹2,500.00',
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: darkText,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTile(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: RadioListTile(
        value: title,
        groupValue: 'UPI (GPay / PhonePe)', // Standard mock state
        onChanged: (val) {},
        activeColor: primaryBlue,
        title: Row(
          children: [
            Icon(icon, color: primaryBlue, size: 22),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
