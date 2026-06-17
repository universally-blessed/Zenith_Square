import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/finance_api_services.dart'; // 🔄 Pointed to split finance service layer

class ChairmanMaintenancePaymentPage extends StatefulWidget {
  const ChairmanMaintenancePaymentPage({super.key});

  @override
  State<ChairmanMaintenancePaymentPage> createState() =>
      _ChairmanMaintenancePaymentPageState();
}

class _ChairmanMaintenancePaymentPageState
    extends State<ChairmanMaintenancePaymentPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";
  String _selectedMethod = 'UPI (GPay / PhonePe / BHIM)';

  bool _isLoading = true;
  bool _isProcessingPay = false;
  bool _hasNoBill = false;
  Map<String, dynamic> _billData = {};

  @override
  void initState() {
    super.initState();
    _loadChairmanBillingMetrics();
  }

  Future<void> _loadChairmanBillingMetrics() async {
    try {
      // 📊 Pulls outstanding due status vectors via split service module hooks
      final res = await FinanceApiService.fetchCurrentBill(_sessionToken);
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
    bool completed = await FinanceApiService.processBillPayment(
      _sessionToken,
      _billData['bill_id'] ?? '',
    );

    if (completed) {
      _showSnack("Transaction successful! Receipt saved.");
      _loadChairmanBillingMetrics();
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
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(
          'Personal Maintenance Due',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: primaryBlue.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: primaryBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Account Mode: Committee Chairman Household Unit',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        _buildBillRow(
                          'Invoice Reference',
                          _billData['bill_id'] ?? 'N/A',
                        ),
                        const SizedBox(height: 10),
                        _buildBillRow(
                          'Billing Cycle',
                          _billData['billing_period'] ?? 'N/A',
                        ),
                        const SizedBox(height: 10),
                        _buildBillRow(
                          'Payment Deadline',
                          _billData['due_date'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Select Payment Method',
                    style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildMethodTile(
                    Icons.qr_code_scanner_outlined,
                    'UPI (GPay / PhonePe / BHIM)',
                  ),
                  const SizedBox(height: 12),
                  _buildMethodTile(
                    Icons.credit_card_outlined,
                    'Credit / Debit Card',
                  ),
                  const SizedBox(height: 12),
                  _buildMethodTile(
                    Icons.account_balance_outlined,
                    'Net Banking Channels',
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isProcessingPay
                          ? null
                          : _handlePaymentExecution,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        disabledBackgroundColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessingPay
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Complete Secure Payment',
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.gpp_good_rounded,
                color: Colors.green.shade800,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Dues Pending',
              style: GoogleFonts.lexend(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your personal maintenance account ledger has been entirely cleared for this cycle.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.black45,
                fontSize: 12.5,
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
          style: GoogleFonts.inter(color: Colors.black54, fontSize: 13.5),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: darkText,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTile(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: RadioListTile<String>(
        value: title,
        groupValue: _selectedMethod,
        onChanged: (val) {
          if (val != null) setState(() => _selectedMethod = val);
        },
        activeColor: primaryBlue,
        title: Row(
          children: [
            Icon(icon, color: primaryBlue, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13.5,
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
