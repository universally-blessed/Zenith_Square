import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart'; // 🔄 Redirected to split Operational worker layer

class EmergencyLogPage extends StatefulWidget {
  const EmergencyLogPage({super.key});

  @override
  State<EmergencyLogPage> createState() => _EmergencyLogPageState();
}

class _EmergencyLogPageState extends State<EmergencyLogPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";
  List<dynamic> _emergencyBroadcasts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveEmergencyLogs();
  }

  Future<void> _loadLiveEmergencyLogs() async {
    final data = await OperationalApiService.fetchEmergencyLogHistory(
      _sessionToken,
    );
    if (mounted) {
      setState(() {
        _emergencyBroadcasts = data;
        _isLoading = false;
      });
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
          'Emergency Dispatch Records',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadLiveEmergencyLogs,
              color: primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historical System Broadcasts',
                      style: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A complete security audit trail of panic alerts, push notifications, and broadcast messages sent out to Zenith Square compound.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _emergencyBroadcasts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 60.0),
                            child: Center(
                              child: Text(
                                'No historical broadcast logs found.',
                                style: GoogleFonts.inter(color: Colors.black38),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _emergencyBroadcasts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final log = _emergencyBroadcasts[index];
                              final bool isCritical =
                                  (log['severity'] ?? '')
                                      .toString()
                                      .toUpperCase() ==
                                  'CRITICAL';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          log['id'] ?? 'ALERT-UNK',
                                          style: GoogleFonts.lexend(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: primaryBlue,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isCritical
                                                ? Colors.red.shade50
                                                : Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            (log['severity'] ?? 'INFO')
                                                .toUpperCase(),
                                            style: GoogleFonts.lexend(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isCritical
                                                  ? Colors.red.shade800
                                                  : Colors.blue.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10.0,
                                      ),
                                      child: Divider(height: 1, thickness: 0.5),
                                    ),
                                    Text(
                                      log['title'] ?? 'Untitled Broadcast',
                                      style: GoogleFonts.lexend(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Target Audience: ${log['scope'] ?? 'General'}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sent: ${log['timestamp'] ?? 'N/A'} • Initiator: ${log['sender'] ?? 'System'}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
