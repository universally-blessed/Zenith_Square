import 'package:flutter/material.dart';
import '../constants/route_strings.dart';

// Import your universal auth files from their new feature homes
import '../../features/authentication/landingPage.dart';
import '../../features/authentication/login_page.dart';
import '../../features/authentication/registration_page.dart';
import '../../features/authentication/forgot_password.dart';
import '../../features/authentication/otp_verify.dart';
import '../../features/profile/view/change_password_page.dart';
import '../../features/profile/view/update_profile.dart';
import '../../features/profile/view/update_nominee.dart';

final Map<String, WidgetBuilder> authRoutes = {
  RouteStrings.landing: (context) => const MobileLandingPage(),
  RouteStrings.login: (context) => const LoginPage(),
  RouteStrings.registration: (context) => const RegistrationPage(),
  RouteStrings.forgotPassword: (context) => const ForgotPasswordPage(),
  RouteStrings.otpVerify: (context) => const OTPVerificationPage(),
  '/change_password': (context) => const ChangePasswordPage(),
  '/update_profile': (context) => const UpdateProfilePage(),
  '/update_nominee': (context) => const UpdateNomineePageContent(),
};
