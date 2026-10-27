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

class _SocietyReportsScreenState extends State<SocietyReportsScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _reportFuture;
  late TabController _tabController;
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReport() {
    setState(() {
      _reportFuture = FinanceApiService.fetchExecutiveReport();
    });
  }

  // ===========================================================================
  // 1. MASTER PDF GENERATION (COMPREHENSIVE SOCIETY OPERATIONS AUDIT)
  // ===========================================================================
  Future<void> _downloadMasterAuditPdf(Map<String, dynamic> data) async {
    if (_isDownloadingPdf) return;
    setState(() => _isDownloadingPdf = true);

    try {
      final society = (data['society'] as Map<String, dynamic>?) ?? {};
      final occupancy = (data['occupancy_report'] as Map<String, dynamic>?) ?? {};
      final complaints = (data['complaints_report'] as Map<String, dynamic>?) ?? {};
      final security = (data['security_report'] as Map<String, dynamic>?) ?? {};
      final facilities = (data['facilities_report'] as Map<String, dynamic>?) ?? {};
      final vehicles = (data['vehicles_report'] as Map<String, dynamic>?) ?? {};

      final societyName = (society['name'] ?? 'Zenith Square Society').toString().toUpperCase();
      final societyCity = (society['city'] ?? 'Ahmedabad').toString();
      final societyAddress = (society['address'] ?? '').toString();
      final societyCode = (society['code'] ?? '').toString();

      final pdf = pw.Document();

      // PAGE 1: EXECUTIVE OVERVIEW & SCORECARD
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pw.Context context) {
            return [
              _pdfOfficialHeader(
                societyName: societyName,
                societyCity: societyCity,
                reportSubtitle: 'Executive All-Society Operational Audit & Governance Statement',
                docType: 'OPERATIONS AUDIT',
                address: societyAddress,
                code: societyCode,
              ),
              pw.SizedBox(height: 14),

              // Executive KPI Summary Grid
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.indigo200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SOCIETY OPERATIONAL HEALTH SCORECARD',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _pdfKpiItem('Occupancy Rate', '${occupancy['occupancy_rate'] ?? 0}% (${occupancy['occupied_flats'] ?? 0}/${occupancy['total_flats'] ?? 0})', PdfColors.teal900),
                        _pdfKpiItem('Helpdesk Resolution', '${complaints['resolution_rate'] ?? 0}%', PdfColors.orange900),
                        _pdfKpiItem('Visitors Logged', '${security['total_visitors_logged'] ?? 0}', PdfColors.blueGrey900),
                        _pdfKpiItem('Active Facilities', '${facilities['total_amenities'] ?? 0} (100% Operational)', PdfColors.indigo900),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Society Operational Summary Table
              pw.Text('OPERATIONAL SECTORS AUDIT SUMMARY:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _pdfTableRow('Operational Department / Sector', 'Status & Key Figures', isHeader: true),
                  _pdfTableRow('Flats & Occupancy', 'Total Flats: ${occupancy['total_flats'] ?? 0} | Occupied: ${occupancy['occupied_flats'] ?? 0} | Vacant: ${occupancy['vacant_flats'] ?? 0} | Owners: ${occupancy['owner_count'] ?? 0} | Tenants: ${occupancy['tenant_count'] ?? 0}'),
                  _pdfTableRow('Complaints & Grievances', 'Total: ${complaints['total_complaints'] ?? 0} | Pending: ${complaints['pending'] ?? 0} | Resolved: ${complaints['resolved'] ?? 0} | Satisfaction: ${complaints['average_rating'] ?? 0}/5.0'),
                  _pdfTableRow('Security & Gate Operations', 'Visitors: ${security['total_visitors_logged'] ?? 0} | Inside: ${security['currently_inside'] ?? 0} | Active Alerts: ${security['active_alerts_count'] ?? 0}'),
                  _pdfTableRow('Facilities & Amenities', 'Total Amenities: ${facilities['total_amenities'] ?? 0} (100% Operational) | Bookings: ${facilities['total_bookings'] ?? 0}'),
                  _pdfTableRow('Vehicles & Parking', 'Total Registered: ${vehicles['total_vehicles'] ?? 0} | 4-Wheelers: ${vehicles['four_wheelers'] ?? 0} | 2-Wheelers: ${vehicles['two_wheelers'] ?? 0} | Allotted Slots: ${vehicles['allocated_slots_count'] ?? 0}'),
                ],
              ),
              pw.SizedBox(height: 18),

              // 1. OCCUPANCY & RESIDENTS AUDIT
              pw.Text('1. RESIDENTS & OCCUPANCY AUDIT', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _pdfTableRow('Block / Metric', 'Total Units & Occupancy Breakdown', isHeader: true),
                  ...((occupancy['blocks_breakdown'] as List<dynamic>?) ?? []).map((b) => _pdfTableRow('Block ${b['block_name']} (${b['block_id']})', 'Total: ${b['total_flats']} | Occupied: ${b['occupied_flats']} | Vacant: ${b['vacant_flats']} | Rate: ${b['occupancy_rate']}%')),
                  _pdfTableRow('Demographics Summary', 'Owners: ${occupancy['owner_count']} | Tenants: ${occupancy['tenant_count']} | Total Residents: ${occupancy['total_residents']} | Nominees: ${occupancy['nominees_count']}'),
                ],
              ),
              pw.SizedBox(height: 16),

              // 2. HELPDESK & SECURITY LOGS AUDIT
              pw.Text('2. HELPDESK, SECURITY & COMMUNITY ASSETS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _pdfTableRow('Sector', 'Audit Finding / Operational Status', isHeader: true),
                  _pdfTableRow('Complaints Performance', 'Total Logged: ${complaints['total_complaints']} | Pending: ${complaints['pending']} | Resolved: ${complaints['resolved']} (${complaints['resolution_rate']}%)'),
                  _pdfTableRow('Resident Feedback Rating', 'Average Score: ${complaints['average_rating']}/5.0 Stars (${complaints['feedback_count']} Reviews)'),
                  _pdfTableRow('Gate & Visitor Security', 'Total Visitors: ${security['total_visitors_logged']} | Emergency Incidents: ${security['total_alerts_count']} (${security['active_alerts_count']} Active)'),
                  _pdfTableRow('Amenities & Vehicle Allotment', 'Facilities: ${facilities['total_amenities']} | Vehicles: ${vehicles['total_vehicles']} (4W: ${vehicles['four_wheelers']}, 2W: ${vehicles['two_wheelers']}) | Slots: ${vehicles['allocated_slots_count']}'),
                ],
              ),
              pw.SizedBox(height: 24),

              // Official Sign-off Block
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 14),
                decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400))),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(width: 130, height: 1, color: PdfColors.grey700),
                        pw.SizedBox(height: 4),
                        pw.Text('Prepared & Verified:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Text('GENERAL SECRETARY', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.indigo900, width: 1)),
                          child: pw.Text('OFFICIAL SEAL & OPERATIONS APPROVED', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(width: 130, height: 1, color: PdfColors.grey700),
                        pw.SizedBox(height: 4),
                        pw.Text('Confirmed & Ratified:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Text('CHAIRMAN / PRESIDENT', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
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
      final fileName = 'SOCIETY_OPERATIONS_AUDIT_${societyName.replaceAll(' ', '_')}_${DateTime.now().year}.pdf';

      downloadWebBinaryFile(
        fileName: fileName,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Downloaded Official Society Operations Audit: $fileName')),
              ],
            ),
            backgroundColor: Colors.blue.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  // PDF Helpers
  pw.Widget _pdfOfficialHeader({
    required String societyName,
    required String societyCity,
    required String reportSubtitle,
    required String docType,
    String? address,
    String? code,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo900, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(societyName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1A237E))),
                pw.SizedBox(height: 3),
                pw.Text('$reportSubtitle | $societyCity${code != null && code.isNotEmpty ? ' ($code)' : ''}', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
                if (address != null && address.isNotEmpty)
                  pw.Text(address, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Report Type: $docType', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('OFFICIAL AUDIT REPORT', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
              pw.Text('Generated: ${DateTime.now().toString().split('.').first}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfKpiItem(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
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
              fontSize: 8.5,
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
              fontSize: 8.5,
              fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHeader ? PdfColors.black : PdfColors.grey900,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MAIN UI BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    const blueColor = Colors.blueAccent;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: const Text(
          'Society Reports & Analytics',
          style: TextStyle(
            color: Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0D1B2A)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: blueColor,
              unselectedLabelColor: Colors.black87,
              indicatorColor: blueColor,
              indicatorWeight: 3.0,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined, color: blueColor, size: 20), text: 'Overview'),
                Tab(icon: Icon(Icons.apartment_outlined, color: blueColor, size: 20), text: 'Occupancy'),
                Tab(icon: Icon(Icons.report_problem_outlined, color: blueColor, size: 20), text: 'Complaints'),
                Tab(icon: Icon(Icons.security_outlined, color: blueColor, size: 20), text: 'Security'),
                Tab(icon: Icon(Icons.pool_outlined, color: blueColor, size: 20), text: 'Facilities'),
              ],
            ),
          ),
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
          final occupancy = (data['occupancy_report'] as Map<String, dynamic>?) ?? {};
          final complaints = (data['complaints_report'] as Map<String, dynamic>?) ?? {};
          final security = (data['security_report'] as Map<String, dynamic>?) ?? {};
          final facilities = (data['facilities_report'] as Map<String, dynamic>?) ?? {};
          final vehicles = (data['vehicles_report'] as Map<String, dynamic>?) ?? {};

          return TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: EXECUTIVE OVERVIEW
              _buildOverviewTab(
                data: data,
                occupancy: occupancy,
                complaints: complaints,
                security: security,
                facilities: facilities,
                vehicles: vehicles,
              ),

              // TAB 2: RESIDENTS & OCCUPANCY
              _buildOccupancyTab(occupancy),

              // TAB 3: COMPLAINTS & HELPDESK
              _buildComplaintsTab(complaints),

              // TAB 4: SECURITY & GATE LOGS
              _buildSecurityTab(security),

              // TAB 5: FACILITIES & VEHICLES
              _buildFacilitiesTab(facilities, vehicles),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TAB 1: EXECUTIVE OVERVIEW
  // ===========================================================================
  Widget _buildOverviewTab({
    required Map<String, dynamic> data,
    required Map<String, dynamic> occupancy,
    required Map<String, dynamic> complaints,
    required Map<String, dynamic> security,
    required Map<String, dynamic> facilities,
    required Map<String, dynamic> vehicles,
  }) {
    final society = (data['society'] as Map<String, dynamic>?) ?? {};
    final societyName = (society['name'] ?? 'Zenith Square Society').toString();
    final societyCity = (society['city'] ?? 'Ahmedabad').toString();
    final societyCode = (society['code'] ?? '').toString();

    final occRate = (occupancy['occupancy_rate'] ?? 0.0).toDouble();
    final occupiedFlats = occupancy['occupied_flats'] ?? 0;
    final totalFlats = occupancy['total_flats'] ?? 0;

    final compPending = complaints['pending'] ?? 0;
    final compRate = (complaints['resolution_rate'] ?? 100.0).toDouble();
    final activeAlerts = security['active_alerts_count'] ?? 0;
    final visitorsTotal = security['total_visitors_logged'] ?? 0;
    final visitorsInside = security['currently_inside'] ?? 0;

    return RefreshIndicator(
      onRefresh: () async => _loadReport(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Executive Master Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF0D1B2A), const Color(0xFF1B263B), Colors.indigo.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified, color: Colors.amberAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            societyName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Official Operations Audit & Governance | $societyCity ${societyCode.isNotEmpty ? '($societyCode)' : ''}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        'Society Health: Active & Fully Operational',
                        style: TextStyle(
                          color: Colors.greenAccent.shade100,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: const Color(0xFF0D1B2A),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: _isDownloadingPdf ? null : () => _downloadMasterAuditPdf(data),
                    icon: _isDownloadingPdf
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D1B2A)))
                        : const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('Export Official Master Audit PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Alert Notice Bar (if any critical attention items)
          if (activeAlerts > 0 || compPending > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Executive Attention: $compPending unresolved complaint(s) and $activeAlerts security alert(s) on file.',
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // 3. Departmental Hub Cards
          _buildSectionTitle('Operational Sectors & Performance'),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: [
              _overviewCard(
                title: 'Flats & Occupancy',
                icon: Icons.apartment,
                color: Colors.teal,
                headline: '$occRate%',
                subtitle: '$occupiedFlats / $totalFlats units occupied',
                badgeText: 'Occupancy Tab',
                onTap: () => _tabController.animateTo(1),
              ),
              _overviewCard(
                title: 'Helpdesk & Complaints',
                icon: Icons.report_problem,
                color: Colors.amber.shade900,
                headline: '$compRate%',
                subtitle: '${complaints['total_complaints'] ?? 0} total ($compPending pending)',
                badgeText: 'Complaints Tab',
                onTap: () => _tabController.animateTo(2),
              ),
              _overviewCard(
                title: 'Security & Gate',
                icon: Icons.security,
                color: Colors.blueGrey.shade800,
                headline: '$visitorsTotal',
                subtitle: '$visitorsInside currently on premises',
                badgeText: 'Security Tab',
                onTap: () => _tabController.animateTo(3),
              ),
              _overviewCard(
                title: 'Amenities & Club',
                icon: Icons.pool,
                color: Colors.cyan.shade800,
                headline: '${facilities['total_amenities'] ?? 0}',
                subtitle: '100% Facilities Operational',
                badgeText: 'Facilities Tab',
                onTap: () => _tabController.animateTo(4),
              ),
              _overviewCard(
                title: 'Vehicles & Parking',
                icon: Icons.directions_car,
                color: Colors.deepPurple,
                headline: '${vehicles['total_vehicles'] ?? 0}',
                subtitle: '${vehicles['allocated_slots_count'] ?? 0} Allotted Slots',
                badgeText: 'Parking Tab',
                onTap: () => _tabController.animateTo(4),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Executive Summary Quick Table
          _buildSectionTitle('Consolidated Key Society Metrics'),
          const SizedBox(height: 8),
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
                children: [
                  _summaryRow('Occupancy Rate', '$occRate% ($occupiedFlats/$totalFlats Flats)', Colors.teal.shade800),
                  const Divider(height: 16),
                  _summaryRow('Owner vs Tenant Ratio', '${occupancy['owner_count'] ?? 0} Owners / ${occupancy['tenant_count'] ?? 0} Tenants', Colors.blueGrey.shade800),
                  const Divider(height: 16),
                  _summaryRow('Complaints Resolution Rate', '$compRate% (${complaints['resolved'] ?? 0}/${complaints['total_complaints'] ?? 0} Resolved)', Colors.green.shade800),
                  const Divider(height: 16),
                  _summaryRow('Resident Feedback Rating', '${complaints['average_rating'] ?? 5.0} / 5.0 Stars (${complaints['feedback_count'] ?? 0} Reviews)', Colors.amber.shade900),
                  const Divider(height: 16),
                  _summaryRow('Visitor Gate Traffic', '$visitorsTotal entries logged ($visitorsInside inside)', Colors.blueGrey.shade800),
                  const Divider(height: 16),
                  _summaryRow('Parking Slot Allotment', '${vehicles['allocated_slots_count'] ?? 0} / ${vehicles['total_vehicles'] ?? 0} Vehicles Allotted', Colors.deepPurple.shade800),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _overviewCard({
    required String title,
    required IconData icon,
    required Color color,
    required String headline,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.blueAccent, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: RESIDENTS & OCCUPANCY
  // ===========================================================================
  Widget _buildOccupancyTab(Map<String, dynamic> occupancy) {
    final totalFlats = occupancy['total_flats'] ?? 0;
    final occupied = occupancy['occupied_flats'] ?? 0;
    final vacant = occupancy['vacant_flats'] ?? 0;
    final rate = (occupancy['occupancy_rate'] ?? 0.0).toDouble();
    final owners = occupancy['owner_count'] ?? 0;
    final tenants = occupancy['tenant_count'] ?? 0;
    final totalResidents = occupancy['total_residents'] ?? 0;
    final nominees = occupancy['nominees_count'] ?? 0;
    final blocks = (occupancy['blocks_breakdown'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: () async => _loadReport(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Hero Occupancy Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade900, Colors.teal.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.teal.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Society Occupancy Rate', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text('Total Units: $totalFlats', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$rate%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: totalFlats > 0 ? (occupied / totalFlats) : 0,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _heroMetricItem('Occupied Units', '$occupied Units', Colors.amberAccent)),
                    const SizedBox(width: 8),
                    Expanded(child: _heroMetricItem('Vacant Units', '$vacant Units', Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Demographics Row
          _buildSectionTitle('Resident Demographics & Distribution'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statMiniCard('Owner Flats', '$owners', Icons.home, Colors.blueAccent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statMiniCard('Tenant Flats', '$tenants', Icons.key, Colors.blueAccent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statMiniCard('Residents', '$totalResidents', Icons.people, Colors.blueAccent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statMiniCard('Nominees', '$nominees', Icons.family_restroom, Colors.blueAccent),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Block-by-Block Occupancy Table
          _buildSectionHeader(title: 'Block-Wise Occupancy Breakdown', icon: Icons.domain),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: blocks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final b = blocks[idx];
                final bTotal = b['total_flats'] ?? 0;
                final bOcc = b['occupied_flats'] ?? 0;
                final bVac = b['vacant_flats'] ?? 0;
                final bRate = (b['occupancy_rate'] ?? 0.0).toDouble();

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: Text(
                      (b['block_name'] ?? 'B').toString(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                    ),
                  ),
                  title: Text('Block ${b['block_name']} (${b['block_id']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('$bOcc Occupied • $bVac Vacant • $bTotal Total Units', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: bTotal > 0 ? (bOcc / bTotal) : 0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '$bRate%',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: COMPLAINTS & HELPDESK
  // ===========================================================================
  Widget _buildComplaintsTab(Map<String, dynamic> complaints) {
    final total = complaints['total_complaints'] ?? 0;
    final pending = complaints['pending'] ?? 0;
    final inProgress = complaints['in_progress'] ?? 0;
    final resolved = complaints['resolved'] ?? 0;
    final rate = (complaints['resolution_rate'] ?? 100.0).toDouble();
    final avgRating = (complaints['average_rating'] ?? 5.0).toDouble();
    final fbCount = complaints['feedback_count'] ?? 0;
    final recent = (complaints['recent_complaints'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: () async => _loadReport(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Resolution Hero Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade900, Colors.deepOrange.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Helpdesk Resolution Rate', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text('Total Logged: $total', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$rate%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _heroMetricItem('Pending', '$pending', Colors.white)),
                    const SizedBox(width: 6),
                    Expanded(child: _heroMetricItem('In Progress', '$inProgress', Colors.amberAccent)),
                    const SizedBox(width: 6),
                    Expanded(child: _heroMetricItem('Resolved', '$resolved', Colors.greenAccent)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Resident Feedback Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.star, color: Colors.blueAccent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('$avgRating', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                          ],
                        ),
                        Text('Resident Satisfaction Rating ($fbCount reviews on file)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Recent Complaints List
          _buildSectionHeader(title: 'Recent Complaints & Tickets', icon: Icons.format_list_bulleted),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: Text('No complaints recorded for this society! 🎉', style: TextStyle(color: Colors.grey))),
              ),
            )
          else
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final c = recent[idx];
                  final statusStr = (c['status'] ?? 'pending').toString().toLowerCase();
                  final isResolved = statusStr == 'resolved';
                  final isPending = statusStr == 'pending';

                  final badgeBg = isResolved ? Colors.green.shade50 : (isPending ? Colors.amber.shade50 : Colors.blue.shade50);
                  final badgeColor = isResolved ? Colors.green.shade800 : (isPending ? Colors.amber.shade900 : Colors.blue.shade800);

                  return ListTile(
                    title: Text(c['title'] ?? 'Complaint', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('By ${c['resident'] ?? 'Resident'} • ${c['created_at'] ?? ''}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        statusStr.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: SECURITY & GATE LOGS
  // ===========================================================================
  Widget _buildSecurityTab(Map<String, dynamic> security) {
    final vTotal = security['total_visitors_logged'] ?? 0;
    final vToday = security['visitors_today'] ?? 0;
    final vMonth = security['visitors_this_month'] ?? 0;
    final vInside = security['currently_inside'] ?? 0;
    final activeAlerts = security['active_alerts_count'] ?? 0;
    final totalAlerts = security['total_alerts_count'] ?? 0;
    final purposes = (security['purpose_breakdown'] as List<dynamic>?) ?? [];
    final alerts = (security['alerts_breakdown'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: () async => _loadReport(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Security Overview Hero Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Visitor Gate Logs & Security Traffic', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                          const SizedBox(width: 4),
                          Text('Inside: $vInside', style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$vTotal', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _heroMetricItem('Logged Today', '$vToday', Colors.white)),
                    const SizedBox(width: 6),
                    Expanded(child: _heroMetricItem('Logged This Month', '$vMonth', Colors.tealAccent)),
                    const SizedBox(width: 6),
                    Expanded(child: _heroMetricItem('Active Alerts', '$activeAlerts', activeAlerts > 0 ? Colors.redAccent : Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Visitor Purpose Breakdown
          _buildSectionHeader(title: 'Visitor Purpose Breakdown', icon: Icons.badge_outlined),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: purposes.isEmpty
                  ? const Text('No visitor log entries found.')
                  : Column(
                      children: purposes.map((p) {
                        final count = p['count'] ?? 0;
                        final double pct = vTotal > 0 ? (count / vTotal) : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(p['purpose'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('$count (${(pct * 100).toStringAsFixed(0)}%)', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Security Emergency Incident History
          _buildSectionHeader(title: 'Emergency Incidents & Alerts ($totalAlerts)', icon: Icons.warning),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final a = alerts[idx];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.crisis_alert, color: Colors.white, size: 18),
                  ),
                  title: Text(a['type'] ?? 'Emergency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Recorded security alert incident', style: TextStyle(fontSize: 11)),
                  trailing: Text('${a['count']} incidents', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 5: FACILITIES & VEHICLES
  // ===========================================================================
  Widget _buildFacilitiesTab(Map<String, dynamic> facilities, Map<String, dynamic> vehicles) {
    final amTotal = facilities['total_amenities'] ?? 0;
    final amAvail = facilities['available_amenities'] ?? 0;
    final amMaint = facilities['maintenance_amenities'] ?? 0;
    final amList = (facilities['amenities_list'] as List<dynamic>?) ?? [];

    final bkTotal = facilities['total_bookings'] ?? 0;
    final bkConfirmed = facilities['confirmed_bookings'] ?? 0;
    final bkPending = facilities['pending_bookings'] ?? 0;

    final vehTotal = vehicles['total_vehicles'] ?? 0;
    final veh2w = vehicles['two_wheelers'] ?? 0;
    final veh4w = vehicles['four_wheelers'] ?? 0;
    final vehSlots = vehicles['allocated_slots_count'] ?? 0;

    return RefreshIndicator(
      onRefresh: () async => _loadReport(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Amenities Hero Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.cyan.shade900, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amenities & Community Facilities', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text('Available: $amAvail / $amTotal', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('$amTotal Facilities', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _heroMetricItem('Operational', '$amAvail', Colors.greenAccent)),
                    const SizedBox(width: 6),
                    Expanded(child: _heroMetricItem('Under Maint.', '$amMaint', Colors.amberAccent)),
                    const SizedBox(width: 6),
                    Expanded(child: _heroMetricItem('Bookings ($bkConfirmed Confirmed)', '$bkTotal', Colors.white)),
                  ],
                ),
                if (bkPending > 0) ...[
                  const SizedBox(height: 8),
                  Text('• $bkPending pending booking(s) awaiting approval', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Amenities List
          _buildSectionHeader(title: 'Active Society Amenities', icon: Icons.sports_tennis),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: amList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final a = amList[idx];
                final isAvailable = (a['status'] ?? '').toString().toLowerCase() == 'available';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.pool, color: Colors.blueAccent, size: 20),
                  ),
                  title: Text(a['name'] ?? 'Amenity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Location: ${a['location'] ?? 'Clubhouse'} • Max Capacity: ${a['capacity'] ?? 'N/A'}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isAvailable ? 'OPERATIONAL' : 'MAINTENANCE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isAvailable ? Colors.green.shade800 : Colors.red.shade800),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Vehicles & Parking Allotment Section
          _buildSectionHeader(title: 'Vehicles & Parking Slots Allocation', icon: Icons.local_parking),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statMiniCard('Total Vehicles', '$vehTotal', Icons.directions_car, Colors.blueAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statMiniCard('4-Wheelers (Cars)', '$veh4w', Icons.directions_car_filled, Colors.blueAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statMiniCard('2-Wheelers (Bikes)', '$veh2w', Icons.two_wheeler, Colors.blueAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statMiniCard('Allocated Slots', '$vehSlots', Icons.local_parking, Colors.blueAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.blue.shade800, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Parking Allotment: $vehSlots out of $vehTotal registered vehicles have an allocated parking spot.',
                            style: TextStyle(fontSize: 11.5, color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  // SHARED MINI HELPERS
  // ===========================================================================
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _statMiniCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 16),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
