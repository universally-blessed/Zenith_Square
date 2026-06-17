import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/networks/operational_api_service.dart'; // 🔄 Refactored to operational context layer

class ManageProfilePage extends StatefulWidget {
  const ManageProfilePage({super.key});

  @override
  State<ManageProfilePage> createState() => _ManageProfilePageState();
}

class _ManageProfilePageState extends State<ManageProfilePage> {
  static const Color primaryBlue = Color(0xFF1A237E);
  static const Color accentBlue = Color(0xFF29B6F6);
  static const Color darkText = Color(0xFF1A1A24);
  static const Color lightBg = Color(0xFFF8F9FA);

  final String _sessionToken = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b";

  Map<String, dynamic> _profileData = {
    'name': 'Chairman Administrator',
    'role': 'Elected Executive Head',
    'phone': '9876543210',
    'email': 'chairman@zenithsquare.com',
    'wings': 'All Wings (A - F)',
    'office': 'Management Suite Block C',
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveProfile();
  }

  /// Extracts real dynamic session rows down from your operational data service
  Future<void> _fetchLiveProfile() async {
    final response = await OperationalApiService.fetchDashboardMeta(
      _sessionToken,
    );
    if (mounted) {
      setState(() {
        if (response['success'] == true && response['data'] != null) {
          final data = response['data'];
          _profileData = {
            'name': data['user_name'] ?? _profileData['name'],
            'role': data['user_role'] ?? _profileData['role'],
            'phone': data['user_phone'] ?? _profileData['phone'],
            'email': data['user_email'] ?? _profileData['email'],
            'wings': data['assigned_wings'] ?? _profileData['wings'],
            'office': data['physical_office'] ?? _profileData['office'],
          };
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.pushNamed(
      context,
      '/update_profile',
      arguments: {
        'phone': _profileData['phone'],
        'email': _profileData['email'],
      },
    );

    if (result == true) {
      setState(() => _isLoading = true);
      _fetchLiveProfile();
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
          'My Executive Profile',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.15,
                              ),
                              child: const CircleAvatar(
                                radius: 42,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.shield_moon_rounded,
                                  size: 40,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: accentBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _profileData['name']!,
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _profileData['role']!.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentBlue,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administrative Account Credentials',
                          style: GoogleFonts.lexend(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildProfilePropertyTile(
                          label: 'Registered Phone Number',
                          value: '+91 ${_profileData['phone']}',
                          icon: Icons.phone_android_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildProfilePropertyTile(
                          label: 'Email Dispatch Destination',
                          value: _profileData['email']!,
                          icon: Icons.mail_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildProfilePropertyTile(
                          label: 'Jurisdiction Control Scope',
                          value: _profileData['wings']!,
                          icon: Icons.domain_disabled_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildProfilePropertyTile(
                          label: 'Physical Desk Headquarters',
                          value: _profileData['office']!,
                          icon: Icons.gite_outlined,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(height: 1, thickness: 0.6),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.08),
                            ),
                          ),
                          child: ListTile(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/change_password',
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.lock_reset_rounded,
                                color: Colors.red.shade800,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Change Security Password',
                              style: GoogleFonts.lexend(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                            subtitle: Text(
                              'Update login access keys regularly',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: Colors.black38,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _navigateToEditProfile,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            icon: const Icon(
                              Icons.build_circle_outlined,
                              size: 18,
                              color: primaryBlue,
                            ),
                            label: Text(
                              'Modify Contact Credentials',
                              style: GoogleFonts.lexend(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
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

  Widget _buildProfilePropertyTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.black38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.lexend(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
