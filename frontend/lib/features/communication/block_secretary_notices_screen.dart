import 'package:flutter/material.dart';
import '../../data/datasource/communication_api_service.dart';

class BlockSecretaryNoticesScreen extends StatefulWidget {
  const BlockSecretaryNoticesScreen({super.key});

  @override
  State<BlockSecretaryNoticesScreen> createState() =>
      _BlockSecretaryNoticesScreenState();
}

class _BlockSecretaryNoticesScreenState
    extends State<BlockSecretaryNoticesScreen> {
  late Future<List<dynamic>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  void _loadNotices() {
    setState(() {
      _noticesFuture = CommunicationApiService.fetchNotices();
    });
  }

  void _openPublishNoticeSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'normal';
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
                          'Post Block Announcement',
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

                    TextFormField(
                      controller: titleController,
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

                    DropdownButtonFormField<String>(
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
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Text('Urgent'),
                        ),
                      ],
                      onChanged: (val) =>
                          setModalState(() => selectedPriority = val!),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);
                              try {
                                // Block ID is handled automatically by backend for Block Secretary role
                                await CommunicationApiService.publishNotice(
                                  title: titleController.text.trim(),
                                  description: descController.text.trim(),
                                  priority: selectedPriority,
                                );
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  _loadNotices();
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Post to My Block',
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
      appBar: AppBar(title: const Text('Block Notice Board')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPublishNoticeSheet,
        backgroundColor: Colors.teal.shade900,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text(
          'Post Block Notice',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _noticesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final notices = snapshot.data ?? [];
          if (notices.isEmpty)
            return const Center(child: Text('No notices for your block.'));

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
                    '${item['description']}\nPosted by: ${item['author_name'] ?? 'Admin'}',
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
