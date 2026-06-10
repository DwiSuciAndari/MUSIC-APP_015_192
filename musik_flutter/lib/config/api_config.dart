import 'dart:io';

class ApiConfig {
  static const String _physical = "192.168.100.17:3000";

  static const String _emulatorAndroid = "http://10.0.2.2:3000";

  static const String _ios = "http://localhost:3000";

  static String get baseUrl {
    if (Platform.isAndroid) {
      return _physical;
    }
    return _ios;
  }
}
