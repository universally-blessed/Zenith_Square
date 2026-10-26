import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/communication/block_secretary_notices_screen.dart';
import 'package:frontend/features/communication/secretary_notices_screen.dart';
import 'package:frontend/features/community/society_documents_screen.dart';
import './features/core/register_screen.dart';
import './features/core/login_screen.dart';
import './features/core/home_screen.dart';
import './features/core/chairman_screen.dart';
import './features/core/secretary_screen.dart';
import 'features/core/block_secretary_screen.dart';
import './features/core/forgot_password.dart';
import './features/core/profile_screen.dart';
import './features/core/nominee_screen.dart';
import './features/core/change_password_screen.dart';
import './features/finance/finance_screen.dart';
import './features/finance/chairman_finance_screen.dart';
import './features/helpdesk/complaints_screen.dart';
import './features/helpdesk/chairman_complaints_screen.dart';
import './features/communication/notices_screen.dart';
import './features/communication/chairman_notices_screen.dart';
import './features/facilities/amenities_screen.dart';
import './features/facilities/chairman_amenities_screen.dart';
import './features/facilities/vehicles_screen.dart';
import './features/facilities/chairman_vehicles_screen.dart';
import './features/community/meetings_screen.dart';
import './features/community/chairman_meetings_screen.dart';
import './features/community/tenant_list_screen.dart';
import './features/community/polls_screen.dart';
import './features/community/chairman_polls_screen.dart';
import './features/community/lost_found_screen.dart';
import './features/community/chairman_lost_found_screen.dart';
import './features/community/block_secretary_residents_screen.dart';
import './features/community/secretary_directory_screen.dart';
import './features/community/secretary_meetings_screen.dart';
import './features/security/security_screen.dart';
import './features/security/chairman_security_screen.dart';
import './features/finance/reports_screen.dart';
import './features/finance/block_secretary_finance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenith Square',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      builder: (context, child) {
        return Container(
          color: Colors.grey.shade900,
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 840),
              child: child,
            ),
          ),
        );
      },
      initialRoute: '/login',
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/nominee': (context) => const NomineeScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/finance': (context) => const FinanceScreen(),
        '/complaints': (context) => const ComplaintsScreen(),
        '/notices': (context) => const NoticesScreen(),
        '/amenities': (context) => const AmenitiesScreen(),
        '/vehicles': (context) => const VehiclesScreen(),
        '/meetings': (context) => const MeetingsScreen(),
        '/polls': (context) => const PollsScreen(),
        '/lost-found': (context) => const LostFoundScreen(),
        '/security': (context) => const SecurityScreen(),

        '/chairman-home': (context) => const ChairmanHomeScreen(),
        '/chairman-finance': (context) => const ChairmanFinanceScreen(),
        '/chairman-complaints': (context) => const ChairmanComplaintsScreen(),
        '/chairman-notices': (context) => const ChairmanNoticesScreen(),
        '/chairman-amenities': (context) => const ChairmanAmenitiesScreen(),
        '/chairman-vehicles': (context) => const ChairmanVehiclesScreen(),
        '/chairman-meetings': (context) => const ChairmanMeetingsScreen(),
        '/chairman-polls': (context) => const ChairmanPollsScreen(),
        '/chairman-lost-found': (context) => const ChairmanLostFoundScreen(),
        '/chairman-security': (context) => const ChairmanSecurityScreen(),
        '/chairman-tenants': (context) => const TenantListScreen(),
        '/chairman-reports': (context) => const SocietyReportsScreen(),

        '/secretary-home': (context) => const SecretaryHomeScreen(),
        '/secretary-notices': (context) => const SecretaryNoticesScreen(),
        '/secretary-members': (context) => const SecretaryDirectoryScreen(),
        '/secretary-complaints': (context) => const ChairmanComplaintsScreen(),
        '/secretary-amenities': (context) => const ChairmanAmenitiesScreen(),
        '/secretary-assets': (context) => const ChairmanVehiclesScreen(),
        '/secretary-lost-found': (context) => const ChairmanLostFoundScreen(),
        '/secretary-polls': (context) => const ChairmanPollsScreen(),
        '/secretary-meetings': (context) => const SecretaryMeetingsScreen(),
        '/secretary-finance': (context) => const ChairmanFinanceScreen(),
        '/secretary-security': (context) => const SecurityScreen(),
        '/secretary-tenants': (context) => const TenantListScreen(),
        '/society-documents': (context) => const SocietyDocumentsScreen(),

        '/block-secretary-home': (context) => const BlockSecretaryHomeScreen(),
        '/block-secretary-notices': (context) =>
            const BlockSecretaryNoticesScreen(),
        '/block-secretary-residents': (context) =>
            const BlockSecretaryResidentsScreen(),
        '/block-secretary-complaints': (context) =>
            const ChairmanComplaintsScreen(),
        '/block-secretary-finance': (context) =>
            const BlockSecretaryFinanceScreen(),
        '/block-secretary-security': (context) => const SecurityScreen(),
      },
    );
  }
}
