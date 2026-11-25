import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
enum DialogType { success, error, warning, info }

bool isTamilLocale(BuildContext context) {
  try {
    final provider = Provider.of<LocaleProvider>(context, listen: false);
    if (provider.locale.languageCode.toLowerCase() == 'ta') return true;
  } catch (_) {}
  try {
    if (Localizations.localeOf(context).languageCode.toLowerCase() == 'ta') return true;
  } catch (_) {}
  return false;
}


class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final DialogType type;
  final VoidCallback onOk;
  final String buttonText;
  final String? actionUrl;
  final String? actionUrlLabel;

  const CustomDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = DialogType.success,
    required this.onOk,
    this.buttonText = 'OK',
    this.actionUrl,
    this.actionUrlLabel,
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
    final bool isTa = isTamilLocale(context);
    final String resolvedButtonText = (buttonText == 'OK' && isTa) ? 'சரி' : buttonText;
    final String resolvedTitle = (isTa && (title == 'Registration Rejected' || title == 'Error' && message.toLowerCase().contains('rejected'))) 
        ? 'பதிவு நிராகரிக்கப்பட்டது' 
        : title;
    final String? resolvedActionUrlLabel = (isTa && (actionUrlLabel == 'kaadaikulam.org/contact' || actionUrlLabel == null))
        ? 'தொடர்பு கொள்ள: kaadaikulam.org/contact'
        : actionUrlLabel;

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
            resolvedTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Message
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (actionUrl != null && actionUrl!.isNotEmpty) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final Uri uri = Uri.parse(actionUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF5D1712), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5D1712).withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.language_rounded, size: 16, color: Color(0xFF5D1712)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        resolvedActionUrlLabel ?? actionUrl!.replaceAll('https://', '').replaceAll('http://', ''),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D1712),
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF5D1712)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
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
              child: Text(
                resolvedButtonText,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
  String buttonText = 'OK',
  bool? autoDismiss,
  Duration duration = const Duration(seconds: 2),
  String? actionUrl,
  String? actionUrlLabel,
}) {
  final bool shouldAutoDismiss = autoDismiss ?? false;
  final bool isTa = isTamilLocale(context);

  String effectiveTitle = title;
  String effectiveMessage = message;
  String? effectiveActionUrl = actionUrl;
  String? effectiveActionUrlLabel = actionUrlLabel;

  if (isTa) {
    final lowerTitle = title.toLowerCase();
    final lowerMsg = message.toLowerCase();

    if (lowerTitle.contains('rejected') || (lowerTitle == 'error' && lowerMsg.contains('rejected'))) {
      effectiveTitle = 'பதிவு நிராகரிக்கப்பட்டது';
    } else if (lowerTitle.contains('login failed')) {
      effectiveTitle = 'உள்நுழைவு தோல்வியடைந்தது';
    } else if (lowerTitle.contains('pending')) {
      effectiveTitle = 'கணக்கு சரிபார்ப்பு நிலுவையில் உள்ளது';
    } else if (lowerTitle == 'error') {
      effectiveTitle = 'பிழை';
    } else if (lowerTitle.contains('fields required')) {
      effectiveTitle = 'விவரங்கள் தேவை';
    } else if (lowerTitle.contains('invalid number') || lowerTitle.contains('invalid input')) {
      effectiveTitle = 'தவறான எண்';
    } else if (lowerTitle.contains('invalid password')) {
      effectiveTitle = 'தவறான கடவுச்சொல்';
    } else if (lowerTitle.contains('otp sent')) {
      effectiveTitle = 'OTP அனுப்பப்பட்டது';
    } else if (lowerTitle.contains('connection error')) {
      effectiveTitle = 'இணைப்பு பிழை';
    }

    if (lowerMsg.contains('rejected') || lowerMsg.contains('membership application')) {
      String reason = '';
      if (message.contains('Reason:')) {
        final parts = message.split('Reason:');
        if (parts.length > 1) {
          reason = parts[1].split('\n')[0].trim();
        }
      }
      if (reason.toLowerCase().contains('duplicate')) {
        reason = 'ஏற்கனவே உள்ள உறுப்பினர் அல்லது நகல் விண்ணப்பம்';
      }
      effectiveMessage = 'உங்கள் உறுப்பினர் பதிவு விண்ணப்பம் நிராகரிக்கப்பட்டது.${reason.isNotEmpty ? '\nகாரணம்: $reason' : ''}\n\nதொடர்பு கொள்ள அல்லது கூடுதல் விவரங்களுக்கு இணையதளத்தைப் பார்வையிடவும்:\nhttps://kaadaikulam.org/contact';
      effectiveActionUrl ??= 'https://kaadaikulam.org/contact';
      effectiveActionUrlLabel = 'தொடர்பு கொள்ள: kaadaikulam.org/contact';
    } else if (lowerMsg.contains('pending')) {
      effectiveMessage = 'உங்கள் கணக்கு தற்போது ஒப்புதலுக்காக நிலுவையில் உள்ளது. நீங்கள் உள்நுழைவதற்கு முன் நிர்வாகி அல்லது ஒருங்கிணைப்பாளர் உங்கள் பதிவை சரிபார்த்து அங்கீகரிக்கும் வரை காத்திருக்கவும்.';
    } else if (lowerMsg.contains('mobile number or password you entered is incorrect')) {
      effectiveMessage = 'நீங்கள் உள்ளிட்ட அலைபேசி எண் அல்லது கடவுச்சொல் தவறானது.';
    } else if (lowerMsg.contains('could not connect to the server')) {
      effectiveMessage = 'சேவையகத்துடன் இணைக்க முடியவில்லை. இணைய இணைப்பை சரிபார்க்கவும்.';
    }
  }

  final String effectiveButtonText = (buttonText == 'OK' && isTa) ? 'சரி' : buttonText;

  final dialog = showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return CustomDialog(
        title: effectiveTitle,
        message: effectiveMessage,
        type: type,
        onOk: onOk ?? () {},
        buttonText: effectiveButtonText,
        actionUrl: effectiveActionUrl,
        actionUrlLabel: effectiveActionUrlLabel,
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
