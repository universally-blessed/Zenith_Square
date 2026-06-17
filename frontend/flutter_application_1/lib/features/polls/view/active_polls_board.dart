import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart'; // 🔄 Redirected to split Operational worker layer

class ActivePollsPage extends StatefulWidget {
  const ActivePollsPage({super.key});

  @override
  State<ActivePollsPage> createState() => _ActivePollsPageState();
}

class _ActivePollsPageState extends State<ActivePollsPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  List<dynamic> _pollsList = [];
  bool _isLoading = true;
  bool _isSubmittingVote = false;

  final Map<String, String> _localSelections = {};

  @override
  void initState() {
    super.initState();
    _loadPollsPool();
  }

  Future<void> _loadPollsPool() async {
    try {
      final data = await OperationalApiService.fetchActivePolls(_sessionToken);
      if (mounted) {
        setState(() {
          _pollsList = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack("Failed to connect to consultation parameters.");
      }
    }
  }

  Future<void> _handleVoteSubmission(String pollId, String optionId) async {
    setState(() => _isSubmittingVote = true);

    bool completed = await OperationalApiService.submitVote(
      _sessionToken,
      pollId,
      optionId,
    );

    if (mounted) {
      setState(() => _isSubmittingVote = false);
      if (completed) {
        _showSnack("Ballot cast securely! Thank you for your response.");
        _loadPollsPool();
      } else {
        _showSnack("Failed to register your vote transaction.");
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
          'Society Polls',
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
          onPressed: () {
            Navigator.pop(context);
            _loadPollsPool;
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadPollsPool,
              color: primaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                children: [
                  Text(
                    'Open Consultations',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _pollsList.isEmpty
                      ? _buildEmptyStatePlaceholder()
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pollsList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final poll = _pollsList[index];
                            return _buildPollCard(poll);
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
          'No active discussion polls run at this time.',
          style: GoogleFonts.inter(color: Colors.black38, fontSize: 13.5),
        ),
      ),
    );
  }

  Widget _buildPollCard(dynamic poll) {
    final String pollId = poll['poll_id'] ?? '';
    final bool hasVoted = poll['has_voted'] ?? false;
    final List<dynamic> options = poll['options'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
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
                'POLL ID: $pollId',
                style: GoogleFonts.lexend(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              Text(
                'Ends: ${poll['end_date'] ?? 'N/A'}',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            poll['title'] ?? 'Proposal Notice',
            style: GoogleFonts.lexend(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            poll['description'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const Divider(height: 30, thickness: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final opt = options[idx];
              final String optionId = opt['option_id']?.toString() ?? '';

              if (hasVoted) {
                return _buildResultsBar(
                  opt['option_text'] ?? '',
                  opt['percentage'],
                );
              } else {
                return _buildSelectionTile(
                  pollId,
                  optionId,
                  opt['option_text'] ?? '',
                );
              }
            },
          ),
          if (!hasVoted) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed:
                    (_localSelections[pollId] == null || _isSubmittingVote)
                    ? null
                    : () => _handleVoteSubmission(
                        pollId,
                        _localSelections[pollId]!,
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmittingVote
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit My Vote',
                        style: GoogleFonts.lexend(
                          color: _localSelections[pollId] == null
                              ? Colors.black38
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionTile(String pollId, String optionId, String text) {
    bool isSelected = _localSelections[pollId] == optionId;
    return InkWell(
      onTap: () => setState(() => _localSelections[pollId] = optionId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryBlue.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryBlue
                : Colors.grey.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_off,
              color: isSelected ? primaryBlue : Colors.black38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: darkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsBar(String label, dynamic percentage) {
    double barValue = (percentage is int)
        ? percentage.toDouble()
        : (percentage ?? 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ),
            Text(
              '${barValue.toStringAsFixed(0)}%',
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: barValue / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
          ),
        ),
      ],
    );
  }
}
