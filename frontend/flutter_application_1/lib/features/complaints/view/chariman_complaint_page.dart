import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart'; // 🔄 Redirected to split Operational worker layer

class ChairmanViewComplaintsPage extends StatefulWidget {
  const ChairmanViewComplaintsPage({super.key});

  @override
  State<ChairmanViewComplaintsPage> createState() =>
      _ChairmanViewComplaintsPageState();
}

class _ChairmanViewComplaintsPageState extends State<ChairmanViewComplaintsPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color emeraldGreen = Color(0xFF2E7D32);

  late TabController _statusTabController;
  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  List<dynamic> _allComplaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _statusTabController = TabController(length: 2, vsync: this);
    _loadGlobalGrievances();
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    super.dispose();
  }

  Future<void> _loadGlobalGrievances() async {
    final data = await OperationalApiService.fetchGlobalComplaints(
      _sessionToken,
    );
    if (mounted) {
      setState(() {
        _allComplaints = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateComplaintState(String targetedComplaintId) async {
    bool stateMutated = await OperationalApiService.updateComplaintStatus(
      _sessionToken,
      targetedComplaintId,
      'RESOLVED',
    );

    if (stateMutated) {
      _loadGlobalGrievances();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Grievance marked as resolved. Notification dispatched to unit.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: emeraldGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: Text(
          'Resident Grievance Console',
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
          controller: _statusTabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Active / Pending'),
            Tab(text: 'Resolved Archives'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : TabBarView(
              controller: _statusTabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildComplaintFilteredPipeline('pending'),
                _buildComplaintFilteredPipeline('resolved'),
              ],
            ),
    );
  }

  Widget _buildComplaintFilteredPipeline(String filterKey) {
    final list = _allComplaints
        .where(
          (element) =>
              (element['status']?.toString().toLowerCase() == filterKey),
        )
        .toList();

    if (list.isEmpty) {
      return Center(
        child: Text(
          'Pipeline clean for this status tier.',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.black38),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final complaint = list[index];
        bool isPending = filterKey == 'pending';
        final String complaintId =
            (complaint['complaint_id'] ?? complaint['id'] ?? index).toString();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    complaintId,
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPending
                          ? Colors.amber.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      filterKey.toUpperCase(),
                      style: GoogleFonts.lexend(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isPending ? Colors.amber.shade900 : emeraldGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.5),
              Text(
                complaint['title'] ?? 'Untitled Concern',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Logged on: ${complaint['created_at'] ?? 'N/A'}",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.black38,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                complaint['description'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              if (isPending) ...[
                const Divider(height: 20, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emeraldGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: Text(
                        'Mark Fixed',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => _updateComplaintState(complaintId),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
