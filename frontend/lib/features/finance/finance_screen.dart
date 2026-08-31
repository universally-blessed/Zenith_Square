import 'package:flutter/material.dart';
import '../../data/datasource/finance_api_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Finance & Maintenance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () => Navigator.pushReplacementNamed(context,'/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Due Bill'),
            Tab(text: 'History'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PendingBillTab(),
          _PaymentHistoryTab(),
          _SocietyExpensesTab(),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: PENDING BILL & SETTLEMENT
// -------------------------------------------------------------
class _PendingBillTab extends StatefulWidget {
  const _PendingBillTab();

  @override
  State<_PendingBillTab> createState() => _PendingBillTabState();
}

class _PendingBillTabState extends State<_PendingBillTab> {
  late Future<Map<String, dynamic>> _billFuture;
  bool _isProcessingPayment = false;

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
        title: const Text('Confirm Settlement'),
        content: Text('Proceed to pay ₹$amount for this month maintenance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessingPayment = true);
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
      if (mounted) setState(() => _isProcessingPayment = false);
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
                ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          );
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
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                Text(
                  data['message'] ?? 'All maintenance dues are settled!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
                onPressed: _isProcessingPayment
                    ? null
                    : () => _handlePayment(
                        bill['bill_id'],
                        bill['payable_amount'].toString(),
                      ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blueAccent,
                ),
                child: _isProcessingPayment
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Pay Maintenance Now',
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
// TAB 2: PAYMENT HISTORY / RECEIPTS
// -------------------------------------------------------------
class _PaymentHistoryTab extends StatefulWidget {
  const _PaymentHistoryTab();

  @override
  State<_PaymentHistoryTab> createState() => _PaymentHistoryTabState();
}

class _PaymentHistoryTabState extends State<_PaymentHistoryTab> {
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = FinanceApiService.fetchPaymentHistory();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
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
    );
  }
}

// -------------------------------------------------------------
// TAB 3: SOCIETY SHARED EXPENSES
// -------------------------------------------------------------
class _SocietyExpensesTab extends StatefulWidget {
  const _SocietyExpensesTab();

  @override
  State<_SocietyExpensesTab> createState() => _SocietyExpensesTabState();
}

class _SocietyExpensesTabState extends State<_SocietyExpensesTab> {
  late Future<List<dynamic>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _expensesFuture = FinanceApiService.fetchSocietyExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
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
                leading: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.indigo,
                ),
                title: Text(
                  exp['expense_type'] ?? 'Expense',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(exp['description'] ?? 'No description provided'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${exp['amount']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
    );
  }
}
