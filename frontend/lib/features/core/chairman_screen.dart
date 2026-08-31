import 'package:flutter/material.dart';
import '../../data/datasource/api_service.dart';

class ChairmanHomeScreen extends StatefulWidget {
  const ChairmanHomeScreen({super.key});

  @override
  State<ChairmanHomeScreen> createState() => _ChairmanHomeScreenState();
}

class _ChairmanHomeScreenState extends State<ChairmanHomeScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.fetchUserProfile();
  }

  void _handleLogout() async {
    await ApiService.clearAuthData();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Chairman Dashboard'),
        elevation: 0,
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
          final userName = profile['user_name'] ?? 'Chairman';
          final societyName = profile['society_name'] ?? 'Zenith Square';

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _profileFuture = ApiService.fetchUserProfile();
              });
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              children: [
                // 1. Chairman Banner Card
                Card(
                  elevation: 0,
                  color: Colors.blueGrey.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                                'Management Panel | $societyName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blueGrey.shade100,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Chairman',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Society Administrative Modules
                _buildSectionTitle('Society Governance'),
                const SizedBox(height: 8),
                _buildGrid([
                  _ActionItem(
                    'Finance',
                    Icons.account_balance_wallet_outlined,
                    Colors.indigo,
                    '/chairman-finance',
                  ),
                  _ActionItem(
                    'Complaints',
                    Icons.report_problem_outlined,
                    Colors.amber.shade800,
                    '/chairman-complaints',
                  ),
                  _ActionItem(
                    'Announcements',
                    Icons.campaign_outlined,
                    Colors.teal,
                    '/chairman-notices',
                  ),
                  _ActionItem(
                    'Amenities',
                    Icons.pool_outlined,
                    Colors.cyan.shade700,
                    '/chairman-amenities',
                  ),
                  _ActionItem(
                    'Vehicles',
                    Icons.directions_car_outlined,
                    Colors.blueGrey,
                    '/chairman-vehicles',
                  ),
                  _ActionItem(
                    'Meetings',
                    Icons.groups_outlined,
                    Colors.deepPurple,
                    '/chairman-meetings',
                  ),
                  _ActionItem(
                    'Polls',
                    Icons.how_to_vote_outlined,
                    Colors.orange.shade700,
                    '/chairman-polls',
                  ),
                  _ActionItem(
                    'Lost & Found',
                    Icons.search_outlined,
                    Colors.brown,
                    '/chairman-lost-found',
                  ),
                  _ActionItem(
                    'Security Desk',
                    Icons.security_outlined,
                    Colors.red.shade700,
                    '/chairman-security',
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
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
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.pushNamed(context, item.route),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 8.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: item.color.withValues(alpha: 0.12),
                    child: Icon(item.icon, size: 20, color: item.color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
  final String route;

  _ActionItem(this.title, this.icon, this.color, this.route);
}
