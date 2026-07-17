import 'dart:io';
import 'dart:convert';

// ==========================================
// Source: add_image_strings.dart
// ==========================================
void add_image_strings_main() {
  final enFile = File('lib/l10n/app_en.arb');
  final taFile = File('lib/l10n/app_ta.arb');
  
  final Map<String, dynamic> enData = jsonDecode(enFile.readAsStringSync());
  final Map<String, dynamic> taData = jsonDecode(taFile.readAsStringSync());
  
  final newEntries = {
    'uploadReceiptLabel': {'en': 'Upload Receipt (Optional)', 'ta': 'ரசீதை பதிவேற்றவும் (விருப்பத்தேர்வு)'},
    'changeImageBtn': {'en': 'Change Image', 'ta': 'படத்தை மாற்று'},
    'removeImageBtn': {'en': 'Remove Image', 'ta': 'படத்தை அகற்று'},
    'noImageSelectedLabel': {'en': 'No image selected', 'ta': 'படம் தேர்ந்தெடுக்கப்படவில்லை'},
    'tapToUploadLabel': {'en': 'Tap to upload receipt', 'ta': 'ரசீதை பதிவேற்ற தட்டவும்'},
  };
  
  newEntries.forEach((key, val) {
    if (!enData.containsKey(key)) {
      enData[key] = val['en'];
    }
    if (!taData.containsKey(key)) {
      taData[key] = val['ta'];
    }
  });
  
  var encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enData));
  taFile.writeAsStringSync(encoder.convert(taData));
  print('ARB files updated successfully');
}


// ==========================================
// Source: find_events_key.dart
// ==========================================
void find_events_key_main() {
  final file = File('lib/l10n/app_ta.arb');
  final Map<String, dynamic> data = jsonDecode(file.readAsStringSync());
  data.forEach((k, v) {
    if (v.toString().contains('நிகழ்வுகள்') || v.toString().contains('நிகழ்வு')) {
      print('Key: $k -> $v');
    }
  });
}


// ==========================================
// Source: find_key.dart
// ==========================================
void find_key_main() {
  final file = File('lib/l10n/app_ta.arb');
  final Map<String, dynamic> data = jsonDecode(file.readAsStringSync());
  data.forEach((k, v) {
    if (v.toString() == 'முகப்பு') {
      print('Key: $k -> $v');
    }
  });
}


// ==========================================
// Source: find_password_keys.dart
// ==========================================
void find_password_keys_main() {
  final file = File('lib/l10n/app_ta.arb');
  final Map<String, dynamic> data = jsonDecode(file.readAsStringSync());
  
  data.forEach((k, v) {
    if (v.toString().contains('கடவுச்சொல்')) {
      print('Key: $k -> $v');
    }
  });
}


// ==========================================
// Source: fix_const.dart
// ==========================================
void fix_const_main() {
  final file = File('lib/presentation/widgets/payment_form.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll("const Center(\n                            child: Text(AppLocalizations", "Center(\n                            child: Text(AppLocalizations");
  
  file.writeAsStringSync(content);
  print('Fixed const errors in payment_form.dart');
}


// ==========================================
// Source: update_admin_dashboard.dart
// ==========================================
void update_admin_dashboard_main() {
  final file = File('lib/presentation/pages/admin_dashboard.dart');
  String content = file.readAsStringSync();
  
  final oldString = '''      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'change_password',
          child: Row(
            children: [
              Icon(Icons.key, size: 18, color: const Color(0xFF5D1712)),
              SizedBox(width: 12),
              Text('Change Password', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.power_settings_new, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text('Logout', style: TextStyle(fontSize: 14, color: Colors.red)),
            ],
          ),
        ),
      ],''';
      
  final newString = '''      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'change_password',
          child: Row(
            children: [
              const Icon(Icons.key, size: 18, color: Color(0xFF5D1712)),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)?.changePassword ?? 'Change Password', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.power_settings_new, size: 18, color: Colors.red),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)?.logout ?? 'Logout', style: const TextStyle(fontSize: 14, color: Colors.red)),
            ],
          ),
        ),
      ],''';

  if (content.contains(oldString)) {
    content = content.replaceFirst(oldString, newString);
    file.writeAsStringSync(content);
    print('admin_dashboard.dart updated successfully');
  } else {
    print('Old string not found in admin_dashboard.dart');
  }
}


// ==========================================
// Source: update_arb.dart
// ==========================================
void update_arb_main() {
  var file = File('lib/l10n/app_ta.arb');
  var data = jsonDecode(file.readAsStringSync());
  data['reports'] = 'தகவல்கள்';
  data['reportStatusFilter'] = 'தகவல்கள் நிலை வடிகட்டி:';
  
  var encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(data));
  print('Done');
}


