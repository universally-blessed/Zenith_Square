import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _tabController = TabController(length: 5, vsync: this);
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
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Ledger Summary'),
            Tab(text: 'Society Incomes'),
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
          _ChairmanIncomesTab(),
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
    if (!mounted) return;
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
// TAB 2: SOCIETY INCOMES (/income/ GET & POST)
// -------------------------------------------------------------
class _ChairmanIncomesTab extends StatefulWidget {
  const _ChairmanIncomesTab();

  @override
  State<_ChairmanIncomesTab> createState() => _ChairmanIncomesTabState();
}

class _ChairmanIncomesTabState extends State<_ChairmanIncomesTab> {
  late Future<List<dynamic>> _incomesFuture;

  @override
  void initState() {
    super.initState();
    _incomesFuture = FinanceApiService.fetchSocietyIncome();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _incomesFuture = FinanceApiService.fetchSocietyIncome();
    });
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  Future<void> _showAddIncomeModal() async {
    final formKey = GlobalKey<FormState>();
    final typeController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSubmitting = false;
    String? sheetError;

    await showModalBottomSheet<void>(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Record Society Income',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                    'Income Source / Category',
                    isRequired: true,
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: typeController,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Clubhouse Rent, Tower Rent, Scrap Sale',
                      counterText: '',
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Please enter income source';
                      if (val.length < 3)
                        return 'Title must be at least 3 characters';
                      if (!RegExp(r'[a-zA-Z]').hasMatch(val)) {
                        return 'Title cannot contain only numbers or symbols';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9\s\-/]+$').hasMatch(val)) {
                        return 'Title can only contain letters, numbers, hyphens, and spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Amount (₹)', isRequired: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                      hintText: '0.00',
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Please enter amount';
                      if (RegExp(r'[a-zA-Z]').hasMatch(val)) {
                        return 'Amount cannot contain letters';
                      }
                      final parsed = double.tryParse(val);
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Received Date', isRequired: true),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(
                      selectedDate.toIso8601String().substring(0, 10),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                      child: const Text('Change Date'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildFieldLabel('Description (Optional)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Receipt number, source details, or remarks...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (sheetError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 18,
                            color: Colors.red.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sheetError!,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() {
                              isSubmitting = true;
                              sheetError = null;
                            });

                            final type = typeController.text.trim();
                            final amount = double.parse(
                              amountController.text.trim(),
                            );
                            final desc = descController.text.trim();
                            final dateStr = selectedDate
                                .toIso8601String()
                                .substring(0, 10);

                            try {
                              await FinanceApiService.recordSocietyIncome(
                                incomeType: type,
                                amount: amount,
                                receivedDate: dateStr,
                                description: desc,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Income recorded successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _refresh();
                              }
                            } catch (e) {
                              setModalState(() {
                                isSubmitting = false;
                                sheetError = e.toString().replaceAll(
                                  'Exception: ',
                                  '',
                                );
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.teal.shade700,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Income',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    typeController.dispose();
    amountController.dispose();
    descController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<dynamic>>(
          future: _incomesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final incomes = snapshot.data ?? [];
            if (incomes.isEmpty) {
              return const Center(child: Text('No society incomes recorded.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: incomes.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final inc = incomes[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE0F2F1),
                      child: Icon(Icons.savings_outlined, color: Colors.teal),
                    ),
                    title: Text(
                      inc['income_type'] ?? 'Income',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      (inc['description'] != null &&
                              inc['description'].toString().isNotEmpty)
                          ? inc['description']
                          : 'No description provided',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+₹${inc['amount']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          inc['received_date'] ?? '',
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
        onPressed: _showAddIncomeModal,
        backgroundColor: Colors.teal.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Income', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 3: EXPENSES (/expenses/ GET & POST)
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
    if (!mounted) return;
    setState(() {
      _expensesFuture = FinanceApiService.fetchSocietyExpenses();
    });
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }

  Future<void> _showAddExpenseModal() async {
    final formKey = GlobalKey<FormState>();
    final typeController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSubmitting = false;
    String? sheetError;

    await showModalBottomSheet<void>(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Record Society Expense',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel(
                    'Expense Title / Category',
                    isRequired: true,
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: typeController,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText:
                          'e.g. Lift AMC, Water Tank Cleaning, Security Salary',
                      counterText: '',
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) {
                        return 'Please enter an expense category';
                      }
                      if (val.length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      if (!RegExp(r'[a-zA-Z]').hasMatch(val)) {
                        return 'Title cannot contain only numbers or symbols; letters are required';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9\s\-/]+$').hasMatch(val)) {
                        return 'Title can only contain letters, numbers, hyphens, and spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Amount (₹)', isRequired: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                      hintText: '0.00',
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Please enter amount';
                      if (RegExp(r'[a-zA-Z]').hasMatch(val)) {
                        return 'Amount cannot contain letters';
                      }
                      final parsed = double.tryParse(val);
                      if (parsed == null || parsed <= 0) {
                        return 'Enter an amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildFieldLabel('Payment Date', isRequired: true),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(
                      selectedDate.toIso8601String().substring(0, 10),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                      child: const Text('Change Date'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildFieldLabel('Description (Optional)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Vendor details, invoice number, or remarks...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (sheetError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 18,
                            color: Colors.red.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sheetError!,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() {
                              isSubmitting = true;
                              sheetError = null;
                            });

                            final type = typeController.text.trim();
                            final amount = double.parse(
                              amountController.text.trim(),
                            );
                            final desc = descController.text.trim();
                            final dateStr = selectedDate
                                .toIso8601String()
                                .substring(0, 10);

                            try {
                              await FinanceApiService.recordSocietyExpense(
                                expenseType: type,
                                amount: amount,
                                paymentDate: dateStr,
                                description: desc,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Expense recorded successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _refresh();
                              }
                            } catch (e) {
                              setModalState(() {
                                isSubmitting = false;
                                sheetError = e.toString().replaceAll(
                                  'Exception: ',
                                  '',
                                );
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Submit Expense',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    typeController.dispose();
    amountController.dispose();
    descController.dispose();
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
// TAB 4: DUE BILL & SETTLEMENT (/bill/latest/ & /bill/pay/)
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
    if (!mounted) return;
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
// TAB 5: PAYMENT HISTORY RECEIPTS (/payment/history/)
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
    if (!mounted) return;
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
