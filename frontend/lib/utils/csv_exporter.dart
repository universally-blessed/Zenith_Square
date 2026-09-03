import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class CsvExporter {
  static void exportReportToCsv({
    required String societyName,
    required Map<String, dynamic> reportData,
  }) {
    final occupancy = reportData['occupancy'] ?? {};
    final fin = reportData['financial_kpis'] ?? {};
    final complaints = reportData['complaints'] ?? {};
    final visitors = reportData['visitors']?['monthly_traffic'] ?? [];

    final List<List<dynamic>> rows = [
      ['EXECUTIVE SUMMARY & MIS REPORT'],
      ['Society Scope:', societyName],
      ['Generated On:', DateTime.now().toIso8601String().split('T').first],
      [],
      // Section 1: Occupancy
      ['OCCUPANCY DISTRIBUTION', 'COUNT', 'PERCENTAGE (%)'],
      ['Owner Occupied', occupancy['owner_occupied'] ?? 0, ''],
      ['Tenant Occupied', occupancy['tenant_occupied'] ?? 0, ''],
      ['Vacant Units', occupancy['vacant'] ?? 0, ''],
      ['Total Flats', occupancy['total_flats'] ?? 0, '100%'],
      [],
      // Section 2: Financials
      ['FINANCIAL OVERVIEW', 'VALUE'],
      ['Total Expenses (INR)', fin['total_expenses'] ?? 0],
      ['Overall Collection Rate (%)', '${fin['collection_rate'] ?? 0}%'],
      [],
      // Section 3: Monthly Breakdown
      ['MONTHLY EXPENSES', 'AMOUNT (INR)'],
      ...(fin['monthly_expenses'] as List<dynamic>? ?? []).map(
        (e) => [e['month'], e['amount']],
      ),
      [],
      ['MONTHLY COLLECTION TREND', 'RATE (%)'],
      ...(fin['collection_trend'] as List<dynamic>? ?? []).map(
        (e) => [e['month'], '${e['rate']}%'],
      ),
      [],
      // Section 4: Complaints & Security
      ['COMPLAINTS & SECURITY METRICS', 'COUNT'],
      ['Complaints Filed', complaints['filed'] ?? 0],
      ['Complaints Resolved', complaints['resolved'] ?? 0],
      [
        'Avg Resolution Duration',
        '${complaints['avg_resolution_days'] ?? 0} Days',
      ],
      [],
      // Section 5: Visitors
      ['MONTHLY VISITOR TRAFFIC', 'VISITOR COUNT'],
      ...(visitors as List<dynamic>).map((v) => [v['month'], v['count']]),
    ];

    // Convert rows to CSV formatted string
    final csvString = rows
        .map((row) => row.map((cell) => '"$cell"').join(','))
        .join('\r\n');

    // Trigger browser download in Flutter Web
    final bytes = utf8.encode(csvString);
    final blob = web.Blob([bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download =
          'MIS_Report_${societyName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }
}
