import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart'; // 🔄 Pointed to decoupled operational architecture layer

class NomineeDetailsPage extends StatefulWidget {
  const NomineeDetailsPage({super.key});

  @override
  State<NomineeDetailsPage> createState() => _NomineeDetailsPageState();
}

class _NomineeDetailsPageState extends State<NomineeDetailsPage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);

  Map<String, dynamic>? _nomineeData;
  bool _pageLoading = true;
  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  @override
  void initState() {
    super.initState();
    _loadNomineeRecord();
  }

  /// Pulls registered entity data records straight from backend database maps
  Future<void> _loadNomineeRecord() async {
    try {
      final response = await OperationalApiService.fetchNomineeDetails(
        _sessionToken,
      );
      if (mounted) {
        setState(() {
          if (response['no_nominee'] == true) {
            _nomineeData = null;
          } else {
            _nomineeData = response;
          }
          _pageLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _pageLoading = false);
    }
  }

  Future<void> _navigateToEditNominee() async {
    final result = await Navigator.pushNamed(context, '/update_nominee');
    if (result == true) {
      setState(() => _pageLoading = true);
      _loadNomineeRecord();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: Text(
          'Nominee Details',
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
      body: _pageLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadNomineeRecord,
              color: primaryBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Primary Association',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _navigateToEditNominee,
                        icon: const Icon(
                          Icons.mode_edit_outline_outlined,
                          size: 18,
                          color: primaryBlue,
                        ),
                        label: Text(
                          _nomineeData == null ? 'Add Details' : 'Modify',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _nomineeData == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60.0),
                            child: Text(
                              'No nominee logs registered to your account unit.',
                              style: GoogleFonts.inter(
                                color: Colors.black38,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      : _buildNomineeCard(context),
                ],
              ),
            ),
    );
  }

  Widget _buildNomineeCard(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      color: primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nomineeData!['nominee_name'] ?? '',
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Relationship: ${_nomineeData!['relation'] ?? ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.black12,
                ),
              ),
              _buildPropertyItem(
                icon: Icons.phone_android_outlined,
                label: 'Emergency Mobile Contact',
                value: '+91 ${_nomineeData!['phone'] ?? ''}',
              ),
              const SizedBox(height: 16),
              _buildPropertyItem(
                icon: Icons.home_work_outlined,
                label: 'Permanent Residential Address',
                value: _nomineeData!['address'] ?? '',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryBlue.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: darkText,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
