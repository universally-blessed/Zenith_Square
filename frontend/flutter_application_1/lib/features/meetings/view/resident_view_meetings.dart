import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart';

class ViewMeetingsPage extends StatefulWidget {
  const ViewMeetingsPage({super.key});

  @override
  State<ViewMeetingsPage> createState() => _ViewMeetingsPageState();
}

class _ViewMeetingsPageState extends State<ViewMeetingsPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";
  late Future<List<dynamic>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshMeetingsPool();
  }

  void _refreshMeetingsPool() {
    setState(() {
      _meetingsFuture = OperationalApiService.fetchMeetings(_sessionToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Society Meetings',
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
      body: RefreshIndicator(
        onRefresh: () async => _refreshMeetingsPool(),
        color: primaryBlue,
        child: FutureBuilder<List<dynamic>>(
          future: _meetingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryBlue),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  Center(
                    child: Text(
                      'No council assemblies or general meetings registered.',
                      style: GoogleFonts.inter(
                        color: Colors.black38,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              );
            }

            final meetingsList = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.all(20.0),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: meetingsList.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      'Scheduled Aggregations',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                  );
                }

                final meeting = meetingsList[index - 1];
                bool isUpcoming = true;

                try {
                  DateTime meetingDate = DateTime.parse(
                    meeting['meeting_date'],
                  );
                  DateTime today = DateTime.now();
                  DateTime cleanToday = DateTime(
                    today.year,
                    today.month,
                    today.day,
                  );
                  if (meetingDate.isBefore(cleanToday)) {
                    isUpcoming = false;
                  }
                } catch (_) {}

                return _buildMeetingCard(
                  title: meeting['title'] ?? 'Committee Assembly',
                  agenda: meeting['agenda'] ?? 'No explicit agenda listed.',
                  date: meeting['meeting_date'] ?? '',
                  time: meeting['start_time'] ?? '',
                  location: meeting['location'] ?? 'Clubhouse Room',
                  isUpcoming: isUpcoming,
                  minutesFilename: meeting['minutes_doc'].toString().isNotEmpty
                      ? meeting['minutes_doc']
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMeetingCard({
    required String title,
    required String agenda,
    required String date,
    required String time,
    required String location,
    required bool isUpcoming,
    String? minutesFilename,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? Colors.blue.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isUpcoming ? 'UPCOMING' : 'CONCLUDED',
                  style: GoogleFonts.lexend(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isUpcoming ? Colors.blue.shade800 : Colors.black45,
                  ),
                ),
              ),
              Text(
                date,
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
            title,
            style: GoogleFonts.lexend(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agenda: $agenda',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const Divider(height: 24, thickness: 0.6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.black38),
              const SizedBox(width: 4),
              Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.black38,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!isUpcoming && minutesFilename != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Opening: $minutesFilename',
                      style: GoogleFonts.lexend(fontSize: 12),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(
                Icons.picture_as_pdf_outlined,
                size: 16,
                color: primaryBlue,
              ),
              label: Text(
                'Download Minutes (MOM)',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
