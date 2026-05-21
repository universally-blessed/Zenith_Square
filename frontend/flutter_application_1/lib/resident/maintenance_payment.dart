import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_services.dart';

class MaintenancePaymentPage extends StatefulWidget {
  const MaintenancePaymentPage({super.key});

  @override
  State<MaintenancePaymentPage> createState() => _MaintenancePaymentPageState();
}

class _MaintenancePaymentPageState extends State<MaintenancePaymentPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";
  String _selectedMethod = 'UPI (GPay / PhonePe)';

  bool _isLoading = true;
  bool _isProcessingPay = false;
  bool _hasNoBill = false;

  Map<String, dynamic> _billData = {};

  @override
  void initState() {
    super.initState();
    _loadBillingMetrics();
  }

  Future<void> _loadBillingMetrics() async {
    try {
      final res = await ApiService.fetchCurrentBill(_sessionToken);
      setState(() {
        if (res['no_bill'] == true) {
          _hasNoBill = true;
        } else {
          _billData = res;
          _hasNoBill = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Failed to fetch billing ledger variables.");
    }
  }

  Future<void> _handlePaymentExecution() async {
    setState(() => _isProcessingPay = true);

    bool completed = await ApiService.processBillPayment(
      _sessionToken,
      _billData['bill_id'] ?? '',
    );

    if (completed) {
      _showSnack("Transaction successful! Receipt generated.");
      _loadBillingMetrics(); // Reload to capture the settled state cleanly
    } else {
      _showSnack("Payment gateway transaction error.");
    }
    setState(() => _isProcessingPay = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.lexend(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _hasNoBill
          ? _buildZeroOutstandingPlaceholder()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic Bill Summary Card reading parameters out of the active database rows
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.08),
                      ),
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
                          '₹ ${(_billData['amount'] ?? 0.0).toStringAsFixed(2)}',
                          style: GoogleFonts.lexend(
                            color: primaryBlue,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 30, thickness: 1),
                        _buildBillRow('Bill ID', _billData['bill_id'] ?? 'N/A'),
                        const SizedBox(height: 10),
                        _buildBillRow(
                          'Billing Period',
                          _billData['billing_period'] ?? 'N/A',
                        ),
                        const SizedBox(height: 10),
                        _buildBillRow(
                          'Due Date',
                          _billData['due_date'] ?? 'N/A',
                        ),
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
                  _buildMethodTile(
                    Icons.credit_card_outlined,
                    'Credit / Debit Card',
                  ),
                  const SizedBox(height: 12),
                  _buildMethodTile(
                    Icons.account_balance_outlined,
                    'Net Banking',
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isProcessingPay
                          ? null
                          : _handlePaymentExecution,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        disabledBackgroundColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isProcessingPay
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Proceed to Pay ₹${(_billData['amount'] ?? 0.0).toStringAsFixed(2)}',
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

  Widget _buildZeroOutstandingPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.gpp_good_rounded,
                color: Colors.green.shade800,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Outstanding Dues',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All your maintenance invoice tracks have been completely cleared for this cycle.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.black45,
                fontSize: 13,
                height: 1.4,
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
      child: RadioListTile<String>(
        value: title,
        // ignore: deprecated_member_use
        groupValue: _selectedMethod,
        // ignore: deprecated_member_use
        onChanged: (val) {
          if (val != null) setState(() => _selectedMethod = val);
        },
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
