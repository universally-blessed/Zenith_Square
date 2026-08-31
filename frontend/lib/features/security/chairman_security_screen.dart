import 'package:flutter/material.dart';
import '../../data/datasource/security_api_service.dart';

class ChairmanSecurityScreen extends StatefulWidget {
  const ChairmanSecurityScreen({super.key});

  @override
  State<ChairmanSecurityScreen> createState() => _ChairmanSecurityScreenState();
}

class _ChairmanSecurityScreenState extends State<ChairmanSecurityScreen>
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
        title: const Text('Security & SOS Desk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/chairman-home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Alerts & SOS'),
            Tab(text: 'Gate Visitor Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ChairmanAlertsTab(), _ChairmanVisitorAuditTab()],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: ACTIVE ALERTS, SOS BROADCAST & DISMISSAL
// -------------------------------------------------------------
class _ChairmanAlertsTab extends StatefulWidget {
  const _ChairmanAlertsTab();

  @override
  State<_ChairmanAlertsTab> createState() => _ChairmanAlertsTabState();
}

class _ChairmanAlertsTabState extends State<_ChairmanAlertsTab> {
  late Future<List<dynamic>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() {
    setState(() {
      _alertsFuture = SecurityApiService.fetchActiveSecurityAlerts();
    });
  }

  Future<void> _handleDismissAlert(String alertId, String alertType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Emergency Alert'),
        content: Text(
          'Mark "$alertType" as resolved? This will clear the alert across the society.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Mark Resolved',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await SecurityApiService.dismissSecurityAlert(alertId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Alert resolved.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadAlerts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showTriggerSosModal() {
    String selectedType = 'Medical Emergency';
    final descController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Broadcast SOS Alert',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'This will immediately alert gate security and society members.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Medical Emergency',
                      child: Text('Medical Emergency'),
                    ),
                    DropdownMenuItem(
                      value: 'Fire Emergency',
                      child: Text('Fire Hazard'),
                    ),
                    DropdownMenuItem(
                      value: 'Lift Stuck',
                      child: Text('Lift / Elevator Stuck'),
                    ),
                    DropdownMenuItem(
                      value: 'Theft / Intruder',
                      child: Text('Theft / Suspicious Activity'),
                    ),
                    DropdownMenuItem(
                      value: 'Other Emergency',
                      child: Text('Other Emergency'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Location / Emergency Details',
                    hintText: 'e.g., Main pump house water pipe burst',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final desc = descController.text.trim();
                          if (desc.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please describe the emergency location/issue',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          try {
                            final res =
                                await SecurityApiService.triggerEmergencyAlert(
                                  alertType: selectedType,
                                  description: desc,
                                );
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res['message'] ?? 'Alert broadcasted!',
                                  ),
                                  backgroundColor: Colors.red.shade800,
                                ),
                              );
                              _loadAlerts();
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red.shade800,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'BROADCAST SOS NOW',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SOS Button Top Banner
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Material(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _showTriggerSosModal,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.crisis_alert, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'TRIGGER EMERGENCY SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Live Alerts Feed
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _alertsFuture,
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
                        onPressed: _loadAlerts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final alerts = snapshot.data ?? [];
              if (alerts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 64,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No active emergency alerts in your society.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All society gates and facilities operating normally.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadAlerts(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  itemCount: alerts.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final a = alerts[i];
                    final dateStr = a['created_at'] != null
                        ? a['created_at']
                              .toString()
                              .substring(0, 16)
                              .replaceAll('T', ' ')
                        : '';

                    return Card(
                      elevation: 0,
                      color: Colors.red.shade50,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  a['alert_type'] ?? 'Emergency',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              a['description'] ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade900,
                                fontSize: 13,
                              ),
                            ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'By: ${a['triggered_by_name'] ?? 'Resident'} (${a['triggered_by_phone'] ?? ''})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _handleDismissAlert(
                                  a['alert_id'],
                                  a['alert_type'] ?? 'Alert',
                                ),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: const Text('Resolve Alert'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// TAB 2: SOCIETY-WIDE GATE VISITOR LOGS AUDIT (READ ONLY)
// -------------------------------------------------------------
class _ChairmanVisitorAuditTab extends StatefulWidget {
  const _ChairmanVisitorAuditTab();

  @override
  State<_ChairmanVisitorAuditTab> createState() =>
      _ChairmanVisitorAuditTabState();
}

class _ChairmanVisitorAuditTabState extends State<_ChairmanVisitorAuditTab> {
  late Future<List<dynamic>> _visitorsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  void _loadVisitors() {
    setState(() {
      _visitorsFuture = SecurityApiService.fetchVisitorLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Filter
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by Visitor, Phone, or Flat (e.g. A-101)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) =>
                setState(() => _searchQuery = val.trim().toLowerCase()),
          ),
        ),
        const Divider(height: 1),

        // Logs List
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _visitorsFuture,
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
                        onPressed: _loadVisitors,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final allLogs = snapshot.data ?? [];
              final filtered = allLogs.where((log) {
                if (_searchQuery.isEmpty) return true;
                final name = (log['visitor_name'] ?? '')
                    .toString()
                    .toLowerCase();
                final phone = (log['visitor_phone'] ?? '')
                    .toString()
                    .toLowerCase();
                final flat = (log['flat_number'] ?? '')
                    .toString()
                    .toLowerCase();
                final block = (log['block_name'] ?? '')
                    .toString()
                    .toLowerCase();
                return name.contains(_searchQuery) ||
                    phone.contains(_searchQuery) ||
                    flat.contains(_searchQuery) ||
                    block.contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No visitor records match the search.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadVisitors(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final log = filtered[i];
                    final hasExited = log['exit_time'] != null;
                    final entryTime = log['entry_time'] != null
                        ? log['entry_time'].toString().substring(11, 16)
                        : '--:--';
                    final entryDate = log['entry_time'] != null
                        ? log['entry_time'].toString().substring(0, 10)
                        : '';
                    final exitTime = hasExited
                        ? log['exit_time'].toString().substring(11, 16)
                        : null;
                    final flatStr =
                        '${log['block_name'] ?? ''} - ${log['flat_number'] ?? ''}';
                    final guard = log['recorded_by_name'] ?? 'Gate Guard';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: hasExited
                              ? Colors.grey.shade200
                              : Colors.green.shade100,
                          child: Icon(
                            Icons.person_pin,
                            color: hasExited
                                ? Colors.grey.shade700
                                : Colors.green.shade800,
                          ),
                        ),
                        title: Text(
                          '${log['visitor_name'] ?? 'Visitor'}  ➔  Flat $flatStr',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Purpose: ${log['purpose'] ?? 'General'}\nContact: ${log['visitor_phone'] ?? 'N/A'}\nEntry: $entryDate at $entryTime${hasExited ? ' • Exit: $exitTime' : ''}\nLogged by: $guard',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: hasExited
                                ? Colors.grey.shade100
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: hasExited
                                  ? Colors.grey.shade300
                                  : Colors.green.shade300,
                            ),
                          ),
                          child: Text(
                            hasExited ? 'EXITED' : 'INSIDE',
                            style: TextStyle(
                              color: hasExited
                                  ? Colors.grey.shade700
                                  : Colors.green.shade800,
                              fontSize: 10,
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
          ),
        ),
      ],
    );
  }
}
