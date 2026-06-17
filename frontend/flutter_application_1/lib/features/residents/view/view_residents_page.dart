import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/society_api_services.dart'; // 🔄 Redirected to split Society worker layer

class ViewResidentsPage extends StatefulWidget {
  const ViewResidentsPage({super.key});

  @override
  State<ViewResidentsPage> createState() => _ViewResidentsPageState();
}

class _ViewResidentsPageState extends State<ViewResidentsPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color emeraldGreen = Color(0xFF2E7D32);

  late TabController _filterTabController;
  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  // Dynamic list holder to receive real parsed JSON structures from your server
  List<dynamic> _societyDirectory = [];
  bool _pageLoading = true;

  @override
  void initState() {
    super.initState();
    _filterTabController = TabController(length: 3, vsync: this);
    _loadLiveDirectory();
  }

  /// Extracts your complete backend tenant join maps dynamically
  Future<void> _loadLiveDirectory() async {
    try {
      final listData = await SocietyApiService.fetchGlobalResidentsDirectory(
        _sessionToken,
      );
      if (mounted) {
        setState(() {
          _societyDirectory = listData;
          _pageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pageLoading = false);
        _showTopSnack(
          "Could not synchronize with society roster rows.",
          isError: true,
        );
      }
    }
  }

  void _showTopSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.lexend(fontSize: 12.5)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade800 : emeraldGreen,
      ),
    );
  }

  @override
  void dispose() {
    _filterTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: Text(
          'Society Registry',
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
        bottom: TabBar(
          controller: _filterTabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.lexend(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.lexend(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'All Members'),
            Tab(text: 'Owners'),
            Tab(text: 'Tenants'),
          ],
        ),
      ),
      body: _pageLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : TabBarView(
              controller: _filterTabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildFilteredList('ALL'),
                _buildFilteredList('OWNER'),
                _buildFilteredList('TENANT'),
              ],
            ),
    );
  }

  Widget _buildFilteredList(String structuralFilter) {
    final dataset = structuralFilter == 'ALL'
        ? _societyDirectory
        : _societyDirectory
              .where((element) => element['role'] == structuralFilter)
              .toList();

    if (dataset.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLiveDirectory,
        color: primaryBlue,
        child: ListView(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: Text(
                  'No records matching filters found.',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: Colors.black38,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLiveDirectory,
      color: primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: dataset.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final member = dataset[index];
          bool isOwner = member['role'] == 'OWNER';
          final String residentId = (member['user_id'] ?? member['id'] ?? index)
              .toString();

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.night_shelter_outlined,
                          color: isOwner ? primaryBlue : Colors.teal.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          member['unit'] ?? 'Unassigned Flat',
                          style: GoogleFonts.lexend(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? primaryBlue.withValues(alpha: 0.06)
                            : Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member['role'] ?? 'MEMBER',
                        style: GoogleFonts.lexend(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isOwner ? primaryBlue : Colors.teal.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                Text(
                  member['name'] ?? 'Unknown Resident',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 6),
                _buildContactMetaRow(
                  Icons.phone_android_rounded,
                  member['phone'] ?? 'No Contact',
                ),
                const SizedBox(height: 4),
                _buildContactMetaRow(
                  Icons.alternate_email_rounded,
                  member['email'] ?? 'No Email',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: primaryBlue,
                        size: 16,
                      ),
                      label: Text(
                        'Message Member',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      onPressed: () => _openDirectMessageOverlay(
                        context,
                        member['name'] ?? 'Resident',
                        residentId,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactMetaRow(IconData icon, String detailValue) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black38),
        const SizedBox(width: 8),
        Text(
          detailValue,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _openDirectMessageOverlay(
    BuildContext context,
    String recipientName,
    String residentId,
  ) {
    final TextEditingController msgController = TextEditingController();
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();
    bool isSendingMessage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Message to $recipientName',
              style: GoogleFonts.lexend(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            content: Form(
              key: dialogFormKey,
              child: TextFormField(
                controller: msgController,
                maxLines: 3,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 13, color: darkText),
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: Colors.black38,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: primaryBlue),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Message body cannot run empty.'
                    : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSendingMessage
                    ? null
                    : () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.lexend(
                    fontSize: 12.5,
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                onPressed: isSendingMessage
                    ? null
                    : () async {
                        if (dialogFormKey.currentState!.validate()) {
                          setDialogState(() => isSendingMessage = true);

                          // 🔄 Hits the real direct message payload endpoint on your server
                          bool success =
                              await SocietyApiService.sendDirectResidentMessage(
                                token: _sessionToken,
                                residentId: residentId,
                                messageText: msgController.text.trim(),
                              );

                          if (mounted) {
                            Navigator.pop(context);
                            if (success) {
                              _showTopSnack(
                                'Message successfully delivered to $recipientName.',
                              );
                            } else {
                              _showTopSnack(
                                'Failed to deliver message payload.',
                                isError: true,
                              );
                            }
                          }
                        }
                      },
                child: isSendingMessage
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Send message',
                        style: GoogleFonts.lexend(
                          fontSize: 12.5,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
