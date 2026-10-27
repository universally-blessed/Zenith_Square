import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasource/finance_api_service.dart';
import 'widgets/financial_document_helper.dart';

class TreasurerFinanceScreen extends StatefulWidget {
  final int initialTabIndex;
  const TreasurerFinanceScreen({super.key, this.initialTabIndex = 0});

  @override
  State<TreasurerFinanceScreen> createState() => _TreasurerFinanceScreenState();
}

class _TreasurerFinanceScreenState extends State<TreasurerFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
        title: const Text('Treasurer Financial Desk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.blueAccent,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Ledger Summary'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Maintenance Bills'),
            Tab(icon: Icon(Icons.savings_outlined), text: 'Society Income'),
            Tab(icon: Icon(Icons.verified_outlined), text: 'Offline Verification'),
            Tab(icon: Icon(Icons.money_off_outlined), text: 'Expenses & Utilities'),
            Tab(icon: Icon(Icons.history_outlined), text: 'Payment Receipts'),
            Tab(icon: Icon(Icons.account_balance_outlined), text: 'Bank Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LedgerSummaryTab(),
          _MaintenanceBillsTab(),
          _SocietyIncomeTab(),
          _OfflineVerificationTab(),
          _ExpensesAndUtilitiesTab(),
          _PaymentReceiptsTab(),
          _BankDetailsTab(),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: LEDGER SUMMARY
// -------------------------------------------------------------
class _LedgerSummaryTab extends StatefulWidget {
  const _LedgerSummaryTab();

  @override
  State<_LedgerSummaryTab> createState() => _LedgerSummaryTabState();
}

class _LedgerSummaryTabState extends State<_LedgerSummaryTab> {
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
              child: Text(
                'Error: ${snapshot.error.toString().replaceAll('Exception: ', '')}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final netBalance = (data['net_balance'] ?? 0.0).toDouble();
          final totalCollected = (data['total_collected'] ?? 0.0).toDouble();
          final totalPending = (data['total_pending'] ?? 0.0).toDouble();
          final totalExpenses = (data['total_expenses'] ?? 0.0).toDouble();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Main Balance Hero Card
              Card(
                elevation: 2,
                color: Colors.blue.shade900,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Net Treasury Balance',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Live from DB',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${netBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Total Inflow minus Outflow',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // KPI Grid
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      'Total Inflow',
                      '₹${totalCollected.toStringAsFixed(2)}',
                      Icons.arrow_downward,
                      Colors.green.shade700,
                      Colors.green.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      'Total Expenses',
                      '₹${totalExpenses.toStringAsFixed(2)}',
                      Icons.arrow_upward,
                      Colors.red.shade700,
                      Colors.red.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _metricCard(
                'Total Pending Maintenance',
                '₹${totalPending.toStringAsFixed(2)}',
                Icons.hourglass_top,
                Colors.orange.shade800,
                Colors.orange.shade50,
              ),

              const SizedBox(height: 24),
              const Text(
                'Treasurer Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        // Switch to maintenance bills tab
                        final parent = context.findAncestorStateOfType<_TreasurerFinanceScreenState>();
                        parent?._tabController.animateTo(1);
                      },
                      icon: const Icon(Icons.add_card, size: 18),
                      label: const Text('Generate Bills'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        // Switch to offline verification tab
                        final parent = context.findAncestorStateOfType<_TreasurerFinanceScreenState>();
                        parent?._tabController.animateTo(2);
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Verify Offline'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.indigo.shade900,
                    side: BorderSide(color: Colors.indigo.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/chairman-reports'),
                  icon: const Icon(Icons.insert_chart_outlined, size: 18),
                  label: const Text('View Financial Analytics & Executive Reports', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 2: MAINTENANCE BILLS (COMPONENT 1 & 2)
// -------------------------------------------------------------
class _MaintenanceBillsTab extends StatefulWidget {
  const _MaintenanceBillsTab();

  @override
  State<_MaintenanceBillsTab> createState() => _MaintenanceBillsTabState();
}

class _MaintenanceBillsTabState extends State<_MaintenanceBillsTab> {
  late Future<List<dynamic>> _billsFuture;
  String _filter = 'ALL'; // ALL, PENDING, PAID
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _billsFuture = FinanceApiService.fetchAllBills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _billsFuture = FinanceApiService.fetchAllBills();
    });
  }

  void _showGenerateDialog() {
    final monthController = TextEditingController(
      text: '${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
    );
    final dueDateController = TextEditingController(
      text: DateTime.now().add(const Duration(days: 15)).toString().substring(0, 10),
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Generate Monthly Bills'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This will auto-calculate and generate maintenance bills for every flat in the society from the configured rate.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: monthController,
                  decoration: const InputDecoration(
                    labelText: 'Billing Month (e.g. November 2026)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dueDateController,
                  decoration: const InputDecoration(
                    labelText: 'Due Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setModalState(() => isSubmitting = true);
                      try {
                        final res = await FinanceApiService.generateBills(
                          billMonth: monthController.text.trim(),
                          dueDate: dueDateController.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green,
                              content: Text(res['message'] ?? 'Bills generated successfully!'),
                            ),
                          );
                          _refresh();
                        }
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Generate Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search Bar (Resident Name & Flat wise)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by resident name or flat (e.g. Aarav, 101)...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              isDense: true,
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val.trim().toLowerCase());
            },
          ),
        ),

        // 2. Filter bar (All, Pending, Paid) & Generate button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ALL', label: Text('All')),
                    ButtonSegment(value: 'PENDING', label: Text('Pending')),
                    ButtonSegment(value: 'PAID', label: Text('Paid')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (set) {
                    setState(() => _filter = set.first);
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                icon: const Icon(Icons.add),
                tooltip: 'Generate Bills',
                onPressed: _showGenerateDialog,
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: FutureBuilder<List<dynamic>>(
              future: _billsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allBills = snapshot.data ?? [];
                final bills = allBills.where((b) {
                  // Status filter
                  if (_filter != 'ALL') {
                    final status = (b['status'] ?? '').toString().toUpperCase();
                    if (status != _filter) return false;
                  }

                  // Search query filter (Name wise & Flat wise)
                  if (_searchQuery.isNotEmpty) {
                    final resident = (b['resident_name'] ?? '').toString().toLowerCase();
                    final flat = (b['flat_number'] ?? '').toString().toLowerCase();
                    final block = (b['block_name'] ?? '').toString().toLowerCase();
                    final fullCardText = 'flat $flat ($block) - $resident'.toLowerCase();
                    final fullFlat = '$flat ($block)'.toLowerCase();
                    final fullFlat2 = '$block-$flat'.toLowerCase();

                    final allResidents = (b['all_residents'] as List<dynamic>?)
                            ?.map((e) => e.toString().toLowerCase())
                            .toList() ??
                        [];
                    final matchesResident = resident.contains(_searchQuery) ||
                        allResidents.any((r) => r.contains(_searchQuery));
                    final matchesFlat = flat.contains(_searchQuery) ||
                        fullCardText.contains(_searchQuery) ||
                        fullFlat.contains(_searchQuery) ||
                        fullFlat2.contains(_searchQuery);

                    if (!matchesResident && !matchesFlat) return false;
                  }

                  return true;
                }).toList();

                if (bills.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No maintenance bills found for "$_searchQuery"'
                              : 'No bills found matching filter.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final b = bills[index];
                    final residentName = (b['resident_name'] ?? '').toString().trim();
                    final isAssigned = (b['is_assigned'] == true) ||
                        (residentName.isNotEmpty &&
                         residentName.toLowerCase() != 'unassigned' &&
                         residentName.toLowerCase() != 'resident');
                    final isPaid = (b['status'] ?? '').toString().toLowerCase() == 'paid';
                    final payableAmt = b['payable_amount'] is num
                        ? (b['payable_amount'] as num)
                        : (double.tryParse(b['payable_amount']?.toString() ?? '') ?? 0);
                    final payableStr = (payableAmt is int || (payableAmt is double && payableAmt == payableAmt.roundToDouble()))
                        ? payableAmt.toInt().toString()
                        : payableAmt.toStringAsFixed(2);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: isAssigned ? Colors.grey.shade300 : Colors.grey.shade200),
                      ),
                      color: isAssigned ? Colors.white : const Color(0xFFFAFAFA),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: !isAssigned
                                  ? Colors.grey.shade100
                                  : (isPaid ? Colors.green.shade50 : Colors.orange.shade50),
                              child: Icon(
                                !isAssigned
                                    ? Icons.person_off_outlined
                                    : (isPaid ? Icons.check_circle : Icons.pending),
                                color: !isAssigned
                                    ? Colors.grey.shade600
                                    : (isPaid ? Colors.green : Colors.orange.shade800),
                              ),
                            ),
                            title: Text(
                              'Flat ${b['flat_number']} (${b['block_name']}) - ${isAssigned ? residentName : 'Unassigned'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isAssigned ? Colors.black87 : Colors.grey.shade700,
                              ),
                            ),
                            subtitle: Text(
                              '${b['bill_month']} • Due: ${b['due_date']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹$payableStr',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isAssigned ? Colors.black87 : Colors.grey.shade600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: !isAssigned
                                        ? Colors.grey.shade200
                                        : (isPaid ? Colors.green.shade100 : Colors.orange.shade100),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    !isAssigned ? 'UNASSIGNED' : (isPaid ? 'PAID' : 'DUE'),
                                    style: TextStyle(
                                      color: !isAssigned
                                          ? Colors.grey.shade700
                                          : (isPaid ? Colors.green.shade900 : Colors.orange.shade900),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isPaid)
                            Padding(
                              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8, top: 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      foregroundColor: Colors.indigo.shade800,
                                      side: BorderSide(color: Colors.indigo.shade200),
                                    ),
                                    icon: const Icon(Icons.visibility_outlined, size: 14),
                                    label: const Text('View Bill', style: TextStyle(fontSize: 12)),
                                    onPressed: () {
                                      final doc = FinancialDocument(
                                        type: FinancialDocumentType.maintenanceBill,
                                        docNumber: 'BILL-${b['bill_id']}',
                                        title: 'MAINTENANCE DUES BILL',
                                        societyName: b['society_name'] ?? 'Zenith Square Co-Op Housing Society Ltd.',
                                        societyCity: b['society_city'] ?? 'Ahmedabad, Gujarat',
                                        categoryOrHead: 'Maintenance Charges (${b['bill_month']})',
                                        amount: (b['payable_amount'] is num ? b['payable_amount'] : double.tryParse(b['payable_amount'].toString()) ?? 0.0).toDouble(),
                                        date: b['due_date'] ?? '',
                                        status: 'PAID',
                                        payerOrPayee: '${b['resident_name']} (Flat ${b['flat_number']})',
                                        paymentMethod: 'SETTLED',
                                        extraDetails: {
                                          'Flat & Block': 'Flat ${b['flat_number']} (${b['block_name']})',
                                          'Resident': b['resident_name'] ?? 'N/A',
                                          'Billing Month': b['bill_month'] ?? '',
                                          'Due Date': b['due_date'] ?? '',
                                          'Payment Status': 'PAID',
                                        },
                                      );
                                      FinancialDocumentHelper.viewDocument(context, doc);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      backgroundColor: Colors.indigo.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                                    label: const Text('Download PDF', style: TextStyle(fontSize: 12)),
                                    onPressed: () {
                                      final doc = FinancialDocument(
                                        type: FinancialDocumentType.maintenanceBill,
                                        docNumber: 'BILL-${b['bill_id']}',
                                        title: 'MAINTENANCE DUES BILL',
                                        societyName: b['society_name'] ?? 'Zenith Square Co-Op Housing Society Ltd.',
                                        societyCity: b['society_city'] ?? 'Ahmedabad, Gujarat',
                                        categoryOrHead: 'Maintenance Charges (${b['bill_month']})',
                                        amount: (b['payable_amount'] is num ? b['payable_amount'] : double.tryParse(b['payable_amount'].toString()) ?? 0.0).toDouble(),
                                        date: b['due_date'] ?? '',
                                        status: 'PAID',
                                        payerOrPayee: '${b['resident_name']} (Flat ${b['flat_number']})',
                                        paymentMethod: 'SETTLED',
                                        extraDetails: {
                                          'Flat & Block': 'Flat ${b['flat_number']} (${b['block_name']})',
                                          'Resident': b['resident_name'] ?? 'N/A',
                                          'Billing Month': b['bill_month'] ?? '',
                                          'Due Date': b['due_date'] ?? '',
                                          'Payment Status': 'PAID',
                                        },
                                      );
                                      FinancialDocumentHelper.downloadDocument(context, doc);
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// TAB 3: SOCIETY INCOME (FEATURE ADDITION)
// -------------------------------------------------------------
class _SocietyIncomeTab extends StatefulWidget {
  const _SocietyIncomeTab();

  @override
  State<_SocietyIncomeTab> createState() => _SocietyIncomeTabState();
}

class _SocietyIncomeTabState extends State<_SocietyIncomeTab> {
  late Future<List<dynamic>> _incomesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _incomesFuture = FinanceApiService.fetchSocietyIncome();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _incomesFuture = FinanceApiService.fetchSocietyIncome();
    });
  }

  void _showAddIncomeDialog() {
    final formKey = GlobalKey<FormState>();
    final typeController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final dateController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal.shade50,
                radius: 18,
                child: Icon(Icons.savings_outlined, color: Colors.teal.shade800, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Record Society Income', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Log non-maintenance revenues such as clubhouse booking, scrap sale, cell tower rent, penalty or sponsorship.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),

                    // Quick Category Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        'Clubhouse Rent',
                        'Tower Rent',
                        'Scrap Sale',
                        'Event Stall',
                        'Solar Subsidy',
                        'Penalty/Fine',
                      ].map((cat) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(cat, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setModalState(() {
                              typeController.text = cat;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: typeController,
                      decoration: const InputDecoration(
                        labelText: 'Income Source / Category *',
                        hintText: 'e.g. Clubhouse Rent, Scrap Sale',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) {
                        final v = val?.trim() ?? '';
                        if (v.isEmpty) return 'Please enter income source';
                        if (v.length < 3) return 'Must be at least 3 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹) *',
                        prefixText: '₹ ',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) {
                        final v = val?.trim() ?? '';
                        if (v.isEmpty) return 'Please enter amount';
                        final numVal = double.tryParse(v);
                        if (numVal == null || numVal <= 0) return 'Enter a valid amount > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Received Date (YYYY-MM-DD) *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_month, size: 20),
                        isDense: true,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() {
                            dateController.text = picked.toIso8601String().substring(0, 10);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description / Remarks (Optional)',
                        hintText: 'Payer name, receipt reference, or bank transaction details...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isSubmitting = true);
                      try {
                        final amt = double.parse(amountController.text.trim());
                        await FinanceApiService.recordSocietyIncome(
                          incomeType: typeController.text.trim(),
                          amount: amt,
                          receivedDate: dateController.text.trim(),
                          description: descController.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.teal,
                              content: Text('Society Income recorded successfully!'),
                            ),
                          );
                          _refresh();
                        }
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: Colors.red, content: Text(e.toString().replaceAll('Exception: ', ''))),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Income', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search & Actions Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search income by source, category, remarks...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim().toLowerCase());
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showAddIncomeDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Record Income', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // 2. Incomes List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: FutureBuilder<List<dynamic>>(
              future: _incomesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allIncomes = snapshot.data ?? [];
                final incomes = allIncomes.where((inc) {
                  if (_searchQuery.isEmpty) return true;
                  final type = (inc['income_type'] ?? '').toString().toLowerCase();
                  final desc = (inc['description'] ?? '').toString().toLowerCase();
                  final amt = (inc['amount'] ?? '').toString().toLowerCase();
                  return type.contains(_searchQuery) || desc.contains(_searchQuery) || amt.contains(_searchQuery);
                }).toList();

                if (incomes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.savings_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No incomes found matching "$_searchQuery"'
                              : 'No society income recorded yet.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _showAddIncomeDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Record First Society Income'),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate total income
                double totalIncomeSum = 0;
                for (var item in allIncomes) {
                  final amt = item['amount'] is num
                      ? (item['amount'] as num).toDouble()
                      : (double.tryParse(item['amount'].toString()) ?? 0.0);
                  totalIncomeSum += amt;
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  children: [
                    // Summary Banner Card
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade800, Colors.teal.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Society Income Received',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${totalIncomeSum.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${allIncomes.length} Recorded',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Incomes Items
                    ...incomes.map((inc) {
                      final amountVal = (inc['amount'] is num
                          ? inc['amount']
                          : double.tryParse(inc['amount'].toString()) ?? 0.0).toDouble();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade50,
                                child: Icon(Icons.savings_outlined, color: Colors.teal.shade700),
                              ),
                              title: Text(
                                inc['income_type'] ?? 'Income',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${inc['received_date'] ?? ''}${inc['description'] != null && inc['description'].toString().isNotEmpty ? ' • ${inc['description']}' : ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                '+₹${amountVal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      foregroundColor: Colors.teal.shade800,
                                      side: BorderSide(color: Colors.teal.shade200),
                                    ),
                                    icon: const Icon(Icons.visibility_outlined, size: 14),
                                    label: const Text('View Receipt', style: TextStyle(fontSize: 12)),
                                    onPressed: () {
                                      final doc = FinancialDocument(
                                        type: FinancialDocumentType.societyIncome,
                                        docNumber: 'REC-INC-${inc['income_id'] ?? ''}',
                                        title: 'SOCIETY INCOME RECEIPT',
                                        societyName: inc['society_name'] ?? 'Zenith Square Co-Op Housing Society Ltd.',
                                        societyCity: inc['society_city'] ?? 'Ahmedabad, Gujarat',
                                        categoryOrHead: inc['income_type'] ?? 'Society Income',
                                        amount: amountVal,
                                        date: inc['received_date'] ?? '',
                                        status: 'RECEIVED & CREDITED',
                                        payerOrPayee: inc['income_type'] ?? 'Revenue Source',
                                        paymentMethod: 'ONLINE / BANK / CASH',
                                        description: inc['description'] ?? '',
                                      );
                                      FinancialDocumentHelper.viewDocument(context, doc);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      backgroundColor: Colors.teal.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                                    label: const Text('Download PDF', style: TextStyle(fontSize: 12)),
                                    onPressed: () {
                                      final doc = FinancialDocument(
                                        type: FinancialDocumentType.societyIncome,
                                        docNumber: 'REC-INC-${inc['income_id'] ?? ''}',
                                        title: 'SOCIETY INCOME RECEIPT',
                                        societyName: inc['society_name'] ?? 'Zenith Square Co-Op Housing Society Ltd.',
                                        societyCity: inc['society_city'] ?? 'Ahmedabad, Gujarat',
                                        categoryOrHead: inc['income_type'] ?? 'Society Income',
                                        amount: amountVal,
                                        date: inc['received_date'] ?? '',
                                        status: 'RECEIVED & CREDITED',
                                        payerOrPayee: inc['income_type'] ?? 'Revenue Source',
                                        paymentMethod: 'ONLINE / BANK / CASH',
                                        description: inc['description'] ?? '',
                                      );
                                      FinancialDocumentHelper.downloadDocument(context, doc);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// TAB 4: OFFLINE VERIFICATION & UPDATION (COMPONENT 20)
// -------------------------------------------------------------
class _OfflineVerificationTab extends StatefulWidget {
  const _OfflineVerificationTab();

  @override
  State<_OfflineVerificationTab> createState() => _OfflineVerificationTabState();
}

class _OfflineVerificationTabState extends State<_OfflineVerificationTab> {
  late Future<List<dynamic>> _pendingBillsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pendingBillsFuture = _loadPendingBills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _loadPendingBills() async {
    final all = await FinanceApiService.fetchAllBills();
    return all.where((b) {
      final st = (b['status'] ?? '').toString().toLowerCase();
      return st == 'pending' || st == 'unassigned';
    }).toList();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _pendingBillsFuture = _loadPendingBills();
    });
  }

  void _verifyPayment(Map<String, dynamic> bill) {
    final residentName = (bill['resident_name'] ?? '').toString().trim();
    final isAssigned = (bill['is_assigned'] == true) ||
        (residentName.isNotEmpty &&
         residentName.toLowerCase() != 'unassigned' &&
         residentName.toLowerCase() != 'resident');

    if (!isAssigned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          content: Text('Cannot verify payment: Flat is unassigned. Please assign a resident to this flat first.'),
        ),
      );
      return;
    }

    String selectedMethod = 'CASH';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Settle Bill: Flat ${bill['flat_number']}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resident: ${bill['resident_name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Month: ${bill['bill_month']}'),
                Text('Payable: ₹${bill['payable_amount']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                const Divider(height: 24),
                const Text('Payment Mode Received:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return const [
                      Text('Cash Received', overflow: TextOverflow.ellipsis, maxLines: 1),
                      Text('Bank Cheque', overflow: TextOverflow.ellipsis, maxLines: 1),
                      Text('NEFT / RTGS Transfer', overflow: TextOverflow.ellipsis, maxLines: 1),
                      Text('Direct UPI Settlement', overflow: TextOverflow.ellipsis, maxLines: 1),
                    ];
                  },
                  items: const [
                    DropdownMenuItem(value: 'CASH', child: Text('Cash Received', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'CHEQUE', child: Text('Bank Cheque', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('NEFT / RTGS Transfer', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'UPI', child: Text('Direct UPI Settlement', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedMethod = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setModalState(() => isSubmitting = true);
                      try {
                        final res = await FinanceApiService.recordOfflinePayment(
                          billId: bill['bill_id'],
                          paymentMethod: selectedMethod,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green,
                              content: Text(res['message'] ?? 'Payment verified successfully!'),
                            ),
                          );
                          _refresh();
                        }
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Mark Paid & Issue Receipt', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search pending bills by resident or flat...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              isDense: true,
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val.trim().toLowerCase());
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: FutureBuilder<List<dynamic>>(
              future: _pendingBillsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allPending = snapshot.data ?? [];
                final pending = allPending.where((b) {
                  if (_searchQuery.isNotEmpty) {
                    final resident = (b['resident_name'] ?? '').toString().toLowerCase();
                    final flat = (b['flat_number'] ?? '').toString().toLowerCase();
                    final block = (b['block_name'] ?? '').toString().toLowerCase();
                    final fullCardText = 'flat $flat ($block) - $resident'.toLowerCase();
                    final combined = '$flat ($block)'.toLowerCase();
                    final combined2 = '$block-$flat'.toLowerCase();

                    final allResidents = (b['all_residents'] as List<dynamic>?)
                            ?.map((e) => e.toString().toLowerCase())
                            .toList() ??
                        [];
                    final matchesResident = resident.contains(_searchQuery) ||
                        allResidents.any((r) => r.contains(_searchQuery));
                    final matchesFlat = flat.contains(_searchQuery) ||
                        fullCardText.contains(_searchQuery) ||
                        combined.contains(_searchQuery) ||
                        combined2.contains(_searchQuery);

                    if (!matchesResident && !matchesFlat) return false;
                  }
                  return true;
                }).toList();

                if (pending.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off : Icons.check_circle_outline,
                          color: _searchQuery.isNotEmpty ? Colors.grey.shade400 : Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No pending bills found for "$_searchQuery"'
                              : 'All maintenance dues are settled!',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final b = pending[index];
                    final residentName = (b['resident_name'] ?? '').toString().trim();
                    final isAssigned = (b['is_assigned'] == true) ||
                        (residentName.isNotEmpty &&
                         residentName.toLowerCase() != 'unassigned' &&
                         residentName.toLowerCase() != 'resident');

                    final amountNum = isAssigned
                        ? (b['payable_amount'] is num
                            ? b['payable_amount']
                            : (double.tryParse(b['payable_amount'].toString()) ?? 0))
                        : 0;
                    final amountStr = (amountNum is int || (amountNum is double && amountNum == amountNum.roundToDouble()))
                        ? amountNum.toInt().toString()
                        : amountNum.toStringAsFixed(2);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: isAssigned ? Colors.grey.shade300 : Colors.grey.shade200),
                      ),
                      color: isAssigned ? Colors.white : const Color(0xFFFAFAFA),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isAssigned ? Colors.orange.shade50 : Colors.grey.shade200,
                              child: Text(
                                b['flat_number'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isAssigned ? Colors.orange.shade900 : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isAssigned ? residentName : 'Unassigned',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isAssigned ? Colors.black87 : Colors.grey.shade700,
                                        ),
                                      ),
                                      if (!isAssigned) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'No Resident',
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('${b['bill_month']} • Due: ${b['due_date']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Amount: ₹$amountStr',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isAssigned ? Colors.blueAccent : Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAssigned ? Colors.teal : Colors.grey.shade300,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade500,
                                elevation: isAssigned ? 1 : 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: isAssigned ? () => _verifyPayment(b) : null,
                              child: Text(
                                'Verify',
                                style: TextStyle(
                                  color: isAssigned ? Colors.white : Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
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
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// TAB 4: EXPENSES & UTILITY BILLS (COMPONENT 5, 6, 7)
// -------------------------------------------------------------
class _ExpensesAndUtilitiesTab extends StatefulWidget {
  const _ExpensesAndUtilitiesTab();

  @override
  State<_ExpensesAndUtilitiesTab> createState() => _ExpensesAndUtilitiesTabState();
}

class _ExpensesAndUtilitiesTabState extends State<_ExpensesAndUtilitiesTab> {
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

  void _showAddExpenseDialog() {
    final typeController = TextEditingController(text: 'Electricity');
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Record Expense / Utility Bill'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: typeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Expense Category / Utility',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return const [
                        Text('Electricity Bill (Torrent/Adani)', overflow: TextOverflow.ellipsis, maxLines: 1),
                        Text('Water Supply & Tanker', overflow: TextOverflow.ellipsis, maxLines: 1),
                        Text('Generator Fuel / Diesel', overflow: TextOverflow.ellipsis, maxLines: 1),
                        Text('Security Agency Monthly Fee', overflow: TextOverflow.ellipsis, maxLines: 1),
                        Text('Housekeeping & Cleaning', overflow: TextOverflow.ellipsis, maxLines: 1),
                        Text('Elevator AMC / Repair', overflow: TextOverflow.ellipsis, maxLines: 1),
                        Text('Plumbing & Common Repairs', overflow: TextOverflow.ellipsis, maxLines: 1),
                        Text('Gardening & Landscaping', overflow: TextOverflow.ellipsis, maxLines: 1),
                        Text('Other Society Operations', overflow: TextOverflow.ellipsis, maxLines: 1),
                      ];
                    },
                    items: const [
                      DropdownMenuItem(value: 'Electricity', child: Text('Electricity Bill (Torrent/Adani)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Water Supply', child: Text('Water Supply & Tanker', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Generator Fuel', child: Text('Generator Fuel / Diesel', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Security Agency', child: Text('Security Agency Monthly Fee', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Housekeeping', child: Text('Housekeeping & Cleaning', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Elevator Maintenance', child: Text('Elevator AMC / Repair', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Plumbing & Repairs', child: Text('Plumbing & Common Repairs', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Gardening', child: Text('Gardening & Landscaping', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Other Operations', child: Text('Other Society Operations', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => typeController.text = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Payment Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Notes / Invoice Ref No.', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (amountController.text.trim().isEmpty) return;
                      setModalState(() => isSubmitting = true);
                      try {
                        await FinanceApiService.recordSocietyExpense(
                          expenseType: typeController.text.trim(),
                          amount: double.parse(amountController.text.trim()),
                          paymentDate: dateController.text.trim(),
                          description: descController.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.green,
                              content: Text('Expense / Utility bill recorded successfully!'),
                            ),
                          );
                          _refresh();
                        }
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Expense', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Society Expense Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                onPressed: _showAddExpenseDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Expense'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: FutureBuilder<List<dynamic>>(
              future: _expensesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final expenses = snapshot.data ?? [];
                if (expenses.isEmpty) {
                  return const Center(child: Text('No expenses recorded yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: expenses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final e = expenses[index];
                    final amountVal = (e['amount'] is num
                        ? e['amount']
                        : double.tryParse(e['amount'].toString()) ?? 0.0).toDouble();

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red.shade50,
                              child: Icon(Icons.receipt_outlined, color: Colors.red.shade700),
                            ),
                            title: Text(e['expense_type'] ?? 'Expense', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${e['payment_date']} • ${e['description'] ?? ''}', style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              '-₹${amountVal.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 15),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    foregroundColor: Colors.red.shade800,
                                    side: BorderSide(color: Colors.red.shade200),
                                  ),
                                  icon: const Icon(Icons.visibility_outlined, size: 14),
                                  label: const Text('View Voucher', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    final doc = FinancialDocument(
                                      type: FinancialDocumentType.societyExpense,
                                      docNumber: 'VOU-EXP-${e['expense_id'] ?? ''}',
                                      title: 'EXPENSE PAYMENT VOUCHER',
                                      societyName: e['society_name'] ?? 'Zenith Square Co-Op Housing Society Ltd.',
                                      societyCity: e['society_city'] ?? 'Ahmedabad, Gujarat',
                                      categoryOrHead: e['expense_type'] ?? 'General Expense',
                                      amount: amountVal,
                                      date: e['payment_date'] ?? '',
                                      status: 'PAID & SETTLED',
                                      payerOrPayee: 'Zenith Square Society Treasury',
                                      paymentMethod: 'TREASURY DISBURSEMENT',
                                      description: e['description'] ?? '',
                                    );
                                    FinancialDocumentHelper.viewDocument(context, doc);
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                                  label: const Text('Download PDF', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    final doc = FinancialDocument(
                                      type: FinancialDocumentType.societyExpense,
                                      docNumber: 'VOU-EXP-${e['expense_id'] ?? ''}',
                                      title: 'EXPENSE PAYMENT VOUCHER',
                                      societyName: e['society_name'] ?? 'Zenith Square Co-Op Housing Society Ltd.',
                                      societyCity: e['society_city'] ?? 'Ahmedabad, Gujarat',
                                      categoryOrHead: e['expense_type'] ?? 'General Expense',
                                      amount: amountVal,
                                      date: e['payment_date'] ?? '',
                                      status: 'PAID & SETTLED',
                                      payerOrPayee: 'Zenith Square Society Treasury',
                                      paymentMethod: 'TREASURY DISBURSEMENT',
                                      description: e['description'] ?? '',
                                    );
                                    FinancialDocumentHelper.downloadDocument(context, doc);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// TAB 5: PAYMENT RECEIPTS (COMPONENT 17)
// -------------------------------------------------------------
class _PaymentReceiptsTab extends StatefulWidget {
  const _PaymentReceiptsTab();

  @override
  State<_PaymentReceiptsTab> createState() => _PaymentReceiptsTabState();
}

class _PaymentReceiptsTabState extends State<_PaymentReceiptsTab> {
  late Future<List<dynamic>> _receiptsFuture;

  @override
  void initState() {
    super.initState();
    _receiptsFuture = FinanceApiService.fetchAllReceipts();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _receiptsFuture = FinanceApiService.fetchAllReceipts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: FutureBuilder<List<dynamic>>(
        future: _receiptsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final receipts = snapshot.data ?? [];
          if (receipts.isEmpty) {
            return const Center(child: Text('No payment receipts generated yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: receipts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = receipts[index];
              final amountVal = (r['amount'] is num
                  ? r['amount']
                  : double.tryParse(r['amount'].toString()) ?? 0.0).toDouble();

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.receipt, color: Colors.white),
                      ),
                      title: Text(r['receipt_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Flat ${r['flat_number']} • ${r['resident_name']} • ${r['payment_method']}', style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        '₹${amountVal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              foregroundColor: Colors.teal.shade800,
                              side: BorderSide(color: Colors.teal.shade200),
                            ),
                            icon: const Icon(Icons.visibility_outlined, size: 14),
                            label: const Text('View Receipt', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              final doc = FinancialDocument(
                                type: FinancialDocumentType.paymentReceipt,
                                docNumber: r['receipt_number'] ?? 'REC-${r['receipt_id']}',
                                title: 'MAINTENANCE PAYMENT RECEIPT',
                                societyName: r['society_name'] ?? 'Zenith Square Co-Op Housing Society Ltd.',
                                societyCity: r['society_city'] ?? 'Ahmedabad, Gujarat',
                                categoryOrHead: 'Maintenance Charges (${r['bill_month'] ?? 'Monthly'})',
                                amount: amountVal,
                                date: r['generated_at'] ?? '',
                                status: 'COMPLETED & VERIFIED',
                                payerOrPayee: '${r['resident_name']} (Flat ${r['flat_number']})',
                                paymentMethod: r['payment_method'] ?? 'ONLINE',
                                extraDetails: {
                                  'Flat Number': 'Flat ${r['flat_number']}',
                                  'Resident Name': r['resident_name'] ?? 'N/A',
                                  'Billing Cycle': r['bill_month'] ?? '',
                                  'Payment ID': r['payment_id'] ?? '',
                                },
                              );
                              FinancialDocumentHelper.viewDocument(context, doc);
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                            label: const Text('Download PDF', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              final doc = FinancialDocument(
                                type: FinancialDocumentType.paymentReceipt,
                                docNumber: r['receipt_number'] ?? 'REC-${r['receipt_id']}',
                                title: 'MAINTENANCE PAYMENT RECEIPT',
                                societyName: r['society_name'] ?? 'Zenith Square Co-Op Housing Society Ltd.',
                                societyCity: r['society_city'] ?? 'Ahmedabad, Gujarat',
                                categoryOrHead: 'Maintenance Charges (${r['bill_month'] ?? 'Monthly'})',
                                amount: amountVal,
                                date: r['generated_at'] ?? '',
                                status: 'COMPLETED & VERIFIED',
                                payerOrPayee: '${r['resident_name']} (Flat ${r['flat_number']})',
                                paymentMethod: r['payment_method'] ?? 'ONLINE',
                                extraDetails: {
                                  'Flat Number': 'Flat ${r['flat_number']}',
                                  'Resident Name': r['resident_name'] ?? 'N/A',
                                  'Billing Cycle': r['bill_month'] ?? '',
                                  'Payment ID': r['payment_id'] ?? '',
                                },
                              );
                              FinancialDocumentHelper.downloadDocument(context, doc);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 6: BANK DETAILS (COMPONENT 18)
// -------------------------------------------------------------
class _BankDetailsTab extends StatefulWidget {
  const _BankDetailsTab();

  @override
  State<_BankDetailsTab> createState() => _BankDetailsTabState();
}

class _BankDetailsTabState extends State<_BankDetailsTab> {
  late Future<Map<String, dynamic>> _bankFuture;

  @override
  void initState() {
    super.initState();
    _bankFuture = FinanceApiService.fetchBankDetails();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _bankFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final b = snapshot.data ?? {};
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance, color: Colors.blue.shade900),
                        const SizedBox(width: 8),
                        Text(
                          'Official Society Bank Account',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This account information is shared with residents for NEFT/RTGS and UPI maintenance dues.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _detailTile(Icons.business, 'Account Name', b['account_name'] ?? 'Society Fund'),
            _detailTile(Icons.account_balance, 'Bank Name', b['bank_name'] ?? 'HDFC Bank Ltd'),
            _detailTile(Icons.numbers, 'Account Number', b['account_number'] ?? '5010098273641'),
            _detailTile(Icons.vpn_key, 'IFSC Code', b['ifsc_code'] ?? 'HDFC0001890'),
            _detailTile(Icons.location_on, 'Branch', b['branch'] ?? 'Main Branch'),
            _detailTile(Icons.qr_code, 'UPI ID', b['upi_id'] ?? 'society@hdfcbank'),
            _detailTile(Icons.currency_rupee, 'Standard Monthly Rate', '₹${b['standard_rate'] ?? 0.0} / unit'),
          ],
        );
      },
    );
  }

  Widget _detailTile(IconData icon, String label, String value) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 18),
          tooltip: 'Copy',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied $label to clipboard')),
            );
          },
        ),
      ),
    );
  }
}
