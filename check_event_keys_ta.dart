import 'dart:io';
import 'dart:convert';

void main() {
  final content = File('lib/l10n/app_ta.arb').readAsStringSync();
  final map = jsonDecode(content) as Map<String, dynamic>;
  final keysToCheck = [
    'eventParticipation', 'eventParticipationTitle', 'sNo', 'eventNameHeader',
    'taxAmount', 'tablePaidAmount', 'balanceAmount', 'statusLabel', 'tablePaymentDate'
  ];
  
  for (var k in keysToCheck) {
    if (map.containsKey(k)) {
      print('$k : ${map[k]}');
    } else {
      print('MISSING: $k');
    }
  }
}
