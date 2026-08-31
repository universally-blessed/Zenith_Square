import 'package:flutter/material.dart';
import '../../data/datasource/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        title: const Text('Resident Portal'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile & Nominee',
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
          final userName = profile['user_name'] ?? 'Resident';
          final flatNumber = profile['flat_number'] ?? 'Unit --';
          final blockName = profile['block_name'] ?? 'Block --';
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
                // 1. Resident Unit Card
                Card(
                  elevation: 0,
                  color: Colors.blue.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$blockName - $flatNumber | $societyName',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade100,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. SOS Emergency Trigger Banner
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/security'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Emergency Security SOS',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.red.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Grid Modules
                _buildSectionTitle('Services & Management'),
                const SizedBox(height: 8),
                _buildGrid([
                  _ActionItem(
                    'Maintenance',
                    Icons.receipt_long,
                    Colors.indigo,
                    '/finance',
                  ),
                  _ActionItem(
                    'Complaints',
                    Icons.report_problem_outlined,
                    Colors.amber.shade800,
                    '/complaints',
                  ),
                  _ActionItem(
                    'Notices',
                    Icons.campaign_outlined,
                    Colors.teal,
                    '/notices',
                  ),
                  _ActionItem(
                    'Amenities',
                    Icons.pool_outlined,
                    Colors.cyan.shade700,
                    '/amenities',
                  ),
                  _ActionItem(
                    'Vehicles',
                    Icons.directions_car_outlined,
                    Colors.blueGrey,
                    '/vehicles',
                  ),
                  _ActionItem(
                    'Meetings',
                    Icons.groups_outlined,
                    Colors.deepPurple,
                    '/meetings',
                  ),
                  _ActionItem(
                    'Polls',
                    Icons.how_to_vote_outlined,
                    Colors.orange.shade700,
                    '/polls',
                  ),
                  _ActionItem(
                    'Lost & Found',
                    Icons.search_outlined,
                    Colors.brown,
                    '/lost-found',
                  ),
                  _ActionItem(
                    'Nominee',
                    Icons.badge_outlined,
                    Colors.blue,
                    '/nominee',
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
