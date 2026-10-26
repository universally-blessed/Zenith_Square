import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasource/security_api_service.dart';

class SecurityGuardDeskScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? initialVisitorFilter; // 'all', 'inside', 'exited'

  const SecurityGuardDeskScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialVisitorFilter,
  });

  @override
  State<SecurityGuardDeskScreen> createState() =>
      _SecurityGuardDeskScreenState();
}

class _SecurityGuardDeskScreenState extends State<SecurityGuardDeskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Security & SOS Desk'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Guard Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade900,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade900,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.crisis_alert, size: 20),
              text: 'Active Alerts & SOS',
            ),
            Tab(
              icon: Icon(Icons.badge_outlined, size: 20),
              text: 'Gate Visitor Logs',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _GuardAlertsTab(),
          _GuardVisitorLogsTab(initialFilter: widget.initialVisitorFilter),
        ],
      ),
    );
  }
}

// =======================================================================
// TAB 1: ACTIVE ALERTS & SOS TRIGGER / RESOLUTION
// =======================================================================
class _GuardAlertsTab extends StatefulWidget {
  const _GuardAlertsTab();

  @override
  State<_GuardAlertsTab> createState() => _GuardAlertsTabState();
}

class _GuardAlertsTabState extends State<_GuardAlertsTab> {
  late Future<List<dynamic>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() {
    if (!mounted) return;
    setState(() {
      _alertsFuture = SecurityApiService.fetchActiveSecurityAlerts();
    });
  }

