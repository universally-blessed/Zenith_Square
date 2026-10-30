import 'package:flutter/material.dart';
import '../../data/datasource/community_api_service.dart';

class SecretaryMeetingsScreen extends StatefulWidget {
  const SecretaryMeetingsScreen({super.key});

  @override
  State<SecretaryMeetingsScreen> createState() =>
      _SecretaryMeetingsScreenState();
}

class _SecretaryMeetingsScreenState extends State<SecretaryMeetingsScreen> {
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
    String? modalError;

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
                      labelText: 'Meeting Title *',
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
                      labelText: 'Meeting Agenda *',
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
                      labelText: 'Venue / Meeting Room *',
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
                            'Date *',
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
                            'Time *',
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
                              useRootNavigator: true,
                              initialEntryMode: TimePickerEntryMode.dial,
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    timePickerTheme: TimePickerThemeData(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  child: MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      alwaysUse24HourFormat: false,
                                      textScaler: const TextScaler.linear(1.0),
                                      size: const Size(200, 200),
                                    ),
                                    child: child!,
                                  ),
                                );
                              },
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
                  const SizedBox(height: 12),
                  if (modalError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        modalError!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() {
                              isSubmitting = true;
                              modalError = null;
                            });
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
                              setModalState(() {
                                isSubmitting = false;
                                modalError = e.toString().replaceAll(
                                  'Exception: ',
                                  '',
                                );
                              });
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
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Meeting updated!'),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
                _loadMeetings();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
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
      appBar: AppBar(
        title: const Text('Society Meetings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