// ==========================================
// Source: update_arb_add_event.dart
// ==========================================
void update_arb_add_event_main() {
  final enFile = File('lib/l10n/app_en.arb');
  final taFile = File('lib/l10n/app_ta.arb');
  
  final Map<String, dynamic> enData = jsonDecode(enFile.readAsStringSync());
  final Map<String, dynamic> taData = jsonDecode(taFile.readAsStringSync());
  
  if (!enData.containsKey('addNewEvent')) {
    enData['addNewEvent'] = 'Add New Event';
  }
  if (!taData.containsKey('addNewEvent')) {
    taData['addNewEvent'] = 'புதிய விசேஷம் சேர்';
  }
  
  var encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enData));
  taFile.writeAsStringSync(encoder.convert(taData));
  print('ARB files updated successfully for Add New Event');
}


// ==========================================
// Source: update_arb_add_event_popup.dart
// ==========================================
void update_arb_add_event_popup_main() {
  final enFile = File('lib/l10n/app_en.arb');
  final taFile = File('lib/l10n/app_ta.arb');
  
  final Map<String, dynamic> enData = jsonDecode(enFile.readAsStringSync());
  final Map<String, dynamic> taData = jsonDecode(taFile.readAsStringSync());
  
  enData['addEventNameUpper'] = 'EVENT NAME';
  taData['addEventNameUpper'] = 'விசேஷத்தின் பெயர்';

  enData['addEventEgName'] = 'e.g. Event_2026';
  taData['addEventEgName'] = 'உ.ம்: Visesham_2026';

  enData['addEventNoteName'] = 'Note: Year should be at the end of the event name (e.g. Event_2026).';
  taData['addEventNoteName'] = 'குறிப்பு: விசேஷத்தின் பெயரின் முடிவில் ஆண்டு இருக்க வேண்டும் (உ.ம்: Visesham_2026).';

  enData['addEventBannerUpper'] = 'EVENT BANNER';
  taData['addEventBannerUpper'] = 'விசேஷம் பேனர்';

  enData['addEventChooseFile'] = 'Choose File';
  taData['addEventChooseFile'] = 'கோப்பைத் தேர்ந்தெடு';

  enData['addEventNoFileChosen'] = 'No file chosen';
  taData['addEventNoFileChosen'] = 'கோப்பு தேர்ந்தெடுக்கப்படவில்லை';

  enData['addEventNoteBanner'] = 'Note: Max file size 2MB (JPG, PNG).';
  taData['addEventNoteBanner'] = 'குறிப்பு: அதிகபட்ச கோப்பு அளவு 2MB (JPG, PNG).';

  enData['addEventDurationUpper'] = 'DURATION';
  taData['addEventDurationUpper'] = 'கால அளவு';

  enData['addEventFrom'] = 'From';
  taData['addEventFrom'] = 'முதல்';

  enData['addEventTo'] = 'To';
  taData['addEventTo'] = 'வரை';

  enData['addEventTaxAmountUpper'] = 'TAX AMOUNT (₹)';
  taData['addEventTaxAmountUpper'] = 'வரித் தொகை (₹)';

  enData['addEventCreateBtn'] = 'Create Event';
  taData['addEventCreateBtn'] = 'விசேஷத்தை உருவாக்கு';

  var encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enData));
  taFile.writeAsStringSync(encoder.convert(taData));
  print('ARB files updated successfully for Add Event Popup');
}


// ==========================================
// Source: update_arb_event_details.dart
// ==========================================
void update_arb_event_details_main() {
  final enFile = File('lib/l10n/app_en.arb');
  final taFile = File('lib/l10n/app_ta.arb');
  
  final Map<String, dynamic> enData = jsonDecode(enFile.readAsStringSync());
  final Map<String, dynamic> taData = jsonDecode(taFile.readAsStringSync());
  
  enData['eventDetails'] = 'Event Details';
  taData['eventDetails'] = 'விசேஷத்தின் விவரங்கள்';

  enData['saveChanges'] = 'Save Changes';
  taData['saveChanges'] = 'மாற்றங்களைச் சேமி';

  var encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enData));
  taFile.writeAsStringSync(encoder.convert(taData));
  print('ARB files updated successfully for Event Details');
}


