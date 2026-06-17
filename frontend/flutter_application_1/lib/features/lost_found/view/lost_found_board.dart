import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart';

class LostFoundPage extends StatefulWidget {
  const LostFoundPage({super.key});

  @override
  State<LostFoundPage> createState() => _LostFoundPageState();
}

class _LostFoundPageState extends State<LostFoundPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  List<dynamic> _boardItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoardLogs();
  }

  Future<void> _loadBoardLogs() async {
    try {
      final dataset = await OperationalApiService.fetchLostFoundItems(
        _sessionToken,
      );
      if (mounted) {
        setState(() {
          _boardItems = dataset;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack("Failed to update notice board listings.");
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.lexend(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Lost & Found Board',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
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
              onRefresh: _loadBoardLogs,
              color: primaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reported Belongings',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showReportingModal(context),
                        icon: const Icon(
                          Icons.campaign_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Report',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _boardItems.isEmpty
                      ? _buildEmptyStatePlaceholder()
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _boardItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final log = _boardItems[index];

                            String status = (log['item_status'] ?? 'LOST')
                                .toString()
                                .toUpperCase();
                            Color tagColor = status == 'FOUND'
                                ? Colors.teal
                                : Colors.orange.shade800;

                            return _buildItemCard(
                              log['item_name'] ?? 'Unknown Object',
                              log['item_description'] ??
                                  'No descriptions provided.',
                              log['item_location'] ?? 'Common Area',
                              log['reported_date'] ?? 'Recent',
                              status,
                              tagColor,
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyStatePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80.0),
        child: Text(
          'No belongings logged on the bulletin board.',
          style: GoogleFonts.inter(color: Colors.black38, fontSize: 13.5),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    String title,
    String desc,
    String location,
    String date,
    String status,
    Color tagColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.lexend(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: Colors.black38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.fmd_good_outlined,
                color: primaryBlue.withValues(alpha: 0.6),
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "Location: $location",
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportingModal(BuildContext context) {
    final modalFormKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    String reportType = 'LOST';

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
                      'Report Item Notice',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: nameController,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: darkText,
                        fontWeight: FontWeight.w600,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Item name is required"
                          : null,
                      decoration: _modalInputDecoration(
                        'What was lost or found?',
                        Icons.widgets_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      style: GoogleFonts.inter(fontSize: 13.5, color: darkText),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Description clues are required"
                          : null,
                      decoration: _modalInputDecoration(
                        'Provide descriptive spot details...',
                        Icons.info_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: locationController,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: darkText,
                        fontWeight: FontWeight.w500,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Estimated location is required"
                          : null,
                      decoration: _modalInputDecoration(
                        'Where? (e.g., Block B Lift Lobby)',
                        Icons.fmd_good_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: reportType,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: darkText,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _modalInputDecoration(
                        'Notice Type Tag',
                        Icons.tag_rounded,
                      ),
                      items: ['LOST', 'FOUND']
                          .map(
                            (st) =>
                                DropdownMenuItem(value: st, child: Text(st)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => reportType = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (modalFormKey.currentState!.validate()) {
                            Navigator.pop(context);
                            setState(() => _isLoading = true);

                            bool success =
                                await OperationalApiService.postLostFoundReport(
                                  _sessionToken,
                                  {
                                    'item_name': nameController.text.trim(),
                                    'item_description': descController.text
                                        .trim(),
                                    'item_location': locationController.text
                                        .trim(),
                                    'item_status': reportType
                                        .toLowerCase(), // Aligns perfectly with backend database string expectations
                                  },
                                );

                            if (success) {
                              _showSnack("Bulletin card published live!");
                              _loadBoardLogs();
                            } else {
                              setState(() => _isLoading = false);
                              _showSnack("Failed logging report to database.");
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Publish to Board',
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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

  InputDecoration _modalInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
      labelStyle: GoogleFonts.inter(fontSize: 13.5, color: Colors.black45),
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
