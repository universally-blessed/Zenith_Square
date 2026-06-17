import 'package:flutter/material.dart';
import 'core/constants/route_strings.dart';
import 'core/routes/app_router.dart';

void main() => runApp(const ZenithSquareApp());

class ZenithSquareApp extends StatelessWidget {
  const ZenithSquareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenith Square',
      debugShowCheckedModeBanner: false,

      // Tells the engine to look at our standardized string constants
      initialRoute: RouteStrings.landing,
      routes: AppRouter.getMasterRouteMap(),
    );
  }
}
