import 'package:flutter/material.dart';
import 'package:flutter_application_1/forgot_password.dart';
import 'package:flutter_application_1/resident/book_amenitites.dart';
import 'package:flutter_application_1/resident/change_password_page.dart';
import 'package:flutter_application_1/resident/complaints.dart';
import 'package:flutter_application_1/resident/feedback.dart';
import 'package:flutter_application_1/resident/lost_found.dart';
import 'package:flutter_application_1/resident/maintenance_payment.dart';
import 'package:flutter_application_1/resident/meetings.dart';
import 'package:flutter_application_1/resident/payment_history.dart';
import 'package:flutter_application_1/resident/polls.dart';
import 'package:flutter_application_1/resident/resident_navigation_holder.dart';
import 'package:flutter_application_1/resident/society_expense_report_page.dart';
import 'package:flutter_application_1/resident/update_nominee.dart';
import 'package:flutter_application_1/resident/update_profile.dart';
import 'package:flutter_application_1/resident/vehicles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_verify.dart';
import 'landingPage.dart';
import 'registration_page.dart';
import 'login_page.dart';
import 'resident/resident_page.dart';

void main() => runApp(const ZenithSquareApp());

class ZenithSquareApp extends StatelessWidget {
  const ZenithSquareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zenith Square',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A237E),
        // Applying Lexend across the app for a modern feel
        textTheme: GoogleFonts.lexendTextTheme(),
      ),
      initialRoute: '/',
      // Add these to your routes in main.dart
      // Add to your routes in main.dart
      routes: {
        '/': (context) => const MobileLandingPage(),
        '/register': (context) => const RegistrationPage(),
        '/login': (context) => const LoginPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const ResidentNavigationHolder(),
        '/otp_verify': (context) => const OTPVerificationPage(),
        '/maintenance': (context) => const MaintenancePaymentPage(),
        '/amenities': (context) => const BookAmenitiesPage(),
        '/complaints': (context) => const FileComplaintPage(),
        '/vehicles': (context) => const MyVehiclesPage(),
        '/polls': (context) => const ActivePollsPage(),
        '/lost_found': (context) => const LostFoundPage(),
        '/expense_report': (context) => const SocietyExpenseReportPage(),
        '/feedback': (context) => const GiveFeedbackPage(),
        '/meetings': (context) => const ViewMeetingsPage(),
        '/update_profile': (context) => const UpdateProfilePage(),
        '/payment_history': (context) => const PaymentHistoryPage(),
        '/update_nominee': (context) => const UpdateNomineePage(),
        '/reset_password': (context) => ChangePasswordPage(),
      },
    );
  }
}
