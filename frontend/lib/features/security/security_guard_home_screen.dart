import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasource/api_service.dart';
import '../../data/datasource/security_api_service.dart';
import './security_guard_desk_screen.dart';

class SecurityGuardHomeScreen extends StatefulWidget {
  const SecurityGuardHomeScreen({super.key});

  @override
  State<SecurityGuardHomeScreen> createState() => _SecurityGuardHomeScreenState();
}

class _SecurityGuardHomeScreenState extends State<SecurityGuardHomeScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<dynamic>> _alertsFuture;
  late Future<List<dynamic>> _visitorsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  void _refreshAll() {
    setState(() {
      _profileFuture = ApiService.fetchUserProfile().then((profile) {
        final role = (profile['role_name'] ?? '').toString().toLowerCase();
        if (mounted && !role.contains('security') && !role.contains('guard') && role != 'chairman') {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
        return profile;
      });
      _alertsFuture = SecurityApiService.fetchActiveSecurityAlerts();
      _visitorsFuture = SecurityApiService.fetchVisitorLogs();
    });
  }

  void _handleLogout() async {
    await ApiService.clearAuthData();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _openDesk({int initialTab = 0, String? filter}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecurityGuardDeskScreen(
          initialTabIndex: initialTab,
          initialVisitorFilter: filter,
        ),
      ),
    ).then((_) => _refreshAll());
  }

  // Quick Direct Log Visitor Entry Modal from Home Dashboard
  void _showLogVisitorModal(String societyName, String guardName) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();

    // Purpose of Visit Dropdown Options
    final purposeOptions = [
      'Guest / Personal Visit',
      'Delivery (Food / Parcel)',
      'Cab / Taxi',
      'Maintenance & Repair',
      'Courier Service',
      'House Help / Maid',
      'Official / Business',
      'Other Purpose',
    ];
    String selectedPurpose = 'Guest / Personal Visit';

    String? selectedFlatId;
    bool isLookingUp = false;
    bool isSubmitting = false;
    String? modalError;
    List<Map<String, dynamic>> flatsList = [];

    try {
      flatsList = await SecurityApiService.fetchSocietyFlats();
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
                                  societyName.isNotEmpty ? societyName : 'Serene Heights',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Main Entrance Gate | Guard: $guardName',
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

                    // 3. Destination Flat Dropdown (Flat number shown clearly first!)
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
                        final flatNum = f['flat_number'] ?? '';
                        final block = f['block_name'] ?? 'A';
                        return DropdownMenuItem<String>(
                          value: f['flat_id'] as String,
                          child: Text(
                            f['display_label'] ?? 'Flat $flatNum - Block $block (Serene Heights)',
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

                    // 5. Specific Purpose / Additional Notes (Optional)
                    TextFormField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Specific Notes / Details (Optional)',
                        hintText: 'e.g. Amazon Parcel, Courier, AC Repair',
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
                                  _refreshAll();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Security Guard Portal'),
        elevation: 0,
        automaticallyImplyLeading: false, // Prevents phantom back button
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Guard Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile').then((_) => _refreshAll()),
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
          final userName = profile['user_name'] ?? 'Raj Patel';
          final societyName = profile['society_name'] ?? 'Serene Heights';

          return RefreshIndicator(
            onRefresh: () async => _refreshAll(),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              children: [
                // 1. Guard Identity Card (Matching the blue card from screenshot)
                Card(
                  elevation: 0,
                  color: Colors.blue.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pushNamed(context, '/profile').then((_) => _refreshAll()),
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                societyName.isNotEmpty ? societyName : 'Serene Heights',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade100,
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
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Active',
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
              ),
              const SizedBox(height: 12),

                // 2. Emergency Security SOS Alert Banner
                FutureBuilder<List<dynamic>>(
                  future: _alertsFuture,
                  builder: (context, alertSnap) {
                    final activeAlerts = alertSnap.data ?? [];
                    final hasAlerts = activeAlerts.isNotEmpty;

                    return InkWell(
                      onTap: () => _openDesk(initialTab: 0),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasAlerts ? Colors.red.shade400 : Colors.red.shade200,
                            width: hasAlerts ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    'Emergency Security SOS',
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (hasAlerts) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade600,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${activeAlerts.length} Active',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 3. Grid Modules: Services & Management (Clean 6-item Grid)
                _buildSectionTitle('Services & Management'),
                const SizedBox(height: 8),
                _buildGrid([
                  _ActionItem(
                    'Log Visitor',
                    Icons.person_add_alt_1_outlined,
                    Colors.amber.shade800,
                    () => _showLogVisitorModal(societyName, userName),
                  ),
                  _ActionItem(
                    'Visitor Logs',
                    Icons.badge_outlined,
                    Colors.teal,
                    () => _openDesk(initialTab: 1, filter: 'all'),
                  ),
                  _ActionItem(
                    'Active Inside',
                    Icons.timer_outlined,
                    Colors.cyan.shade700,
                    () => _openDesk(initialTab: 1, filter: 'inside'),
                  ),
                  _ActionItem(
                    'Mark Exit',
                    Icons.exit_to_app_rounded,
                    Colors.orange.shade700,
                    () => _openDesk(initialTab: 1, filter: 'inside'),
                  ),
                  _ActionItem(
                    'Broadcast SOS',
                    Icons.crisis_alert,
                    Colors.red.shade700,
                    () => _openDesk(initialTab: 0),
                  ),
                ]),

                const SizedBox(height: 18),

                // 4. Live Gate & Security Metrics Card
                _buildSectionTitle('Gate Operations Summary'),
                const SizedBox(height: 8),
                FutureBuilder<List<dynamic>>(
                  future: _visitorsFuture,
                  builder: (context, visitorSnap) {
                    final logs = visitorSnap.data ?? [];
                    final insideCount = logs.where((l) => l['exit_time'] == null).length;
                    final totalCount = logs.length;

                    return FutureBuilder<List<dynamic>>(
                      future: _alertsFuture,
                      builder: (context, alertSnap) {
                        final alerts = alertSnap.data ?? [];
                        final activeAlertCount = alerts.length;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricItem(
                                label: 'Visitors Inside',
                                count: '$insideCount',
                                color: Colors.green.shade700,
                                icon: Icons.person_pin_circle_outlined,
                                onTap: () => _openDesk(initialTab: 1, filter: 'inside'),
                              ),
                              Container(
                                height: 36,
                                width: 1,
                                color: Colors.grey.shade300,
                              ),
                              _buildMetricItem(
                                label: 'Total Logs',
                                count: '$totalCount',
                                color: Colors.blue.shade800,
                                icon: Icons.history_outlined,
                                onTap: () => _openDesk(initialTab: 1, filter: 'all'),
                              ),
                              Container(
                                height: 36,
                                width: 1,
                                color: Colors.grey.shade300,
                              ),
                              _buildMetricItem(
                                label: 'Active Alerts',
                                count: '$activeAlertCount',
                                color: activeAlertCount > 0
                                    ? Colors.red.shade700
                                    : Colors.grey.shade600,
                                icon: Icons.crisis_alert,
                                onTap: () => _openDesk(initialTab: 0),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
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
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: item.onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
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
  final VoidCallback onTap;

  _ActionItem(this.title, this.icon, this.color, this.onTap);
}
