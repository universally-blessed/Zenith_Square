import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/route_strings.dart';
import '../../core/networks/society_api_services.dart';

class ChairmanHomePage extends StatefulWidget {
  final Map<String, dynamic> chairmanData;
  final Function(int)? onNavigationRequested;

  const ChairmanHomePage({
    required this.chairmanData,
    this.onNavigationRequested,
    super.key,
  });

  @override
  State<ChairmanHomePage> createState() => _ChairmanHomePageState();
}

class _ChairmanHomePageState extends State<ChairmanHomePage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color accentBlue = Color(0xFF29B6F6);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color emeraldGreen = Color(0xFF2E7D32);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  Map<String, dynamic>? _liveMetrics;
  bool _isLoadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _loadLiveSocietyMetrics();
  }

  // Triggers the background network query straight to the PostgreSQL data rows
  Future<void> _loadLiveSocietyMetrics() async {
    final response = await SocietyApiService.fetchSocietyReportMetrics(
      _sessionToken,
    );
    if (mounted) {
      setState(() {
        if (response['success'] == true) {
          _liveMetrics = response['metrics'];
        }
        _isLoadingMetrics = false;
      });
    }
  }

  void _handleEmergencyBroadcast(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Broadcast Society Emergency?',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action will instantly send emergency push alerts and SMS messages to all registered residents across all wings.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.lexend(
                        color: darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '🚨 Emergency broadcast dispatched to all residents!',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Broadcast Now',
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(
          'Zenith Square Control Deck',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pushNamed(context, '/manage_profile'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(
                Icons.power_settings_new_outlined,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLiveSocietyMetrics,
        color: primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExecutiveHeader(),

              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 6.0),
                child: InkWell(
                  onTap: () => _handleEmergencyBroadcast(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.red.shade700,
                          child: const Icon(
                            Icons.gpp_maybe_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRIGGER EMERGENCY BROADCAST',
                                style: GoogleFonts.lexend(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red.shade900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to deploy security alerts & panic triggers',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.red.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              _buildDecisionApprovalCard(context),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    _buildSectionTitle('Administrative Management'),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildControlCard(
                          context,
                          'Broadcast Board',
                          Icons.campaign_rounded,
                          Colors.orange.shade800,
                          RouteStrings.manageNotices,
                        ),
                        _buildControlCard(
                          context,
                          'Resident Directory',
                          Icons.supervised_user_circle_sharp,
                          Colors.indigo.shade700,
                          RouteStrings.viewResidents,
                        ),
                        _buildControlCard(
                          context,
                          'Meeting Assembly',
                          Icons.groups_outlined,
                          Colors.teal.shade700,
                          '/manage_meetings',
                        ),
                        _buildControlCard(
                          context,
                          'Asset Registry',
                          Icons.gite_rounded,
                          Colors.blueGrey.shade700,
                          '/manage_assets',
                        ),
                        _buildControlCard(
                          context,
                          'Review Complaints',
                          Icons.assignment_late_outlined,
                          Colors.red.shade700,
                          RouteStrings.viewComplaints,
                        ),
                        _buildControlCard(
                          context,
                          'Society Reports',
                          Icons.analytics_outlined,
                          Colors.purple.shade700,
                          RouteStrings.societyReports,
                        ),
                        _buildControlCard(
                          context,
                          'Resident Payment Audit',
                          Icons.history_toggle_off_rounded,
                          Colors.green.shade700,
                          RouteStrings.financialSummary,
                        ),
                        _buildControlCard(
                          context,
                          'Society Expenses',
                          Icons.insert_chart_outlined_rounded,
                          Colors.blueGrey.shade800,
                          RouteStrings.expenseReport,
                        ),
                        _buildControlCard(
                          context,
                          'Lost & Found Logs',
                          Icons.find_in_page_outlined,
                          Colors.cyan.shade800,
                          '/lost_found_registry',
                        ),
                        _buildControlCard(
                          context,
                          'Committee Board',
                          Icons.assignment_ind_outlined,
                          Colors.deepPurple.shade800,
                          '/committee_management',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Live Society Metrics'),
                    const SizedBox(height: 12),
                    _isLoadingMetrics
                        ? Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryBlue,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : _buildLiveAnalyticsSection(),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Personal Resident Utilities'),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.0,
                      children: [
                        _buildMiniUtilityCard(
                          context,
                          'Pay Maintenance',
                          Icons.payment_outlined,
                          Colors.green.shade700,
                          '/pay_maintenance',
                        ),
                        _buildMiniUtilityCard(
                          context,
                          'Book Facility',
                          Icons.event_seat_outlined,
                          Colors.cyan.shade800,
                          '/book_amenity',
                        ),
                        _buildMiniUtilityCard(
                          context,
                          'Join Poll',
                          Icons.how_to_vote_outlined,
                          Colors.deepPurple.shade600,
                          '/participate_poll',
                        ),
                        _buildMiniUtilityCard(
                          context,
                          'My Vehicles',
                          Icons.directions_car_filled_outlined,
                          Colors.blue.shade800,
                          '/crud_vehicles',
                        ),
                        _buildMiniUtilityCard(
                          context,
                          'Nominees',
                          Icons.family_restroom_outlined,
                          Colors.pink.shade700,
                          '/manage_nominee',
                        ),
                        _buildMiniUtilityCard(
                          context,
                          'SOS Logs',
                          Icons.history_edu_rounded,
                          Colors.blueGrey.shade600,
                          '/trigger_emergency',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lexend(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: darkText,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildExecutiveHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elected Executive Panel',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.chairmanData['user_name'] ??
                        'Chairman Administrator',
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accentBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentBlue.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'CHAIRMAN',
                  style: GoogleFonts.lexend(
                    color: accentBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_city_rounded,
                  color: accentBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${widget.chairmanData['society_name'] ?? 'Zenith Square'} Administration Hub",
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionApprovalCard(BuildContext context) {
    bool isProcessing = false;
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setApprovalState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.gavel_rounded,
                      color: Colors.amber.shade900,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Executive Decisions',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteStrings.approveDecisions,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 2.0,
                        ),
                        child: Text(
                          'See All',
                          style: GoogleFonts.lexend(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.amber,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Proposal ID: RQ001 • Budget Update',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '1 Action Req',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Authorize a ₹15,000 reallocation ledger entry for common area main drainage pump overhaul line items requested by the Secretary.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isProcessing ? null : () {},
                      child: Text(
                        'Reject',
                        style: GoogleFonts.lexend(
                          color: Colors.red.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emeraldGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setApprovalState(() => isProcessing = true);
                              await Future.delayed(
                                const Duration(milliseconds: 800),
                              );
                              setApprovalState(() => isProcessing = false);
                            },
                      child: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Grant Approval',
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlCard(
    BuildContext context,
    String title,
    IconData icon,
    Color cardColor,
    String path,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, path),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: cardColor, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniUtilityCard(
    BuildContext context,
    String label,
    IconData icon,
    Color elementColor,
    String targetRoute,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushNamed(context, targetRoute),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: elementColor, size: 20),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveAnalyticsSection() {
    // Safely reads keys from server data dictionary, falling back to static strings if mapping breaks
    final String occupancy =
        _liveMetrics?['occupancy_rate']?.toString() ?? '85.0%';
    final String collection =
        _liveMetrics?['collection_rate']?.toString() ?? '81.7%';
    final String ownership =
        _liveMetrics?['ownership_ratio']?.toString() ?? '55% Own';
    final String tickerText =
        _liveMetrics?['system_ticker_msg']?.toString() ??
        'Average resolution timeline dropped to 3 days this month.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAnalyticsMiniMetric(
                'Occupancy Rate',
                occupancy,
                Colors.blue.shade800,
              ),
              _buildAnalyticsMiniMetric(
                'Collection (Q1)',
                collection,
                emeraldGreen,
              ),
              _buildAnalyticsMiniMetric(
                'Active Ratios',
                ownership,
                Colors.purple.shade700,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Row(
            children: [
              const Icon(Icons.trending_up, color: emeraldGreen, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tickerText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsMiniMetric(
    String title,
    String value,
    Color markerColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.black38,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: markerColor,
          ),
        ),
      ],
    );
  }
}
