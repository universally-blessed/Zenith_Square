import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_services.dart';

class ResidentHomePage extends StatelessWidget {
  final Map<String, dynamic>
  userData; // Receives data packet dynamically from parent holder
  final Function(int)? onTabSwitchRequested;

  const ResidentHomePage({
    required this.userData,
    this.onTabSwitchRequested,
    super.key,
  });

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
            _buildEmergencySOSCard(context),

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

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.25,
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
                      _buildServiceCard(
                        context,
                        'Expense Report',
                        Icons.insert_chart_outlined_rounded,
                        Colors.blueGrey.shade700,
                        '/expense_report',
                      ),
                      _buildServiceCard(
                        context,
                        'Give Feedback',
                        Icons.rate_review_outlined,
                        Colors.pink.shade700,
                        '/feedback',
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
          // Locate this section inside _buildPremiumHeader() in resident_page.dart:
          Text(
            // The '??' acts as an inline null-safety net
            userData['user_name'] ?? 'Resident Member',
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
                  // Safely bounds fallback text labels if the network loop is loading
                  "${userData['society_name'] ?? 'Zenith Square'}  •  ${userData['unit_info'] ?? 'Loading Space...'}",
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
    final String sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

    bool isSending = false; // ✅ Move here

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setCardState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade100, width: 1.2),
            ),
            child: Row(
              children: [
                Icon(Icons.gpp_maybe_outlined, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(child: Text("Emergency SOS")),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          setCardState(() => isSending = true);

                          bool success = await ApiService.triggerEmergencySOS(
                            sessionToken,
                          );

                          setCardState(() => isSending = false);
                        },
                  child: isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SOS"),
                ),
              ],
            ),
          ),
        );
      },
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: elementColor.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: elementColor, size: 24),
                ),
                const SizedBox(height: 12),
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
    // Pass your active session string token variables natively here
    final String sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

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
              onPressed: () => onTabSwitchRequested?.call(
                1,
              ), // Navigates cleanly to the dedicated Tab 2 ActiveFeed view
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

        FutureBuilder<List<dynamic>>(
          future: ApiService.fetchNotices(sessionToken),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: primaryBlue,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            // Fallback view state layout if database return runs empty arrays
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: Text(
                    'No active announcements posted.',
                    style: GoogleFonts.inter(
                      color: Colors.black38,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }

            // Capture the single absolute newest broadcast record item tuple line entry
            final newestNotice = snapshot.data!.first;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.01),
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
                          'LATEST NOTICE',
                          style: GoogleFonts.lexend(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                      Text(
                        newestNotice['created_at'] ?? '',
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
                    newestNotice['title'] ?? 'Untitled Broadcast',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    newestNotice['description'] ?? '',
                    maxLines:
                        2, // Keeps text cropped to look tidy on a summary dashboard card grid
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
