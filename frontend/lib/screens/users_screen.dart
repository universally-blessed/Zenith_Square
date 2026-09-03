import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const UsersScreen({super.key, required this.adminData});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _users = [];
  List<dynamic> _roles = [];
  List<dynamic> _societies = [];
  List<dynamic> _committeeRequests = [];
  bool _loading = true;

  // Search, Filters & Pagination
  final TextEditingController _userSearchController = TextEditingController();
  String _userSearchQuery = '';
  String? _selectedRoleId;
  String? _selectedSocietyId;
  int _userCurrentPage = 0;
  final int _rowsPerPage = 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() async {
    setState(() => _loading = true);
    try {
      final users = await ApiService.getUsers(
        societyId: _selectedSocietyId,
        roleId: _selectedRoleId,
      );
      final roles = await ApiService.getRoles();
      final societies = await ApiService.getSocieties();
      final requests = await ApiService.getCommitteeRequests();
      setState(() {
        _users = users;
        _roles = roles;
        _societies = societies;
        _committeeRequests = requests;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _toggleStatus(String userId, bool currentStatus) async {
    final success = await ApiService.toggleUserStatus(userId, currentStatus);
    if (success) _loadData();
  }

  // Dialog for Scenario 1: Direct Assignment
  // Dialog for Scenario 1: Direct Assignment
  void _showAssignInitialRoleDialog(Map<String, dynamic> user) {
    // Find initial role matching role_id or role_name
    String? currentRoleId = user['role_id']?.toString();
    if (currentRoleId == null && user['role'] != null) {
      currentRoleId = user['role'] is Map
          ? user['role']['role_id']?.toString()
          : user['role']?.toString();
    }

    // Ensure initial value exists in _roles list
    final bool roleExists = _roles.any(
      (r) => r['role_id'].toString() == currentRoleId,
    );
    String? selectedRole = roleExists
        ? currentRoleId
        : (_roles.isNotEmpty ? _roles.first['role_id'].toString() : null);

    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text('Assign Initial Role: ${user['user_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Select Role',
                  border: OutlineInputBorder(),
                ),
                items: _roles.map<DropdownMenuItem<String>>((r) {
                  return DropdownMenuItem(
                    value: r['role_id'].toString(),
                    child: Text(r['role_name'] ?? r['role_id'].toString()),
                  );
                }).toList(),
                onChanged: isSubmitting
                    ? null
                    : (val) => setModalState(() => selectedRole = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (selectedRole == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a role.'),
                          ),
                        );
                        return;
                      }

                      setModalState(() => isSubmitting = true);

                      try {
                        final success = await ApiService.assignInitialRole(
                          user['user_id'],
                          selectedRole!,
                        );

                        if (success && mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Role assigned successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadData();
                        }
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${e.toString().replaceAll('Exception: ', '')}',
                              ),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Assign Role',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog for Scenario 2: Admin Proposes Role Change (Requires Chairman approval)
  void _showInitiateChangeDialog(Map<String, dynamic> user) {
    String? selectedRole = _roles.isNotEmpty ? _roles.first['role_id'] : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Request Committee Change: ${user['user_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This role change will be submitted to the Society Chairman for approval.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Target Role',
                  border: OutlineInputBorder(),
                ),
                items: _roles.map<DropdownMenuItem<String>>((r) {
                  return DropdownMenuItem(
                    value: r['role_id'].toString(),
                    child: Text(r['role_name'] ?? r['role_id']),
                  );
                }).toList(),
                onChanged: (val) => setModalState(() => selectedRole = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
              ),
              onPressed: () async {
                if (selectedRole == null) return;
                final success = await ApiService.createCommitteeChangeRequest(
                  user['user_id'],
                  selectedRole!,
                );
                if (success && mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Change request sent to Chairman for approval!',
                      ),
                    ),
                  );
                  _loadData();
                }
              },
              child: const Text(
                'Submit to Chairman',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRequest(String reqId, String action) async {
    final success = await ApiService.handleCommitteeAction(
      reqId,
      action == 'approve' ? 'Approved' : 'Rejected',
    );
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $action successfully!')),
        );
      }
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2563EB),
          tabs: const [
            Tab(text: 'All Registered Users', icon: Icon(Icons.people_outline)),
            Tab(
              text: 'Committee Role Change Requests',
              icon: Icon(Icons.assignment_turned_in_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [_buildUsersTable(), _buildRequestsTable()],
                ),
        ),
      ],
    );
  }

  // Inside lib/screens/users_screen.dart

  Widget _buildUsersTable() {
    final filteredUsers = _users.where((u) {
      final name = (u['user_name'] ?? '').toString().toLowerCase();
      final email = (u['user_email'] ?? '').toString().toLowerCase();
      final phone = (u['user_phone'] ?? '').toString().toLowerCase();
      final id = (u['user_id'] ?? '').toString().toLowerCase();
      final society = (u['society_name'] ?? u['society_id'] ?? '')
          .toString()
          .toLowerCase();
      final role = (u['role_name'] ?? u['role_id'] ?? '')
          .toString()
          .toLowerCase();
      final query = _userSearchQuery.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          id.contains(query) ||
          society.contains(query) ||
          role.contains(query);
    }).toList();

    final int totalPages = (filteredUsers.length / _rowsPerPage).ceil();
    final int startIndex = _userCurrentPage * _rowsPerPage;
    final int endIndex = (startIndex + _rowsPerPage > filteredUsers.length)
        ? filteredUsers.length
        : startIndex + _rowsPerPage;
    final paginatedUsers = (startIndex < filteredUsers.length)
        ? filteredUsers.sublist(startIndex, endIndex)
        : [];

    return ListView(
      children: [
        // Search and Filter Controls
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _userSearchController,
                decoration: InputDecoration(
                  hintText:
                      'Search user by name, email, phone, society, role...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _userSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _userSearchController.clear;
                              _userSearchQuery = '';
                              _userCurrentPage = 0;
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (val) {
                  setState(() {
                    _userSearchQuery = val;
                    _userCurrentPage = 0;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            // Society Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _selectedSocietyId,
                hint: const Text('All Societies'),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Societies'),
                  ),
                  ..._societies.map(
                    (s) => DropdownMenuItem(
                      value: s['society_id'].toString(),
                      child: Text(s['society_name'] ?? s['society_id']),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() => _selectedSocietyId = val);
                  _loadData();
                },
              ),
            ),
            const SizedBox(width: 12),
            // Role Filter Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _selectedRoleId,
                hint: const Text('All Roles'),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Roles')),
                  ..._roles.map(
                    (r) => DropdownMenuItem(
                      value: r['role_id'].toString(),
                      child: Text(r['role_name'] ?? r['role_id']),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() => _selectedRoleId = val);
                  _loadData();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Users Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
              ),
            ],
          ),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
            // Update DataTable columns
            columns: const [
              DataColumn(label: Text('User ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Society')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: paginatedUsers.map<DataRow>((u) {
              final bool isActive = u['is_active'] ?? true;
              return DataRow(
                cells: [
                  DataCell(Text(u['user_id'] ?? '')),
                  DataCell(Text(u['user_name'] ?? '')),
                  DataCell(Text(u['user_email'] ?? '-')),
                  DataCell(Text(u['user_phone'] ?? '-')),
                  DataCell(Text(u['society_name'] ?? u['society_id'] ?? '-')),
                  DataCell(Text(u['role_name'] ?? u['role_id'] ?? '-')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Single Action: Soft Deactivate / Reactivate
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Scenario 1: Assign initial role directly
                        IconButton(
                          icon: const Icon(
                            Icons.assignment_ind,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                          tooltip: 'Assign Initial Role Directly',
                          onPressed: () => _showAssignInitialRoleDialog(u),
                        ),
                        // Scenario 2: Propose role change (Dual Approval)
                        IconButton(
                          icon: const Icon(
                            Icons.swap_horiz,
                            color: Colors.orange,
                            size: 20,
                          ),
                          tooltip: 'Initiate Role Change (Awaits Chairman)',
                          onPressed: () => _showInitiateChangeDialog(u),
                        ),
                        // Soft Deactivate / Reactivate
                        IconButton(
                          icon: Icon(
                            isActive ? Icons.block : Icons.check_circle_outline,
                            color: isActive ? Colors.redAccent : Colors.green,
                            size: 20,
                          ),
                          tooltip: isActive
                              ? 'Deactivate Account'
                              : 'Reactivate Account',
                          onPressed: () =>
                              _toggleStatus(u['user_id'], isActive),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Pagination Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${filteredUsers.isEmpty ? 0 : startIndex + 1} to $endIndex of ${filteredUsers.length} users',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _userCurrentPage > 0
                      ? () => setState(() => _userCurrentPage--)
                      : null,
                ),
                Text(
                  'Page ${_userCurrentPage + 1} of ${totalPages == 0 ? 1 : totalPages}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: (_userCurrentPage + 1 < totalPages)
                      ? () => setState(() => _userCurrentPage++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestsTable() {
    if (_committeeRequests.isEmpty) {
      return const Center(
        child: Text(
          'No committee change requests found.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
              ),
            ],
          ),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text('Request ID')),
              DataColumn(label: Text('Society')),
              DataColumn(label: Text('Requested By (Chairman)')),
              DataColumn(label: Text('Target Member')),
              DataColumn(label: Text('Requested Role')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _committeeRequests.map<DataRow>((req) {
              final String status = req['status'] ?? 'Pending_Admin_Approval';
              final bool isPendingAdmin = status == 'Pending_Admin_Approval';
              final bool isPendingChairman =
                  status == 'Pending_Chairman_Approval';

              return DataRow(
                cells: [
                  DataCell(Text(req['request_id'] ?? '')),
                  DataCell(Text(req['society_name'] ?? '-')),
                  DataCell(
                    Text(
                      req['requested_by_name'] ??
                          (isPendingChairman ? 'Super Admin' : '-'),
                    ),
                  ),
                  DataCell(
                    Text(req['target_user_name'] ?? req['target_user'] ?? '-'),
                  ),
                  DataCell(
                    Text(req['new_role_name'] ?? req['new_role'] ?? '-'),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'Approved'
                            ? Colors.green.withValues(alpha: 0.1)
                            : status == 'Rejected'
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.replaceAll('_', ' '),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: status == 'Approved'
                              ? Colors.green
                              : status == 'Rejected'
                              ? Colors.red
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    isPendingAdmin
                        ? Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () => _handleRequest(
                                  req['request_id'],
                                  'approve',
                                ),
                                child: const Text(
                                  'Approve',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () =>
                                    _handleRequest(req['request_id'], 'reject'),
                                child: const Text(
                                  'Reject',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            isPendingChairman
                                ? 'Awaiting Chairman'
                                : 'Processed',
                            style: TextStyle(
                              color: isPendingChairman
                                  ? Colors.orange.shade800
                                  : Colors.grey,
                              fontWeight: isPendingChairman
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