// ==========================================
// Source: update_arb_password.dart
// ==========================================
void update_arb_password_main() {
  final enFile = File('lib/l10n/app_en.arb');
  final taFile = File('lib/l10n/app_ta.arb');
  
  final Map<String, dynamic> enData = jsonDecode(enFile.readAsStringSync());
  final Map<String, dynamic> taData = jsonDecode(taFile.readAsStringSync());
  
  if (!enData.containsKey('changePassword')) {
    enData['changePassword'] = 'Change Password';
  }
  if (!taData.containsKey('changePassword')) {
    taData['changePassword'] = 'கடவுச்சொல்லை மாற்று';
  }
  
  var encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enData));
  taFile.writeAsStringSync(encoder.convert(taData));
  print('ARB files updated successfully for change password');
}


// ==========================================
// Source: update_arb_payment.dart
// ==========================================
void update_arb_payment_main() {
  final enFile = File('lib/l10n/app_en.arb');
  final taFile = File('lib/l10n/app_ta.arb');
  
  final Map<String, dynamic> enData = jsonDecode(enFile.readAsStringSync());
  final Map<String, dynamic> taData = jsonDecode(taFile.readAsStringSync());
  
  final newEntries = {
    'myPaymentDetails': {'en': 'My Payment Details', 'ta': 'எனது கட்டண விவரங்கள்'},
    'myInfo': {'en': 'My Info', 'ta': 'எனது தகவல்'},
    'nameLabelShort': {'en': 'Name:', 'ta': 'பெயர்:'},
    'idLabelShort': {'en': 'ID:', 'ta': 'ஐடி:'},
    'addressLabelShort': {'en': 'Address:', 'ta': 'முகவரி:'},
    'eventInfo': {'en': 'Event Info', 'ta': 'நிகழ்வு தகவல்'},
    'payAmountLabel': {'en': 'Pay Amount *', 'ta': 'செலுத்தும் தொகை *'},
    'dateLabel': {'en': 'Date: ', 'ta': 'தேதி: '},
    'rsSummary': {'en': 'Rs Summary', 'ta': 'தொகை சுருக்கம்'},
    'totalAmountLabel': {'en': 'Total Amount', 'ta': 'மொத்த தொகை'},
    'alreadyPaidLabel': {'en': 'Already Paid', 'ta': 'ஏற்கனவே செலுத்தியது'},
    'paymentMethodLabel': {'en': 'Payment Method', 'ta': 'கட்டண முறை'},
    'bankMethod': {'en': 'Bank', 'ta': 'வங்கி'},
    'chequeMethod': {'en': 'Cheque', 'ta': 'காசோலை'},
    'upiMethod': {'en': 'UPI', 'ta': 'UPI'},
    'cashMethod': {'en': 'Cash', 'ta': 'பணம்'},
    'chooseBankLabel': {'en': 'Choose Bank *', 'ta': 'வங்கியைக் தேர்ந்தெடுக்கவும் *'},
    'otherBankNameLabel': {'en': 'Other Bank Name *', 'ta': 'மற்ற வங்கி பெயர் *'},
    'upiTransactionIdLabel': {'en': 'UPI Transaction ID *', 'ta': 'UPI பரிவர்த்தனை ஐடி *'},
    'referenceIdLabel': {'en': 'Reference ID *', 'ta': 'குறிப்பு ஐடி *'},
    'chequeNumberLabel': {'en': 'Cheque Number *', 'ta': 'காசோலை எண் *'},
    'saveReceiptBtn': {'en': 'Save Receipt', 'ta': 'ரசீதை சேமி'},
    'savingBtn': {'en': 'Saving...', 'ta': 'சேமிக்கிறது...'},
    'confirmationRequiredTitle': {'en': 'Confirmation Required', 'ta': 'உறுதிப்படுத்தல் தேவை'},
    'confirmDetailsBeforeSaving': {'en': 'Please confirm the details before saving.', 'ta': 'சேமிப்பதற்கு முன் விவரங்களை உறுதிப்படுத்தவும்.'},
    'successTitle': {'en': 'Success', 'ta': 'வெற்றி'},
    'receiptSavedSuccess': {'en': 'Payment receipt saved successfully.', 'ta': 'கட்டண ரசீது வெற்றிகரமாக சேமிக்கப்பட்டது.'},
    'errorTitle': {'en': 'Error', 'ta': 'பிழை'},
    'unableToSaveReceipt': {'en': 'Unable to save receipt.', 'ta': 'ரசீதை சேமிக்க முடியவில்லை.'},
    'invalidAmount': {'en': 'Invalid Amount', 'ta': 'தவறான தொகை'},
    'chooseBankTitle': {'en': 'Choose bank', 'ta': 'வங்கியைக் தேர்ந்தெடுக்கவும்'},
    'searchBankHint': {'en': 'Search bank...', 'ta': 'வங்கியைக் தேடு...'},
    'noBanksFound': {'en': 'No banks found', 'ta': 'வங்கிகள் எதுவும் இல்லை'},
    'requiredValidation': {'en': 'Required', 'ta': 'கட்டாயம் தேவை'},
    'greaterThanZeroValidation': {'en': 'Must be greater than 0', 'ta': '0 ஐ விட அதிகமாக இருக்க வேண்டும்'},
    'exceedBalanceValidation': {'en': 'Cannot exceed balance', 'ta': 'மீதத் தொகையை விட அதிகமாக இருக்க முடியாது'},
  };
  
  newEntries.forEach((key, val) {
    if (!enData.containsKey(key)) {
      enData[key] = val['en'];
    }
    if (!taData.containsKey(key)) {
      taData[key] = val['ta'];
    }
  });
  
  var encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enData));
  taFile.writeAsStringSync(encoder.convert(taData));
  print('ARB files updated successfully');
}


