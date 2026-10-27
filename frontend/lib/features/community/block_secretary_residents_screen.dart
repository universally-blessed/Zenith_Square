import 'package:flutter/material.dart';
import '../../data/datasource/community_api_service.dart';

class BlockSecretaryResidentsScreen extends StatefulWidget {
  const BlockSecretaryResidentsScreen({super.key});

  @override
  State<BlockSecretaryResidentsScreen> createState() =>
      _BlockSecretaryResidentsScreenState();
}

class _BlockSecretaryResidentsScreenState
    extends State<BlockSecretaryResidentsScreen> {
  List<dynamic> _residents = [];
  bool _isLoading = true;
  String _searchQuery = '';
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
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _residents = res['residents'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Block Residents Directory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search block resident or flat #',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (val) {
                setState(() => _searchQuery = val);
                _fetchDirectory();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _residents.isEmpty
                ? const Center(child: Text('No residents found in your block.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _residents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = _residents[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            r['user_name'] ?? 'Resident',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Flat: ${r['flat_number'] ?? '--'}\nPhone: ${r['user_phone'] ?? 'N/A'}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
