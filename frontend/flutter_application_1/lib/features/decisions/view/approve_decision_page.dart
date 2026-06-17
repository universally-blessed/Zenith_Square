import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart'; // Point to your newly split service file

class ApproveDecisionsPage extends StatefulWidget {
  const ApproveDecisionsPage({super.key});

  @override
  State<ApproveDecisionsPage> createState() => _ApproveDecisionsPageState();
}

class _ApproveDecisionsPageState extends State<ApproveDecisionsPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color emeraldGreen = Color(0xFF2E7D32);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  List<dynamic> _pendingProposals = [];
  bool _pageLoading = true;
  bool isCastingAction = false;

  @override
  void initState() {
    super.initState();
    _loadLiveProposalsPipeline();
  }

  /// Pulls pending ledger reallocations down from your Django database view
  Future<void> _loadLiveProposalsPipeline() async {
    try {
      final dataset = await OperationalApiService.fetchExecutiveDecisions(
        _sessionToken,
      );
      if (mounted) {
        setState(() {
          _pendingProposals = dataset;
          _pageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pageLoading = false);
        _showSnack(
          "Could not connect to decision pipeline parameters.",
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
        backgroundColor: isError ? Colors.red.shade800 : emeraldGreen,
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
          'Executive Decision Pipeline',
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
      body: _pageLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadLiveProposalsPipeline,
              color: primaryBlue,
              child: _pendingProposals.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      physics:
                          const AlwaysScrollableScrollPhysics(), // Ensures swipe refresh triggers when list length updates
                      itemCount: _pendingProposals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final proposal = _pendingProposals[index];
                        return _buildDecisionCard(proposal, index);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      // Wrapped inside a scroll container to support smooth pull-to-refresh execution
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 140.0, left: 32, right: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: emeraldGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pipeline Fully Cleared',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'There are no pending committee proposals or role change mutations awaiting your executive sign-off.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: Colors.black38,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionCard(dynamic proposal, int index) {
    bool isCastingAction = false;
    final String requestId = (proposal['request_id'] ?? proposal['id'] ?? index)
        .toString();

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setCardState) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
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
                    'REQ: $requestId',
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
                      color: primaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      proposal['category'] ?? 'GENERAL',
                      style: GoogleFonts.lexend(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                proposal['title'] ?? 'Untitled Proposal',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                proposal['description'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Divider(height: 1, thickness: 0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetaLabel(
                    'Originator',
                    proposal['requested_by'] ?? 'Committee Node',
                  ),
                  _buildMetaLabel(
                    'Impact Metric',
                    proposal['impact_metric'] ?? 'Standard Scope',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .end, // Correct alignment formatting parameters
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: isCastingAction
                        ? null
                        : () => _submitExecutiveDecision(
                            requestId,
                            'Rejected',
                            setCardState,
                          ),
                    child: Text(
                      'Deny',
                      style: GoogleFonts.lexend(
                        color: Colors.red.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emeraldGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onPressed: isCastingAction
                        ? null
                        : () => _submitExecutiveDecision(
                            requestId,
                            'Approved',
                            setCardState,
                          ),
                    child: isCastingAction
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Grant Authorization',
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaLabel(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            color: Colors.black38,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Dispatches the chosen executive validation action back down to your server pipeline
  Future<void> _submitExecutiveDecision(
    String requestId,
    String outcome,
    StateSetter setCardState,
  ) async {
    setCardState(() => isCastingAction = true);

    bool completed = await OperationalApiService.updateDecisionApprovalStatus(
      _sessionToken,
      requestId,
      outcome,
    );

    if (mounted) {
      if (completed) {
        _showSnack("Proposal record safely processed as: $outcome.");
        _loadLiveProposalsPipeline(); // Hot-reloads list states
      } else {
        setCardState(() => isCastingAction = false);
        _showSnack(
          "Failed to submit authorization status transaction to backend.",
          isError: true,
        );
      }
    }
  }
}
