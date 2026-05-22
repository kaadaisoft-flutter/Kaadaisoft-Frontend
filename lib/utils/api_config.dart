import 'package:flutter/foundation.dart';

class ApiConfig {
  // Use 127.0.0.1 for Web and Desktop
  // Use 10.0.2.2 for Android Emulator to access host localhost
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      // Laptop local IP for physical/wireless mobile debugging access
      return 'http://192.168.68.116:8000';
    }
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
  static String get updateApplicationStatus => '$baseUrl/api/update-application-status';
  static String get memberCoordinator => '$baseUrl/api/member-coordinator';
  static String get paymentMembers => '$baseUrl/api/payments/members';
  static String get filterPayments => '$baseUrl/api/payments/filter';
  static String get updateMember => '$baseUrl/api/update-member';
  static String get bulkUploadMembers => '$baseUrl/api/bulk-upload-members';
  static String get paymentSummary => '$baseUrl/api/payments/event-summary';
  static String get saveReceipt => '$baseUrl/api/payments/save-receipt';
}
