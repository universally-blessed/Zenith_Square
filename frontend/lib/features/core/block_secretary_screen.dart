import 'package:flutter/material.dart';
import '../../data/datasource/api_service.dart';

class BlockSecretaryHomeScreen extends StatefulWidget {
  const BlockSecretaryHomeScreen({super.key});

  @override
  State<BlockSecretaryHomeScreen> createState() =>
      _BlockSecretaryHomeScreenState();
}

class _BlockSecretaryHomeScreenState extends State<BlockSecretaryHomeScreen> {
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
        title: const Text('Block Secretary Panel'),
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
          final userName = profile['user_name'] ?? 'Block Secretary';
          final blockName = profile['block_name'] ?? 'Block';
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
                // Block Secretary Banner
                Card(
                  elevation: 0,
                  color: Colors.teal.shade900,
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
                                '$blockName Representative | $societyName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.teal.shade100,
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
                            color: Colors.teal.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            blockName,
                            style: const TextStyle(
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
                _buildSectionTitle('Block & Community Operations'),
                const SizedBox(height: 8),
                _buildGrid([
                  _ActionItem(
                    'Block Residents',
                    Icons.groups_outlined,
                    Colors.teal.shade800,
                    '/block-secretary-residents',
                  ),
                  _ActionItem(
                    'Block Complaints',
                    Icons.report_problem_outlined,
                    Colors.amber.shade800,
                    '/block-secretary-complaints',
                  ),
                  _ActionItem(
                    'Block Notices',
                    Icons.campaign_outlined,
                    Colors.cyan.shade800,
                    '/block-secretary-notices',
                  ),
                  _ActionItem(
                    'Maintenance Payment',
                    Icons.groups_outlined,
                    Colors.deepPurple,
                    '/block-secretary-finance',
                  ),
                  _ActionItem(
                    'Lost & Found',
                    Icons.manage_search_outlined,
                    Colors.brown,
                    '/lost-found',
                  ),
                  _ActionItem(
                    'Polls & Voting',
                    Icons.how_to_vote_outlined,
                    Colors.purple,
                    '/polls',
                  ),
                  _ActionItem(
                    'Meetings',
                    Icons.groups_outlined,
                    Colors.deepPurple,
                    '/meetings',
                  ),
                  _ActionItem(
                    'Amenities',
                    Icons.groups_outlined,
                    Colors.deepPurple,
                    '/amenities',
                  ),
                  _ActionItem(
                    'Society Documents',
                    Icons.how_to_vote_outlined,
                    Colors.purple,
                    '/society-documents',
                  ),
                  _ActionItem(
                    'Vehicles',
                    Icons.groups_outlined,
                    Colors.deepPurple,
                    '/vehicles',
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
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
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
                vertical: 16.0,
                horizontal: 12.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: item.color.withValues(alpha: 0.12),
                    child: Icon(item.icon, size: 24, color: item.color),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
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