// ==========================================
// Source: update_arb_receiver.dart
// ==========================================
void update_arb_receiver_main() {
  final enFile = File('lib/l10n/app_en.arb');
  final taFile = File('lib/l10n/app_ta.arb');
  
  final Map<String, dynamic> enData = jsonDecode(enFile.readAsStringSync());
  final Map<String, dynamic> taData = jsonDecode(taFile.readAsStringSync());
  
  final newEntries = {
    'receiverInfoTitle': {'en': 'Receiver Info', 'ta': 'பெறுநர் தகவல்'},
    'personReceivedMoneyLabel': {'en': 'Person Received the Money *', 'ta': 'பணம் பெற்றவர் பெயர் *'},
    'enterReceiverNameHint': {'en': 'Enter name of receiver', 'ta': 'பெறுநரின் பெயரை உள்ளிடவும்'},
    'confirmDetailsLabel': {'en': 'Confirm Details', 'ta': 'விவரங்களை உறுதிப்படுத்தவும்'},
  };
  
  newEntries.forEach((key, val) {
    if (!enData.containsKey(key)) {
      enData[key] = val['en'];
    }
    if (!taData.containsKey(key)) {
      taData[key] = val['ta'];
    }
  });
  
  var encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enData));
  taFile.writeAsStringSync(encoder.convert(taData));
  print('ARB files updated successfully for Receiver Info');
}


// ==========================================
// Source: update_dashboard_str.dart
// ==========================================
void update_dashboard_str_main() {
  var f = File('lib/l10n/app_ta.arb');
  var data = jsonDecode(f.readAsStringSync());
  data['dashboard'] = 'டாஷ்போர்டு';
  var enc = JsonEncoder.withIndent('  ');
  f.writeAsStringSync(enc.convert(data));
  print('Updated app_ta.arb for dashboard');
}


