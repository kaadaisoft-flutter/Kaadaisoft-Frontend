import 'dart:io';
import 'dart:convert';

void main() {
  final content = File('lib/l10n/app_en.arb').readAsStringSync();
  final map = jsonDecode(content) as Map<String, dynamic>;
  final keysToCheck = [
    'eventParticipation', 'eventParticipationTitle', 'sNo', 'eventNameHeader',
    'taxAmount', 'paidAmount', 'balanceAmount', 'statusLabel', 'paymentDate'
  ];
  
  for (var k in map.keys) {
    if (k.toLowerCase().contains('event') || 
        k.toLowerCase().contains('tax') || 
        k.toLowerCase().contains('paid') || 
        k.toLowerCase().contains('balance') || 
        k.toLowerCase().contains('status') ||
        k.toLowerCase().contains('payment') ||
        k.toLowerCase().contains('date')) {
      print('$k : ${map[k]}');
    }
  }
}
