import 'package:flutter/material.dart';
import '../../data/datasource/communication_api_service.dart';
import '../../data/datasource/api_service.dart';

class ChairmanNoticesScreen extends StatefulWidget {
  const ChairmanNoticesScreen({super.key});

  @override
  State<ChairmanNoticesScreen> createState() => _ChairmanNoticesScreenState();
}

class _ChairmanNoticesScreenState extends State<ChairmanNoticesScreen> {
  late Future<List<dynamic>> _noticesFuture;
  List<Block> _blocks = [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
    _loadBlocks();
  }

  void _loadNotices() {
    setState(() {
      _noticesFuture = CommunicationApiService.fetchNotices();
    });
  }

  Future<void> _loadBlocks() async {
    try {
      final profile = await ApiService.fetchUserProfile();
      String societyId = profile['society_id'] ?? '';

      // Fallback: If society_id is missing, match via society_name from public societies list
      if (societyId.isEmpty) {
        final societies = await ApiService.fetchSocieties();
        final currentSocietyName = profile['society_name'] ?? '';
        final match = societies.firstWhere(
          (s) => s.name.toLowerCase() == currentSocietyName.toLowerCase(),
          orElse: () => societies.isNotEmpty
              ? societies.first
              : Society(id: '', name: ''),
        );
        societyId = match.id;
      }

      if (societyId.isNotEmpty) {
        final blocks = await ApiService.fetchBlocks(societyId);
        if (mounted) setState(() => _blocks = blocks);
      }
    } catch (error) {
      debugPrint('[ChairmanNotices] Failed to load blocks: $error');
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade800;
      case 'normal':
      default:
        return Colors.teal;
    }
  }

  Future<void> _handleDeleteNotice(String noticeId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Notice'),
        content: Text('Are you sure you want to archive "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await CommunicationApiService.deleteNotice(noticeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Notice archived successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadNotices();
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

  void _openPublishNoticeSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'normal';
    String? selectedBlockId;
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Publish Announcement',
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
                        labelText: 'Notice Title',
                        hintText: 'e.g., Annual Society Meeting, Water Outage',
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
                        labelText: 'Notice Details',
                        hintText: 'Write the complete announcement...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter notice details'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Priority Selector
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'normal',
                                child: Text('Normal'),
                              ),
                              DropdownMenuItem(
                                value: 'high',
                                child: Text('High'),
                              ),
                              DropdownMenuItem(
                                value: 'urgent',
                                child: Text('Urgent'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedPriority = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Block Scope Selector
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: selectedBlockId,
                            decoration: const InputDecoration(
                              labelText: 'Target Scope',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Blocks'),
                              ),
                              ..._blocks.map(
                                (b) => DropdownMenuItem(
                                  value: b.id,
                                  child: Text(b.name),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setModalState(() => selectedBlockId = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);
                              try {
                                final res =
                                    await CommunicationApiService.publishNotice(
                                      title: titleController.text.trim(),
                                      description: descController.text.trim(),
                                      priority: selectedPriority,
                                      blockId: selectedBlockId,
                                    );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['message'] ??
                                            'Notice published successfully!',
                                      ),
                                      backgroundColor: Colors.green.shade700,
                                    ),
                                  );
                                  _loadNotices();
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.teal,
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
                              'Publish Notice',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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
      appBar: AppBar(
        title: const Text('Society Announcements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/chairman-home'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPublishNoticeSheet,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text('Post Notice', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _noticesFuture,
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
                    onPressed: _loadNotices,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notices = snapshot.data ?? [];
          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No notices posted yet.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Post Notice" to broadcast an update.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadNotices(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: notices.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = notices[i];
                final priority = (item['priority'] ?? 'normal')
                    .toString()
                    .toUpperCase();
                final priorityColor = _getPriorityColor(
                  item['priority'] ?? 'normal',
                );
                final blockScope = item['block_name'] ?? 'All Blocks';
                final dateStr = item['created_at'] != null
                    ? item['created_at'].toString().substring(0, 10)
                    : '';

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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                priority,
                                style: TextStyle(
                                  color: priorityColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Archive Notice',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _handleDeleteNotice(
                                    item['notice_id'],
                                    item['title'] ?? 'Notice',
                                  ),
                                ),
                              ],
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
                        const SizedBox(height: 6),
                        Text(
                          item['description'] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Icon(
                              Icons.apartment,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Scope: $blockScope',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
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