// ==========================================
// Source: update_events.dart
// ==========================================
void update_events_main() {
  final file = File('lib/l10n/app_ta.arb');
  final Map<String, dynamic> data = jsonDecode(file.readAsStringSync());
  
  data['events'] = 'விசேஷங்கள்';
  data['paidBalanceFromAllEvents'] = 'அனைத்து விசேஷங்களுக்கும் செலுத்தப்பட்ட மொத்த தொகை';
  data['eventParticipation'] = 'விசேஷங்களில் பங்கேற்பு'; // participation in occasions
  data['eventsManagement'] = 'விசேஷங்கள் மேலாண்மை';
  data['eventNameHeader'] = 'விசேஷத்தின் பெயர்'; // Name of occasion
  data['totalEvents'] = 'மொத்த விசேஷங்கள்:';
  data['eventYearLabel'] = 'விசேஷம் ஆண்டு';
  data['eventLabel'] = 'விசேஷம்';
  data['chooseEventYear'] = 'விசேஷம் ஆண்டைத் தேர்ந்தெடுக்கவும்';
  data['chooseEvents'] = 'விசேஷங்களைத் தேர்ந்தெடுக்கவும்';
  data['eventMoneyHeader'] = 'விசேஷப் பணம்';
  data['privacySec2Item3'] = 'சமூக விசேஷங்கள் மற்றும் உறுப்பினர் புதுப்பிப்புகளை ஒருங்கிணைத்தல்.';
  data['eventParticipationTitle'] = 'விசேஷங்களில் பங்கேற்பு:';
  data['eventInfo'] = 'விசேஷம் தகவல்';
  
  var encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(data));
  print('ARB files updated successfully for events -> special occasions');
}


// ==========================================
// Source: update_events_content.dart
// ==========================================
void update_events_content_main() {
  final file = File('lib/presentation/pages/events_content.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll(
    "const Text('Add New Event')",
    "Text(AppLocalizations.of(context)?.addNewEvent ?? 'Add New Event')"
  );
  
  content = content.replaceAll(
    "'Add New Event',",
    "AppLocalizations.of(context)?.addNewEvent ?? 'Add New Event',"
  );
  
  file.writeAsStringSync(content);
  print('events_content.dart updated successfully for Add New Event');
}


// ==========================================
// Source: update_events_content_popup.dart
// ==========================================
void update_events_content_popup_main() {
  final file = File('lib/presentation/pages/events_content.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll(
    "const Text('EVENT NAME'",
    "Text(AppLocalizations.of(context)?.addEventNameUpper ?? 'EVENT NAME'"
  );
  
  content = content.replaceAll(
    "'e.g. Event_2026'",
    "AppLocalizations.of(context)?.addEventEgName ?? 'e.g. Event_2026'"
  );
  
  content = content.replaceAll(
    "'Note: Year should be at the end of the event name (e.g. Event_2026).'",
    "AppLocalizations.of(context)?.addEventNoteName ?? 'Note: Year should be at the end of the event name (e.g. Event_2026).'"
  );
  
  content = content.replaceAll(
    "const Text('EVENT BANNER'",
    "Text(AppLocalizations.of(context)?.addEventBannerUpper ?? 'EVENT BANNER'"
  );
  
  content = content.replaceAll(
    "const Text('Choose File'",
    "Text(AppLocalizations.of(context)?.addEventChooseFile ?? 'Choose File'"
  );
  
  content = content.replaceAll(
    "'No file chosen'",
    "AppLocalizations.of(context)?.addEventNoFileChosen ?? 'No file chosen'"
  );
  
  content = content.replaceAll(
    "'Note: Max file size 2MB (JPG, PNG).'",
    "AppLocalizations.of(context)?.addEventNoteBanner ?? 'Note: Max file size 2MB (JPG, PNG).'"
  );
  
  content = content.replaceAll(
    "const Text('DURATION'",
    "Text(AppLocalizations.of(context)?.addEventDurationUpper ?? 'DURATION'"
  );
  
  content = content.replaceAll(
    "const Text('From'",
    "Text(AppLocalizations.of(context)?.addEventFrom ?? 'From'"
  );
  
  content = content.replaceAll(
    "const Text('To'",
    "Text(AppLocalizations.of(context)?.addEventTo ?? 'To'"
  );
  
  content = content.replaceAll(
    "const Text('TAX AMOUNT (₹)'",
    "Text(AppLocalizations.of(context)?.addEventTaxAmountUpper ?? 'TAX AMOUNT (₹)'"
  );
  
  content = content.replaceAll(
    "const Text('Create Event'",
    "Text(AppLocalizations.of(context)?.addEventCreateBtn ?? 'Create Event'"
  );
  
  file.writeAsStringSync(content);
  print('events_content.dart updated successfully for the popup');
}


