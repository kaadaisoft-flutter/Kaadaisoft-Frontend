import 'dart:io';

void main() {
  final path = 'lib/presentation/pages/member_details_content.dart';
  var content = File(path).readAsStringSync();

  // Add import if missing
  if (!content.contains('package:flutter_gen/gen_l10n/app_localizations.dart')) {
    content = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';\n" + content;
  }

  // Remove const from Row children list
  content = content.replaceAll(
    'children: const [',
    'children: [',
  );
  
  // Remove const from Row
  content = content.replaceAll(
    'const Row(\n            children: [',
    'Row(\n            children: [',
  );
  
  // Actually, there's `const Row(` at line 300
  // "          const Row(\n            children: [\n              Icon(Icons.group, color: const Color(0xFF5D1712), size: 24),\n              SizedBox(width: 12),\n              Text(AppLocalizations"
  
  // Let's just do a simple replaceAll for `const Row` that precedes `AppLocalizations`
  content = content.replaceAll(
    'const Row(\n            children: [\n              Icon(Icons.group, color: const Color(0xFF5D1712), size: 24),\n              SizedBox(width: 12),\n              Text(AppLocalizations',
    'Row(\n            children: [\n              const Icon(Icons.group, color: Color(0xFF5D1712), size: 24),\n              const SizedBox(width: 12),\n              Text(AppLocalizations',
  );

  // For the first Row
  content = content.replaceAll(
    'Row(\n                mainAxisSize: MainAxisSize.min,\n                children: [\n                  Icon(Icons.person, color: Color(0xFF5D1712), size: 28),\n                  SizedBox(width: 12),\n                  Text(AppLocalizations',
    'Row(\n                mainAxisSize: MainAxisSize.min,\n                children: [\n                  const Icon(Icons.person, color: Color(0xFF5D1712), size: 28),\n                  const SizedBox(width: 12),\n                  Text(AppLocalizations',
  );
  
  // Check if I need to handle `const Row` generically just in case.
  content = content.replaceAll('const Row(', 'Row(');

  File(path).writeAsStringSync(content);
}
