import 'package:flutter/material.dart';
import '../../data/datasource/community_api_service.dart';

class SecretaryDirectoryScreen extends StatefulWidget {
  const SecretaryDirectoryScreen({super.key});

  @override
  State<SecretaryDirectoryScreen> createState() =>
      _SecretaryDirectoryScreenState();
}

class _SecretaryDirectoryScreenState extends State<SecretaryDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members & Committee Directory'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Residents Directory'),
            Tab(text: 'Committee Members'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SecretaryResidentsDirectoryTab(),
          _SecretaryCommitteeTab(),
        ],
      ),
    );
  }
}

// TAB 1: RESIDENTS DIRECTORY (With Block Filter & Search)
class _SecretaryResidentsDirectoryTab extends StatefulWidget {
  const _SecretaryResidentsDirectoryTab();

  @override
  State<_SecretaryResidentsDirectoryTab> createState() =>
      _SecretaryResidentsDirectoryTabState();
}

class _SecretaryResidentsDirectoryTabState
    extends State<_SecretaryResidentsDirectoryTab> {
  List<dynamic> _residents = [];
  List<dynamic> _blocks = [];
  String _selectedBlockId = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDirectory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDirectory() async {
    setState(() => _isLoading = true);
    try {
      final res = await CommunityApiService.fetchResidentsDirectory(
        blockId: _selectedBlockId,
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _residents = res['residents'] ?? [];
          _blocks = res['blocks'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by resident name or flat #',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _fetchDirectory();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (val) {
                  setState(() {}); // Rebuild to toggle clear icon
                },
                onSubmitted: (val) {
                  setState(() => _searchQuery = val);
                  _fetchDirectory();
                },
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Blocks'),
                      selected: _selectedBlockId == 'all',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedBlockId = 'all');
                          _fetchDirectory();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._blocks.map((b) {
                      final isSelected = _selectedBlockId == b['block_id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(b['block_name'] ?? ''),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedBlockId = selected
                                  ? b['block_id']
                                  : 'all';
                            });
                            _fetchDirectory();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _residents.isEmpty
              ? const Center(child: Text('No residents match your criteria.'))
              : RefreshIndicator(
                  onRefresh: _fetchDirectory,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _residents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = _residents[i];
                      final occupancyType = (r['occupancy_type'] ?? 'Owner')
                          .toString();
                      final isTenant = occupancyType.toLowerCase() == 'tenant';

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isTenant
                                ? Colors.purple.shade50
                                : Colors.teal.shade50,
                            child: Text(
                              (r['user_name'] ?? 'R')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isTenant
                                    ? Colors.purple.shade800
                                    : Colors.teal.shade800,
                              ),
                            ),
                          ),
                          title: Text(
                            r['user_name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Unit: ${r['block_name'] ?? ''} - ${r['flat_number'] ?? '--'}\nPhone: ${r['user_phone'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  r['role_name'] ?? 'Resident',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isTenant
                                      ? Colors.purple.shade50
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isTenant
                                        ? Colors.purple.shade200
                                        : Colors.blue.shade200,
                                  ),
                                ),
                                child: Text(
                                  occupancyType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isTenant
                                        ? Colors.purple.shade900
                                        : Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// TAB 2: ACTIVE COMMITTEE DIRECTORY (Read-Only)
class _SecretaryCommitteeTab extends StatefulWidget {
  const _SecretaryCommitteeTab();

  @override
  State<_SecretaryCommitteeTab> createState() => _SecretaryCommitteeTabState();
}

class _SecretaryCommitteeTabState extends State<_SecretaryCommitteeTab> {
  late Future<List<dynamic>> _committeeFuture;

  @override
  void initState() {
    super.initState();
    _loadCommittee();
  }

  void _loadCommittee() {
    setState(() {
      _committeeFuture = CommunityApiService.fetchCommitteeMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _committeeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  snapshot.error.toString().replaceAll('Exception: ', ''),
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadCommittee,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return const Center(
            child: Text('No active committee members recorded.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadCommittee(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: members.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final c = members[i];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade50,
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.deepPurple,
                    ),
                  ),
                  title: Text(
                    c['user_name'] ?? 'Member',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Designation: ${c['role_name'] ?? 'Committee'}\nPhone: ${c['user_phone'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c['status'] ?? 'Active',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
