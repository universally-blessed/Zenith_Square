import 'package:flutter/material.dart';
import '../services/api_service.dart';
import './reports_screen.dart';
import './users_screen.dart';
import './socities_screen.dart';
import '../services/session_manager.dart';
import './login_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const DashboardScreen({super.key, required this.adminData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _loading = true;
  Map<String, dynamic>? _overviewDashboardData;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    try {
      final overview = await ApiService.getOverviewDashboard();
      setState(() {
        _overviewDashboardData = overview;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) =>
                setState(() => _selectedIndex = idx),
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF1E293B),
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.blue.shade300,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.apartment),
                label: Text('Societies'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics),
                label: Text('MIS Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    tooltip: 'Logout',
                    onPressed: () async {
                      await SessionManager.clearSession();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildBodyContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return const SocietiesScreen();
      case 2:
        return UsersScreen(adminData: widget.adminData);
      case 3:
        return const ReportsScreen();
      case 4:
        return ProfileScreen(adminData: widget.adminData);
      default:
        return Center(
          child: Text('Section $_selectedIndex under construction'),
        );
    }
  }

  Widget _buildOverviewTab() {
    final kpis = _overviewDashboardData?['kpis'] ?? {};
    final int pendingAdminCount = kpis['pending_admin_count'] ?? 0;
    final int pendingChairmanCount = kpis['pending_chairman_count'] ?? 0;
    final pendingReqs =
        _overviewDashboardData?['pending_committee_requests']
            as List<dynamic>? ??
        [];
    final recentUsers =
        _overviewDashboardData?['recent_users'] as List<dynamic>? ?? [];
    final recentFeedbacks =
        _overviewDashboardData?['recent_feedbacks'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.adminData['username'] ?? 'Super Admin'}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Platform-wide governance and operational summary',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (pendingAdminCount > 0 || pendingChairmanCount > 0)
              Row(
                children: [
                  if (pendingAdminCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$pendingAdminCount Need Your Approval',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (pendingChairmanCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$pendingChairmanCount Awaiting Chairman',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _kpiCard(
              'Total Societies',
              '${kpis['total_societies'] ?? 0}',
              Icons.apartment,
              Colors.indigo,
            ),
            const SizedBox(width: 16),
            _kpiCard(
              'Active Societies',
              '${kpis['active_societies'] ?? 0}',
              Icons.domain_verification,
              Colors.teal,
            ),
            const SizedBox(width: 16),
            _kpiCard(
              'Registered Users',
              '${kpis['total_users'] ?? 0}',
              Icons.people,
              Colors.blue,
            ),
            const SizedBox(width: 16),
            _kpiCard(
              'Pending Approvals',
              '${kpis['pending_requests_count'] ?? (pendingAdminCount + pendingChairmanCount)}',
              Icons.assignment_late,
              Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _contentCard(
          title: 'Committee Role Change Requests',
          subtitle:
              'Requests awaiting Super Admin authorization or Chairman confirmation',
          icon: Icons.pending_actions,
          trailing: TextButton(
            onPressed: () => setState(() => _selectedIndex = 2),
            child: const Text('View All In Users Tab'),
          ),
          child: pendingReqs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No pending committee requests awaiting approval',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        columnSpacing: 24,
                        horizontalMargin: 16,
                        headingRowColor: WidgetStatePropertyAll(
                          Colors.grey.shade50,
                        ),
                        columns: const [
                          DataColumn(label: Text('Request ID')),
                          DataColumn(label: Text('Society')),
                          DataColumn(label: Text('Initiator')),
                          DataColumn(label: Text('Target User')),
                          DataColumn(label: Text('Requested Role')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: pendingReqs.map<DataRow>((r) {
                          final String status =
                              r['status'] ?? 'Pending_Admin_Approval';
                          final bool isAdminPending =
                              status == 'Pending_Admin_Approval';

                          return DataRow(
                            cells: [
                              DataCell(Text(r['request_id'] ?? '')),
                              DataCell(Text(r['society_name'] ?? '-')),
                              DataCell(Text(r['requested_by'] ?? '-')),
                              DataCell(Text(r['target_user'] ?? '-')),
                              DataCell(
                                Text(
                                  r['new_role'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAdminPending
                                        ? Colors.orange.withValues(alpha: 0.1)
                                        : Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: isAdminPending
                                          ? Colors.orange.shade800
                                          : Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isAdminPending
                                        ? const Color(0xFF2563EB)
                                        : Colors.grey.shade400,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: () =>
                                      setState(() => _selectedIndex = 2),
                                  child: Text(
                                    isAdminPending ? 'Review' : 'Track',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _contentCard(
                title: 'New Registered Users',
                subtitle: 'Latest members joined across societies',
                icon: Icons.person_add_alt,
                child: recentUsers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No users registered yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : Column(
                        children: recentUsers.map((u) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text(
                                (u['user_name'] as String? ?? 'U')[0]
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              u['user_name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${u['society_name']} • ${u['role_name']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (u['is_active'] ?? true)
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                (u['is_active'] ?? true)
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: (u['is_active'] ?? true)
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _contentCard(
                title: 'Resident Feedback & Suggestions',
                subtitle: 'Platform and community reviews from residents',
                icon: Icons.rate_review_outlined,
                child: recentFeedbacks.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No feedback entries logged yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : Column(
                        children: recentFeedbacks.map((fb) {
                          final int rating = fb['rating'] is int
                              ? fb['rating']
                              : int.tryParse(fb['rating'].toString()) ?? 5;

                          return ListTile(
                            onTap: () => _showFeedbackDetails(fb),
                            leading: CircleAvatar(
                              backgroundColor: Colors.amber.shade50,
                              child: const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              fb['comments'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${fb['society_name']} • By ${fb['user_name']} (${fb['created_at']})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                5,
                                (idx) => Icon(
                                  idx < rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _contentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF2563EB), size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 24,
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDetails(Map<String, dynamic> fb) {
    final int rating = fb['rating'] is int
        ? fb['rating']
        : int.tryParse(fb['rating'].toString()) ?? 5;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.rate_review_outlined, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text('Feedback #${fb['feedback_id']}'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ...List.generate(
                    5,
                    (idx) => Icon(
                      idx < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($rating / 5)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Submitted by: ${fb['user_name']} (${fb['society_name']})',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Text(
                'Date: ${fb['created_at']}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Divider(height: 24),
              const Text(
                'Feedback / Comments:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  fb['comments'] ?? '-',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
