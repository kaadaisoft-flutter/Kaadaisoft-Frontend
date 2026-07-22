import 'package:flutter/foundation.dart';

class ApiConfig {
  // Use 127.0.0.1 for Web and Desktop
  // Use 10.0.2.2 for Android Emulator to access host localhost
  static String get baseUrl {
    if (kIsWeb) {
      // If we are running on a local web server, use localhost
      if (Uri.base.origin.contains('localhost') || Uri.base.origin.contains('127.0.0.1')) {
        return 'http://localhost:8000';
      }
      // Otherwise, use the live backend URL
      return 'https://kaadaisoft-backend.onrender.com';
    } else {
      // Laptop local IP for physical/wireless mobile debugging access
      return 'http://192.168.68.110:8000';
    }
  }

  // Safe getter for origin that won't crash on mobile apps
  static String get webOrigin {
    if (kIsWeb) {
      return Uri.base.origin;
    }
    return 'https://kaadaikulam.netlify.app';
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
  static String approveUpdateRequest(int id) => '$baseUrl/api/update-requests/approve/$id';
  static String rejectUpdateRequest(int id) => '$baseUrl/api/update-requests/reject/$id';
  
  static String get getPaymentRequests => '$baseUrl/api/payment-requests';
  static String approvePaymentRequest(int id) => '$baseUrl/api/payment-requests/approve/$id';
  static String rejectPaymentRequest(int id) => '$baseUrl/api/payment-requests/reject/$id';
}
