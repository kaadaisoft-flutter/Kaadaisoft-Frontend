import 'package:flutter/foundation.dart';

class ApiConfig {
  // Use 127.0.0.1 for Web and Desktop
  // Use 10.0.2.2 for Android Emulator to access host localhost
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    // For mobile emulators (Android), we need to use 10.0.2.2
    // If you are using a physical device, replace this with your computer's IP address
    return 'http://127.0.0.1:8000'; 
  }

  // Common endpoints
  static String get login => '$baseUrl/api/login';
  static String get register => '$baseUrl/api/register';
  static String get checkExistence => '$baseUrl/api/check-existence';
  static String get members => '$baseUrl/api/members';
  static String get dashboardStats => '$baseUrl/api/dashboard-stats';
  static String get pendingPayments => '$baseUrl/api/pending-payments';
  static String get eventYears => '$baseUrl/api/events/years';
  static String get eventsByYear => '$baseUrl/api/events/by-year';
  static String get memberCoordinator => '$baseUrl/api/member-coordinator';
  static String get paymentMembers => '$baseUrl/api/payments/members';
  static String get filterPayments => '$baseUrl/api/payments/filter';
  static String get updateMember => '$baseUrl/api/update-member';
}
