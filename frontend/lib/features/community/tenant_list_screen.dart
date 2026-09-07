import 'package:flutter/material.dart';
import '../../data/datasource/community_api_service.dart';
import './add_tenant_screen.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({Key? key}) : super(key: key);

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  List<dynamic> _tenants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTenants();
  }

  Future<void> _fetchTenants() async {
    setState(() => _isLoading = true);
    try {
      final tenants = await CommunityApiService.fetchTenants();
      setState(() {
        _tenants = tenants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _handleMoveOut(String tenantId, String tenantName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Move-Out'),
        content: Text(
          'Are you sure you want to mark $tenantName as moved out? Status will change to inactive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await CommunityApiService.markTenantMoveOut(tenantId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant status updated to inactive.')),
      );
      _fetchTenants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Society Tenants')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Add Tenant'),
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTenantScreen()),
          );
          if (added == true) _fetchTenants();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tenants.isEmpty
          ? const Center(child: Text('No tenants recorded yet.'))
          : RefreshIndicator(
              onRefresh: _fetchTenants,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _tenants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final t = _tenants[index];
                  final isActive =
                      (t['status'] ?? '').toString().toLowerCase() == 'active';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t['tenant_name'] ?? 'Unknown Resident',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.green.shade900
                                        : Colors.grey.shade800,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: isActive
                                    ? Colors.green.shade100
                                    : Colors.grey.shade300,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Flat: ${t['block_name'] ?? ''} - ${t['flat_number'] ?? ''}',
                          ),
                          Text('Phone: ${t['tenant_phone'] ?? '--'}'),
                          if (t['owner_name'] != null)
                            Text('Owner: ${t['owner_name']}'),
                          Text('Move-In: ${t['move_in_date'] ?? '--'}'),
                          if (t['move_out_date'] != null)
                            Text('Move-Out: ${t['move_out_date']}'),
                          if (isActive) ...[
                            const Divider(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(
                                  Icons.exit_to_app,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Mark Move-Out',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () => _handleMoveOut(
                                  t['tenant_id'],
                                  t['tenant_name'] ?? 'Resident',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
