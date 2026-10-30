import 'package:flutter/material.dart';
import '../../data/datasource/api_service.dart';

class SecretaryHomeScreen extends StatefulWidget {
  const SecretaryHomeScreen({super.key});

  @override
  State<SecretaryHomeScreen> createState() => _SecretaryHomeScreenState();
}

class _SecretaryHomeScreenState extends State<SecretaryHomeScreen> {
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
        title: const Text('Secretary Dashboard'),
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
          final userName = profile['user_name'] ?? 'Secretary';
          final societyName = profile['society_name'] ?? 'Zenith Square';
          final hasSecurity = profile['has_security'] ?? true;

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
                // Secretary Banner
                Card(
                  elevation: 0,
                  color: Colors.indigo.shade900,
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
                                'General Secretary | $societyName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.indigo.shade100,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigoAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Secretary',
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
                _buildSectionTitle('Administration & Management'),
                const SizedBox(height: 8),
                _buildGrid([
                  _ActionItem(
                    'Members & Flats',
                    Icons.people_alt_outlined,
                    Colors.blue.shade800,
                    '/secretary-members',
                  ),
                  _ActionItem(
                    'Complaints',
                    Icons.report_problem_outlined,
                    Colors.amber.shade800,
                    '/secretary-complaints',
                  ),
                  _ActionItem(
                    'Announcements',
                    Icons.campaign_outlined,
                    Colors.teal,
                    '/secretary-notices',
                  ),
                  _ActionItem(
                    'Maintenance Payment',
                    Icons.account_balance_wallet_outlined,
                    Colors.indigo,
                    '/secretary-finance',
                  ),
                  _ActionItem(
                    'Amenity Requests',
                    Icons.event_seat_outlined,
                    Colors.cyan.shade800,
                    '/secretary-amenities',
                  ),
                  _ActionItem(
                    'Assets & Service',
                    Icons.build_circle_outlined,
                    Colors.deepOrange,
                    '/secretary-assets',
                  ),
                  _ActionItem(
                    'Lost & Found',
                    Icons.manage_search_outlined,
                    Colors.brown,
                    '/secretary-lost-found',
                  ),
                  _ActionItem(
                    'Polls & Surveys',
                    Icons.how_to_vote_outlined,
                    Colors.purple,
                    '/secretary-polls',
                  ),
                  _ActionItem(
                    'Meetings',
                    Icons.groups_outlined,
                    Colors.deepPurple,
                    '/secretary-meetings',
                  ),
                  _ActionItem(
                    'Tenants',
                    Icons.real_estate_agent_outlined,
                    Colors.teal.shade700,
                    '/secretary-tenants',
                  ),
                  _ActionItem(
                    'Society Documents',
                    Icons.folder_shared_outlined,
                    Colors.blueGrey,
                    '/society-documents',
                  ),
                  if (hasSecurity)
                    _ActionItem(
                      'Security & Gate',
                      Icons.security_outlined,
                      Colors.red.shade700,
                      '/secretary-security',
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
        childAspectRatio: 0.82,
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
