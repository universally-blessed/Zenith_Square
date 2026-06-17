import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/finance_api_services.dart'; // 🔄 Swapped to split finance layout worker

class ChairmanFinancialSummaryPage extends StatefulWidget {
  const ChairmanFinancialSummaryPage({super.key});

  @override
  State<ChairmanFinancialSummaryPage> createState() =>
      _ChairmanFinancialSummaryPageState();
}

class _ChairmanFinancialSummaryPageState
    extends State<ChairmanFinancialSummaryPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color emeraldGreen = Color(0xFF2E7D32);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";
  List<dynamic> _reconciledTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveInboundLedger();
  }

  /// Pulls real-time payment reconciliation histories across all blocks
  Future<void> _loadLiveInboundLedger() async {
    try {
      final data = await FinanceApiService.fetchGlobalInboundLedger(
        _sessionToken,
      );
      if (mounted) {
        setState(() {
          _reconciledTransactions = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to align global treasury metrics vectors."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: Text(
          'Society Financial Ledger',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
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
          : RefreshIndicator(
              onRefresh: _loadLiveInboundLedger,
              color: primaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Audit Control Summary',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Below is the cross-verified stream of online payments and physical instruments processed and closed by the committee treasury.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.black45,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _reconciledTransactions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 80.0),
                            child: Text(
                              'No reconciled transaction rows found.',
                              style: GoogleFonts.inter(
                                color: Colors.black38,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reconciledTransactions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final tx = _reconciledTransactions[index];
                            bool isOnline = tx['method']
                                .toString()
                                .toUpperCase()
                                .contains('ONLINE');
                            double amt =
                                double.tryParse(tx['amount'].toString()) ?? 0.0;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tx['receipt_no'] ?? 'REC-UNK',
                                        style: GoogleFonts.lexend(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: primaryBlue,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOnline
                                              ? Colors.blue.shade50
                                              : Colors.purple.shade50,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          tx['method'] ?? 'UPI',
                                          style: GoogleFonts.lexend(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isOnline
                                                ? Colors.blue.shade800
                                                : Colors.purple.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10.0,
                                    ),
                                    child: Divider(height: 1, thickness: 0.5),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Unit Focus: ${tx['unit'] ?? 'Unassigned Wing'}',
                                              style: GoogleFonts.lexend(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: darkText,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Settle Date: ${tx['date'] ?? 'Recent'} • Status: ${tx['status'] ?? 'SUCCESS'}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11.5,
                                                color: emeraldGreen,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '₹ ${amt.toStringAsFixed(0)}',
                                        style: GoogleFonts.lexend(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: darkText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
