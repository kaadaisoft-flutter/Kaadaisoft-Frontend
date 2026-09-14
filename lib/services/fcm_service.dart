import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_config.dart';

class FcmService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request permission for iOS/Web (Android 13+ requires permission too)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted permission for notifications');
      
      // Set presentation options for foreground notifications
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _setupToken();

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _sendTokenToServer(newToken);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
        }
      });
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  static Future<void> _setupToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint("FCM Device Token: $token");
        await _sendTokenToServer(token);
      }
    } catch (e) {
      debugPrint("Error fetching FCM token: $e");
    }
  }

  static Future<void> updateTokenForUser([dynamic explicitUserId]) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _sendTokenToServer(token, explicitUserId: explicitUserId);
      }
    } catch (e) {
      debugPrint("Error in updateTokenForUser: $e");
    }
  }

  static Future<void> _sendTokenToServer(String token, {dynamic explicitUserId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = explicitUserId ?? prefs.getInt('userId') ?? prefs.get('userId');
      if (userId == null) {
        debugPrint("FCM token update skipped: user_id is null");
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/update-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': token,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("Successfully updated FCM token on server for user $userId.");
      } else {
        debugPrint("Failed to update FCM token on server: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error sending FCM token to server: $e");
    }
  }
}

// Background handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
