import 'dart:io';
void main() {
  var en = File('lib/l10n/app_en.arb').readAsStringSync();
  en = en.replaceAll('"Last Updated"', r'\"Last Updated\"');
  File('lib/l10n/app_en.arb').writeAsStringSync(en);
  
  var ta = File('lib/l10n/app_ta.arb').readAsStringSync();
  ta = ta.replaceAll('"கடைசியாகப் புதுப்பிக்கப்பட்ட"', r'\"கடைசியாகப் புதுப்பிக்கப்பட்ட\"');
  File('lib/l10n/app_ta.arb').writeAsStringSync(ta);
}
