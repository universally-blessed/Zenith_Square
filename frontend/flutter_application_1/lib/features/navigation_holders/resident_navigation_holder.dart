import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './resident_page.dart';
import '../../core/networks/operational_api_service.dart';

class ResidentNavigationHolder extends StatefulWidget {
  const ResidentNavigationHolder({super.key});

  @override
  State<ResidentNavigationHolder> createState() =>
      _ResidentNavigationHolderState();
}

class _ResidentNavigationHolderState extends State<ResidentNavigationHolder> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic> _profileMeta = {
    'user_name': 'Loading...',
    'society_name': 'Zenith Square',
    'unit_info': 'Fetching Unit...',
  };

  // Active user session simulation token matching Django authentication backend
  final String _authToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";
  static const Color primaryBlue = Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    _fetchGlobalDashboardContext();
  }

  Future<void> _fetchGlobalDashboardContext() async {
    try {
      final result = await OperationalApiService.fetchDashboardMeta(_authToken);
      if (result['success'] == true) {
        setState(() {
          _profileMeta = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnack("Failed to parse structural profile context tokens.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Error communicating with data servers.");
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 3),
        ),
      );
    }

    // Dynamic relational tab construction injecting database content streams down to viewports
    final List<Widget> tabs = [
      ResidentHomePage(
        userData:
            _profileMeta, // Securely passing backend records directly into your home screen
        onTabSwitchRequested: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const ResidentActiveFeedPage(),
      const ResidentLoggedActionsPage(),
      ResidentProfileHubPage(
        profileData: _profileMeta,
      ), // Injecting active profile map down to template rows
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
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
          onTap: (index) => setState(() => _currentIndex = index),
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
class ResidentActiveFeedPage extends StatefulWidget {
  const ResidentActiveFeedPage({super.key});

  @override
  State<ResidentActiveFeedPage> createState() => _ResidentActiveFeedPageState();
}

class _ResidentActiveFeedPageState extends State<ResidentActiveFeedPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  late Future<List<dynamic>> _noticesFuture;
  late Future<List<dynamic>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshBroadcastPools();
  }

  void _refreshBroadcastPools() {
    setState(() {
      _noticesFuture = OperationalApiService.fetchNotices(_sessionToken);
      _meetingsFuture = OperationalApiService.fetchMeetings(_sessionToken);
    });
  }

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
              Tab(text: 'Meetings & MOM'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            _refreshBroadcastPools();
          },
          color: primaryBlue,
          child: TabBarView(
            children: [_buildNoticesTab(), _buildMeetingsTab()],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticesTab() {
    return FutureBuilder<List<dynamic>>(
      future: _noticesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No announcements posted on the notice board.',
              style: GoogleFonts.inter(color: Colors.black38, fontSize: 13.5),
            ),
          );
        }

        final noticesList = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: noticesList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final notice = noticesList[index];
            return _buildFeedItem(
              category: 'BROADCAST ALERT',
              tagColor: Colors.orange.shade800,
              date: notice['created_at'] ?? '',
              title: notice['title'] ?? 'Untitled Notice',
              body: notice['description'] ?? '',
            );
          },
        );
      },
    );
  }

  Widget _buildMeetingsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _meetingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No council or general meetings scheduled.',
              style: GoogleFonts.inter(color: Colors.black38, fontSize: 13.5),
            ),
          );
        }

        final meetingsList = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: meetingsList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final meeting = meetingsList[index];
            bool hasMOM = (meeting['minutes_doc'] ?? '').toString().isNotEmpty;

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hasMOM
                              ? Colors.teal.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hasMOM ? 'MOM AVAILABLE' : 'UPCOMING',
                          style: GoogleFonts.lexend(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: hasMOM
                                ? Colors.teal.shade800
                                : Colors.blue.shade800,
                          ),
                        ),
                      ),
                      Text(
                        meeting['meeting_date'] ?? '',
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
                    meeting['title'] ?? 'Committee Assembly',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${meeting['location']} • Time: ${meeting['start_time']}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  if (meeting['agenda'].toString().isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    Text(
                      "Agenda: ${meeting['agenda']}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeedItem({
    required String category,
    required Color tagColor,
    required String date,
    required String title,
    required String body,
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

// ================= Tab 3 Content (Refactored Stateful Implementation) =================
class ResidentLoggedActionsPage extends StatefulWidget {
  const ResidentLoggedActionsPage({super.key});

  @override
  State<ResidentLoggedActionsPage> createState() =>
      ResidentLoggedActionsPageState(); // <-- Error: Looking for _ResidentLoggedActionsPageState
}

class ResidentLoggedActionsPageState extends State<ResidentLoggedActionsPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  // Active user session simulation token matching Django authentication back-end
  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  late Future<List<dynamic>> _complaintsFuture;
  late Future<List<dynamic>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshDataPools();
  }

  void _refreshDataPools() {
    setState(() {
      _complaintsFuture = OperationalApiService.fetchComplaints(_sessionToken);
      _bookingsFuture = OperationalApiService.fetchLiveReservations(
        _sessionToken,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
        body: RefreshIndicator(
          onRefresh: () async {
            _refreshDataPools();
          },
          color: primaryBlue,
          child: TabBarView(
            children: [_buildComplaintsTab(), _buildBookingsTab()],
          ),
        ),
      ),
    );
  }

  // Tab A: Displays complaints logged dynamically via Django database serialization templates
  Widget _buildComplaintsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _complaintsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No active complaints logged.',
              style: GoogleFonts.inter(color: Colors.black38, fontSize: 13.5),
            ),
          );
        }

        final complaintsList = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: complaintsList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = complaintsList[index];
            String status = (item['status'] ?? 'PENDING')
                .toString()
                .toUpperCase();
            Color statusColor = status == 'RESOLVED'
                ? Colors.green
                : Colors.amber.shade900;

            return _buildTrackerCard(
              id: item['complaint_id'] ?? 'CM-UNK',
              title: item['title'] ?? 'Untitled Issue',
              subtitle:
                  "Logged on: ${(item['created_at'] ?? '').toString().split('T')[0]}",
              statusText: status,
              statusColor: statusColor,
              icon: Icons.chat_bubble_outline_rounded,
              trailingDetails:
                  item['description'] ?? 'No description supplied.',
            );
          },
        );
      },
    );
  }

  // Tab B: Displays bookings logged dynamically via amenity_booking schema rows
  Widget _buildBookingsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No asset reservations found.',
              style: GoogleFonts.inter(color: Colors.black38, fontSize: 13.5),
            ),
          );
        }

        final bookingsList = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: bookingsList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = bookingsList[index];
            String status = (item['status'] ?? 'PENDING')
                .toString()
                .toUpperCase();

            Color statusColor = Colors.amber.shade900;
            if (status == 'APPROVED') statusColor = Colors.blue.shade700;
            if (status == 'EXPIRED') statusColor = Colors.red.shade800;

            return _buildTrackerCard(
              id: item['booking_id'] ?? 'BK-UNK',
              title: "Amenity: ${item['amenity_id'] ?? 'Facility'}",
              subtitle: "Event Date: ${item['booking_date']}",
              statusText: status,
              statusColor: statusColor,
              icon: Icons.gite_outlined,
              trailingDetails:
                  "Allocated Slots: ${item['slots'] ?? 'Unassigned Window'}",
            );
          },
        );
      },
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
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
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
  final Map<String, dynamic>
  profileData; // Receives dynamic data packet from backend context
  final VoidCallback?
  onProfileUpdated; // Optional handle to trigger data re-fetch on parent holder

  const ResidentProfileHubPage({
    required this.profileData,
    this.onProfileUpdated,
    super.key,
  });

  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ACCOUNT INFORMATION BLOCK
            _buildInfoCard(
              title: 'Account Information',
              icon: Icons.person_outline_rounded,
              onActionPressed: () async {
                // Passes live session data down to input field controllers natively
                final dynamic checkSuccess = await Navigator.pushNamed(
                  context,
                  '/update_profile',
                  arguments: {
                    'phone': profileData['phone'],
                    'email': profileData['email'],
                  },
                );
                // Trigger refresh if database row mutation completes successfully
                if (checkSuccess == true && onProfileUpdated != null) {
                  onProfileUpdated!();
                }
              },
              actionLabel: 'Modify',
              children: [
                _buildDataRow(
                  'Full Name',
                  profileData['user_name'] ?? 'Resident Member',
                ),
                _buildDataRow('Phone Number', profileData['phone'] ?? 'N/A'),
                _buildDataRow(
                  'Email Address',
                  (profileData['email'] == null ||
                          profileData['email'].toString().isEmpty)
                      ? 'Not Provided'
                      : profileData['email'],
                ),
                const Divider(height: 16),
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/change_password',
                  ), // FIX: Adjusted route path match rule keys
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 4.0,
                    ),
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

            // 2. NOMINEE BLOCK (Static parameters awaiting phase updates)
            _buildInfoCard(
              title: 'Nominee & Emergency Contact',
              icon: Icons.contact_emergency_outlined,
              onActionPressed: () =>
                  Navigator.pushNamed(context, '/update_nominee'),
              actionLabel: 'Manage',
              children: [
                _buildDataRow('Nominee Name', 'Priya Shah'),
                _buildDataRow('Relationship', 'Spouse'),
                _buildDataRow('Contact Phone', '+91 9876543211'),
                _buildDataRow('Address', 'Satellite Road, Ahmedabad'),
              ],
            ),
            const SizedBox(height: 16),

            // 3. UNIT LOGS GENERAL OVERVIEW
            _buildInfoCard(
              title: 'Unit Tenancy Logs',
              icon: Icons.history_edu_outlined,
              children: [
                _buildDataRow(
                  'Assigned Space',
                  profileData['unit_info'] ?? 'Loading...',
                ),
                _buildDataRow('Current Status', 'Self Occupied'),
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
                _buildHistoryRow('Initial Allocation', 'Period: 2024-01-01'),
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
