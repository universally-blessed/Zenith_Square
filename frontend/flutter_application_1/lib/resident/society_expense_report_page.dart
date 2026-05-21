import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_services.dart';

class SocietyExpenseReportPage extends StatefulWidget {
  const SocietyExpenseReportPage({super.key});

  @override
  State<SocietyExpenseReportPage> createState() =>
      _SocietyExpenseReportPageState();
}

class _SocietyExpenseReportPageState extends State<SocietyExpenseReportPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  List<dynamic> _expenseLedger = [];
  bool _isLoading = true;
  double _totalOutflow = 0.0;

  // Visual categorization allocations map tracking weights programmatically
  final Map<String, double> _categoryTotals = {};

  @override
  void initState() {
    super.initState();
    _loadExpensesMetrics();
  }

  Future<void> _loadExpensesMetrics() async {
    try {
      final List<dynamic> data = await ApiService.fetchSocietyExpenses(
        _sessionToken,
      );

      double calculatedSum = 0.0;
      final Map<String, double> tempCategorySums = {};

      for (var item in data) {
        // Safe casting parse handling alternative numeric schema string structures
        double amount = double.tryParse(item['amount'].toString()) ?? 0.0;
        calculatedSum += amount;

        String rawType = item['expense_type'] ?? 'Other';
        tempCategorySums[rawType] = (tempCategorySums[rawType] ?? 0.0) + amount;
      }

      setState(() {
        _expenseLedger = data;
        _totalOutflow = calculatedSum;
        _categoryTotals.clear();
        _categoryTotals.addAll(tempCategorySums);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to compile financial ledger vectors."),
        ),
      );
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadExpensesMetrics,
              color: primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Financial Summary Card reading metrics straight from PostgreSQL
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Outflow Balance Track',
                            style: GoogleFonts.inter(
                              color: Colors.black45,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹ ${_totalOutflow.toStringAsFixed(2)}',
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

                          Text(
                            'Fund Allocation Breakdown',
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 14),

                          _categoryTotals.isEmpty
                              ? Text(
                                  'No breakdown variables registered.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.black38,
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _categoryTotals.length,
                                  itemBuilder: (context, index) {
                                    String categoryKey = _categoryTotals.keys
                                        .elementAt(index);
                                    double count =
                                        _categoryTotals[categoryKey] ?? 0.0;
                                    return _buildBudgetProgressRow(
                                      categoryKey,
                                      count,
                                      _totalOutflow,
                                      _getCategoryColor(categoryKey),
                                    );
                                  },
                                ),
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

                    _expenseLedger.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40.0),
                              child: Text(
                                'No expense transactions posted.',
                                style: GoogleFonts.inter(color: Colors.black38),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _expenseLedger.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final expense = _expenseLedger[index];
                              String expenseType =
                                  expense['expense_type'] ?? 'General';
                              double parsedAmount =
                                  double.tryParse(
                                    expense['amount'].toString(),
                                  ) ??
                                  0.0;

                              return _buildExpenseLedgerItem(
                                type: expenseType,
                                description:
                                    expense['description'] ??
                                    'No transaction detail provided.',
                                amount: '₹${parsedAmount.toStringAsFixed(2)}',
                                date: expense['payment_date'] ?? 'Recent',
                                icon: _getCategoryIcon(expenseType),
                                iconColor: _getCategoryColor(expenseType),
                              );
                            },
                          ),
                  ],
                ),
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
    double percent = total > 0 ? (count / total) : 0.0;
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
              color: iconColor.withValues(alpha: 0.08),
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

  // Helper Utility: Mapping clean styling colors on the fly based on SQL content parameters
  Color _getCategoryColor(String type) {
    switch (type.toLowerCase().trim()) {
      case 'staff salaries':
        return Colors.indigo;
      case 'electricity':
        return Colors.amber.shade700;
      case 'routine maintenance':
        return Colors.green;
      case 'water utility bills':
        return Colors.blue;
      case 'repairs':
      case 'general repairs':
        return Colors.red.shade600;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String type) {
    switch (type.toLowerCase().trim()) {
      case 'staff salaries':
        return Icons.badge_outlined;
      case 'electricity':
        return Icons.electric_bolt_outlined;
      case 'routine maintenance':
        return Icons.assignment_outlined;
      case 'water utility bills':
        return Icons.water_drop_outlined;
      case 'repairs':
      case 'general repairs':
        return Icons.handyman_outlined;
      default:
        return Icons.insert_chart_outlined_rounded;
    }
  }
}
