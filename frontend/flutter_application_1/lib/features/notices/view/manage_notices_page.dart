import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart'; // 🔄 Updated to use the split service layer

class ManageNoticesPage extends StatefulWidget {
  const ManageNoticesPage({super.key});

  @override
  State<ManageNoticesPage> createState() => _ManageNoticesPageState();
}

class _ManageNoticesPageState extends State<ManageNoticesPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  List<dynamic> _noticesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveNotices();
  }

  Future<void> _loadLiveNotices() async {
    try {
      // 📢 Pulling live announcements down from our segregated operational network service
      final data = await OperationalApiService.fetchNotices(_sessionToken);
      if (mounted) {
        setState(() {
          _noticesList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(
          "Could not synchronize with the notice board database.",
          isError: true,
        );
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.lexend(fontSize: 12.5)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade800 : primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: Text(
          'Broadcast Control Board',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadLiveNotices,
              color: primaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Announcements',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openNoticeFormModal(context),
                        icon: const Icon(
                          Icons.add_comment_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Publish',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _noticesList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 80.0),
                            child: Text(
                              'No active board notices broadcasted.',
                              style: GoogleFonts.inter(
                                color: Colors.black38,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _noticesList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final notice = _noticesList[index];
                            return _buildNoticeCard(notice, index);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildNoticeCard(dynamic notice, int index) {
    final dynamic idKey = notice['notice_id'] ?? notice['id'] ?? index;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.campaign_rounded,
                    color: primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'BROADCAST LIVE',
                    style: GoogleFonts.lexend(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                notice['created_at'] ?? 'Recent',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notice['title'] ?? 'Untitled Broadcast',
            style: GoogleFonts.lexend(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            notice['description'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _confirmDeleteDialog(context, idKey),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Colors.red.shade800,
                ),
                label: Text(
                  'Retract Notice',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openNoticeFormModal(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final modalFormKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: modalFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compose Board Notice',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: titleController,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: darkText,
                        fontWeight: FontWeight.w600,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Notice header title required"
                          : null,
                      decoration: _inputDecoration(
                        'Notice Subject Header',
                        Icons.title_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      style: GoogleFonts.inter(fontSize: 13.5, color: darkText),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Notice description details required"
                          : null,
                      decoration: _inputDecoration(
                        'Write description message details here...',
                        Icons.description_outlined,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (modalFormKey.currentState!.validate()) {
                                  setModalState(() => isSubmitting = true);

                                  // 📢 Calling our shared operational service method
                                  bool success =
                                      await OperationalApiService.createSocietyNotice(
                                        _sessionToken,
                                        titleController.text.trim(),
                                        descriptionController.text.trim(),
                                      );

                                  if (success) {
                                    _loadLiveNotices();
                                    if (context.mounted) Navigator.pop(context);
                                    _showSnack(
                                      "Notice broadcasted live across community dashboards!",
                                    );
                                  } else {
                                    setModalState(() => isSubmitting = false);
                                    _showSnack(
                                      "Failed to broadcast announcement row.",
                                      isError: true,
                                    );
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Publish Broadcast Notification',
                                style: GoogleFonts.lexend(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteDialog(BuildContext context, dynamic noticeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Retract Broadcast Announcement?',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'This action removes the announcement row layout permanently from the database. Residents will instantly lose access to this notice on their dashboard timelines.',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.lexend(
                fontSize: 12.5,
                color: Colors.black38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              // 📢 Calling our shared operational service method to delete the notice
              bool success = await OperationalApiService.deleteSocietyNotice(
                _sessionToken,
                noticeId,
              );

              if (success) {
                _showSnack(
                  "Announcement row deleted from notice board streams.",
                  isError: true,
                );
                _loadLiveNotices();
              } else {
                setState(() => _isLoading = false);
                _showSnack(
                  "Failed to remove announcement from database entry.",
                  isError: true,
                );
              }
            },
            child: Text(
              'Delete Notice',
              style: GoogleFonts.lexend(
                fontSize: 12.5,
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      prefixIcon: Icon(icon, color: primaryBlue, size: 18),
      labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
      filled: true,
      fillColor: const Color(0xFFFBFBFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }
}
