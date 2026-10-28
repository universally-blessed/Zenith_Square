import 'package:flutter/material.dart';
import '../../data/datasource/communication_api_service.dart';
import '../../data/datasource/api_service.dart';

class SecretaryNoticesScreen extends StatefulWidget {
  const SecretaryNoticesScreen({super.key});

  @override
  State<SecretaryNoticesScreen> createState() => _SecretaryNoticesScreenState();
}

class _SecretaryNoticesScreenState extends State<SecretaryNoticesScreen> {
  late Future<List<dynamic>> _noticesFuture;
  List<Block> _blocks = [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
    _loadBlocks();
  }

  void _loadNotices() {
    if (!mounted) return;
    setState(() {
      _noticesFuture = CommunicationApiService.fetchNotices();
    });
  }

  Future<void> _loadBlocks() async {
    try {
      final profile = await ApiService.fetchUserProfile();
      String societyId = profile['society_id'] ?? '';
      if (societyId.isNotEmpty && mounted) {
        final blocks = await ApiService.fetchBlocks(societyId);
        if (mounted) setState(() => _blocks = blocks);
      }
    } catch (e) {
      debugPrint('[SecretaryNotices] Error loading blocks: $e');
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade800;
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
            content: Text(res['message'] ?? 'Notice archived!'),
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
    String? sheetError;
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
                          'Post Society Notice',
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
                    const SizedBox(height: 14),
                    if (sheetError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 18,
                              color: Colors.red.shade800,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sheetError!,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    TextFormField(
                      controller: titleController,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Title must be at least 3 chars'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Details *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? 'Details must be at least 10 chars'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
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
                            onChanged: (val) =>
                                setModalState(() => selectedPriority = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                            onChanged: (val) =>
                                setModalState(() => selectedBlockId = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);
                              try {
                                await CommunicationApiService.publishNotice(
                                  title: titleController.text.trim(),
                                  description: descController.text.trim(),
                                  priority: selectedPriority,
                                  blockId: selectedBlockId,
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  _loadNotices();
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                sheetError = e.toString().replaceAll(
                                  'Exception: ',
                                  '',
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Publish Announcement',
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
      appBar: AppBar(title: const Text('Secretary Notice Board')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPublishNoticeSheet,
        backgroundColor: Colors.indigo.shade900,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text('Post Notice', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _noticesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notices = snapshot.data ?? [];
          if (notices.isEmpty) {
            return const Center(child: Text('No notices posted yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notices.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final item = notices[i];
              return Card(
                child: ListTile(
                  title: Text(
                    item['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${item['description']}\nScope: ${item['block_name'] ?? 'All Blocks'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _handleDeleteNotice(
                      item['notice_id'],
                      item['title'] ?? '',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
