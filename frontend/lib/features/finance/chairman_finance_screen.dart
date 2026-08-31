import 'package:flutter/material.dart';
import '../../data/datasource/finance_api_service.dart';

class ChairmanFinanceScreen extends StatefulWidget {
  const ChairmanFinanceScreen({super.key});

  @override
  State<ChairmanFinanceScreen> createState() => _ChairmanFinanceScreenState();
}

class _ChairmanFinanceScreenState extends State<ChairmanFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treasury & Maintenance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/chairman-home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Ledger Summary'),
            Tab(text: 'Society Expenses'),
            Tab(text: 'My Unit Due'),
            Tab(text: 'Payment Receipts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FinancialSummaryTab(),
          _ChairmanExpensesTab(),
          _ChairmanPersonalDueTab(),
          _ChairmanPaymentHistoryTab(),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: SUMMARY (/summary/)
// -------------------------------------------------------------
class _FinancialSummaryTab extends StatefulWidget {
  const _FinancialSummaryTab();

  @override
  State<_FinancialSummaryTab> createState() => _FinancialSummaryTabState();
}

class _FinancialSummaryTabState extends State<_FinancialSummaryTab> {
  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = FinanceApiService.fetchFinancialSummary();
  }

  void _refresh() {
    setState(() {
      _summaryFuture = FinanceApiService.fetchFinancialSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final totalCollected = data['total_collected'] ?? 0.0;
          final totalPending = data['total_pending'] ?? 0.0;
          final totalExpenses = data['total_expenses'] ?? 0.0;
          final netBalance = data['net_balance'] ?? 0.0;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                elevation: 0,
                color: Colors.blueGrey.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Society Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${netBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Inflow',
                      '₹${totalCollected.toStringAsFixed(2)}',
                      Icons.arrow_downward,
                      Colors.green.shade700,
                      Colors.green.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Total Outflow',
                      '₹${totalExpenses.toStringAsFixed(2)}',
                      Icons.arrow_upward,
                      Colors.red.shade700,
                      Colors.red.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                'Uncollected Pending Maintenance',
                '₹${totalPending.toStringAsFixed(2)}',
                Icons.pending_actions,
                Colors.orange.shade800,
                Colors.orange.shade50,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 2: EXPENSES (/expenses/ GET & POST)
// -------------------------------------------------------------
class _ChairmanExpensesTab extends StatefulWidget {
  const _ChairmanExpensesTab();

  @override
  State<_ChairmanExpensesTab> createState() => _ChairmanExpensesTabState();
}

class _ChairmanExpensesTabState extends State<_ChairmanExpensesTab> {
  late Future<List<dynamic>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _expensesFuture = FinanceApiService.fetchSocietyExpenses();
  }

  void _refresh() {
    setState(() {
      _expensesFuture = FinanceApiService.fetchSocietyExpenses();
    });
  }

  void _showAddExpenseModal() {
    final formKey = GlobalKey<FormState>();
    final typeController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Record Society Expense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'Expense Title / Category',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Lift AMC, Water Tank Cleaning',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter title'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter amount';
                    if (double.tryParse(v.trim()) == null)
                      return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text(
                    'Payment Date: ${selectedDate.toIso8601String().substring(0, 10)}',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: const Text('Change'),
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    try {
                      await FinanceApiService.recordSocietyExpense(
                        expenseType: typeController.text.trim(),
                        amount: double.parse(amountController.text.trim()),
                        paymentDate: selectedDate.toIso8601String().substring(
                          0,
                          10,
                        ),
                        description: descController.text.trim(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Expense recorded successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _refresh();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Submit Expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<dynamic>>(
          future: _expensesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final expenses = snapshot.data ?? [];
            if (expenses.isEmpty) {
              return const Center(child: Text('No society expenses recorded.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: expenses.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final exp = expenses[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEDE7F6),
                      child: Icon(
                        Icons.receipt_outlined,
                        color: Colors.deepPurple,
                      ),
                    ),
                    title: Text(
                      exp['expense_type'] ?? 'Expense',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      (exp['description'] != null &&
                              exp['description'].toString().isNotEmpty)
                          ? exp['description']
                          : 'No description provided',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${exp['amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.redAccent,
                          ),
                        ),
                        Text(
                          exp['payment_date'] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseModal,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 3: DUE BILL & SETTLEMENT (/bill/latest/ & /bill/pay/)
// -------------------------------------------------------------
class _ChairmanPersonalDueTab extends StatefulWidget {
  const _ChairmanPersonalDueTab();

  @override
  State<_ChairmanPersonalDueTab> createState() =>
      _ChairmanPersonalDueTabState();
}

class _ChairmanPersonalDueTabState extends State<_ChairmanPersonalDueTab> {
  late Future<Map<String, dynamic>> _billFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _billFuture = FinanceApiService.fetchLatestBill();
  }

  void _refresh() {
    setState(() {
      _billFuture = FinanceApiService.fetchLatestBill();
    });
  }

  Future<void> _handlePayment(String billId, String amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Settle maintenance payment of ₹$amount?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final res = await FinanceApiService.payBill(billId, method: 'ONLINE');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Payment completed!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _billFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};
        final hasPending = data['has_pending_bill'] ?? false;
        final bill = data['bill'];

        if (!hasPending || bill == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 56,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                Text(
                  data['message'] ?? 'Your unit maintenance is up to date!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bill['bill_month'] ?? 'Maintenance',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'UNPAID',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        'Unit: ${bill['block_name']} - ${bill['flat_number']}',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due Date: ${bill['due_date']}',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹${bill['payable_amount']}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () => _handlePayment(
                        bill['bill_id'],
                        bill['payable_amount'].toString(),
                      ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blueAccent,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Settle Maintenance',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// TAB 4: PAYMENT HISTORY RECEIPTS (/payment/history/)
// -------------------------------------------------------------
class _ChairmanPaymentHistoryTab extends StatefulWidget {
  const _ChairmanPaymentHistoryTab();

  @override
  State<_ChairmanPaymentHistoryTab> createState() =>
      _ChairmanPaymentHistoryTabState();
}

class _ChairmanPaymentHistoryTabState
    extends State<_ChairmanPaymentHistoryTab> {
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = FinanceApiService.fetchPaymentHistory();
  }

  void _refresh() {
    setState(() {
      _historyFuture = FinanceApiService.fetchPaymentHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return const Center(
              child: Text('No previous payment receipts found.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: history.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final item = history[i];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.greenAccent,
                    child: Icon(Icons.check, color: Colors.green),
                  ),
                  title: Text(
                    '${item['bill_month'] ?? 'Maintenance'} - ₹${item['amount']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Receipt: ${item['receipt_number']}\nMethod: ${item['payment_method']}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    item['payment_date'] != null
                        ? item['payment_date'].toString().substring(0, 10)
                        : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
