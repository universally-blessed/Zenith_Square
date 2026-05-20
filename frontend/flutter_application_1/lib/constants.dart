import 'dart:io';

class ApiConstants {
  // If running on Android Emulator, it uses 10.0.2.2 to access your laptop's localhost
  // If running on iOS or Web, it uses 127.0.0.1
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }
}
