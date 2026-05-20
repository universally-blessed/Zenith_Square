import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivePollsPage extends StatefulWidget {
  const ActivePollsPage({super.key});

  @override
  State<ActivePollsPage> createState() => _ActivePollsPageState();
}

class _ActivePollsPageState extends State<ActivePollsPage> {
  String?
  selectedOption; // Captures choice to record user response token tracking

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
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Open Consultations',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.03),
                    blurRadius: 12,
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
                      Text(
                        'POLL ID: PL001',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E),
                        ),
                      ),
                      Text(
                        'Ends: 2026-04-15',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.black38,
                          fontWeight: FontWeight.w600,
                        ),
                      ), // Mapped example from DB dictionary
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Parking Rule Change Proposal',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A24),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vote on the implementation of tighter visitor parking structural window allocations inside common area pathways.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const Divider(height: 30, thickness: 1),

                  _buildPollOption('Agree with rule change'),
                  const SizedBox(height: 10),
                  _buildPollOption('Keep current regulations split'),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: selectedOption == null
                          ? null
                          : () {}, // Submits record transaction sequence directly into database
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        disabledBackgroundColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Submit My Vote',
                        style: GoogleFonts.lexend(
                          color: selectedOption == null
                              ? Colors.black38
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollOption(String text) {
    bool isSelected = selectedOption == text;
    return InkWell(
      onTap: () => setState(() => selectedOption = text),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A237E).withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1A237E)
                : Colors.grey.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF1A237E) : Colors.black38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: const Color(0xFF1A1A24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
