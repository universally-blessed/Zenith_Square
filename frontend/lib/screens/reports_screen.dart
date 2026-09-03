import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/csv_exporter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  String? _selectedSociety;
  List<dynamic> _societies = [];

  // Dedicated data buckets for each endpoint
  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? _financialsData;
  Map<String, dynamic>? _securityComplaintsData;
  Map<String, dynamic>? _operationsData;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  void _fetchReportData() async {
    setState(() => _loading = true);
    try {
      // Execute calls to all 4 endpoints in parallel
      final results = await Future.wait([
        ApiService.getReportsSummary(societyId: _selectedSociety),
        ApiService.getFinancialsReport(societyId: _selectedSociety),
        ApiService.getSecurityComplaintsReport(societyId: _selectedSociety),
        ApiService.getOperationsReport(societyId: _selectedSociety),
        ApiService.getSocieties(),
      ]);

      setState(() {
        _summaryData = results[0] as Map<String, dynamic>;
        _financialsData = results[1] as Map<String, dynamic>;
        _securityComplaintsData = results[2] as Map<String, dynamic>;
        _operationsData = results[3] as Map<String, dynamic>;
        _societies = results[4] as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 1. Occupancy from Summary Endpoint
    final occupancy = _summaryData?['occupancy'] ?? {};

    // 2. Financials from /reports/financials/
    final financialTrend =
        _financialsData?['collection_trend'] as List<dynamic>? ?? [];
    final monthlyExpenses =
        _financialsData?['monthly_expenses'] as List<dynamic>? ?? [];

    // 3. Complaints & SLA from /reports/security-complaints/
    final complaints = _securityComplaintsData ?? {};

    // 4. Operations & Visitor logs from /reports/operations/
    final visitors =
        _operationsData?['monthly_traffic'] as List<dynamic>? ?? [];

    // Consolidated payload for CSV Export
    final Map<String, dynamic> exportPayload = {
      'occupancy': occupancy,
      'financial_kpis': _financialsData ?? {},
      'complaints': complaints,
      'visitors': _operationsData ?? {},
    };

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header & Filter Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Executive MIS Reports',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                // Society Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSociety,
                    hint: const Text('All Societies'),
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Societies'),
                      ),
                      ..._societies.map(
                        (s) => DropdownMenuItem(
                          value: s['society_id'].toString(),
                          child: Text(s['society_name'] ?? s['society_id']),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedSociety = val);
                      _fetchReportData();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Export to CSV Button
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Export CSV',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final selectedName = _selectedSociety == null
                        ? 'Consolidated_All_Societies'
                        : (_societies.firstWhere(
                                (s) =>
                                    s['society_id'].toString() ==
                                    _selectedSociety,
                                orElse: () => {
                                  'society_name': _selectedSociety,
                                },
                              )['society_name'] ??
                              _selectedSociety!);

                    CsvExporter.exportReportToCsv(
                      societyName: selectedName,
                      reportData: exportPayload,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Row 1: Occupancy Distribution & Collection Rate Trend
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildOccupancyCard(occupancy)),
            const SizedBox(width: 24),
            Expanded(child: _buildCollectionTrendCard(financialTrend)),
          ],
        ),
        const SizedBox(height: 24),

        // Row 2: Monthly Expenses & Resolution SLA
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildExpenseBarChart(monthlyExpenses)),
            const SizedBox(width: 24),
            Expanded(child: _buildComplaintsCard(complaints)),
          ],
        ),
        const SizedBox(height: 24),

        // Row 3: Operations & Visitor Traffic
        _buildVisitorBarChart(visitors),
      ],
    );
  }

  // 1. Occupancy Pie Chart
  Widget _buildOccupancyCard(Map<String, dynamic> occ) {
    final double owner = ((occ['owner_occupied'] ?? 0) as num).toDouble();
    final double tenant = ((occ['tenant_occupied'] ?? 0) as num).toDouble();
    final double vacant = ((occ['vacant'] ?? 0) as num).toDouble();
    final double total = owner + tenant + vacant;

    return _cardContainer(
      title: 'Occupancy Distribution',
      child: SizedBox(
        height: 220,
        child: total == 0
            ? const Center(
                child: Text(
                  'No flats registered',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          if (owner > 0)
                            PieChartSectionData(
                              color: Colors.blue,
                              value: owner,
                              title: '${owner.toInt()}',
                              radius: 50,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (tenant > 0)
                            PieChartSectionData(
                              color: Colors.teal,
                              value: tenant,
                              title: '${tenant.toInt()}',
                              radius: 50,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (vacant > 0)
                            PieChartSectionData(
                              color: Colors.orange,
                              value: vacant,
                              title: '${vacant.toInt()}',
                              radius: 50,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _indicator(Colors.blue, 'Owner (${owner.toInt()})'),
                      const SizedBox(height: 8),
                      _indicator(Colors.teal, 'Tenant (${tenant.toInt()})'),
                      const SizedBox(height: 8),
                      _indicator(Colors.orange, 'Vacant (${vacant.toInt()})'),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  // 2. Collection Rate Line Chart
  Widget _buildCollectionTrendCard(List<dynamic> trend) {
    if (trend.isEmpty) {
      return _cardContainer(
        title: 'Collection Rate Trend (%)',
        child: const SizedBox(
          height: 220,
          child: Center(
            child: Text(
              'No billing records found',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return _cardContainer(
      title: 'Collection Rate Trend (%)',
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 35),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, _) {
                    int idx = val.toInt();
                    if (idx >= 0 && idx < trend.length) {
                      return Text(trend[idx]['month'] ?? '');
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: trend.asMap().entries.map((e) {
                  return FlSpot(
                    e.key.toDouble(),
                    ((e.value['rate'] ?? 0) as num).toDouble(),
                  );
                }).toList(),
                isCurved: true,
                color: Colors.teal,
                barWidth: 4,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Monthly Expenses Bar Chart
  Widget _buildExpenseBarChart(List<dynamic> expenses) {
    if (expenses.isEmpty) {
      return _cardContainer(
        title: 'Total Monthly Expenses (₹)',
        child: const SizedBox(
          height: 220,
          child: Center(
            child: Text(
              'No expense records logged',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return _cardContainer(
      title: 'Total Monthly Expenses (₹)',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, _) {
                    int idx = val.toInt();
                    if (idx >= 0 && idx < expenses.length) {
                      return Text(expenses[idx]['month'] ?? '');
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            barGroups: expenses.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: ((e.value['amount'] ?? 0) as num).toDouble(),
                    color: Colors.blueAccent,
                    width: 28,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // 4. Security & Complaints Overview
  Widget _buildComplaintsCard(Map<String, dynamic> comp) {
    return _cardContainer(
      title: 'Security & Complaint Resolution',
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statRow(
              'Complaints Filed',
              '${comp['total_complaints'] ?? comp['filed'] ?? 0}',
              Colors.blue,
            ),
            _statRow(
              'Complaints Resolved',
              '${comp['resolved'] ?? 0}',
              Colors.green,
            ),
            _statRow(
              'Avg Resolution Time',
              '${comp['avg_resolution_days'] ?? 0} Days',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  // 5. Operations & Visitor Traffic Bar Chart
  Widget _buildVisitorBarChart(List<dynamic> visitors) {
    if (visitors.isEmpty) {
      return _cardContainer(
        title: 'Monthly Visitor Traffic',
        child: const SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'No visitor check-in activity logged',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return _cardContainer(
      title: 'Monthly Visitor Traffic',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, _) {
                    int idx = val.toInt();
                    if (idx >= 0 && idx < visitors.length) {
                      return Text(visitors[idx]['month'] ?? '');
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            barGroups: visitors.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: ((e.value['count'] ?? 0) as num).toDouble(),
                    color: Colors.teal,
                    width: 28,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cardContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _indicator(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}
