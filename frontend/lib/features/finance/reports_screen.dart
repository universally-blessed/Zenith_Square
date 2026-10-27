import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/datasource/finance_api_service.dart';
import '../../../utils/file_download_helper.dart';

class SocietyReportsScreen extends StatefulWidget {
  const SocietyReportsScreen({super.key});

  @override
  State<SocietyReportsScreen> createState() => _SocietyReportsScreenState();
}

class _SocietyReportsScreenState extends State<SocietyReportsScreen> {
  late Future<Map<String, dynamic>> _reportFuture;
  int _selectedMonthIndex = 0;
  bool _isDownloadingPdf = false;

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

  // ---------------------------------------------------------------------------
  // PDF GENERATION & DOWNLOAD
  // ---------------------------------------------------------------------------
  Future<void> _downloadReportPdf({
    required Map<String, dynamic> data,
    Map<String, dynamic>? singleMonth,
  }) async {
    if (_isDownloadingPdf) return;
    setState(() => _isDownloadingPdf = true);

    try {
      final society = (data['society'] as Map<String, dynamic>?) ?? {};
      final treasury = (data['treasury_summary'] as Map<String, dynamic>?) ?? {};
      final monthly = (data['monthly_reports'] as List<dynamic>?) ?? [];
      final breakdowns = (data['category_breakdowns'] as Map<String, dynamic>?) ?? {};

      final societyName = (society['name'] ?? 'Zenith Square Society').toString().toUpperCase();
      final societyCity = (society['city'] ?? 'Ahmedabad').toString();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pw.Context context) {
            return [
              // 1. Official Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo900, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            societyName,
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF1A237E),
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Financial Management & Audit Statement | $societyCity',
                            style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            'Report Type: ${singleMonth != null ? '${singleMonth['month_label']} Monthly Statement' : 'Comprehensive Multi-Month Financial Audit'}',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700),
                          ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'OFFICIAL REPORT',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                        ),
                        pw.Text(
                          'Generated: ${DateTime.now().toString().split('.').first}',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          'Currency: INR (Rs.)',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // 2. Executive Summary KPIs Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'OVERALL TREASURY SUMMARY',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _pdfKpiItem('Net Treasury Balance', 'Rs. ${(treasury['net_balance'] ?? 0).toStringAsFixed(2)}', PdfColors.indigo900),
                        _pdfKpiItem('Total Inflow Collected', 'Rs. ${(treasury['total_inflow'] ?? 0).toStringAsFixed(2)}', PdfColors.green800),
                        _pdfKpiItem('Total Society Expenses', 'Rs. ${(treasury['total_expenses'] ?? 0).toStringAsFixed(2)}', PdfColors.red800),
                        _pdfKpiItem('Pending Maintenance Dues', 'Rs. ${(treasury['total_pending_dues'] ?? 0).toStringAsFixed(2)}', PdfColors.orange900),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // 3. If Single Month Report
              if (singleMonth != null) ...[
                pw.Text(
                  'MONTHLY STATEMENT: ${(singleMonth['month_label'] ?? '').toString().toUpperCase()}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    _pdfTableRow('Metric', 'Amount / Value', isHeader: true),
                    _pdfTableRow('Maintenance Billed (Assigned Flats)', 'Rs. ${(singleMonth['maintenance_billed'] ?? 0).toStringAsFixed(2)}'),
                    _pdfTableRow('Maintenance Collected', 'Rs. ${(singleMonth['maintenance_collected'] ?? 0).toStringAsFixed(2)}'),
                    _pdfTableRow('Recovery / Collection Rate', '${singleMonth['collection_rate'] ?? 0}%'),
                    _pdfTableRow('Pending Dues for Month', 'Rs. ${(singleMonth['maintenance_pending'] ?? 0).toStringAsFixed(2)}'),
                    _pdfTableRow('Other Society Incomes', 'Rs. ${(singleMonth['society_income'] ?? 0).toStringAsFixed(2)}'),
                    _pdfTableRow('Total Monthly Inflow', 'Rs. ${(singleMonth['total_income'] ?? 0).toStringAsFixed(2)}'),
                    _pdfTableRow('Total Monthly Expenses', 'Rs. ${(singleMonth['total_expenses'] ?? 0).toStringAsFixed(2)}'),
                    _pdfTableRow('Net Operating Surplus / Deficit', 'Rs. ${(singleMonth['net_surplus'] ?? 0).toStringAsFixed(2)}', isBold: true),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Itemized Breakdown for month
                if ((singleMonth['expense_breakdown'] as List<dynamic>? ?? []).isNotEmpty) ...[
                  pw.Text('ITEMIZED EXPENSES FOR ${singleMonth['month_label']}:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      _pdfTableRow('Expense Category', 'Amount (INR)', isHeader: true),
                      ...(singleMonth['expense_breakdown'] as List<dynamic>).map((e) => _pdfTableRow(e['category'].toString(), 'Rs. ${(e['amount'] ?? 0).toStringAsFixed(2)}')),
                    ],
                  ),
                  pw.SizedBox(height: 14),
                ],

                if ((singleMonth['income_breakdown'] as List<dynamic>? ?? []).isNotEmpty) ...[
                  pw.Text('ITEMIZED SOCIETY INCOMES FOR ${singleMonth['month_label']}:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      _pdfTableRow('Income Source', 'Amount (INR)', isHeader: true),
                      ...(singleMonth['income_breakdown'] as List<dynamic>).map((inc) => _pdfTableRow(inc['category'].toString(), 'Rs. ${(inc['amount'] ?? 0).toStringAsFixed(2)}')),
                    ],
                  ),
                  pw.SizedBox(height: 14),
                ],
              ],

