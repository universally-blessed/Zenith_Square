import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/finance_api_services.dart';

class SocietyReportsPage extends StatefulWidget {
  const SocietyReportsPage({super.key});

  @override
  State<SocietyReportsPage> createState() => _SocietyReportsPageState();
}

class _SocietyReportsPageState extends State<SocietyReportsPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color lightBg = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: lightBg,
        appBar: AppBar(
          backgroundColor: primaryBlue,
          elevation: 0,
          title: Text(
            'Society Analytics & Insights',
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.lexend(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.lexend(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.pie_chart_outline_rounded, size: 20),
                text: 'Demographics',
              ),
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined, size: 20),
                text: 'Financials',
              ),
              Tab(
                icon: Icon(Icons.analytics_outlined, size: 20),
                text: 'Operations',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(),
          children: [
            DemographicsBackgroundGrid(),
            FinancialBackgroundGrid(),
            OperationalBackgroundGrid(),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. DEMOGRAPHICS TAB VIEW COMPONENTS
// ==========================================
class DemographicsBackgroundGrid extends StatelessWidget {
  const DemographicsBackgroundGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader('Occupancy & Tenant Composition'),
        const SizedBox(height: 12),
        // Renders structural 55% / 30% / 15% breakdown parameters
        _buildStatCard(
          title: 'Total Community Distribution',
          value: '60 Total Registered Flats', // Ripped from MIS metric counts
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildProgressMetricRow(
                'Owner Occupied (55%)',
                33,
                60,
                Colors.blue.shade700,
              ),
              _buildProgressMetricRow(
                'Tenant Occupied (30%)',
                18,
                60,
                Colors.teal.shade600,
              ),
              _buildProgressMetricRow(
                'Vacant Spaces (15%)',
                9,
                60,
                Colors.orange.shade700,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader('Diversity Metrics'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildValueIndicatorCard(
                'Gender Diversity Ratio',
                '48 : 52',
                'Male vs Female %',
                Icons.wc_rounded,
                Colors.indigo.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildValueIndicatorCard(
                'Overall Occupancy',
                '85.0%',
                'Active residency status',
                Icons.holiday_village_outlined,
                Colors.green.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================
// 2. FINANCIALS TAB VIEW COMPONENTS
// ==========================================
class FinancialBackgroundGrid extends StatelessWidget {
  const FinancialBackgroundGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader('Maintenance Collection Ratios'),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'March 2026 Invoice Collection Tracker',
          value: '81.7% Fulfilled',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: 0.817,
                backgroundColor: Colors.grey.shade200,
                color: Colors.green.shade700,
                minHeight: 10,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSubIndicatorText(
                    'Active Defaulters',
                    '3 Units',
                    Colors.red.shade800,
                  ),
                  _buildSubIndicatorText(
                    'Standard Unit Rate',
                    '₹2,500/Mo',
                    _ResidentReportsStyle.darkText,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader('Monthly Expense Overhaul Breakdown'),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'Utility & Operation Capital Pools (March 2026)',
          value: 'Total Spent: ₹50,000',
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildProgressMetricRow(
                'Staff Salaries (50%)',
                25000,
                50000,
                Colors.amber.shade900,
              ),
              _buildProgressMetricRow(
                'Electricity Draw (22%)',
                11000,
                50000,
                Colors.blue.shade700,
              ),
              _buildProgressMetricRow(
                'Maintenance & Assets (10.8%)',
                5400,
                50000,
                Colors.purple.shade600,
              ),
              _buildProgressMetricRow(
                'Water Infrastructure (9.6%)',
                4800,
                50000,
                Colors.cyan.shade700,
              ),
              _buildProgressMetricRow(
                'Structural Repairs (7.6%)',
                3800,
                50000,
                Colors.red.shade600,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 3. OPERATIONS TAB VIEW COMPONENTS
// ==========================================
class OperationalBackgroundGrid extends StatelessWidget {
  const OperationalBackgroundGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader('Facility Allocation & Asset Bookings'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildValueIndicatorCard(
                'Total Amenities Booked',
                '18 Slots',
                'Reservations completed',
                Icons.bookmark_added_outlined,
                Colors.teal.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildValueIndicatorCard(
                'Revenue Gathered',
                '₹16,300',
                'Asset collection funds',
                Icons.monetization_on_outlined,
                Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Complaint Categories & Performance'),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'Resolution Service Speed Performance',
          value: '3 Days Average Turnaround',
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildProgressMetricRow(
                'Electrical Queries Resolved',
                4,
                4,
                Colors.green.shade700,
              ),
              _buildProgressMetricRow(
                'Plumbing Grievances Logged',
                3,
                3,
                Colors.blue.shade700,
              ),
              _buildProgressMetricRow(
                'Parking Rules Inquiries',
                3,
                3,
                Colors.purple.shade700,
              ),
              _buildProgressMetricRow(
                'Common Area Tickets Filed',
                2,
                2,
                Colors.orange.shade700,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Volume Filed: 20 Tickets',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Resolved: 14 Tickets',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 🛠️ REUSABLE DASHBOARD INTERFACE UTILITIES
// ==========================================
Widget _buildSectionHeader(String sectionLabel) {
  return Text(
    sectionLabel,
    style: GoogleFonts.lexend(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: _ResidentReportsStyle.darkText,
      letterSpacing: -0.1,
    ),
  );
}

Widget _buildStatCard({
  required String title,
  required String value,
  required Widget child,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1A237E).withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _ResidentReportsStyle.primaryBlue,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Divider(height: 1, thickness: 0.5),
        ),
        child,
      ],
    ),
  );
}

Widget _buildProgressMetricRow(
  String rowLabel,
  int activePart,
  int totalSum,
  Color metricsColor,
) {
  double ratioFraction = totalSum > 0 ? (activePart / totalSum) : 0.0;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              rowLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _ResidentReportsStyle.darkText,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$activePart Units',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratioFraction,
          backgroundColor: Colors.grey.shade100,
          color: metricsColor,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    ),
  );
}

Widget _buildValueIndicatorCard(
  String title,
  String bigValue,
  String subtitle,
  IconData conceptualIcon,
  Color decorationColor,
) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: decorationColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(conceptualIcon, color: decorationColor, size: 18),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.black38,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          bigValue,
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _ResidentReportsStyle.darkText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.black45),
        ),
      ],
    ),
  );
}

Widget _buildSubIndicatorText(String label, String value, Color textHue) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: Colors.black38),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: GoogleFonts.lexend(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: textHue,
        ),
      ),
    ],
  );
}

// Private style helper isolation block
class _ResidentReportsStyle {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
}