  Future<void> _handleDismissAlert(String alertId, String alertType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text('Resolve Alert'),
          ],
        ),
        content: Text(
          'Mark "$alertType" as resolved? This will clear the emergency alert across the society.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final res = await SecurityApiService.dismissSecurityAlert(alertId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Alert marked as resolved.'),
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
  }

  void _showTriggerSosModal() {
    final formKey = GlobalKey<FormState>();
    final descController = TextEditingController();
    String selectedType = 'Medical Emergency';
    bool isSubmitting = false;
    String? sheetError;

    final alertCategories = [
      {'label': 'Medical Emergency', 'icon': Icons.medical_services_outlined},
      {'label': 'Fire Emergency', 'icon': Icons.local_fire_department_outlined},
      {'label': 'Lift Stuck', 'icon': Icons.elevator_outlined},
      {'label': 'Theft / Intruder', 'icon': Icons.security_outlined},
      {'label': 'Other Emergency', 'icon': Icons.warning_amber_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.crisis_alert, color: Colors.red.shade700, size: 26),
                          const SizedBox(width: 8),
                          const Text(
                            'Broadcast Emergency SOS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
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
                  Text(
                    'This will immediately sound the alarm across all society residents and management.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Emergency Category',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: alertCategories.map((cat) {
                      final isSelected = selectedType == cat['label'];
                      return ChoiceChip(
                        avatar: Icon(
                          cat['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.red.shade800,
                        ),
                        label: Text(cat['label'] as String),
                        selected: isSelected,
                        selectedColor: Colors.red.shade700,
                        backgroundColor: Colors.red.shade50,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.red.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => selectedType = cat['label'] as String);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Emergency Details & Location *',
                      hintText: 'e.g. Smoke detected near Block B Lift, need fire assistance',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter location or emergency details';
                      }
                      if (v.trim().length < 5) {
                        return 'Description must be at least 5 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (sheetError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 18, color: Colors.red.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sheetError!,
                              style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() {
                              isSubmitting = true;
                              sheetError = null;
                            });
                            try {
                              final res = await SecurityApiService.triggerEmergencyAlert(
                                alertType: selectedType,
                                description: descController.text.trim(),
                              );
                              if (mounted) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message'] ?? 'Alert broadcasted successfully!',
                                    ),
                                    backgroundColor: Colors.red.shade800,
                                  ),
                                );
                                _loadAlerts();
                              }
                            } catch (e) {
                              setModalState(() {
                                isSubmitting = false;
                                sheetError = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.crisis_alert),
                    label: Text(
                      isSubmitting ? 'BROADCASTING...' : 'BROADCAST SOS NOW',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Broadcast Button Header
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Material(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(10),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _showTriggerSosModal,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.crisis_alert, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'TRIGGER EMERGENCY SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Live Alerts List
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
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 10),
                      Text(
                        snapshot.error.toString().replaceAll('Exception: ', ''),
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
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
                return RefreshIndicator(
                  onRefresh: () async => _loadAlerts(),
                  child: ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shield_outlined,
                                size: 64,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Active Emergency Alerts',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'All society gates & residential zones are clear.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadAlerts(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  itemCount: alerts.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final a = alerts[i];
                    final dateStr = a['created_at'] != null
                        ? a['created_at'].toString().substring(0, 16).replaceAll('T', ' ')
                        : '';

                    return Card(
                      elevation: 0,
                      color: Colors.red.shade50,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.red.shade200, width: 1.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.warning_amber_rounded,
                                        size: 18,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      a['alert_type'] ?? 'Emergency',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              a['description'] ?? '',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'By: ${a['triggered_by_name'] ?? 'Resident'} (${a['triggered_by_phone'] ?? ''})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text('Mark Resolved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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

// =======================================================================
// TAB 2: GATE VISITOR LOGS (VISITOR & VISITOR_LOGS TABLES)
// =======================================================================
class _GuardVisitorLogsTab extends StatefulWidget {
  final String? initialFilter;

  const _GuardVisitorLogsTab({this.initialFilter});

  @override
  State<_GuardVisitorLogsTab> createState() => _GuardVisitorLogsTabState();
}

class _GuardVisitorLogsTabState extends State<_GuardVisitorLogsTab> {
  late Future<List<dynamic>> _visitorsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'inside', 'exited'

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _filterStatus = widget.initialFilter!;
    }
    _loadVisitors();
  }

  void _loadVisitors() {
    if (!mounted) return;
    setState(() {
      _visitorsFuture = SecurityApiService.fetchVisitorLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleMarkExit(int logId, String visitorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.blue.shade800),
            const SizedBox(width: 8),
            const Text('Log Visitor Exit'),
          ],
        ),
        content: Text(
          'Record exit timestamp for "$visitorName"? This will mark them as exited the society gate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Exit'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final res = await SecurityApiService.logVisitorExit(logId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Visitor exit timestamp recorded.'),
              backgroundColor: Colors.blue.shade800,
            ),
          );
          _loadVisitors();
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
  }

  // LOG NEW VISITOR ENTRY MODAL
  void _showLogVisitorModal() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();

    // Purpose of Visit Dropdown Options
    final purposeOptions = [
      'Guest / Personal Visit',
      'Delivery (Food / Parcel)',
      'Cab / Taxi',
      'Home Maintenance & Repair',
      'Maid / Domestic Staff',
      'Courier Delivery',
      'Doctor / Medical',
      'Other Purpose',
    ];
    String selectedPurpose = 'Guest / Personal Visit';

    String? selectedFlatId;
    bool isLookingUp = false;
    bool isSubmitting = false;
    String? modalError;
    List<Map<String, dynamic>> flatsList = [];

    // Pre-load society flats
    String socName = 'Serene Heights';
    try {
      flatsList = await SecurityApiService.fetchSocietyFlats();
      if (flatsList.isNotEmpty && flatsList.first['society_name'] != null) {
        socName = flatsList.first['society_name'].toString();
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_add_alt_1,
                                color: Colors.blue.shade800,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Log Gate Visitor Entry',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
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

                    // Society Details Badge Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_city, color: Colors.blue.shade900, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  socName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Main Entrance Gate | Database Synced',
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Database',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 1. Visitor Mobile Number Field with 10-Digit Validation
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Visitor Mobile Number (10 digits) *',
                        hintText: 'Enter 10-digit number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        suffixIcon: isLookingUp
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (phone) async {
                        if (phone.length == 10) {
                          setModalState(() => isLookingUp = true);
                          final existing =
                              await SecurityApiService.lookupVisitor(phone);
                          setModalState(() {
                            isLookingUp = false;
                            if (existing != null &&
                                existing['visitor_name'] != null) {
                              nameController.text =
                                  existing['visitor_name'].toString().trim();
                            }
                          });
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter 10-digit mobile number';
                        }
                        final clean = v.trim();
                        if (clean.length != 10) {
                          return 'Mobile number must be exactly 10 digits';
                        }
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(clean)) {
                          return 'Only numbers are allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // 2. Visitor Full Name Field
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Visitor Full Name *',
                        hintText: 'e.g. Ramesh Kumar',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter visitor name';
                        }
                        if (v.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // 3. Destination Flat Dropdown (Serene Heights Flats)
                    DropdownButtonFormField<String>(
                      initialValue: selectedFlatId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Destination Flat (Serene Heights) *',
                        hintText: 'Select destination flat',
                        prefixIcon: const Icon(Icons.apartment_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: flatsList.map((f) {
                        final flatNum = f['flat_number']?.toString() ?? '';
                        final block = f['block_name']?.toString() ?? 'A';
                        return DropdownMenuItem<String>(
                          value: f['flat_id'] as String,
                          child: Text(
                            f['display_label'] ?? 'Flat $flatNum - Block $block ($socName)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() => selectedFlatId = val);
                      },
                      validator: (v) =>
                          v == null ? 'Select destination flat' : null,
                    ),
                    const SizedBox(height: 12),

                    // 4. Purpose of Visit Dropdown Menu
                    DropdownButtonFormField<String>(
                      initialValue: selectedPurpose,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Purpose of Visit *',
                        prefixIcon: const Icon(Icons.assignment_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: purposeOptions.map((p) {
                        return DropdownMenuItem<String>(
                          value: p,
                          child: Text(
                            p,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedPurpose = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 6. Specific Purpose / Additional Notes (Optional)
                    TextFormField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Specific Notes / Details (Optional)',
                        hintText: 'e.g. Amazon Package, AC Repair, Personal Visit',
                        prefixIcon: const Icon(Icons.edit_note_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (modalError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 18, color: Colors.red.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modalError!,
                                style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() {
                                isSubmitting = true;
                                modalError = null;
                              });

                              try {
                                final finalPurpose = notesController.text.trim().isNotEmpty
                                    ? '$selectedPurpose (${notesController.text.trim()})'
                                    : selectedPurpose;

                                final res = await SecurityApiService.logVisitorEntry(
                                  visitorName: nameController.text.trim(),
                                  visitorPhone: phoneController.text.trim(),
                                  flatId: selectedFlatId!,
                                  purpose: finalPurpose,
                                );

                                if (mounted) {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['message'] ?? 'Visitor entry logged successfully!',
                                      ),
                                      backgroundColor: Colors.green.shade800,
                                    ),
                                  );
                                  _loadVisitors();
                                }
                              } catch (e) {
                                setModalState(() {
                                  isSubmitting = false;
                                  modalError =
                                      e.toString().replaceAll('Exception: ', '');
                                });
                              }
                            },
                      icon: isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        isSubmitting ? 'LOGGING ENTRY...' : 'CONFIRM GATE ENTRY',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getPurposeIcon(String purpose) {
    final p = purpose.toLowerCase();
    if (p.contains('deliver') || p.contains('courier') || p.contains('package')) {
      return Icons.local_shipping_outlined;
    }
    if (p.contains('cab') || p.contains('taxi') || p.contains('uber') || p.contains('ola')) {
      return Icons.local_taxi_outlined;
    }
    if (p.contains('repair') || p.contains('maintain') || p.contains('service')) {
      return Icons.handyman_outlined;
    }
    if (p.contains('maid') || p.contains('help') || p.contains('clean')) {
      return Icons.cleaning_services_outlined;
    }
    return Icons.person_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action Bar: Search & "Log New Visitor" Button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by visitor, phone, flat...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showLogVisitorModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Visitor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter Chips (All, Currently Inside, Exited)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Logs'),
                selected: _filterStatus == 'all',
                selectedColor: Colors.blue.shade100,
                labelStyle: TextStyle(
                  color: _filterStatus == 'all' ? Colors.blue.shade900 : Colors.black87,
                  fontWeight: _filterStatus == 'all' ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (val) => setState(() => _filterStatus = 'all'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Inside'),
                  ],
                ),
                selected: _filterStatus == 'inside',
                selectedColor: Colors.green.shade100,
                labelStyle: TextStyle(
                  color: _filterStatus == 'inside' ? Colors.green.shade900 : Colors.black87,
                  fontWeight: _filterStatus == 'inside' ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (val) => setState(() => _filterStatus = 'inside'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Exited'),
                selected: _filterStatus == 'exited',
                selectedColor: Colors.grey.shade300,
                labelStyle: TextStyle(
                  color: _filterStatus == 'exited' ? Colors.grey.shade900 : Colors.black87,
                  fontWeight: _filterStatus == 'exited' ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (val) => setState(() => _filterStatus = 'exited'),
              ),
            ],
          ),
        ),

        // Visitor Logs List
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
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 10),
                      Text(
                        snapshot.error.toString().replaceAll('Exception: ', ''),
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadVisitors,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final allLogs = snapshot.data ?? [];

              // Filter by Status & Search Query
              final filtered = allLogs.where((l) {
                // Status Filter
                final isInside = (l['exit_time'] == null);
                if (_filterStatus == 'inside' && !isInside) return false;
                if (_filterStatus == 'exited' && isInside) return false;

                // Search Filter
                if (_searchQuery.isNotEmpty) {
                  final name = (l['visitor_name'] ?? '').toString().toLowerCase();
                  final phone = (l['visitor_phone'] ?? '').toString().toLowerCase();
                  final flat = (l['flat_number'] ?? '').toString().toLowerCase();
                  final block = (l['block_name'] ?? '').toString().toLowerCase();
                  final purpose = (l['purpose'] ?? '').toString().toLowerCase();

                  if (!name.contains(_searchQuery) &&
                      !phone.contains(_searchQuery) &&
                      !flat.contains(_searchQuery) &&
                      !block.contains(_searchQuery) &&
                      !purpose.contains(_searchQuery)) {
                    return false;
                  }
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => _loadVisitors(),
                  child: ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No visitor records match "$_searchQuery"'
                                  : 'No visitor gate logs recorded yet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap "+ Log Visitor" above to register new visitors.',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _loadVisitors(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final log = filtered[i];
                    final isInside = (log['exit_time'] == null);
                    final entryStr = log['entry_time']?.toString().substring(0, 16).replaceAll('T', ' ') ?? '--';
                    final exitStr = log['exit_time']?.toString().substring(0, 16).replaceAll('T', ' ');
                    final socName = (log['society_name'] != null && log['society_name'].toString().isNotEmpty)
                        ? log['society_name'].toString()
                        : 'Serene Heights';
                    final rawFlatNum = (log['flat_number'] ?? '').toString().trim();
                    final rawBlock = (log['block_name'] ?? '').toString().trim();
                    final flatLabel = rawFlatNum.isNotEmpty
                        ? 'Flat $rawFlatNum - Block ${rawBlock.isNotEmpty ? rawBlock : "A"}'
                        : (log['flat_id'] != null && log['flat_id'].toString().isNotEmpty
                            ? 'Flat ${log['flat_id']}'
                            : 'Flat Details Pending');

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isInside ? Colors.green.shade300 : Colors.grey.shade200,
                          width: isInside ? 1.4 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Avatar, Visitor Name, Status Badge
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isInside
                                      ? Colors.green.shade50
                                      : Colors.grey.shade100,
                                  child: Icon(
                                    _getPurposeIcon(log['purpose'] ?? ''),
                                    color: isInside
                                        ? Colors.green.shade700
                                        : Colors.grey.shade700,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log['visitor_name'] ?? 'Visitor',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        log['visitor_phone'] ?? '',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isInside
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isInside ? 'INSIDE' : 'EXITED',
                                    style: TextStyle(
                                      color: isInside
                                          ? Colors.green.shade800
                                          : Colors.grey.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Destination & Purpose Row (Wrap prevents any 13px or text overflow)
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.apartment,
                                        size: 14,
                                        color: Colors.blue.shade800,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        flatLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 13,
                                        color: Colors.amber.shade900,
                                      ),
                                      const SizedBox(width: 4),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 160),
                                        child: Text(
                                          log['purpose'] ?? 'Visit',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    socName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),

                            // Timestamp & Exit Button Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'In: $entryStr',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (exitStr != null)
                                      Text(
                                        'Out: $exitStr',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blueGrey.shade600,
                                        ),
                                      ),
                                    if (log['recorded_by_name'] != null)
                                      Text(
                                        'Guard: ${log['recorded_by_name']}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                  ],
                                ),
                                if (isInside)
                                  ElevatedButton.icon(
                                    onPressed: () => _handleMarkExit(
                                      log['log_id'] ?? log['logs_id'],
                                      log['visitor_name'] ?? 'Visitor',
                                    ),
                                    icon: const Icon(Icons.exit_to_app, size: 16),
                                    label: const Text('Mark Exit'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade800,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                              ],
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
