import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Enables clean paths without the '#' hash
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/session_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Removes '/#/' from Flutter Web URLs
  usePathUrlStrategy();
  runApp(const SocietyAdminApp());
}

class SocietyAdminApp extends StatelessWidget {
  const SocietyAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Smart Society Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Segoe UI',
      ),
      // Default entry route for browser
      initialRoute: '/admin/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/admin/login':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const AuthWrapper(),
            );
          case '/admin/dashboard':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const DashboardRouteWrapper(),
            );
          default:
            // Fallback redirect to /admin/login
            return MaterialPageRoute(
              settings: const RouteSettings(name: '/admin/login'),
              builder: (_) => const AuthWrapper(),
            );
        }
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SessionManager.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data == true) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: SessionManager.getAdminProfile(),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.hasData && adminSnapshot.data != null) {
                return DashboardScreen(adminData: adminSnapshot.data!);
              }
              return const LoginScreen();
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}

class DashboardRouteWrapper extends StatelessWidget {
  const DashboardRouteWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: SessionManager.getAdminProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return DashboardScreen(adminData: snapshot.data!);
        }
        return const LoginScreen();
      },
    );
  }
}
