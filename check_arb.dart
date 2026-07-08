import 'dart:io';

void main() {
  var content = File('lib/l10n/app_en.arb').readAsStringSync();
  print(content.substring(content.length - 150));
  var content2 = File('lib/l10n/app_ta.arb').readAsStringSync();
  print(content2.substring(content2.length - 150));
}
