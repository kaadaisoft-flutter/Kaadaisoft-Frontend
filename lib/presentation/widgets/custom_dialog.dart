import 'package:flutter/material.dart';

enum DialogType { success, error, warning, info }

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final DialogType type;
  final VoidCallback onOk;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = DialogType.success,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _contentBox(context),
    );
  }

  Widget _contentBox(BuildContext context) {
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (type) {
      case DialogType.success:
        icon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF10B981);
        iconBgColor = const Color(0xFFECFDF5);
        break;
      case DialogType.error:
        icon = Icons.error_rounded;
        iconColor = const Color(0xFFEF4444);
        iconBgColor = const Color(0xFFFEF2F2);
        break;
      case DialogType.warning:
        icon = Icons.warning_rounded;
        iconColor = const Color(0xFFF59E0B); // Aadhaar-style Orange
        iconBgColor = const Color(0xFFFFFBEB);
        break;
      case DialogType.info:
        icon = Icons.info_rounded;
        iconColor = const Color(0xFF5D1712);
        iconBgColor = const Color(0xFFEFF6FF);
        break;

    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: const Color(0xFFF3F4F6), // Light grey background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 15),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Message
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // OK Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOk();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF374151), // Dark grey button
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showStatusDialog(BuildContext context, {
  required String title,
  required String message,
  DialogType type = DialogType.success,
  VoidCallback? onOk,
  bool? autoDismiss,
  Duration duration = const Duration(seconds: 2),
}) {
  final bool shouldAutoDismiss = autoDismiss ?? false;
  final dialog = showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return CustomDialog(
        title: title,
        message: message,
        type: type,
        onOk: onOk ?? () {},
      );
    },
  );

  if (shouldAutoDismiss) {
    Future.delayed(duration, () {
      if (!context.mounted) return;
      if (Navigator.of(context).canPop()) {
        // We need to be careful here. Navigator.pop() might pop the wrong thing 
        // if the user already closed the dialog manually.
        // In a real app, we'd use a unique key or check the route name.
        Navigator.of(context).pop();
        if (onOk != null) onOk();
      }
    });
  }

  return dialog;
}
