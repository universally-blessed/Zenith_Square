import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/routes/chairman_routes.dart';
import 'package:flutter_application_1/core/routes/resident_routes.dart';
import 'auth_routes.dart';
// Note: We will import resident_routes and chairman_routes here as we build them out!

class AppRouter {
  static Map<String, WidgetBuilder> getMasterRouteMap() {
    return {...authRoutes, ...ResidentRoutes.routes, ...ChairmanRoutes.routes};
  }
}