              // 4. Comparative Multi-Month Table (if Full Report)
              if (singleMonth == null && monthly.isNotEmpty) ...[
                pw.Text(
                  'MULTI-MONTH COMPARATIVE FINANCIAL LEDGER',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                      children: [
                        _pdfHeaderCell('Month'),
                        _pdfHeaderCell('Billed'),
                        _pdfHeaderCell('Collected'),
                        _pdfHeaderCell('Rate %'),
                        _pdfHeaderCell('Other Inc'),
                        _pdfHeaderCell('Inflow'),
                        _pdfHeaderCell('Expenses'),
                        _pdfHeaderCell('Surplus'),
                      ],
                    ),
                    ...monthly.map((m) {
                      final net = (m['net_surplus'] ?? 0).toDouble();
                      return pw.TableRow(
                        children: [
                          _pdfDataCell(m['month_abbr'].toString()),
                          _pdfDataCell('Rs.${(m['maintenance_billed'] ?? 0).toInt()}'),
                          _pdfDataCell('Rs.${(m['maintenance_collected'] ?? 0).toInt()}'),
                          _pdfDataCell('${m['collection_rate']}%'),
                          _pdfDataCell('Rs.${(m['society_income'] ?? 0).toInt()}'),
                          _pdfDataCell('Rs.${(m['total_income'] ?? 0).toInt()}'),
                          _pdfDataCell('Rs.${(m['total_expenses'] ?? 0).toInt()}'),
                          _pdfDataCell(
                            'Rs.${net.toInt()}',
                            textColor: net >= 0 ? PdfColors.green800 : PdfColors.red800,
                            isBold: true,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 16),

                // Category Breakdowns
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Expense categories
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('EXPENSE DISTRIBUTION', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                          pw.SizedBox(height: 6),
                          pw.Table(
                            border: pw.TableBorder.all(color: PdfColors.grey300),
                            children: [
                              _pdfTableRow('Category', 'Amount', isHeader: true),
                              ...((breakdowns['expenses'] as List<dynamic>?) ?? []).map((e) => _pdfTableRow(e['category'].toString(), 'Rs.${(e['amount'] ?? 0).toInt()}')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    // Income categories
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('INCOME DISTRIBUTION', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                          pw.SizedBox(height: 6),
                          pw.Table(
                            border: pw.TableBorder.all(color: PdfColors.grey300),
                            children: [
                              _pdfTableRow('Category', 'Amount', isHeader: true),
                              ...((breakdowns['incomes'] as List<dynamic>?) ?? []).map((inc) => _pdfTableRow(inc['category'].toString(), 'Rs.${(inc['amount'] ?? 0).toInt()}')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              // 5. Sign-off / Verification Block
              pw.Spacer(),
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 14),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                        pw.SizedBox(height: 4),
                        pw.Text('Prepared & Verified by:', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        pw.Text('TREASURER', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                        pw.SizedBox(height: 4),
                        pw.Text('Audited & Confirmed by:', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                        pw.Text('CHAIRMAN / SECRETARY', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final suffix = singleMonth != null ? singleMonth['month_code'] : 'FULL_AUDIT';
      final fileName = 'FINANCIAL_REPORT_${societyName.replaceAll(' ', '_')}_$suffix.pdf';

      downloadWebBinaryFile(
        fileName: fileName,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Downloaded: $fileName')),
              ],
            ),
            backgroundColor: Colors.indigo.shade800,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  pw.Widget _pdfKpiItem(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  pw.TableRow _pdfTableRow(String col1, String col2, {bool isHeader = false, bool isBold = false}) {
    return pw.TableRow(
      decoration: isHeader ? const pw.BoxDecoration(color: PdfColors.grey200) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(
            col1,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHeader ? PdfColors.black : PdfColors.grey800,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(
            col2,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHeader ? PdfColors.black : PdfColors.grey900,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _pdfDataCell(String text, {PdfColor? textColor, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Financial Analytics & Reports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadReport,
          ),
        ],
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
          final treasury = (data['treasury_summary'] as Map<String, dynamic>?) ?? {};
          final rawReports = (data['monthly_reports'] as List<dynamic>?) ?? [];
          final breakdowns = (data['category_breakdowns'] as Map<String, dynamic>?) ?? {};

          if (rawReports.isEmpty) {
            return const Center(child: Text('No financial report data available.'));
          }

          // Order months with newest/current first so it is immediately visible
          final monthlyReports = rawReports.reversed.toList();

          final safeSelectedIdx = _selectedMonthIndex < monthlyReports.length ? _selectedMonthIndex : 0;
          final selectedMonthData = monthlyReports[safeSelectedIdx] as Map<String, dynamic>;

          return RefreshIndicator(
            onRefresh: () async => _loadReport(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Top Action Banner with Download Button
                _buildTopActionBanner(data),
                const SizedBox(height: 16),

                // 1. Lifetime Treasury Health Card
                _buildTreasuryOverviewCard(treasury),
                const SizedBox(height: 20),

                // 2. Past & Current Reports Explorer
                _buildSectionHeader(
                  title: 'Monthly Financial Reports (Current & Past)',
                  icon: Icons.history,
                ),
                const SizedBox(height: 8),
                _buildMonthSelectorChips(monthlyReports, safeSelectedIdx),
                const SizedBox(height: 12),

                // Selected Month Detailed Financial Report Card
                _buildSelectedMonthCard(data, selectedMonthData),
                const SizedBox(height: 24),

                // 3. Multi-Month Comparative Ledger Table
                _buildSectionHeader(
                  title: 'Comparative Monthly Financial Ledger',
                  icon: Icons.table_chart_outlined,
                ),
                const SizedBox(height: 10),
                _buildComparativeLedgerTable(data, monthlyReports),
                const SizedBox(height: 24),

                // 4. Cumulative Categorical Breakdowns
                _buildSectionHeader(
                  title: 'Cumulative Income & Expense Categories',
                  icon: Icons.pie_chart_outline,
                ),
                const SizedBox(height: 10),
                _buildCategoryBreakdownsCard(breakdowns),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey.shade800),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopActionBanner(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance, color: Colors.indigo.shade800, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Financial Statements',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Official Audit & Past Ledgers',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade800,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isDownloadingPdf ? null : () => _downloadReportPdf(data: data),
            icon: _isDownloadingPdf
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf, size: 14),
            label: const Text('Download PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasuryOverviewCard(Map<String, dynamic> treasury) {
    final netBalance = (treasury['net_balance'] ?? 0.0).toDouble();
    final totalInflow = (treasury['total_inflow'] ?? 0.0).toDouble();
    final totalExpenses = (treasury['total_expenses'] ?? 0.0).toDouble();
    final totalPending = (treasury['total_pending_dues'] ?? 0.0).toDouble();
    final assignedUnits = treasury['assigned_units'] ?? 0;
    final totalUnits = treasury['total_units'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade900, Colors.indigo.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cumulative Net Treasury Balance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Units: $assignedUnits / $totalUnits',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${netBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // 3 KPIs Row
          Row(
            children: [
              Expanded(
                child: _heroMetricItem('Total Inflow', '₹${totalInflow.toStringAsFixed(0)}', Colors.greenAccent),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _heroMetricItem('Total Expenses', '₹${totalExpenses.toStringAsFixed(0)}', Colors.redAccent.shade100),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _heroMetricItem('Pending Dues', '₹${totalPending.toStringAsFixed(0)}', Colors.orangeAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PAST & CURRENT MONTH SELECTOR
  // ---------------------------------------------------------------------------
  Widget _buildMonthSelectorChips(List<dynamic> monthlyReports, int selectedIdx) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: monthlyReports.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final m = monthlyReports[index] as Map<String, dynamic>;
          final isSelected = index == selectedIdx;
          final isCurrent = m['is_current'] == true;
          final label = isCurrent ? '${m['month_label']} (Current)' : m['month_label'];

          return ChoiceChip(
            selected: isSelected,
            onSelected: (val) {
              if (val) setState(() => _selectedMonthIndex = index);
            },
            showCheckmark: false,
            avatar: isCurrent ? Icon(Icons.star, size: 14, color: isSelected ? Colors.amber : Colors.amber.shade800) : null,
            label: Text(label),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            selectedColor: Colors.indigo.shade800,
            backgroundColor: Colors.white,
            side: BorderSide(color: isSelected ? Colors.indigo.shade800 : Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          );
        },
      ),
    );
  }

  Widget _buildSelectedMonthCard(Map<String, dynamic> fullData, Map<String, dynamic> month) {
    final monthLabel = month['month_label'] ?? 'Monthly Report';
    final billed = (month['maintenance_billed'] ?? 0.0).toDouble();
    final collected = (month['maintenance_collected'] ?? 0.0).toDouble();
    final pending = (month['maintenance_pending'] ?? 0.0).toDouble();
    final rate = (month['collection_rate'] ?? 0.0).toDouble();
    final otherInc = (month['society_income'] ?? 0.0).toDouble();
    final totalInflow = (month['total_income'] ?? 0.0).toDouble();
    final totalExp = (month['total_expenses'] ?? 0.0).toDouble();
    final netSurplus = (month['net_surplus'] ?? 0.0).toDouble();

    final expenseBreakdown = (month['expense_breakdown'] as List<dynamic>?) ?? [];
    final incomeBreakdown = (month['income_breakdown'] as List<dynamic>?) ?? [];

    final isPositive = netSurplus >= 0;

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
            // Month Header & Download Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Monthly Financial Audit & Breakdown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: _isDownloadingPdf ? null : () => _downloadReportPdf(data: fullData, singleMonth: month),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                  label: const Text('Month PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),

            // Financial KPIs for this month
            Row(
              children: [
                Expanded(
                  child: _monthKpiCard('Maintenance Billed', '₹${billed.toStringAsFixed(0)}', Colors.indigo.shade800, Colors.indigo.shade50),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _monthKpiCard('Collected ($rate%)', '₹${collected.toStringAsFixed(0)}', Colors.green.shade800, Colors.green.shade50),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _monthKpiCard('Pending Dues', '₹${pending.toStringAsFixed(0)}', Colors.orange.shade900, Colors.orange.shade50),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _monthKpiCard('Other Society Incomes', '₹${otherInc.toStringAsFixed(0)}', Colors.teal.shade800, Colors.teal.shade50),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _monthKpiCard('Total Inflow', '₹${totalInflow.toStringAsFixed(0)}', Colors.blue.shade900, Colors.blue.shade50),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _monthKpiCard('Total Expenses', '₹${totalExp.toStringAsFixed(0)}', Colors.red.shade800, Colors.red.shade50),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Net Surplus Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isPositive ? Colors.green.shade200 : Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isPositive ? 'Net Monthly Surplus:' : 'Net Monthly Deficit:',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isPositive ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₹${netSurplus.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isPositive ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Itemized Monthly Incomes & Expenses
            if (incomeBreakdown.isNotEmpty || expenseBreakdown.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Itemized Month Transactions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              if (incomeBreakdown.isNotEmpty) ...[
                Text('Incomes Received:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade800)),
                const SizedBox(height: 4),
                ...incomeBreakdown.map((inc) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '• ${inc['category']}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('+ ₹${inc['amount']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
              ],
              if (expenseBreakdown.isNotEmpty) ...[
                Text('Expenses Disbursed:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade800)),
                const SizedBox(height: 4),
                ...expenseBreakdown.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '• ${e['category']}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('- ₹${e['amount']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                    ],
                  ),
                )),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _monthKpiCard(String label, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMPARATIVE MULTI-MONTH LEDGER TABLE
  // ---------------------------------------------------------------------------
  Widget _buildComparativeLedgerTable(Map<String, dynamic> fullData, List<dynamic> monthlyReports) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DataTable(
          columnSpacing: 14,
          horizontalMargin: 12,
          headingRowColor: WidgetStateProperty.all(Colors.blueGrey.shade900),
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          dataRowMinHeight: 36,
          dataRowMaxHeight: 44,
          columns: const [
            DataColumn(label: Text('Month')),
            DataColumn(label: Text('Billed (₹)')),
            DataColumn(label: Text('Collected (₹)')),
            DataColumn(label: Text('Rate (%)')),
            DataColumn(label: Text('Other Inc (₹)')),
            DataColumn(label: Text('Total Inflow (₹)')),
            DataColumn(label: Text('Expenses (₹)')),
            DataColumn(label: Text('Net Surplus (₹)')),
            DataColumn(label: Text('PDF')),
          ],
          rows: monthlyReports.map((m) {
            final net = (m['net_surplus'] ?? 0.0).toDouble();
            final isPos = net >= 0;

            return DataRow(
              cells: [
                DataCell(Text(m['month_abbr'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataCell(Text('₹${(m['maintenance_billed'] ?? 0).toInt()}', style: const TextStyle(fontSize: 12))),
                DataCell(Text('₹${(m['maintenance_collected'] ?? 0).toInt()}', style: const TextStyle(fontSize: 12, color: Colors.green))),
                DataCell(Text('${m['collection_rate']}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                DataCell(Text('₹${(m['society_income'] ?? 0).toInt()}', style: const TextStyle(fontSize: 12))),
                DataCell(Text('₹${(m['total_income'] ?? 0).toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                DataCell(Text('₹${(m['total_expenses'] ?? 0).toInt()}', style: const TextStyle(fontSize: 12, color: Colors.red))),
                DataCell(Text(
                  '₹${net.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPos ? Colors.green.shade800 : Colors.red.shade800),
                )),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.indigo),
                    tooltip: 'Download ${m['month_label']} PDF',
                    onPressed: () => _downloadReportPdf(data: fullData, singleMonth: m),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ALL-TIME CATEGORY BREAKDOWNS
  // ---------------------------------------------------------------------------
  Widget _buildCategoryBreakdownsCard(Map<String, dynamic> breakdowns) {
    final expenses = (breakdowns['expenses'] as List<dynamic>?) ?? [];
    final incomes = (breakdowns['incomes'] as List<dynamic>?) ?? [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Incomes breakdown
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.savings_outlined, color: Colors.green.shade700, size: 16),
                      const SizedBox(width: 6),
                      const Text('Income Sources', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 16),
                  if (incomes.isEmpty)
                    Text('No other income records', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
                  else
                    ...incomes.map((inc) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(inc['category'] ?? 'Misc', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                          Text('₹${inc['amount']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Expenses breakdown
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.money_off_outlined, color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 6),
                      const Text('Expense Heads', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 16),
                  if (expenses.isEmpty)
                    Text('No expense records', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
                  else
                    ...expenses.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(e['category'] ?? 'General', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                          Text('₹${e['amount']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800)),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
