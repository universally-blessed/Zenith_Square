import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import your existing pages here
import './resident_page.dart';
// import './polls.dart'; // Using this as part of Active Feed
// import './complaints.dart'; // Using this inside Logged Actions

class ResidentNavigationHolder extends StatefulWidget {
  const ResidentNavigationHolder({super.key});

  @override
  State<ResidentNavigationHolder> createState() =>
      _ResidentNavigationHolderState();
}

class _ResidentNavigationHolderState extends State<ResidentNavigationHolder> {
  int _currentIndex = 0;

  // Global theme color mirroring your onboarding system branding archetype
  static const Color primaryBlue = Color(0xFF1A237E);

  // Structural mapping of your core functional domains
  late final List<Widget> _tabs = [
    ResidentHomePage(
      onTabSwitchRequested: (index) {
        setState(() {
          _currentIndex =
              index; // Smoothly changes the bottom bar state programmatically
        });
      },
    ),
    const ResidentActiveFeedPage(),
    const ResidentLoggedActionsPage(),
    const ResidentProfileHubPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack optimizes mobile performance by preserving tab state layouts when switching
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.black38,
          selectedLabelStyle: GoogleFonts.lexend(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.lexend(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          iconSize: 24,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Actions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ================= Tab 2 Content (Cleanly Separated Class) =================
class ResidentActiveFeedPage extends StatelessWidget {
  const ResidentActiveFeedPage({super.key});

  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            'Society Broadcasts',
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          backgroundColor: primaryBlue,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.lexend(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.lexend(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Notice Board'),
              Tab(text: 'Meetings & MOM'), // Links to meeting & minutes records
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildNoticesList(context), _buildMeetingsList()],
        ),
      ),
    );
  }

  Widget _buildNoticesList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildFeedItem(
          category: 'MAINTENANCE ALERT',
          tagColor: Colors.orange.shade800,
          date: 'May 20, 2026',
          title: 'Elevator Shaft Inspection Block B',
          body:
              'Technicians will perform mandatory structural hoisting checks on Friday between 01:00 PM and 04:00 PM.',
          icon: Icons.build_circle_outlined,
        ),
      ],
    );
  }

  Widget _buildMeetingsList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'UPCOMING',
                      style: GoogleFonts.lexend(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  Text(
                    '2026-06-05',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Annual General Body Meeting (AGM)',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Location: Main Clubhouse Hall • Time: 10:00 AM',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedItem({
    required String category,
    required Color tagColor,
    required String date,
    required String title,
    required String body,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.lexend(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                  ),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= Tab 3 Content (Cleanly Separated Class) =================
class ResidentLoggedActionsPage extends StatelessWidget {
  const ResidentLoggedActionsPage({super.key});

  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Dual monitoring scopes
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            'Status Tracker',
            style: GoogleFonts.lexend(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          backgroundColor: primaryBlue,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'My Complaints'),
              Tab(text: 'Amenity Bookings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildComplaintsTab(), _buildBookingsTab()],
        ),
      ),
    );
  }

  // Tab A: Displays complaints logged via complaint table
  Widget _buildComplaintsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildTrackerCard(
          id: 'CMP-402',
          title: 'Plumbing Leakage Block A Shaft',
          subtitle: 'Reported on: 2026-05-18',
          statusText: 'RESOLVED',
          statusColor: Colors.green,
          icon: Icons.plumbing_outlined,
          trailingDetails: 'Resolved by Maintenance Cell on 2026-05-19.',
        ),
        const SizedBox(height: 14),
        _buildTrackerCard(
          id: 'CMP-419',
          title: 'Basement Lift Fan Inoperative',
          subtitle: 'Reported on: 2026-05-20',
          statusText: 'PENDING',
          statusColor: Colors.amber.shade900,
          icon: Icons.elevator_outlined,
          trailingDetails: 'Assigned to technical vendor operations team.',
        ),
      ],
    );
  }

  // Tab B: Displays bookings logged via amenity_booking table
  Widget _buildBookingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildTrackerCard(
          id: 'BKG-901',
          title: 'Clubhouse Banquet Hall',
          subtitle: 'Event Date: 2026-05-28',
          statusText: 'APPROVED',
          statusColor: Colors.blue.shade700,
          icon: Icons.gite_outlined,
          trailingDetails:
              'Timings: 04:00 PM - 11:00 PM • Verified by Secretary.',
        ),
      ],
    );
  }

  Widget _buildTrackerCard({
    required String id,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
    required IconData icon,
    required String trailingDetails,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: darkText, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, thickness: 0.6),
          ),
          Text(
            trailingDetails,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= Tab 4 Content (Cleanly Separated Class) =================
class ResidentProfileHubPage extends StatelessWidget {
  const ResidentProfileHubPage({super.key});

  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Profile & Household',
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
              Icons.history_toggle_off_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pushNamed(
              context,
              '/payment_history',
            ), // system connection to payment ledger logs
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: User Account Information Card
            // Inside Tab 4 Account Information Card children array:
            _buildInfoCard(
              title: 'Account Information',
              icon: Icons.person_outline_rounded,
              onActionPressed: () =>
                  Navigator.pushNamed(context, '/update_profile'),
              actionLabel: 'Modify',
              children: [
                _buildDataRow('Full Name', 'Amit Harish Patel'),
                _buildDataRow('Phone Number', '+91 9287451024'),
                _buildDataRow('Email Address', 'amitpatel@gmail.com'),
                const Divider(height: 16), // Divider for spacing
                // NEW Reset Password Navigation Row Trigger
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/reset_password'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Change Password',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Colors.red.shade800,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 2: Nominee Management
            _buildInfoCard(
              title: 'Nominee & Emergency Contact',
              icon: Icons.contact_emergency_outlined,
              onActionPressed: () => Navigator.pushNamed(
                context,
                '/update_nominee',
              ), // NEW Nominee Form connection
              actionLabel: 'Manage',
              children: [
                _buildDataRow('Nominee Name', 'Priya Shah'),
                _buildDataRow('Relationship', 'Spouse'),
                _buildDataRow('Contact Phone', '+91 9876543211'),
                _buildDataRow('Address', 'Satellite Road, Ahmedabad'),
              ],
            ),
            const SizedBox(height: 16),

            // Section 3: Relational Tenant & History Tracker
            _buildInfoCard(
              title: 'Unit Tenancy Logs',
              icon: Icons.history_edu_outlined,
              children: [
                _buildDataRow('Current Status', 'Rented Out'),
                _buildDataRow(
                  'Active Tenant',
                  'Rahul Mahesh Shah',
                ), // Maps to active row in tenant table
                _buildDataRow('Lease Move-In', '2025-01-10'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1),
                ),
                Text(
                  'Past Occupancy Logs',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 6),
                _buildHistoryRow(
                  'Ankit Vyas (Tenant)',
                  'Moved Out: 2024-12-01',
                ),
                _buildHistoryRow(
                  'Self Occupied',
                  'Period: 2024-01-01 to 2024-09-30',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    VoidCallback? onActionPressed,
    String? actionLabel,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ],
              ),
              if (onActionPressed != null && actionLabel != null)
                TextButton(
                  onPressed: onActionPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 20, thickness: 0.8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: darkText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String occupant, String duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            occupant,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
          ),
          Text(
            duration,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}
