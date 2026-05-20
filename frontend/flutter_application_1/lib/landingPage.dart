import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MobileLandingPage extends StatelessWidget {
  const MobileLandingPage({super.key});

  static const Color primaryBlue = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // TOP SECTION: Branding
          Container(
            height: screenHeight * 0.45,
            width: double.infinity,
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.domain_rounded, size: 80, color: primaryBlue),
                const SizedBox(height: 16),
                Text(
                  'Zenith Square',
                  style: GoogleFonts.lexend(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'SMART SOCIETY SOLUTIONS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: primaryBlue.withOpacity(0.6),
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM SECTION: Welcome & Actions
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome',
                    style: GoogleFonts.lexend(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your all-in-one digital platform designed to foster a better residential community through seamless management and transparent communication.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.6,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: 'Register',
                          isPrimary: false,
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _actionButton(
                          label: 'Login',
                          isPrimary: true,
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : Colors.transparent,
          foregroundColor: isPrimary ? primaryBlue : Colors.white,
          elevation: 0,
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: Colors.white, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
