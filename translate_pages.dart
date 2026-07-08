import 'dart:io';
import 'dart:convert';

void main() {
  final enArbPath = 'lib/l10n/app_en.arb';
  final taArbPath = 'lib/l10n/app_ta.arb';

  final privacyEn = {
    "privacySubTitle": "Your privacy and data security are our top priorities.",
    "lastUpdated": "LAST UPDATED: MAY 07, 2026",
    "privacyIntro": "At **Poondurai Kaadai Kulam**, we are committed to protecting your personal data and ensuring that your privacy is respected. This policy explains how we collect, use, and safeguard your information.",
    "privacySec1Title": "1. Information We Collect",
    "privacySec1Desc": "We collect information you provide directly to us when you register for an account, including:",
    "privacySec1Item1Title": "Personal Identity",
    "privacySec1Item1Desc": "Full name and photographs.",
    "privacySec1Item2Title": "Contact Details",
    "privacySec1Item2Desc": "Mobile number and physical address.",
    "privacySec1Item3Title": "Community Data",
    "privacySec1Item3Desc": "Family membership details and role assignments.",
    "privacySec2Title": "2. How We Use Your Information",
    "privacySec2Desc": "The information we collect is strictly used for community management purposes:",
    "privacySec2Item1": "Verifying community membership and user authenticity.",
    "privacySec2Item2": "Processing tax payments and generating official receipts.",
    "privacySec2Item3": "Coordinating community events and member updates.",
    "privacySec2Item4": "Maintaining a secure and transparent community registry.",
    "privacySec3Title": "3. Data Sharing & Disclosure",
    "privacySec3Desc": "We do not sell, trade, or rent your personal information to third parties. Your data is only visible to authorized platform administrators and coordinators for verification purposes within the Poondurai Kaadai Kulam community ecosystem.",
    "privacySec4Title": "4. Security Measures",
    "privacySec4Desc": "We implement a variety of security measures to maintain the safety of your personal information. Your data is stored on secure servers and access is restricted to authorized personnel only. While we strive for absolute security, please note that no method of digital storage is 100% impenetrable.",
    "privacySec5Title": "5. Your Data Rights",
    "privacySec5Desc": "You have the right to access and update your information at any time. If you wish to correct your data or request account closure, you can manage your profile settings or contact the administrator directly.",
    "privacySec6Title": "6. Cookies & Tracking",
    "privacySec6Desc": "Our platform may use essential session cookies to keep you logged in and ensure the website functions correctly. We do not use tracking cookies for advertising purposes.",
    "privacySec7Title": "7. Changes to This Policy",
    "privacySec7Desc": "We may update this Privacy Policy to reflect changes in our practices. Any updates will be posted on this page with an updated \\\"Last Updated\\\" date.",
    "privacySec8Title": "8. Contact Our Team",
    "privacySec8Desc": "If you have any questions or concerns regarding this Privacy Policy or your data, please reach out to the platform administrator.",
    "allRightsReserved": "© 2026 Poondurai Kaadai Kulam. All rights reserved.",
    "backToLogin": "Back to Login",
    
    "termsSubTitle": "Legal agreement for using Poondurai Kaadai Kulam platform",
    "termsIntro": "Please read these terms and conditions carefully before using our services. By using our platform, you agree to comply with and be bound by these terms.",
    "termsSec1Title": "1. Agreement to Terms",
    "termsSec1Desc": "By accessing or using our website, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree with any part of these terms, you must not use our services. This agreement constitutes a legally binding contract between you and Poondurai Kaadai Kulam.",
    "termsSec2Title": "2. User Registration",
    "termsSec2Desc": "To access certain features of the website, you are required to register for an account. You agree to provide accurate, current, and complete information during the registration process (Mobile Number, Address, etc.) and to update such information to keep it accurate, current, and complete.",
    "termsSec3Title": "3. Responsibility for Account",
    "termsSec3Desc": "You are solely responsible for maintaining the confidentiality of your account password and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account or any other breach of security.",
    "termsSec4Title": "4. Use of Information",
    "termsSec4Desc": "The information provided on this platform is for community management and membership purposes. While we strive to maintain high data accuracy, we do not warrant the completeness or reliability of user-submitted information at all times.",
    "termsSec5Title": "5. Prohibited Activities",
    "termsSec5Desc": "You agree not to use the platform for any unlawful purpose or any purpose prohibited under these Terms. Prohibited activities include but are not limited to: uploading false documents, attempting to breach security, or harassing other community members.",
    "termsSec6Title": "6. Intellectual Property",
    "termsSec6Desc": "All content included on this website, such as custom scripts, branding, UI designs, and logos, is the property of Poondurai Kaadai Kulam or its content suppliers and is protected by copyright laws.",
    "termsSec7Title": "7. Termination of Use",
    "termsSec7Desc": "We reserve the right to terminate or suspend your access to the platform without notice, for any conduct that we, in our sole discretion, believe is in violation of any applicable law or is harmful to the interests of the community.",
    "termsSec8Title": "8. Changes to Terms",
    "termsSec8Desc": "We reserve the right to modify these Terms and Conditions at any time. Changes will be effective immediately upon posting. Your continued use of the website following changes will mean that you accept and agree to the modified terms."
  };

  final privacyTa = {
    "privacySubTitle": "உங்கள் தனியுரிமை மற்றும் தரவுப் பாதுகாப்பே எங்களின் முதன்மை முன்னுரிமைகள்.",
    "lastUpdated": "கடைசியாகப் புதுப்பிக்கப்பட்டது: மே 07, 2026",
    "privacyIntro": "பூந்துறை காடைகுலத்தில், உங்கள் தனிப்பட்ட தரவைப் பாதுகாப்பதற்கும் உங்கள் தனியுரிமை மதிக்கப்படுவதை உறுதி செய்வதற்கும் நாங்கள் கடமைப்பட்டுள்ளோம். உங்கள் தகவல்களை நாங்கள் எவ்வாறு சேகரிக்கிறோம், பயன்படுத்துகிறோம் மற்றும் பாதுகாக்கிறோம் என்பதை இந்தக் கொள்கை விளக்குகிறது.",
    "privacySec1Title": "1. நாங்கள் சேகரிக்கும் தகவல்கள்",
    "privacySec1Desc": "நீங்கள் கணக்கைப் பதிவு செய்யும் போது நீங்கள் எங்களுக்கு நேரடியாக வழங்கும் தகவல்களை நாங்கள் சேகரிக்கிறோம், இதில் அடங்கும்:",
    "privacySec1Item1Title": "தனிப்பட்ட அடையாளம்",
    "privacySec1Item1Desc": "முழு பெயர் மற்றும் புகைப்படங்கள்.",
    "privacySec1Item2Title": "தொடர்பு விவரங்கள்",
    "privacySec1Item2Desc": "மொபைல் எண் மற்றும் முகவரி.",
    "privacySec1Item3Title": "சமூகத் தரவு",
    "privacySec1Item3Desc": "குடும்ப உறுப்பினர் விவரங்கள் மற்றும் பொறுப்புகள்.",
    "privacySec2Title": "2. உங்கள் தகவலை நாங்கள் எவ்வாறு பயன்படுத்துகிறோம்",
    "privacySec2Desc": "நாங்கள் சேகரிக்கும் தகவல்கள் சமூக மேலாண்மை நோக்கங்களுக்காக மட்டுமே பயன்படுத்தப்படுகின்றன:",
    "privacySec2Item1": "சமூக உறுப்பினர் மற்றும் பயனர் நம்பகத்தன்மையை சரிபார்த்தல்.",
    "privacySec2Item2": "வரி செலுத்துதல்களைச் செயலாக்குதல் மற்றும் அதிகாரப்பூர்வ ரசீதுகளை உருவாக்குதல்.",
    "privacySec2Item3": "சமூக நிகழ்வுகள் மற்றும் உறுப்பினர் புதுப்பிப்புகளை ஒருங்கிணைத்தல்.",
    "privacySec2Item4": "பாதுகாப்பான மற்றும் வெளிப்படையான சமூகப் பதிவேட்டைப் பராமரித்தல்.",
    "privacySec3Title": "3. தரவுப் பகிர்தல் & வெளிப்படுத்தல்",
    "privacySec3Desc": "உங்கள் தனிப்பட்ட தகவல்களை நாங்கள் விற்கவோ, வர்த்தகம் செய்யவோ அல்லது மூன்றாம் தரப்பினருக்கு வாடகைக்கு விடவோ மாட்டோம். பூந்துறை காடைகுலம் சமூக சுற்றுச்சூழல் அமைப்பிற்குள் சரிபார்ப்பு நோக்கங்களுக்காக அங்கீகரிக்கப்பட்ட தள நிர்வாகிகளுக்கும் ஒருங்கிணைப்பாளர்களுக்கும் மட்டுமே உங்கள் தரவு தெரியும்.",
    "privacySec4Title": "4. பாதுகாப்பு நடவடிக்கைகள்",
    "privacySec4Desc": "உங்கள் தனிப்பட்ட தகவலின் பாதுகாப்பைப் பேணுவதற்கு நாங்கள் பல்வேறு பாதுகாப்பு நடவடிக்கைகளைச் செயல்படுத்துகிறோம். உங்கள் தரவு பாதுகாப்பான சேவையகங்களில் சேமிக்கப்படுகிறது, மேலும் அணுகல் அங்கீகரிக்கப்பட்ட பணியாளர்களுக்கு மட்டுமே தடைசெய்யப்பட்டுள்ளது. முழுமையான பாதுகாப்பிற்காக நாங்கள் பாடுபடுகையில், டிஜிட்டல் சேமிப்பகத்தின் எந்த முறையும் 100% ஊடுருவ முடியாதது என்பதை நினைவில் கொள்ளவும்.",
    "privacySec5Title": "5. உங்கள் தரவு உரிமைகள்",
    "privacySec5Desc": "எந்த நேரத்திலும் உங்கள் தகவலை அணுகவும் புதுப்பிக்கவும் உங்களுக்கு உரிமை உள்ளது. உங்கள் தரவைத் திருத்த அல்லது கணக்கை மூடுவதற்குக் கோர விரும்பினால், உங்கள் சுயவிவர அமைப்புகளை நீங்கள் நிர்வகிக்கலாம் அல்லது நிர்வாகியை நேரடியாகத் தொடர்புகொள்ளலாம்.",
    "privacySec6Title": "6. குக்கீகள் & கண்காணிப்பு",
    "privacySec6Desc": "உங்களை உள்நுழைந்திருக்கவும் இணையதளம் சரியாகச் செயல்படுவதை உறுதி செய்யவும் எங்கள் தளம் அத்தியாவசிய அமர்வு குக்கீகளைப் பயன்படுத்தலாம். விளம்பர நோக்கங்களுக்காக கண்காணிப்பு குக்கீகளை நாங்கள் பயன்படுத்துவதில்லை.",
    "privacySec7Title": "7. இந்தக் கொள்கையில் மாற்றங்கள்",
    "privacySec7Desc": "எங்கள் நடைமுறைகளில் ஏற்படும் மாற்றங்களைப் பிரதிபலிக்கும் வகையில் இந்தத் தனியுரிமைக் கொள்கையை நாங்கள் புதுப்பிக்கலாம். எந்தவொரு புதுப்பிப்புகளும் புதுப்பிக்கப்பட்ட \\\"கடைசியாகப் புதுப்பிக்கப்பட்ட\\\" தேதியுடன் இந்தப் பக்கத்தில் வெளியிடப்படும்.",
    "privacySec8Title": "8. எங்கள் குழுவைத் தொடர்புகொள்ளவும்",
    "privacySec8Desc": "இந்தத் தனியுரிமைக் கொள்கை அல்லது உங்கள் தரவு குறித்து ஏதேனும் கேள்விகள் அல்லது கவலைகள் இருந்தால், தள நிர்வாகியைத் தொடர்புகொள்ளவும்.",
    "allRightsReserved": "© 2026 பூந்துறை காடைகுலம். அனைத்து உரிமைகளும் பாதுகாக்கப்பட்டவை.",
    "backToLogin": "உள்நுழைவுக்குத் திரும்பு",
    
    "termsSubTitle": "பூந்துறை காடைகுலம் தளத்தைப் பயன்படுத்துவதற்கான சட்ட ஒப்பந்தம்",
    "termsIntro": "எங்கள் சேவைகளைப் பயன்படுத்துவதற்கு முன் இந்த விதிமுறைகளையும் நிபந்தனைகளையும் கவனமாகப் படிக்கவும். எங்கள் தளத்தைப் பயன்படுத்துவதன் மூலம், இந்த விதிமுறைகளுக்கு இணங்கவும் கட்டுப்படவும் ஒப்புக்கொள்கிறீர்கள்.",
    "termsSec1Title": "1. விதிமுறைகளுக்கான ஒப்பந்தம்",
    "termsSec1Desc": "எங்கள் இணையதளத்தை அணுகுவதன் மூலம் அல்லது பயன்படுத்துவதன் மூலம், இந்த விதிமுறைகள் மற்றும் நிபந்தனைகள் மற்றும் எங்கள் தனியுரிமைக் கொள்கைக்குக் கட்டுப்பட ஒப்புக்கொள்கிறீர்கள். இந்த விதிமுறைகளின் எந்தப் பகுதியையும் நீங்கள் ஏற்கவில்லை என்றால், நீங்கள் எங்கள் சேவைகளைப் பயன்படுத்தக் கூடாது. இந்த ஒப்பந்தம் உங்களுக்கும் பூந்துறை காடைகுலத்திற்கும் இடையிலான சட்டப்பூர்வ பிணைப்பு ஒப்பந்தமாகும்.",
    "termsSec2Title": "2. பயனர் பதிவு",
    "termsSec2Desc": "இணையதளத்தின் சில அம்சங்களை அணுக, நீங்கள் கணக்கைப் பதிவு செய்ய வேண்டும். பதிவுச் செயல்பாட்டின் போது துல்லியமான, தற்போதைய மற்றும் முழுமையான தகவலை (மொபைல் எண், முகவரி போன்றவை) வழங்கவும், அத்தகைய தகவலைத் துல்லியமாகவும், தற்போதையதாகவும், முழுமையாகவும் வைத்திருக்க புதுப்பிக்கவும் ஒப்புக்கொள்கிறீர்கள்.",
    "termsSec3Title": "3. கணக்கிற்கான பொறுப்பு",
    "termsSec3Desc": "உங்கள் கணக்கு கடவுச்சொல்லின் ரகசியத்தன்மையைப் பேணுவதற்கும் உங்கள் கணக்கின் கீழ் நிகழும் அனைத்துச் செயல்பாடுகளுக்கும் நீங்கள் மட்டுமே பொறுப்பாவீர்கள். உங்கள் கணக்கின் அங்கீகரிக்கப்படாத பயன்பாடு அல்லது பாதுகாப்பை மீறும் வேறு ஏதேனும் இருந்தால் உடனடியாக எங்களுக்குத் தெரிவிக்க ஒப்புக்கொள்கிறீர்கள்.",
    "termsSec4Title": "4. தகவலின் பயன்பாடு",
    "termsSec4Desc": "இந்தத் தளத்தில் வழங்கப்படும் தகவல்கள் சமூக மேலாண்மை மற்றும் உறுப்பினர் நோக்கங்களுக்காக ஆகும். உயர் தரவுத் துல்லியத்தைப் பராமரிக்க நாங்கள் பாடுபடுகையில், பயனர் சமர்ப்பித்த தகவலின் முழுமை அல்லது நம்பகத்தன்மைக்கு நாங்கள் எப்போதும் உத்தரவாதம் அளிக்க மாட்டோம்.",
    "termsSec5Title": "5. தடைசெய்யப்பட்ட செயல்பாடுகள்",
    "termsSec5Desc": "சட்டத்திற்குப் புறம்பான நோக்கத்திற்காகவோ அல்லது இந்த விதிமுறைகளின் கீழ் தடைசெய்யப்பட்ட எந்த நோக்கத்திற்காகவோ தளத்தைப் பயன்படுத்த வேண்டாம் என்று ஒப்புக்கொள்கிறீர்கள். தடைசெய்யப்பட்ட செயல்பாடுகளில் தவறான ஆவணங்களைப் பதிவேற்றுவது, பாதுகாப்பை மீற முயற்சிப்பது அல்லது பிற சமூக உறுப்பினர்களைத் துன்புறுத்துவது ஆகியவை அடங்கும், ஆனால் இவை மட்டும் அல்ல.",
    "termsSec6Title": "6. அறிவுசார் சொத்து",
    "termsSec6Desc": "தனிப்பயன் ஸ்கிரிப்டுகள், பிராண்டிங், UI வடிவமைப்புகள் மற்றும் லோகோக்கள் போன்ற இந்த இணையதளத்தில் உள்ள அனைத்து உள்ளடக்கங்களும் பூந்துறை காடைகுலம் அல்லது அதன் உள்ளடக்க சப்ளையர்களின் சொத்து மற்றும் பதிப்புரிமைச் சட்டங்களால் பாதுகாக்கப்படுகின்றன.",
    "termsSec7Title": "7. பயன்பாட்டை நிறுத்துதல்",
    "termsSec7Desc": "பொருந்தக்கூடிய எந்தவொரு சட்டத்தையும் மீறுவதாக அல்லது சமூகத்தின் நலன்களுக்கு தீங்கு விளைவிப்பதாக எங்களின் சொந்த விருப்பத்தின் பேரில் நாங்கள் நம்பும் எந்தவொரு நடத்தைக்கும், அறிவிப்பு இல்லாமல் தளத்திற்கான உங்கள் அணுகலை நிறுத்தவோ அல்லது இடைநிறுத்தவோ எங்களுக்கு உரிமை உள்ளது.",
    "termsSec8Title": "8. விதிமுறைகளில் மாற்றங்கள்",
    "termsSec8Desc": "இந்த விதிமுறைகளையும் நிபந்தனைகளையும் எந்த நேரத்திலும் மாற்றுவதற்கு எங்களுக்கு உரிமை உள்ளது. மாற்றங்கள் வெளியிடப்பட்டவுடன் உடனடியாகச் செயல்படும். மாற்றங்களைத் தொடர்ந்து இணையதளத்தைத் தொடர்ந்து பயன்படுத்துவது, மாற்றியமைக்கப்பட்ட விதிமுறைகளை நீங்கள் ஏற்றுக்கொண்டு ஒப்புக்கொள்கிறீர்கள் என்பதாகும்."
  };

  void updateArb(String path, Map<String, String> newKeys) {
    final file = File(path);
    final content = file.readAsStringSync();
    final Map<String, dynamic> data = json.decode(content);
    data.addAll(newKeys);
    
    // Sort keys or just dump
    file.writeAsStringSync(json.encode(data));
  }

  updateArb(enArbPath, privacyEn);
  updateArb(taArbPath, privacyTa);

  final privacyReplacements = {
    "'Your privacy and data security are our top priorities.'": "AppLocalizations.of(context)?.privacySubTitle ?? 'Your privacy and data security are our top priorities.'",
    "'LAST UPDATED: MAY 07, 2026'": "AppLocalizations.of(context)?.lastUpdated ?? 'LAST UPDATED: MAY 07, 2026'",
    "'At **Poondurai Kaadai Kulam**, we are committed to protecting your personal data and ensuring that your privacy is respected. This policy explains how we collect, use, and safeguard your information.'": "AppLocalizations.of(context)?.privacyIntro ?? 'At **Poondurai Kaadai Kulam**, we are committed to protecting your personal data and ensuring that your privacy is respected. This policy explains how we collect, use, and safeguard your information.'",
    "'1. Information We Collect'": "AppLocalizations.of(context)?.privacySec1Title ?? '1. Information We Collect'",
    "'We collect information you provide directly to us when you register for an account, including:'": "AppLocalizations.of(context)?.privacySec1Desc ?? 'We collect information you provide directly to us when you register for an account, including:'",
    "'Personal Identity'": "AppLocalizations.of(context)?.privacySec1Item1Title ?? 'Personal Identity'",
    "'Full name and photographs.'": "AppLocalizations.of(context)?.privacySec1Item1Desc ?? 'Full name and photographs.'",
    "'Contact Details'": "AppLocalizations.of(context)?.privacySec1Item2Title ?? 'Contact Details'",
    "'Mobile number and physical address.'": "AppLocalizations.of(context)?.privacySec1Item2Desc ?? 'Mobile number and physical address.'",
    "'Community Data'": "AppLocalizations.of(context)?.privacySec1Item3Title ?? 'Community Data'",
    "'Family membership details and role assignments.'": "AppLocalizations.of(context)?.privacySec1Item3Desc ?? 'Family membership details and role assignments.'",
    "'2. How We Use Your Information'": "AppLocalizations.of(context)?.privacySec2Title ?? '2. How We Use Your Information'",
    "'The information we collect is strictly used for community management purposes:'": "AppLocalizations.of(context)?.privacySec2Desc ?? 'The information we collect is strictly used for community management purposes:'",
    "'Verifying community membership and user authenticity.'": "AppLocalizations.of(context)?.privacySec2Item1 ?? 'Verifying community membership and user authenticity.'",
    "'Processing tax payments and generating official receipts.'": "AppLocalizations.of(context)?.privacySec2Item2 ?? 'Processing tax payments and generating official receipts.'",
    "'Coordinating community events and member updates.'": "AppLocalizations.of(context)?.privacySec2Item3 ?? 'Coordinating community events and member updates.'",
    "'Maintaining a secure and transparent community registry.'": "AppLocalizations.of(context)?.privacySec2Item4 ?? 'Maintaining a secure and transparent community registry.'",
    "'3. Data Sharing & Disclosure'": "AppLocalizations.of(context)?.privacySec3Title ?? '3. Data Sharing & Disclosure'",
    "'We do not sell, trade, or rent your personal information to third parties. Your data is only visible to authorized platform administrators and coordinators for verification purposes within the Poondurai Kaadai Kulam community ecosystem.'": "AppLocalizations.of(context)?.privacySec3Desc ?? 'We do not sell, trade, or rent your personal information to third parties. Your data is only visible to authorized platform administrators and coordinators for verification purposes within the Poondurai Kaadai Kulam community ecosystem.'",
    "'4. Security Measures'": "AppLocalizations.of(context)?.privacySec4Title ?? '4. Security Measures'",
    "'We implement a variety of security measures to maintain the safety of your personal information. Your data is stored on secure servers and access is restricted to authorized personnel only. While we strive for absolute security, please note that no method of digital storage is 100% impenetrable.'": "AppLocalizations.of(context)?.privacySec4Desc ?? 'We implement a variety of security measures to maintain the safety of your personal information. Your data is stored on secure servers and access is restricted to authorized personnel only. While we strive for absolute security, please note that no method of digital storage is 100% impenetrable.'",
    "'5. Your Data Rights'": "AppLocalizations.of(context)?.privacySec5Title ?? '5. Your Data Rights'",
    "'You have the right to access and update your information at any time. If you wish to correct your data or request account closure, you can manage your profile settings or contact the administrator directly.'": "AppLocalizations.of(context)?.privacySec5Desc ?? 'You have the right to access and update your information at any time. If you wish to correct your data or request account closure, you can manage your profile settings or contact the administrator directly.'",
    "'6. Cookies & Tracking'": "AppLocalizations.of(context)?.privacySec6Title ?? '6. Cookies & Tracking'",
    "'Our platform may use essential session cookies to keep you logged in and ensure the website functions correctly. We do not use tracking cookies for advertising purposes.'": "AppLocalizations.of(context)?.privacySec6Desc ?? 'Our platform may use essential session cookies to keep you logged in and ensure the website functions correctly. We do not use tracking cookies for advertising purposes.'",
    "'7. Changes to This Policy'": "AppLocalizations.of(context)?.privacySec7Title ?? '7. Changes to This Policy'",
    "'We may update this Privacy Policy to reflect changes in our practices. Any updates will be posted on this page with an updated \"Last Updated\" date.'": "AppLocalizations.of(context)?.privacySec7Desc ?? 'We may update this Privacy Policy to reflect changes in our practices. Any updates will be posted on this page with an updated \\\"Last Updated\\\" date.'",
    "'8. Contact Our Team'": "AppLocalizations.of(context)?.privacySec8Title ?? '8. Contact Our Team'",
    "'If you have any questions or concerns regarding this Privacy Policy or your data, please reach out to the platform administrator.'": "AppLocalizations.of(context)?.privacySec8Desc ?? 'If you have any questions or concerns regarding this Privacy Policy or your data, please reach out to the platform administrator.'",
    "'© 2026 Poondurai Kaadai Kulam. All rights reserved.'": "AppLocalizations.of(context)?.allRightsReserved ?? '© 2026 Poondurai Kaadai Kulam. All rights reserved.'",
    "'Back to Login'": "AppLocalizations.of(context)?.backToLogin ?? 'Back to Login'",
    "'Privacy Policy'": "AppLocalizations.of(context)?.privacyPolicy ?? 'Privacy Policy'"
  };

  final termsReplacements = {
    "'Legal agreement for using Poondurai Kaadai Kulam platform'": "AppLocalizations.of(context)?.termsSubTitle ?? 'Legal agreement for using Poondurai Kaadai Kulam platform'",
    "'LAST UPDATED: MAY 07, 2026'": "AppLocalizations.of(context)?.lastUpdated ?? 'LAST UPDATED: MAY 07, 2026'",
    "'Please read these terms and conditions carefully before using our services. By using our platform, you agree to comply with and be bound by these terms.'": "AppLocalizations.of(context)?.termsIntro ?? 'Please read these terms and conditions carefully before using our services. By using our platform, you agree to comply with and be bound by these terms.'",
    "'1. Agreement to Terms'": "AppLocalizations.of(context)?.termsSec1Title ?? '1. Agreement to Terms'",
    "'By accessing or using our website, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree with any part of these terms, you must not use our services. This agreement constitutes a legally binding contract between you and Poondurai Kaadai Kulam.'": "AppLocalizations.of(context)?.termsSec1Desc ?? 'By accessing or using our website, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree with any part of these terms, you must not use our services. This agreement constitutes a legally binding contract between you and Poondurai Kaadai Kulam.'",
    "'2. User Registration'": "AppLocalizations.of(context)?.termsSec2Title ?? '2. User Registration'",
    "'To access certain features of the website, you are required to register for an account. You agree to provide accurate, current, and complete information during the registration process (Mobile Number, Address, etc.) and to update such information to keep it accurate, current, and complete.'": "AppLocalizations.of(context)?.termsSec2Desc ?? 'To access certain features of the website, you are required to register for an account. You agree to provide accurate, current, and complete information during the registration process (Mobile Number, Address, etc.) and to update such information to keep it accurate, current, and complete.'",
    "'3. Responsibility for Account'": "AppLocalizations.of(context)?.termsSec3Title ?? '3. Responsibility for Account'",
    "'You are solely responsible for maintaining the confidentiality of your account password and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account or any other breach of security.'": "AppLocalizations.of(context)?.termsSec3Desc ?? 'You are solely responsible for maintaining the confidentiality of your account password and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account or any other breach of security.'",
    "'4. Use of Information'": "AppLocalizations.of(context)?.termsSec4Title ?? '4. Use of Information'",
    "'The information provided on this platform is for community management and membership purposes. While we strive to maintain high data accuracy, we do not warrant the completeness or reliability of user-submitted information at all times.'": "AppLocalizations.of(context)?.termsSec4Desc ?? 'The information provided on this platform is for community management and membership purposes. While we strive to maintain high data accuracy, we do not warrant the completeness or reliability of user-submitted information at all times.'",
    "'5. Prohibited Activities'": "AppLocalizations.of(context)?.termsSec5Title ?? '5. Prohibited Activities'",
    "'You agree not to use the platform for any unlawful purpose or any purpose prohibited under these Terms. Prohibited activities include but are not limited to: uploading false documents, attempting to breach security, or harassing other community members.'": "AppLocalizations.of(context)?.termsSec5Desc ?? 'You agree not to use the platform for any unlawful purpose or any purpose prohibited under these Terms. Prohibited activities include but are not limited to: uploading false documents, attempting to breach security, or harassing other community members.'",
    "'6. Intellectual Property'": "AppLocalizations.of(context)?.termsSec6Title ?? '6. Intellectual Property'",
    "'All content included on this website, such as custom scripts, branding, UI designs, and logos, is the property of Poondurai Kaadai Kulam or its content suppliers and is protected by copyright laws.'": "AppLocalizations.of(context)?.termsSec6Desc ?? 'All content included on this website, such as custom scripts, branding, UI designs, and logos, is the property of Poondurai Kaadai Kulam or its content suppliers and is protected by copyright laws.'",
    "'7. Termination of Use'": "AppLocalizations.of(context)?.termsSec7Title ?? '7. Termination of Use'",
    "'We reserve the right to terminate or suspend your access to the platform without notice, for any conduct that we, in our sole discretion, believe is in violation of any applicable law or is harmful to the interests of the community.'": "AppLocalizations.of(context)?.termsSec7Desc ?? 'We reserve the right to terminate or suspend your access to the platform without notice, for any conduct that we, in our sole discretion, believe is in violation of any applicable law or is harmful to the interests of the community.'",
    "'8. Changes to Terms'": "AppLocalizations.of(context)?.termsSec8Title ?? '8. Changes to Terms'",
    "'We reserve the right to modify these Terms and Conditions at any time. Changes will be effective immediately upon posting. Your continued use of the website following changes will mean that you accept and agree to the modified terms.'": "AppLocalizations.of(context)?.termsSec8Desc ?? 'We reserve the right to modify these Terms and Conditions at any time. Changes will be effective immediately upon posting. Your continued use of the website following changes will mean that you accept and agree to the modified terms.'",
    "'© 2026 Poondurai Kaadai Kulam. All rights reserved.'": "AppLocalizations.of(context)?.allRightsReserved ?? '© 2026 Poondurai Kaadai Kulam. All rights reserved.'",
    "'Back to Login'": "AppLocalizations.of(context)?.backToLogin ?? 'Back to Login'",
    "'Terms and Conditions'": "AppLocalizations.of(context)?.termsAndConditionsTitle ?? 'Terms and Conditions'"
  };

  void replaceInFile(String path, Map<String, String> replacements) {
    final file = File(path);
    var content = file.readAsStringSync();
    
    if (!content.contains("import '../../l10n/app_localizations.dart';")) {
      content = "import '../../l10n/app_localizations.dart';\n" + content;
    }
    
    replacements.forEach((oldText, newText) {
      content = content.replaceAll(oldText, newText);
    });

    // Remove const before Text
    content = content.replaceAll('const Text(', 'Text(');
    content = content.replaceAll('const RichText(', 'RichText(');
    content = content.replaceAll('const Expanded(', 'Expanded(');
    
    file.writeAsStringSync(content);
  }

  replaceInFile('lib/presentation/pages/privacy_policy_page.dart', privacyReplacements);
  replaceInFile('lib/presentation/pages/terms_and_conditions_page.dart', termsReplacements);
}
