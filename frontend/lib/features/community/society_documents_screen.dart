import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasource/community_api_service.dart';
import '../../data/datasource/api_service.dart';

class SocietyDocumentsScreen extends StatefulWidget {
  const SocietyDocumentsScreen({super.key});

  @override
  State<SocietyDocumentsScreen> createState() => _SocietyDocumentsScreenState();
}

class _SocietyDocumentsScreenState extends State<SocietyDocumentsScreen> {
  late Future<List<dynamic>> _docsFuture;
  bool _canManage = false;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadDocuments();
  }

  Future<void> _checkPermissions() async {
    try {
      final profile = await ApiService.fetchUserProfile();
      final role = (profile['role_name'] ?? '').toString().toLowerCase();
      if (mounted) {
        setState(() {
          _canManage = ['chairman', 'secretary', 'admin'].contains(role);
          _isLoadingRole = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  void _loadDocuments() {
    if (!mounted) return;
    setState(() {
      _docsFuture = CommunityApiService.fetchSocietyDocuments();
    });
  }

  Future<void> _handleDelete(String docId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to remove "$title"?'),
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

    if (confirm != true) return;

    try {
      final res = await CommunityApiService.deleteSocietyDocument(docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Document deleted.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _loadDocuments();
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

  void _openUploadSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final linkController = TextEditingController();
    String selectedType = 'Bye-Laws';
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
                        'Upload Society Document',
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

                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Document Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Bye-Laws',
                        child: Text('Society Bye-Laws'),
                      ),
                      DropdownMenuItem(
                        value: 'NOC Template',
                        child: Text('NOC Template'),
                      ),
                      DropdownMenuItem(
                        value: 'Circular',
                        child: Text('Official Circular'),
                      ),
                      DropdownMenuItem(
                        value: 'Meeting Minutes',
                        child: Text('Meeting Minutes'),
                      ),
                      DropdownMenuItem(
                        value: 'Audit Report',
                        child: Text('Financial Audit Report'),
                      ),
                      DropdownMenuItem(
                        value: 'General',
                        child: Text('General Document'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedType = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Document Title',
                      hintText: 'e.g., Society Rules & Regulations 2026',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Enter document title';
                      if (val.length < 3)
                        return 'Title must be at least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: linkController,
                    decoration: const InputDecoration(
                      labelText: 'File URL / Google Drive Link',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Enter document file URL';
                      return null;
                    },
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
                                  await CommunityApiService.uploadSocietyDocument(
                                    title: titleController.text.trim(),
                                    documentType: selectedType,
                                    fileUrl: linkController.text.trim(),
                                  );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message'] ?? 'Document uploaded!',
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                                _loadDocuments();
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
                      backgroundColor: Colors.blueAccent,
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
                            'Upload Document',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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

  IconData _getDocIcon(String docType) {
    switch (docType.toLowerCase()) {
      case 'bye-laws':
        return Icons.gavel_rounded;
      case 'noc template':
        return Icons.verified_user_outlined;
      case 'circular':
        return Icons.campaign_outlined;
      case 'meeting minutes':
        return Icons.groups_outlined;
      case 'audit report':
        return Icons.assessment_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Documents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: _openUploadSheet,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Document'),
            )
          : null,
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<dynamic>>(
              future: _docsFuture,
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
                          onPressed: _loadDocuments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No society documents published yet.',
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadDocuments(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final doc = docs[i];
                      final docType = doc['document_type'] ?? 'General';
                      final uploadedAt = doc['uploaded_at'] != null
                          ? doc['uploaded_at'].toString().substring(0, 10)
                          : '';

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: Icon(
                              _getDocIcon(docType),
                              color: Colors.blueAccent,
                            ),
                          ),
                          title: Text(
                            doc['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Type: $docType • By: ${doc['uploaded_by_name'] ?? 'Management'}\nUploaded: $uploadedAt',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          isThreeLine: true,
                          onTap: () => _openDocumentUrl(
                            doc['file_url'] ?? '',
                          ), // <--- Tap anywhere on card to open
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.open_in_new,
                                  size: 20,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () =>
                                    _openDocumentUrl(doc['file_url'] ?? ''),
                              ),
                              if (_canManage)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _handleDelete(
                                    doc['document_id'],
                                    doc['title'] ?? 'Document',
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
    );
  }

  Future<void> _openDocumentUrl(String urlString) async {
    if (urlString.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid document link.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uri url = Uri.parse(urlString.trim());

    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.platformDefault,
      );

      if (!launched) {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document link: $urlString'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