// ==========================================
// Source: update_password_fields.dart
// ==========================================
void update_password_fields_main() {
  final file = File('lib/l10n/app_ta.arb');
  final Map<String, dynamic> data = jsonDecode(file.readAsStringSync());
  
  data['password'] = 'பாஸ்வேர்டு';
  data['forgotPassword'] = 'பாஸ்வேர்டு மறந்துவிட்டதா?';
  data['forgotPasswordTitle'] = 'பாஸ்வேர்டு மறந்துவிட்டதா';
  data['resetPasswordTitle'] = 'பாஸ்வேர்டு மாற்று';
  data['resetPasswordInstruction'] = 'உங்கள் மின்னஞ்சலுக்கு அனுப்பப்பட்ட 6 இலக்க OTP மற்றும் புதிய பாஸ்வேர்டை உள்ளிடவும்.';
  data['newPasswordHint'] = 'புதிய பாஸ்வேர்டு';
  data['resetPasswordButton'] = 'பாஸ்வேர்டு மாற்று';
  
  // Update terms as well to be consistent
  data['termsSec3Desc'] = data['termsSec3Desc'].toString().replaceAll('கடவுச்சொல்லின்', 'பாஸ்வேர்டின்');
  
  var encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(data));
  print('ARB files updated successfully for password fields');
}


// ==========================================
// Source: update_payment_form.dart
// ==========================================
void update_payment_form_main() {
  final file = File('lib/presentation/widgets/payment_form.dart');
  String content = file.readAsStringSync();
  
  if (!content.contains("import '../../l10n/app_localizations.dart';")) {
    content = content.replaceFirst(
      "import '../../utils/api_config.dart';",
      "import '../../utils/api_config.dart';\nimport '../../l10n/app_localizations.dart';"
    );
  }

  // Define simple replacements that don't mess up variable logic
  final replacements = {
    "'My Payment Details'": "AppLocalizations.of(context)!.myPaymentDetails",
    "title: 'My Info'": "title: AppLocalizations.of(context)!.myInfo",
    "_infoRow('Name:'": "_infoRow(AppLocalizations.of(context)!.nameLabelShort",
    "_infoRow('ID:'": "_infoRow(AppLocalizations.of(context)!.idLabelShort",
    "Text('Address:'": "Text(AppLocalizations.of(context)!.addressLabelShort",
    "title: 'Event Info'": "title: AppLocalizations.of(context)!.eventInfo",
    "Text('Event Year'": "Text(AppLocalizations.of(context)!.eventYearLabel",
    "hint: 'Choose Year'": "hint: AppLocalizations.of(context)!.chooseYearHint",
    "Text('Event'": "Text(AppLocalizations.of(context)!.eventLabel",
    "hint: 'Choose Event'": "hint: AppLocalizations.of(context)!.chooseEventHint",
    "Text('Pay Amount *'": "Text(AppLocalizations.of(context)!.payAmountLabel",
    "Text('Date: \${": "Text('\${AppLocalizations.of(context)!.dateLabel}\${",
    "title: 'Rs Summary'": "title: AppLocalizations.of(context)!.rsSummary",
    "_summaryRow('Total Amount'": "_summaryRow(AppLocalizations.of(context)!.totalAmountLabel",
    "_summaryRow('Already Paid'": "_summaryRow(AppLocalizations.of(context)!.alreadyPaidLabel",
    "_summaryRow('Balance Amount'": "_summaryRow(AppLocalizations.of(context)!.balanceAmount",
    "title: 'Payment Method'": "title: AppLocalizations.of(context)!.paymentMethodLabel",
    "Text('Choose Bank *'": "Text(AppLocalizations.of(context)!.chooseBankLabel",
    "_textField('Other Bank Name *'": "_textField(AppLocalizations.of(context)!.otherBankNameLabel",
    "_textField('UPI Transaction ID *'": "_textField(AppLocalizations.of(context)!.upiTransactionIdLabel",
    "_textField('Reference ID *'": "_textField(AppLocalizations.of(context)!.referenceIdLabel",
    "_textField('Cheque Number *'": "_textField(AppLocalizations.of(context)!.chequeNumberLabel",
    "'Save Receipt'": "AppLocalizations.of(context)!.saveReceiptBtn",
    "'Saving...'": "AppLocalizations.of(context)!.savingBtn",
    "'Confirmation Required'": "AppLocalizations.of(context)!.confirmationRequiredTitle",
    "'Please confirm the details before saving.'": "AppLocalizations.of(context)!.confirmDetailsBeforeSaving",
    "'Success'": "AppLocalizations.of(context)!.successTitle",
    "'Payment receipt saved successfully.'": "AppLocalizations.of(context)!.receiptSavedSuccess",
    "'Error'": "AppLocalizations.of(context)!.errorTitle",
    "'Unable to save receipt.'": "AppLocalizations.of(context)!.unableToSaveReceipt",
    "'Invalid Amount'": "AppLocalizations.of(context)!.invalidAmount",
    "'Choose bank'": "AppLocalizations.of(context)!.chooseBankTitle",
    "'Search bank...'": "AppLocalizations.of(context)!.searchBankHint",
    "'No banks found'": "AppLocalizations.of(context)!.noBanksFound",
    "return 'Required';": "return AppLocalizations.of(context)!.requiredValidation;",
    "'Required'": "AppLocalizations.of(context)!.requiredValidation",
    "'Must be greater than 0'": "AppLocalizations.of(context)!.greaterThanZeroValidation",
    "return 'Cannot exceed balance (₹ \$_balance)';": "return '\${AppLocalizations.of(context)!.exceedBalanceValidation} (₹ \$_balance)';",
    "'Connection Error'": "AppLocalizations.of(context)!.connectionErrorTitle"
  };

  replacements.forEach((oldText, newText) {
    content = content.replaceAll(oldText, newText);
  });
  
  // Fix _methodRadio
  if (content.contains("Widget _methodRadio(String value, IconData icon) {")) {
    content = content.replaceAll(
      "Widget _methodRadio(String value, IconData icon) {",
      "Widget _methodRadio(String value, String label, IconData icon) {"
    );
    content = content.replaceAll(
      "Text(value,",
      "Text(label,"
    );
    
    // Update calls to _methodRadio
    content = content.replaceAll(
      "_methodRadio('Bank', Icons.account_balance)",
      "_methodRadio('Bank', AppLocalizations.of(context)!.bankMethod, Icons.account_balance)"
    );
    content = content.replaceAll(
      "_methodRadio('Cheque', Icons.article_outlined)",
      "_methodRadio('Cheque', AppLocalizations.of(context)!.chequeMethod, Icons.article_outlined)"
    );
    content = content.replaceAll(
      "_methodRadio('UPI', Icons.qr_code_scanner)",
      "_methodRadio('UPI', AppLocalizations.of(context)!.upiMethod, Icons.qr_code_scanner)"
    );
    content = content.replaceAll(
      "_methodRadio('Cash', Icons.money)",
      "_methodRadio('Cash', AppLocalizations.of(context)!.cashMethod, Icons.money)"
    );
  }

  file.writeAsStringSync(content);
  print('payment_form.dart updated successfully');
}


