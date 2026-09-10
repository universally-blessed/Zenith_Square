import 'package:flutter/material.dart';
import '../../data/datasource/finance_api_service.dart';

class SocietyReportsScreen extends StatefulWidget {
  const SocietyReportsScreen({super.key});

  @override
  State<SocietyReportsScreen> createState() => _SocietyReportsScreenState();
}

class _SocietyReportsScreenState extends State<SocietyReportsScreen> {
  late Future<Map<String, dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    setState(() {
      _reportFuture = FinanceApiService.fetchExecutiveReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Society Analytics & Reports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportFuture,
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadReport,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final occupancy = data['occupancy_distribution'] ?? {};
          final monthlyTable =
              (data['monthly_summary_table'] as List<dynamic>?) ?? [];
          final breakdowns = data['current_month_breakdowns'] ?? {};

          return RefreshIndicator(
            onRefresh: () async => _loadReport(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Occupancy Breakdown Card
                _buildOccupancySection(occupancy),
                const SizedBox(height: 20),

                // 2. Financial Analysis Cards (Income & Expense)
                _buildSectionHeader('Financial Analysis'),
                const SizedBox(height: 10),
                _buildFinancialCards(
                  monthlyTable,
                  breakdowns['incomes'] ?? [],
                  breakdowns['expenses'] ?? [],
                ),
                const SizedBox(height: 20),

                // 3. Security & Operational Metrics
                _buildSectionHeader('Operations & Governance'),
                const SizedBox(height: 10),
                _buildOperationsCards(monthlyTable),
                const SizedBox(height: 20),

                // 4. Detailed Consolidated Summary Table
                _buildSectionHeader('Detailed Summary Report'),
                const SizedBox(height: 10),
                _buildSummaryDataTable(monthlyTable),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SECTION 1: OCCUPANCY DISTRIBUTION
  // --------------------------------------------------------------------------
  Widget _buildOccupancySection(Map<String, dynamic> occ) {
    final owner = occ['owner_occupied'] ?? {};
    final tenant = occ['tenant_occupied'] ?? {};
    final vacant = occ['vacant'] ?? {};
    final total = occ['total_flats'] ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Occupancy Distribution',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    Expanded(
                      flex: ((owner['percentage'] ?? 0) * 10).toInt(),
                      child: Container(color: Colors.blue.shade600),
                    ),
                    Expanded(
                      flex: ((tenant['percentage'] ?? 0) * 10).toInt(),
                      child: Container(color: Colors.teal.shade500),
                    ),
                    Expanded(
                      flex: ((vacant['percentage'] ?? 0) * 10).toInt(),
                      child: Container(color: Colors.orange.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Table(
              border: TableBorder.all(color: Colors.grey.shade200),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blueGrey.shade900),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Metric',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Count',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildTableRow(
                  'Owner Occupied',
                  '${owner['count'] ?? 0}',
                  '${owner['percentage'] ?? 0}%',
                ),
                _buildTableRow(
                  'Tenant Occupied',
                  '${tenant['count'] ?? 0}',
                  '${tenant['percentage'] ?? 0}%',
                ),
                _buildTableRow(
                  'Vacant',
                  '${vacant['count'] ?? 0}',
                  '${vacant['percentage'] ?? 0}%',
                ),
                _buildTableRow('Total Units', '$total', '100%', isBold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(
    String label,
    String count,
    String pct, {
    bool isBold = false,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            count,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            pct,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SECTION 2: FINANCIAL TREND CARDS
  // --------------------------------------------------------------------------
  Widget _buildFinancialCards(
    List<dynamic> monthly,
    List<dynamic> incomeBreakdown,
    List<dynamic> expenseBreakdown,
  ) {
    return Column(
      children: [
        // Monthly Collection Rate Comparison
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collection Rate Trend (%)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: monthly.map((m) {
                    return Column(
                      children: [
                        Text(
                          '${m['collection_rate']}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: (m['collection_rate'] ?? 0) * 0.7,
                          width: 28,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m['month_abbr'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Income by Category Breakdown
        if (incomeBreakdown.isNotEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Income Breakdown (Current Month)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...incomeBreakdown.map((inc) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            inc['category'] ?? 'Miscellaneous',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '+ ₹ ${inc['amount']}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Expense by Category Breakdown
        if (expenseBreakdown.isNotEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expense Breakdown (Current Month)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...expenseBreakdown.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e['category'] ?? 'General',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '- ₹ ${e['amount']}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SECTION 3: OPERATIONS & GOVERNANCE CARDS
  // --------------------------------------------------------------------------
  Widget _buildOperationsCards(List<dynamic> monthly) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Visitor Volume',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ...monthly.map(
                    (m) => Text(
                      '${m['month_abbr']}: ${m['total_visitors']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complaints Resolved',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ...monthly.map(
                    (m) => Text(
                      '${m['month_abbr']}: ${m['complaints_resolved']}/${m['complaints_filed']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SECTION 4: CONSOLIDATED EXECUTIVE SUMMARY TABLE
  // --------------------------------------------------------------------------
  Widget _buildSummaryDataTable(List<dynamic> monthly) {
    if (monthly.isEmpty) return const SizedBox.shrink();

    final months = monthly.map((m) => m['month_abbr'].toString()).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade900),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          dataRowMinHeight: 32,
          dataRowMaxHeight: 40,
          columns: [
            const DataColumn(label: Text('Metric')),
            ...months.map((m) => DataColumn(label: Text(m))),
          ],
          rows: [
            _sectionDataRow('FINANCIAL', months.length),
            _metricRow(
              'Collection Rate (%)',
              monthly,
              (m) => '${m['collection_rate']}%',
            ),
            _metricRow(
              'Total Inflow (₹)',
              monthly,
              (m) => '₹ ${m['total_income'] ?? m['collection_rate']}',
            ),
            _metricRow(
              'Other Incomes (₹)',
              monthly,
              (m) => '₹ ${m['other_income'] ?? 0.0}',
            ),
            _metricRow(
              'Total Expenses (₹)',
              monthly,
              (m) => '₹ ${m['total_expenses']}',
            ),
            _metricRow(
              'Net Operating Surplus (₹)',
              monthly,
              (m) => '₹ ${m['net_surplus'] ?? 0.0}',
            ),
            _metricRow(
              'Amenity Revenue (₹)',
              monthly,
              (m) => '₹ ${m['amenity_revenue']}',
            ),
            _metricRow(
              'Defaulters (Count)',
              monthly,
              (m) => '${m['defaulters_count']}',
            ),

            _sectionDataRow('SECURITY & COMPLAINTS', months.length),
            _metricRow(
              'Total Security Alerts',
              monthly,
              (m) => '${m['security_alerts']}',
            ),
            _metricRow(
              'Complaints Filed',
              monthly,
              (m) => '${m['complaints_filed']}',
            ),
            _metricRow(
              'Complaints Resolved',
              monthly,
              (m) => '${m['complaints_resolved']}',
            ),
            _metricRow(
              'Avg Resolution (Days)',
              monthly,
              (m) => '${m['avg_resolution_days']} days',
            ),

            _sectionDataRow('OPERATIONS', months.length),
            _metricRow(
              'Total Visitors',
              monthly,
              (m) => '${m['total_visitors']}',
            ),
            _metricRow(
              'Amenity Bookings',
              monthly,
              (m) => '${m['amenity_bookings']}',
            ),
            _metricRow(
              'Participation Rate (%)',
              monthly,
              (m) => '${m['participation_rate']}%',
            ),
            _metricRow(
              'Asset Maintenance (₹)',
              monthly,
              (m) => '₹ ${m['asset_maintenance_cost']}',
            ),
          ],
        ),
      ),
    );
  }

  DataRow _sectionDataRow(String title, int monthCount) {
    return DataRow(
      color: WidgetStateProperty.all(Colors.blueGrey.shade100),
      cells: [
        DataCell(
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
        ),
        ...List.generate(monthCount, (_) => const DataCell(Text(''))),
      ],
    );
  }

  DataRow _metricRow(
    String title,
    List<dynamic> monthly,
    String Function(dynamic) extractor,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(title, style: const TextStyle(fontSize: 12))),
        ...monthly.map(
          (m) => DataCell(
            Text(extractor(m), style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
