import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart';

class CommitteeManagementPage extends StatefulWidget {
  const CommitteeManagementPage({super.key});

  @override
  State<CommitteeManagementPage> createState() =>
      _CommitteeManagementPageState();
}

class _CommitteeManagementPageState extends State<CommitteeManagementPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color emeraldGreen = Color(0xFF2E7D32);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";
  bool _isLoading = true;

  // Live data storage
  List<dynamic> _committeeMembers = [];
  List<dynamic> _clearanceRequests = [];

  @override
  void initState() {
    super.initState();
    _loadCommitteeData();
  }

  Future<void> _loadCommitteeData() async {
    try {
      // Fetching live data from your decoupled operational service
      final data = await OperationalApiService.fetchCommitteeData(
        _sessionToken,
      );
      if (mounted) {
        setState(() {
          _committeeMembers = data['members'] ?? [];
          _clearanceRequests = data['requests'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Processes clearance using the ID directly from the request object
  Future<void> _processClearanceDecision(
    Map<String, dynamic> request,
    bool approved,
  ) async {
    final String requestId = request['id'].toString();

    setState(() => _isLoading = true);

    bool success = await OperationalApiService.updateDecisionApprovalStatus(
      _sessionToken,
      requestId,
      approved ? 'Approved' : 'Rejected',
    );

    if (mounted) {
      if (success) {
        _showSnack(approved ? "Clearance approved." : "Clearance rejected.");
        _loadCommitteeData(); // Refresh list
      } else {
        setState(() => _isLoading = false);
        _showSnack("Error communicating with security pipeline.");
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
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(
          'Committee Board',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadCommitteeData,
              color: primaryBlue,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Text(
                    'Active Executive Panel',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _committeeMembers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildMemberTile(_committeeMembers[index]),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Dual-Authorization Clearance Pipeline',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _clearanceRequests.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'No pending requests.',
                              style: GoogleFonts.inter(color: Colors.black38),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _clearanceRequests.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) =>
                              _buildClearanceCard(_clearanceRequests[index]),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildMemberTile(dynamic member) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryBlue.withValues(alpha: 0.06),
            child: const Icon(Icons.person_outline_rounded, color: primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] ?? '',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                Text(
                  '${member['wing']} • ID: ${member['id']}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              member['role']?.toString().toUpperCase() ?? '',
              style: GoogleFonts.lexend(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearanceCard(Map<String, dynamic> request) {
    final bool needsAction = request['status'] == 'awaiting_chairman_approval';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: needsAction
              ? Colors.amber.shade300
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request['request_id'] ?? '',
            style: GoogleFonts.lexend(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const Divider(height: 20, thickness: 0.5),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 13.5, color: darkText),
              children: [
                const TextSpan(text: 'Reassign '),
                TextSpan(
                  text: request['target_name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' to '),
                TextSpan(
                  text: request['proposed_role'].toString().toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (needsAction)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _processClearanceDecision(request, false),
                  child: Text(
                    'Reject',
                    style: GoogleFonts.lexend(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _processClearanceDecision(request, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldGreen,
                  ),
                  child: Text(
                    'Approve',
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