// ==========================================
// Source: update_receiver_form.dart
// ==========================================
void update_receiver_form_main() {
  final file = File('lib/presentation/widgets/payment_form.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll(
    "title: 'Receiver Info'",
    "title: AppLocalizations.of(context)!.receiverInfoTitle"
  );
  
  content = content.replaceAll(
    "const Text('Person Received the Money *'",
    "Text(AppLocalizations.of(context)!.personReceivedMoneyLabel"
  );
  
  content = content.replaceAll(
    "hintText: 'Enter name of receiver'",
    "hintText: AppLocalizations.of(context)!.enterReceiverNameHint"
  );
  
  content = content.replaceAll(
    "const Expanded(child: Text('Confirm Details'",
    "Expanded(child: Text(AppLocalizations.of(context)!.confirmDetailsLabel"
  );
  
  file.writeAsStringSync(content);
  print('payment_form.dart updated for Receiver Info successfully');
}


// ==========================================
// Source: update_spoken_tamil.dart
// ==========================================
void update_spoken_tamil_main() {
  final file = File('lib/l10n/app_ta.arb');
  final Map<String, dynamic> data = jsonDecode(file.readAsStringSync());
  
  data['changePassword'] = 'பாஸ்வேர்டு மாற்று';
  data['logout'] = 'லாக் அவுட்';
  
  var encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(data));
  print('ARB files updated successfully for spoken Tamil');
}


// ==========================================
// Source: update_stat.dart
// ==========================================
void update_stat_main() {
  var f = File('lib/l10n/app_ta.arb');
  var data = jsonDecode(f.readAsStringSync());
  data['statApprovals'] = 'விண்ணப்பங்கள்';
  var enc = JsonEncoder.withIndent('  ');
  f.writeAsStringSync(enc.convert(data));
  print('Updated app_ta.arb');
}
