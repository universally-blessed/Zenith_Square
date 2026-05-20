import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResidentHomePage extends StatelessWidget {
  // Callback actions passed down from the parent shell to switch tabs smoothly
  final Function(int)? onTabSwitchRequested;

  const ResidentHomePage({this.onTabSwitchRequested, super.key});

  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color accentBlue = Color(0xFF29B6F6);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(
          'Zenith Square',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 19,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.white,
              size: 26,
            ),
            // UX Solution 1: Navigates directly to Feed Tab (Index 1)
            onPressed: () => onTabSwitchRequested?.call(1),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(
                Icons.logout_outlined,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumHeader(),
            _buildEmergencySOSCard(
              context,
            ), // UI/UX Solution 2: With SnackBar context

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features & Services',
                    style: GoogleFonts.lexend(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FIXED GRID: childAspectRatio fixes the massive white spaces from your image
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio:
                        1.25, // Compact structure preventing layout stretch
                    children: [
                      _buildServiceCard(
                        context,
                        'Maintenance',
                        Icons.payment_outlined,
                        Colors.indigo.shade600,
                        '/maintenance',
                      ),
                      _buildServiceCard(
                        context,
                        'Book Amenities',
                        Icons.event_seat_outlined,
                        Colors.teal.shade600,
                        '/amenities',
                      ),
                      _buildServiceCard(
                        context,
                        'Complaints',
                        Icons.chat_bubble_outline_rounded,
                        Colors.amber.shade800,
                        '/complaints',
                      ),
                      _buildServiceCard(
                        context,
                        'My Vehicles',
                        Icons.time_to_leave_outlined,
                        Colors.cyan.shade700,
                        '/vehicles',
                      ),
                      _buildServiceCard(
                        context,
                        'Active Polls',
                        Icons.poll_outlined,
                        Colors.purple.shade600,
                        '/polls',
                      ),
                      _buildServiceCard(
                        context,
                        'Lost & Found',
                        Icons.fingerprint_outlined,
                        Colors.green.shade600,
                        '/lost_found',
                      ),
                      // Added to fulfill missing relational DB transparency report tracking
                      _buildServiceCard(
                        context,
                        'Expense Report',
                        Icons.insert_chart_outlined_rounded,
                        Colors.blueGrey.shade700,
                        '/expense_report',
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  _buildNoticeFeedSection(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Amit Harish Patel',
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.apartment_outlined,
                  color: accentBlue,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Zenith Square  •  Block A-101',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySOSCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(
              Icons.gpp_maybe_outlined,
              color: Colors.red.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency SOS',
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Alert main gate security immediately.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // UI/UX Solution 2: Interactive validation acknowledgment snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'SOS Alert Transmitted! Gate Security Dispatched.',
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red.shade800,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              child: Text(
                'SOS',
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    IconData icon,
    Color elementColor,
    String route,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.pushNamed(context, route),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 14.0,
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centers elements vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Centers elements horizontally
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: elementColor.withValues(alpha: 0.07),
                    shape: BoxShape
                        .circle, // Circular shape looks tighter and cleaner
                  ),
                  child: Icon(icon, color: elementColor, size: 24),
                ),
                const SizedBox(height: 12), // Tightly bounds text to icon
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeFeedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notice Board',
              style: GoogleFonts.lexend(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            TextButton(
              // UX Solution 4: Routes directly to the global Feed view tab shell
              onPressed: () => onTabSwitchRequested?.call(1),
              child: Text(
                'See All',
                style: GoogleFonts.lexend(
                  color: primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MAINTENANCE',
                      style: GoogleFonts.lexend(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  Text(
                    'May 20, 2026',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Water Supply Suspension Notice',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Please note that water utility supply will be paused from 10:00 AM to 01:00 PM for routine maintenance cleanings.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
