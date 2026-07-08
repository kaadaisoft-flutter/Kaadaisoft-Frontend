import 'dart:io';

void main() {
  final path = 'lib/presentation/pages/member_details_content.dart';
  var content = File(path).readAsStringSync();

  content = content.replaceAll(
    "Text('Member Details:',",
    "Text(AppLocalizations.of(context)?.memberDetailsTitle ?? 'Member Details:',",
  );

  content = content.replaceAll(
    "label: const Text('Download ID Card'),",
    "label: Text(AppLocalizations.of(context)?.downloadIdCardBtn ?? 'Download ID Card'),",
  );

  content = content.replaceAll(
    "Text('Family Members',",
    "Text(AppLocalizations.of(context)?.familyMembersList ?? 'Family Members',",
  );

  content = content.replaceAll(
    "_roundIcon(Icons.contact_page_outlined, 'Community Certificate', onTap: () => _showImageViewer(_userData?['Communitycertificateimage'], 'Community Certificate')),",
    "_roundIcon(Icons.contact_page_outlined, AppLocalizations.of(context)?.communityCertificateLabel ?? 'Community Certificate', onTap: () => _showImageViewer(_userData?['Communitycertificateimage'], AppLocalizations.of(context)?.communityCertificateLabel ?? 'Community Certificate')),",
  );

  content = content.replaceAll(
    "_actionButton('Event Participation',",
    "_actionButton(AppLocalizations.of(context)?.eventParticipation ?? 'Event Participation',",
  );

  content = content.replaceAll(
    "_actionButton('Update Details',",
    "_actionButton(AppLocalizations.of(context)?.updateDetails ?? 'Update Details',",
  );

  content = content.replaceAll(
    "_detailItem('Name:',",
    "_detailItem(AppLocalizations.of(context)?.nameLabel ?? 'Name: ',",
  );

  content = content.replaceAll(
    "_detailItem('Family Membership ID:',",
    "_detailItem(AppLocalizations.of(context)?.familyMembershipId ?? 'Family Membership ID:',",
  );

  content = content.replaceAll(
    "_detailItem('Phone Number:',",
    "_detailItem(AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number:',",
  );

  content = content.replaceAll(
    "_addressItem('Address:', _userData!),",
    "_addressItem(AppLocalizations.of(context)?.address ?? 'Address:', _userData!),",
  );

  content = content.replaceAll(
    "data['State'] ?? 'Tamil Nadu'",
    "data['State'] ?? (AppLocalizations.of(context)?.tamilNaduLabel ?? 'Tamil Nadu')",
  );
  
  // FAMILY TABLE
  content = content.replaceAll(
    "              columns: const [\n                DataColumn(label: Text('S.No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),\n                DataColumn(label: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),\n                DataColumn(label: Text('Relationship', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),\n                DataColumn(label: Text('Gender', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),\n                DataColumn(label: Text('Age', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),\n              ],",
    "              columns: [\n                DataColumn(label: Text(AppLocalizations.of(context)?.sNo ?? 'S.No', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),\n                DataColumn(label: Text(AppLocalizations.of(context)?.nameHeader ?? 'Name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),\n                DataColumn(label: Text(AppLocalizations.of(context)?.relationshipHeader ?? 'Relationship', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),\n                DataColumn(label: Text(AppLocalizations.of(context)?.genderHeader ?? 'Gender', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),\n                DataColumn(label: Text(AppLocalizations.of(context)?.ageHeader ?? 'Age', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),\n              ],",
  );
  
  // EVENT PARTICIPATION DIALOG
  content = content.replaceAll(
    "Text('Event Participation:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))",
    "Text(AppLocalizations.of(context)?.eventParticipationTitle ?? 'Event Participation:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))",
  );
  
  content = content.replaceAll(
    "                          columns: const [\n                            DataColumn(label: Text('SNo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text('Event Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text('Tax Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text('Paid Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text('Balance Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text('Payment Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                          ],",
    "                          columns: [\n                            DataColumn(label: Text(AppLocalizations.of(context)?.sNo ?? 'SNo', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text(AppLocalizations.of(context)?.eventNameHeader ?? 'Event Name', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text(AppLocalizations.of(context)?.taxAmount ?? 'Tax Amount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text(AppLocalizations.of(context)?.tablePaidAmount ?? 'Paid Amount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text(AppLocalizations.of(context)?.balanceAmount ?? 'Balance Amount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text(AppLocalizations.of(context)?.statusLabel ?? 'Status', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                            DataColumn(label: Text(AppLocalizations.of(context)?.tablePaymentDate ?? 'Payment Date', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),\n                          ],",
  );

  File(path).writeAsStringSync(content);
}
