import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SocietyExpenseReportPage extends StatelessWidget {
  const SocietyExpenseReportPage({super.key});

  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Expense Transparency',
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master Financial Summary Card (Data matches Presentation Page 78 metrics)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Outflow (March 2026)',
                    style: GoogleFonts.inter(
                      color: Colors.black45,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ 50,000.00', // Matches PPT Page 78 Total Expenses perfectly
                    style: GoogleFonts.lexend(
                      color: primaryBlue,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, thickness: 0.8),
                  ),

                  // Visual Budget Distribution Bars (UI/UX Best Practice for Scannability)
                  Text(
                    'Fund Allocation Breakdown',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildBudgetProgressRow(
                    'Staff Salaries',
                    25000,
                    50000,
                    Colors.indigo,
                  ), // 50% allocation
                  _buildBudgetProgressRow(
                    'Electricity',
                    11000,
                    50000,
                    Colors.amber.shade700,
                  ), // 22% allocation
                  _buildBudgetProgressRow(
                    'Routine Maintenance',
                    5400,
                    50000,
                    Colors.green,
                  ), // 10.8% allocation
                  _buildBudgetProgressRow(
                    'Water Utility Bills',
                    4800,
                    50000,
                    Colors.blue,
                  ), // 9.6% allocation
                  _buildBudgetProgressRow(
                    'General Repairs',
                    3800,
                    50000,
                    Colors.red.shade600,
                  ), // 7.6% allocation
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'Transactional Ledger',
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 14),

            // Item Ledger list conforming to your society_expenses database layout properties
            _buildExpenseLedgerItem(
              type: 'Staff Salaries',
              description:
                  'Security guard cell, sweepers, and supervisor payroll payouts.',
              amount: '₹25,000.00',
              date: '2026-03-31',
              icon: Icons.badge_outlined,
              iconBgColor: Colors.indigo.shade50,
              iconColor: Colors.indigo,
            ),
            const SizedBox(height: 12),
            _buildExpenseLedgerItem(
              type: 'Electricity',
              description:
                  'Common area lightning grid & elevator shaft transformer bills.',
              amount: '₹11,000.00',
              date: '2026-04-01',
              icon: Icons.electric_bolt_outlined,
              iconBgColor: Colors.amber.shade50,
              iconColor: Colors.amber.shade800,
            ),
            const SizedBox(height: 12),
            _buildExpenseLedgerItem(
              type: 'Repairs',
              description:
                  'Main overhead water pump impeller core replacement.',
              amount: '₹3,800.00',
              date: '2026-03-15',
              icon: Icons.handyman_outlined,
              iconBgColor: Colors.red.shade50,
              iconColor: Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetProgressRow(
    String label,
    double count,
    double total,
    Color barColor,
  ) {
    double percent = count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${count.toInt()} (${(percent * 100).toStringAsFixed(1)}%)',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseLedgerItem({
    required String type,
    required String description,
    required String amount,
    required String date,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    Text(
                      amount,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cleared on: $date',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
