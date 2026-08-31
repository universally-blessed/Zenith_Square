import 'package:flutter/material.dart';
import '../../data/datasource/community_api_service.dart';

class ChairmanMeetingsScreen extends StatefulWidget {
  const ChairmanMeetingsScreen({super.key});

  @override
  State<ChairmanMeetingsScreen> createState() => _ChairmanMeetingsScreenState();
}

class _ChairmanMeetingsScreenState extends State<ChairmanMeetingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Meetings & Committee'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/chairman-home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Meetings'),
            Tab(text: 'Committee'),
            Tab(text: 'Role Approvals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ChairmanMeetingsTab(),
          _ChairmanCommitteeTab(),
          _ChairmanRoleApprovalsTab(),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: SCHEDULED MEETINGS & MINUTES EDITING & DELETION
// -------------------------------------------------------------
class _ChairmanMeetingsTab extends StatefulWidget {
  const _ChairmanMeetingsTab();

  @override
  State<_ChairmanMeetingsTab> createState() => _ChairmanMeetingsTabState();
}

class _ChairmanMeetingsTabState extends State<_ChairmanMeetingsTab> {
  late Future<List<dynamic>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  void _loadMeetings() {
    setState(() {
      _meetingsFuture = CommunityApiService.fetchMeetings();
    });
  }

  Future<void> _handleDeleteMeeting(String meetingId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Meeting'),
        content: Text('Are you sure you want to permanently delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await CommunityApiService.deleteMeeting(meetingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Meeting deleted successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadMeetings();
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

  void _openScheduleMeetingSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final agendaController = TextEditingController();
    final locationController = TextEditingController();
    final minutesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                      const Text(
                        'Schedule General Meeting',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Title',
                      hintText: 'e.g. Annual General Body Meeting (AGM)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter meeting title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: agendaController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Agenda',
                      hintText: 'List topics, discussions, or proposals...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter agenda description'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Venue / Meeting Room',
                      hintText: 'e.g. Society Clubhouse, Block A Lawn',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter meeting location'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Date',
                            style: TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.calendar_today, size: 18),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Time',
                            style: TextStyle(fontSize: 12),
                          ),
                          subtitle: Text(
                            selectedTime.format(context),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.access_time, size: 18),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setModalState(() => selectedTime = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: minutesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Initial Minutes / Link (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              final dateStr =
                                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                              final timeStr =
                                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';

                              final res =
                                  await CommunityApiService.scheduleMeeting(
                                    title: titleController.text.trim(),
                                    agenda: agendaController.text.trim(),
                                    meetingDate: dateStr,
                                    startTime: timeStr,
                                    location: locationController.text.trim(),
                                    minutesDoc:
                                        minutesController.text.trim().isNotEmpty
                                        ? minutesController.text.trim()
                                        : null,
                                  );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message'] ??
                                          'Meeting scheduled successfully!',
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                                _loadMeetings();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceAll('Exception: ', ''),
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.deepPurple,
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
                            'Schedule Meeting',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openEditMinutesDialog(Map<String, dynamic> meeting) {
    final minutesController = TextEditingController(
      text: meeting['minutes_doc'] ?? '',
    );
    final agendaController = TextEditingController(
      text: meeting['agenda'] ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Minutes: ${meeting['title']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: agendaController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Agenda',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: minutesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Meeting Minutes / Summary',
                  hintText: 'Record discussion points, voting outcomes...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await CommunityApiService.updateMeetingMinutes(
                  meeting['meeting_id'],
                  minutesDoc: minutesController.text.trim(),
                  agenda: agendaController.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Meeting updated!'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                  _loadMeetings();
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
            },
            child: const Text('Save Minutes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScheduleMeetingSheet,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Meeting', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _meetingsFuture,
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
                    onPressed: _loadMeetings,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final meetings = snapshot.data ?? [];
          if (meetings.isEmpty) {
            return const Center(child: Text('No meetings scheduled yet.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadMeetings(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: meetings.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final m = meetings[i];
                final hasMinutes =
                    m['minutes_doc'] != null &&
                    (m['minutes_doc'] as String).trim().isNotEmpty;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
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
                            Expanded(
                              child: Text(
                                m['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.deepPurple.shade200,
                                ),
                              ),
                              child: Text(
                                m['meeting_date'] ?? '',
                                style: TextStyle(
                                  color: Colors.deepPurple.shade900,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Agenda: ${m['agenda'] ?? ''}',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              m['location'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              m['start_time'] != null
                                  ? m['start_time'].toString().substring(0, 5)
                                  : '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (hasMinutes) ...[
                          const Divider(height: 18),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Meeting Minutes / Summary:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m['minutes_doc'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => _openEditMinutesDialog(m),
                              icon: const Icon(Icons.edit_note, size: 18),
                              label: Text(
                                hasMinutes ? 'Edit Minutes' : 'Attach Minutes',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Delete Meeting',
                              onPressed: () => _handleDeleteMeeting(
                                m['meeting_id'],
                                m['title'] ?? 'Meeting',
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
    );
  }
}

// -------------------------------------------------------------
// TAB 2: ACTIVE COMMITTEE DIRECTORY & DROPDOWN ROLE ASSIGNMENT
// -------------------------------------------------------------
class _ChairmanCommitteeTab extends StatefulWidget {
  const _ChairmanCommitteeTab();

  @override
  State<_ChairmanCommitteeTab> createState() => _ChairmanCommitteeTabState();
}

class _ChairmanCommitteeTabState extends State<_ChairmanCommitteeTab> {
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

  void _openRoleChangeRequestModal() async {
    List<dynamic> members = [];
    try {
      members = await CommunityApiService.fetchSocietyMembersDropdown();
    } catch (_) {}

    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    String? selectedUserId = members.isNotEmpty
        ? members.first['user_id']
        : null;
    String selectedRoleId = 'R02';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                const Text(
                  'Initiate Committee Role Reassignment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select a resident and proposed role. This request requires Admin dual-approval.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),

                // Resident Dropdown
                if (members.isEmpty)
                  const Text(
                    'No resident profiles found.',
                    style: TextStyle(color: Colors.red),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: selectedUserId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Society Resident',
                      border: OutlineInputBorder(),
                    ),
                    items: members.map((m) {
                      return DropdownMenuItem<String>(
                        value: m['user_id'].toString(),
                        child: Text(
                          '${m['user_name']} (${m['block_name']} - ${m['flat_number']})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedUserId = v);
                    },
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please select a resident'
                        : null,
                  ),
                const SizedBox(height: 12),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: selectedRoleId,
                  decoration: const InputDecoration(
                    labelText: 'Proposed Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'R01', child: Text('Resident')),
                    DropdownMenuItem(value: 'R02', child: Text('Secretary')),
                    DropdownMenuItem(
                      value: 'R03',
                      child: Text('Block Secretary'),
                    ),
                    DropdownMenuItem(value: 'R04', child: Text('Treasurer')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => selectedRoleId = v);
                  },
                ),
                const SizedBox(height: 18),

                ElevatedButton(
                  onPressed: isSubmitting || selectedUserId == null
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => isSubmitting = true);
                          try {
                            final res =
                                await CommunityApiService.submitRoleChangeRequest(
                                  targetUserId: selectedUserId!,
                                  newRoleId: selectedRoleId,
                                );
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res['message'] ?? 'Role change requested!',
                                  ),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                              _loadCommittee();
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.deepPurple,
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
                          'Submit For Admin Approval',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRoleChangeRequestModal,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.swap_horiz, color: Colors.white),
        label: const Text('Assign Role', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<dynamic>>(
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
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
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
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 3: DUAL-APPROVAL QUEUE & REQUEST CANCELLATIONS
// -------------------------------------------------------------
class _ChairmanRoleApprovalsTab extends StatefulWidget {
  const _ChairmanRoleApprovalsTab();

  @override
  State<_ChairmanRoleApprovalsTab> createState() =>
      _ChairmanRoleApprovalsTabState();
}

class _ChairmanRoleApprovalsTabState extends State<_ChairmanRoleApprovalsTab> {
  late Future<List<dynamic>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    setState(() {
      _requestsFuture = CommunityApiService.fetchCommitteeChangeRequests();
    });
  }

  Future<void> _handleAction(String requestId, String action) async {
    try {
      final res = await CommunityApiService.handleCommitteeChangeAction(
        requestId,
        action,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Request updated successfully!'),
            backgroundColor: action == 'Approved'
                ? Colors.green.shade700
                : Colors.orange.shade800,
          ),
        );
        _loadRequests();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _requestsFuture,
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
                  onPressed: _loadRequests,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Text('No committee change requests found.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadRequests(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: requests.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final req = requests[i];
              final status = (req['status'] ?? 'Pending').toString();
              final isAwaitingChairman = status == 'Pending_Chairman_Approval';
              final isAwaitingAdmin = status == 'Pending_Admin_Approval';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
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
                            'Request #${req['request_id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: status.contains('Approved')
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status.contains('Approved')
                                    ? Colors.green.shade800
                                    : Colors.orange.shade900,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Target Member: ${req['target_user_name'] ?? 'User'}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Proposed Role: ${req['new_role_name'] ?? '--'}',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                      Text(
                        'Initiated by: ${req['requested_by_name'] ?? 'Initiator'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (isAwaitingChairman) ...[
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  _handleAction(req['request_id'], 'Rejected'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _handleAction(req['request_id'], 'Approved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text(
                                'Approve Role Change',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ] else if (isAwaitingAdmin) ...[
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Awaiting Admin Sign-off',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _handleAction(req['request_id'], 'Cancelled'),
                              child: const Text(
                                'Cancel Request',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
