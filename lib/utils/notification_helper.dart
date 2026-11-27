import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class NotificationHelper {
  static void showSuccess(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 3),
      showProgressBar: false,
      margin: const EdgeInsets.only(top: 20, right: 20),
    );
  }

  static void showError(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      showProgressBar: false,
      margin: const EdgeInsets.only(top: 20, right: 20),
    );
  }

  static void showPushNotificationBanner(
    BuildContext context, {
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      primaryColor: const Color(0xFF5D1712),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      description: Text(body, style: const TextStyle(fontSize: 13)),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 6),
      showProgressBar: true,
      callbacks: ToastificationCallbacks(
        onTap: (toastItem) {
          toastification.dismiss(toastItem);
          onTap?.call();
        },
      ),
      margin: const EdgeInsets.only(top: 20, right: 20),
    );
  }
}
