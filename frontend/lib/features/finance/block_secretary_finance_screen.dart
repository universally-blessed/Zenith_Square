import 'package:flutter/material.dart';
import '../../data/datasource/finance_api_service.dart';

class BlockSecretaryFinanceScreen extends StatefulWidget {
  const BlockSecretaryFinanceScreen({super.key});

  @override
  State<BlockSecretaryFinanceScreen> createState() =>
      _BlockSecretaryFinanceScreenState();
}

class _BlockSecretaryFinanceScreenState
    extends State<BlockSecretaryFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Block Finance & Dues'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Unit Due'),
            Tab(text: 'Block Dues Status'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_PersonalUnitDueTab(), _BlockDuesStatusTab()],
      ),
    );
  }
}

// TAB 1: PERSONAL UNIT DUE
class _PersonalUnitDueTab extends StatefulWidget {
  const _PersonalUnitDueTab();

  @override
  State<_PersonalUnitDueTab> createState() => _PersonalUnitDueTabState();
}

class _PersonalUnitDueTabState extends State<_PersonalUnitDueTab> {
  late Future _billFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  void _loadBill() {
    setState(() {
      _billFuture = FinanceApiService.fetchLatestBill();
    });
  }

  Future<void> _handlePayment(String billId, String amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Settlement'),
        content: Text('Pay ₹$amount for this month maintenance?'),
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

    setState(() => _isProcessing = true);
    try {
      final res = await FinanceApiService.payBill(billId, method: 'ONLINE');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBill();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _billFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};
        final hasPending = data['has_pending_bill'] ?? false;
        final bill = data['bill'];

        if (!hasPending || bill == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 12),
                Text(
                  'All maintenance dues settled!',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill['bill_month'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unit: ${bill['block_name']} - ${bill['flat_number']}',
                      ),
                      Text('Due Date: ${bill['due_date']}'),
                      const Divider(height: 20),
                      Text(
                        '₹${bill['total_payable'] ?? bill['payable_amount']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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
                child: const Text('Pay Maintenance'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// TAB 2: BLOCK DUES STATUS WITH SEARCH & FILTER
class _BlockDuesStatusTab extends StatefulWidget {
  const _BlockDuesStatusTab();

  @override
  State<_BlockDuesStatusTab> createState() => _BlockDuesStatusTabState();
}

class _BlockDuesStatusTabState extends State<_BlockDuesStatusTab> {
  late Future _reportFuture;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'ALL'; // Options: ALL, PAID, PENDING

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadReport() {
    setState(() {
      _reportFuture = FinanceApiService.fetchBlockReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString().replaceAll('Exception: ', ''),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final summary = data['summary'] ?? {};
        final rawBills = (data['bills'] as List<dynamic>?) ?? [];

        // Apply Search and Status Filters
        final filteredBills = rawBills.where((item) {
          final flatNum = (item['flat_number'] ?? '').toString().toLowerCase();
          final residentName = (item['resident_name'] ?? '')
              .toString()
              .toLowerCase();
          final status = (item['status'] ?? '').toString().toUpperCase();
          final searchQuery = _searchController.text.trim().toLowerCase();

          // 1. Check search text match (flat number or resident name)
          final matchesSearch =
              searchQuery.isEmpty ||
              flatNum.contains(searchQuery) ||
              residentName.contains(searchQuery);

          // 2. Check status filter match
          bool matchesStatus = true;
          if (_selectedStatusFilter == 'PAID') {
            matchesStatus = status == 'PAID';
          } else if (_selectedStatusFilter == 'PENDING') {
            matchesStatus = status == 'PENDING';
          }

          return matchesSearch && matchesStatus;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => _loadReport(),
          child: Column(
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(14),
                color: Colors.blueGrey.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Block: ${data['block_name'] ?? '--'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Paid: ${summary['paid_count']}/${summary['total_flats']}',
                    ),
                    Text(
                      'Rate: ${summary['collection_rate']}%',
                      style: TextStyle(
                        color: Colors.teal.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Filter Controls Header
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search Flat / Resident...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'ALL', label: Text('All')),
                          ButtonSegment(value: 'PAID', label: Text('Paid')),
                          ButtonSegment(
                            value: 'PENDING',
                            label: Text('Pending'),
                          ),
                        ],
                        selected: {_selectedStatusFilter},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _selectedStatusFilter = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Results List / Empty State
              Expanded(
                child: filteredBills.isEmpty
                    ? Center(
                        child: Text(
                          'No flats match your filter criteria.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredBills.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final item = filteredBills[i];
                          final isPaid =
                              (item['status'] ?? '').toString().toLowerCase() ==
                              'paid';

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text(
                                'Flat ${item['flat_number']} (${item['resident_name']})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Amount: ₹${item['payable_amount']} • Due: ${item['due_date']}',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPaid
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isPaid ? 'PAID' : 'PENDING',
                                  style: TextStyle(
                                    color: isPaid
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
