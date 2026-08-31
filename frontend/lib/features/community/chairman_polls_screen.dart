import 'package:flutter/material.dart';
import '../../data/datasource/community_api_service.dart';

class ChairmanPollsScreen extends StatefulWidget {
  const ChairmanPollsScreen({super.key});

  @override
  State<ChairmanPollsScreen> createState() => _ChairmanPollsScreenState();
}

class _ChairmanPollsScreenState extends State<ChairmanPollsScreen> {
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

  Future<void> _handleDeletePoll(String pollId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Poll'),
        content: Text(
          'Are you sure you want to permanently delete "$title"? This will remove all options and cast votes.',
        ),
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

    if (confirmed != true) return;

    try {
      final res = await CommunityApiService.deletePoll(pollId);
      _showToast(res['message'] ?? 'Poll deleted successfully!');
      _loadPolls();
    } catch (e) {
      _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
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

  void _openCreatePollSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
    DateTime selectedEndDate = DateTime.now().add(const Duration(days: 7));
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                        'Create Society Poll',
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Poll Question / Title',
                      hintText: 'e.g. Should we install EV charging stations?',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter question'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description / Context (Optional)',
                      hintText:
                          'Provide background details or estimated costs...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_month,
                      color: Colors.orange,
                    ),
                    title: const Text(
                      'Poll Expiry Date',
                      style: TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      '${selectedEndDate.year}-${selectedEndDate.month.toString().padLeft(2, '0')}-${selectedEndDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedEndDate,
                          firstDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        );
                        if (picked != null) {
                          setModalState(() => selectedEndDate = picked);
                        }
                      },
                      child: const Text('Change Date'),
                    ),
                  ),
                  const Divider(height: 16),
                  const Text(
                    'Poll Options (2 to 6)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(optionControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: optionControllers[index],
                              decoration: InputDecoration(
                                labelText: 'Option ${index + 1}',
                                hintText: index == 0
                                    ? 'Yes / Approve'
                                    : 'No / Reject',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter option text'
                                  : null,
                            ),
                          ),
                          if (optionControllers.length > 2) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setModalState(() {
                                  optionControllers.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  if (optionControllers.length < 6)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            optionControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Option'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              final optionsList = optionControllers
                                  .map((c) => c.text.trim())
                                  .where((t) => t.isNotEmpty)
                                  .toList();

                              final dateStr =
                                  '${selectedEndDate.year}-${selectedEndDate.month.toString().padLeft(2, '0')}-${selectedEndDate.day.toString().padLeft(2, '0')}';

                              final res = await CommunityApiService.createPoll(
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                endDate: dateStr,
                                options: optionsList,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                _showToast(
                                  res['message'] ??
                                      'Poll published successfully!',
                                );
                                _loadPolls();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              _showToast(
                                e.toString().replaceAll('Exception: ', ''),
                                isError: true,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
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
                            'Publish Poll',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polls & Voting'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/chairman-home'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePollSheet,
        backgroundColor: Colors.orange.shade700,
        icon: const Icon(Icons.how_to_vote, color: Colors.white),
        label: const Text('Create Poll', style: TextStyle(color: Colors.white)),
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
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Create Poll" to initiate a community vote.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
                final createdBy = poll['created_by_name'] ?? 'Chairman';
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
                            Row(
                              children: [
                                Text(
                                  'Ends: $endDate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Delete Poll',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () =>
                                      _handleDeletePoll(pollId, title),
                                ),
                              ],
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

                        // Options Display
                        ...options.map((opt) {
                          final optionId = opt['option_id'];
                          final optionText = opt['option_text'] ?? '';
                          final votesCount = (opt['votes_count'] ?? 0) as int;
                          final double percentage = totalVotes > 0
                              ? (votesCount / totalVotes)
                              : 0.0;
                          final isUserChoice =
                              (hasVoted && userVotedOptionId == optionId);

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
