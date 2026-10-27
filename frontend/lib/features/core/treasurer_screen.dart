import 'package:flutter/material.dart';
import '../../data/datasource/api_service.dart';
import '../../data/datasource/finance_api_service.dart';
import '../finance/treasurer_finance_screen.dart';

class TreasurerHomeScreen extends StatefulWidget {
  const TreasurerHomeScreen({super.key});

  @override
  State<TreasurerHomeScreen> createState() => _TreasurerHomeScreenState();
}

class _TreasurerHomeScreenState extends State<TreasurerHomeScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfileAndCheckRole();
    _summaryFuture = FinanceApiService.fetchFinancialSummary();
  }

  Future<Map<String, dynamic>> _loadProfileAndCheckRole() async {
    try {
      final profile = await ApiService.fetchUserProfile();
      final role = (profile['role_name'] ?? '').toString().toLowerCase();
      if (mounted) {
        if (role == 'chairman') {
          Navigator.pushNamedAndRemoveUntil(context, '/chairman-home', (route) => false);
        } else if (role.contains('security') || role.contains('guard')) {
          Navigator.pushNamedAndRemoveUntil(context, '/security-home', (route) => false);
        } else if (role != 'treasurer') {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
      return profile;
    } catch (_) {
      rethrow;
    }
  }

  void _handleLogout() async {
    await ApiService.clearAuthData();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _navigateToFinanceTab(int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TreasurerFinanceScreen(initialTabIndex: tabIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Treasurer Desk'),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data ?? {};
          final userName = profile['user_name'] ?? 'Nirmal Patel';
          final societyName = profile['society_name'] ?? 'Serene Heights';
          final blockName = profile['block_name'] ?? '';
          final flatNumber = profile['flat_number'] ?? '';

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _profileFuture = _loadProfileAndCheckRole();
                _summaryFuture = FinanceApiService.fetchFinancialSummary();
              });
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              children: [
                // 1. Treasurer Header Card
                Card(
                  elevation: 0,
                  color: const Color(0xFF0F172A), // Dark slate
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Chief Treasurer • $societyName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade100,
                                ),
                              ),
                              if (flatNumber.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Resident Unit: $blockName - $flatNumber',
                                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Treasurer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Real-time Live Treasury Metrics Card
                FutureBuilder<Map<String, dynamic>>(
                  future: _summaryFuture,
                  builder: (context, sumSnap) {
                    final sData = sumSnap.data ?? {};
                    final netBal = (sData['net_balance'] ?? 0.0).toDouble();
                    final collected = (sData['total_collected'] ?? 0.0).toDouble();
                    final pending = (sData['total_pending'] ?? 0.0).toDouble();

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _navigateToFinanceTab(0),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Live Society Treasury',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                ),
                                Row(
                                  children: [
                                    Text('View Ledger', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                                    Icon(Icons.chevron_right, size: 16, color: Colors.blue.shade700),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _quickStat('Net Balance', '₹${netBal.toStringAsFixed(0)}', Colors.blue.shade800),
                                _quickStat('Total Collected', '₹${collected.toStringAsFixed(0)}', Colors.green.shade800),
                                _quickStat('Pending Dues', '₹${pending.toStringAsFixed(0)}', Colors.orange.shade900),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // 3. Treasury & Financial Management
                _buildSectionTitle('Treasury & Financial Management'),
                const SizedBox(height: 8),
                _buildGrid([
                  _ActionItem('Ledger Summary', Icons.account_balance_wallet, Colors.indigo, () => _navigateToFinanceTab(0)),
                  _ActionItem('Maintenance Bills', Icons.add_card, Colors.blueAccent, () => _navigateToFinanceTab(1)),
                  _ActionItem('Society Income', Icons.savings_outlined, Colors.teal.shade700, () => _navigateToFinanceTab(2)),
                  _ActionItem('Offline Verify', Icons.verified, Colors.teal, () => _navigateToFinanceTab(3)),
                  _ActionItem('Expenses & Utilities', Icons.money_off, Colors.redAccent, () => _navigateToFinanceTab(4)),
                  _ActionItem('Payment Receipts', Icons.history, Colors.deepPurple, () => _navigateToFinanceTab(5)),
                  _ActionItem('Bank Details', Icons.account_balance, Colors.amber.shade800, () => _navigateToFinanceTab(6)),
                  _ActionItem('Financial Reports', Icons.insert_chart_outlined, Colors.cyan.shade800, () => Navigator.pushNamed(context, '/treasurer-reports')),
                ]),

                const SizedBox(height: 20),

                // 4. Resident Services & Community
                _buildSectionTitle('Resident Services & Community'),
                const SizedBox(height: 8),
                _buildGrid([
                  _ActionItem('Pay Maintenance', Icons.receipt_long, Colors.indigo.shade700, () => Navigator.pushNamed(context, '/finance')),
                  _ActionItem('Security Desk', Icons.security_outlined, Colors.red.shade700, () => Navigator.pushNamed(context, '/security')),
                  _ActionItem('My Vehicles', Icons.directions_car_outlined, Colors.blueGrey, () => Navigator.pushNamed(context, '/vehicles')),
                  _ActionItem('Notices', Icons.campaign_outlined, Colors.teal, () => Navigator.pushNamed(context, '/notices')),
                  _ActionItem('Meetings', Icons.groups_outlined, Colors.deepPurple, () => Navigator.pushNamed(context, '/meetings')),
                  _ActionItem('Society Polls', Icons.how_to_vote_outlined, Colors.orange.shade700, () => Navigator.pushNamed(context, '/polls')),
                  _ActionItem('Lost & Found', Icons.search_outlined, Colors.brown, () => Navigator.pushNamed(context, '/lost-found')),
                  _ActionItem('Amenities Booking', Icons.pool_outlined, Colors.cyan.shade700, () => Navigator.pushNamed(context, '/amenities')),
                  _ActionItem('Complaints Desk', Icons.report_problem_outlined, Colors.amber.shade900, () => Navigator.pushNamed(context, '/complaints')),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _quickStat(String title, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildGrid(List<_ActionItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: item.color.withValues(alpha: 0.12),
                    child: Icon(item.icon, color: item.color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionItem(this.title, this.icon, this.color, this.onTap);
}
