import 'package:flutter/material.dart';
import '../../data/datasource/community_api_service.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  late Future<List<dynamic>> _pollsFuture;
  final Map<String, String> _selectedOptionByPoll = {};
  final Set<String> _votingPollIds = {};

  @override
  void initState() {
    super.initState();
    _loadPolls();
  }

  void _loadPolls() {
    setState(() {
      _pollsFuture = CommunityApiService.fetchActivePolls();
    });
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _handleVote(String pollId) async {
    final selectedOptionId = _selectedOptionByPoll[pollId];
    if (selectedOptionId == null) {
      _showToast('Please select an option to vote', isError: true);
      return;
    }

    setState(() => _votingPollIds.add(pollId));

    try {
      final res = await CommunityApiService.castVote(
        pollId: pollId,
        optionId: selectedOptionId,
      );
      _showToast(res['message'] ?? 'Vote recorded successfully!');
      _loadPolls();
    } catch (e) {
      _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _votingPollIds.remove(pollId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Polls & Voting'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pushReplacementNamed(context, "/home"),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _pollsFuture,
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
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadPolls,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final polls = snapshot.data ?? [];
          if (polls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.how_to_vote_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No active community polls.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadPolls(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: polls.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final poll = polls[i];
                final pollId = poll['poll_id'] ?? '';
                final title = poll['poll_title'] ?? '';
                final description = poll['poll_description'] ?? '';
                final createdBy = poll['created_by_name'] ?? 'Admin';
                final endDate = poll['end_date'] ?? '';
                final isClosed = poll['status'] == 'closed';
                final hasVoted = poll['has_voted'] == true;
                final userVotedOptionId = poll['user_voted_option_id'];
                final totalVotes = (poll['total_votes'] ?? 0) as int;
                final options = (poll['options'] as List<dynamic>?) ?? [];
                final isSubmitting = _votingPollIds.contains(pollId);

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isClosed
                                    ? Colors.grey.shade200
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isClosed
                                      ? Colors.grey.shade400
                                      : Colors.orange.shade200,
                                ),
                              ),
                              child: Text(
                                isClosed ? 'CLOSED' : 'ACTIVE POLL',
                                style: TextStyle(
                                  color: isClosed
                                      ? Colors.grey.shade800
                                      : Colors.orange.shade900,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'Ends: $endDate',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Options Display (Voting / Results)
                        ...options.map((opt) {
                          final optionId = opt['option_id'];
                          final optionText = opt['option_text'] ?? '';
                          final votesCount = (opt['votes_count'] ?? 0) as int;
                          final double percentage = totalVotes > 0
                              ? (votesCount / totalVotes)
                              : 0.0;
                          final isUserChoice =
                              (hasVoted && userVotedOptionId == optionId);

                          // Result bar view (if voted or closed)
                          if (hasVoted || isClosed) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          if (isUserChoice) ...[
                                            const Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            optionText,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isUserChoice
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '$votesCount votes (${(percentage * 100).toStringAsFixed(1)}%)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: percentage,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                    backgroundColor: Colors.grey.shade200,
                                    color: isUserChoice
                                        ? Colors.green
                                        : Colors.orange.shade700,
                                  ),
                                ],
                              ),
                            );
                          }

                          // Radio button selector view (if eligible to vote)
                          return RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            value: optionId,
                            groupValue: _selectedOptionByPoll[pollId],
                            title: Text(
                              optionText,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(
                                  () => _selectedOptionByPoll[pollId] = val,
                                );
                              }
                            },
                          );
                        }),

                        const SizedBox(height: 8),

                        // Action / Info Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Votes: $totalVotes • By $createdBy',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (!hasVoted && !isClosed)
                              ElevatedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => _handleVote(pollId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Submit Vote'),
                              ),
                          ],
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
}
