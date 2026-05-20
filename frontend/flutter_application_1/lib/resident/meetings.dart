import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewMeetingsPage extends StatelessWidget {
  const ViewMeetingsPage({super.key});

  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);

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
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            'Scheduled Aggregations',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 14),

          // Data matches your meeting SQL scheme structure properties
          _buildMeetingCard(
            title: 'Annual General Body Meeting (AGM)',
            agenda:
                'Discussion on major block re-painting project budgets, CCTV scaling setup parameters, and validation of new security vendors.',
            date: '2026-06-05',
            time: '10:00 AM',
            location: 'Main Community Clubhouse Hall',
            isUpcoming: true,
          ),
          const SizedBox(height: 16),
          _buildMeetingCard(
            title: 'Emergency Drainage Sync Call',
            agenda:
                'Reviewing basement shaft layout pipeline blocks and technical repair vendor estimates confirmation.',
            date: '2026-05-10',
            time: '08:30 PM',
            location: 'Block A Parking Lobby Axis',
            isUpcoming: false,
            minutesFilename:
                'MOM_Drainage_Fix_Signed.pdf', // Simulates minutes_doc field
          ),
        ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUpcoming ? Colors.blue.shade800 : Colors.black45,
                  ),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 12,
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Agenda: $agenda',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.black54,
              height: 1.45,
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
              onPressed:
                  () {}, // Simulated hook to fetch your minutes_doc PDF target
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
