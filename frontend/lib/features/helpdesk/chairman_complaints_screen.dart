import 'package:flutter/material.dart';
import '../../data/datasource/helpdesk_api_service.dart';

class ChairmanComplaintsScreen extends StatefulWidget {
  const ChairmanComplaintsScreen({super.key});

  @override
  State<ChairmanComplaintsScreen> createState() =>
      _ChairmanComplaintsScreenState();
}

class _ChairmanComplaintsScreenState extends State<ChairmanComplaintsScreen>
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
        title: const Text('Helpdesk & Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/chairman-home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Society Complaints'),
            Tab(text: 'Resident Feedbacks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_SocietyComplaintsTab(), _SocietyFeedbacksTab()],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: ALL SOCIETY COMPLAINTS (WITH STATUS MANAGEMENT)
// -------------------------------------------------------------
class _SocietyComplaintsTab extends StatefulWidget {
  const _SocietyComplaintsTab();

  @override
  State<_SocietyComplaintsTab> createState() => _SocietyComplaintsTabState();
}

class _SocietyComplaintsTabState extends State<_SocietyComplaintsTab> {
  late Future<List<dynamic>> _complaintsFuture;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  void _loadComplaints() {
    setState(() {
      _complaintsFuture = HelpdeskApiService.fetchComplaints();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in-progress':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.amber.shade800;
    }
  }

  void _showUpdateStatusDialog(String complaintId, String currentStatus) {
    String newStatus = currentStatus.toLowerCase();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Ticket Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assign progress status to this complaint:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value:
                    [
                      'pending',
                      'in-progress',
                      'resolved',
                      'rejected',
                    ].contains(newStatus)
                    ? newStatus
                    : 'pending',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Status',
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'in-progress',
                    child: Text('In-Progress'),
                  ),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => newStatus = val);
                  }
                },
              ),
            ],
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
                  final res = await HelpdeskApiService.updateComplaintStatus(
                    complaintId,
                    newStatus,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          res['message'] ?? 'Status updated successfully!',
                        ),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );
                    _loadComplaints();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _openFileComplaintSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'File Chairman Complaint',
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
                      labelText: 'Title / Subject',
                      hintText: 'e.g., Common Area Lighting Issue',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Description',
                      hintText: 'Describe the issue...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter description'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              final res =
                                  await HelpdeskApiService.fileComplaint(
                                    title: titleController.text.trim(),
                                    description: descController.text.trim(),
                                  );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message'] ??
                                          'Complaint registered successfully!',
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                                _loadComplaints();
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
                      backgroundColor: Colors.amber.shade800,
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
                            'Submit Ticket',
                            style: TextStyle(color: Colors.white, fontSize: 16),
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
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openFileComplaintSheet,
        backgroundColor: Colors.amber.shade800,
        icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
        label: const Text('New Ticket', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('in-progress', 'In-Progress'),
                const SizedBox(width: 8),
                _buildFilterChip('resolved', 'Resolved'),
                const SizedBox(width: 8),
                _buildFilterChip('rejected', 'Rejected'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Complaints List
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _complaintsFuture,
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
                          snapshot.error.toString().replaceAll(
                            'Exception: ',
                            '',
                          ),
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadComplaints,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allComplaints = snapshot.data ?? [];
                final filteredComplaints = allComplaints.where((c) {
                  if (_selectedFilter == 'all') return true;
                  return (c['status'] ?? '').toString().toLowerCase() ==
                      _selectedFilter;
                }).toList();

                if (filteredComplaints.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFilter == 'all'
                              ? 'No complaints filed in society.'
                              : 'No complaints under "$_selectedFilter".',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadComplaints(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: filteredComplaints.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final item = filteredComplaints[i];
                      final status = (item['status'] ?? 'pending').toString();
                      final color = _getStatusColor(status);
                      final residentName = item['resident_name'] ?? 'Resident';
                      final blockName = item['block_name'] ?? '--';
                      final flatNumber = item['flat_number'] ?? '--';

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#${item['complaint_id'] ?? ''}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _showUpdateStatusDialog(
                                      item['complaint_id'],
                                      status,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.edit,
                                            size: 12,
                                            color: color,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['description'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 13,
                                ),
                              ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$residentName ($blockName - $flatNumber)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  Text(
                                    item['created_at'] != null
                                        ? item['created_at']
                                              .toString()
                                              .substring(0, 10)
                                        : '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
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
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
        }
      },
    );
  }
}

// -------------------------------------------------------------
// TAB 2: RESIDENT FEEDBACK LOGS (/feedback/ GET)
// -------------------------------------------------------------
class _SocietyFeedbacksTab extends StatefulWidget {
  const _SocietyFeedbacksTab();

  @override
  State<_SocietyFeedbacksTab> createState() => _SocietyFeedbacksTabState();
}

class _SocietyFeedbacksTabState extends State<_SocietyFeedbacksTab> {
  late Future<List<dynamic>> _feedbackFuture;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  void _loadFeedbacks() {
    setState(() {
      _feedbackFuture = HelpdeskApiService.fetchFeedbacks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _feedbackFuture,
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
                  onPressed: _loadFeedbacks,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final feedbacks = snapshot.data ?? [];
        if (feedbacks.isEmpty) {
          return const Center(child: Text('No society feedback received yet.'));
        }

        return RefreshIndicator(
          onRefresh: () async => _loadFeedbacks(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: feedbacks.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final fb = feedbacks[i];
              final rating = fb['rating'] ?? 5;
              final residentName = fb['resident_name'] ?? 'Resident';

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
                            residentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: Colors.amber.shade700,
                                size: 18,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fb['feedback_text'] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 13,
                        ),
                      ),
                      const Divider(height: 16),
                      Text(
                        fb['created_at'] != null
                            ? fb['created_at'].toString().substring(0, 10)
                            : '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
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
    );
  }
}
