import 'dart:io';

void main() {
  final files = ['lib/l10n/app_en.arb', 'lib/l10n/app_ta.arb'];
  for (final path in files) {
    var content = File(path).readAsStringSync();
    content = content.replaceAll(r'\"', '"');
    File(path).writeAsStringSync(content);
  }
}
