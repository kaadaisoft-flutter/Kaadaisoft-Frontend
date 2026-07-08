import 'dart:io';

void main() {
  final path = 'lib/presentation/widgets/registration_form.dart';
  var content = File(path).readAsStringSync();
  
  content = content.replaceAll(
    "title: 'Missing Details',",
    "title: AppLocalizations.of(context)?.missingDetailsTitle ?? 'Missing Details',"
  );
  content = content.replaceAll(
    "title: 'Missing Document',",
    "title: AppLocalizations.of(context)?.missingDocumentTitle ?? 'Missing Document',"
  );
  content = content.replaceAll(
    "title: 'Agreement Required',",
    "title: AppLocalizations.of(context)?.agreementRequiredTitle ?? 'Agreement Required',"
  );
  content = content.replaceAll(
    "title: 'Registration Successful',",
    "title: AppLocalizations.of(context)?.registrationSuccessfulTitle ?? 'Registration Successful',"
  );
  content = content.replaceAll(
    "title: 'Registration Failed',",
    "title: AppLocalizations.of(context)?.registrationFailedTitle ?? 'Registration Failed',"
  );
  content = content.replaceAll(
    "title: 'Connection Error',",
    "title: AppLocalizations.of(context)?.connectionErrorTitle ?? 'Connection Error',"
  );
  
  File(path).writeAsStringSync(content);
}
