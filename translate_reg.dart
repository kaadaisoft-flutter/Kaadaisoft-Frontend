import 'dart:io';

void main() {
  final file = File('lib/presentation/widgets/registration_form.dart');
  String content = file.readAsStringSync();

  // Add import
  if (!content.contains("import '../../l10n/app_localizations.dart';")) {
    content = content.replaceFirst(
      "import '../../services/geo_data_service.dart';", 
      "import '../../services/geo_data_service.dart';\nimport '../../l10n/app_localizations.dart';"
    );
  }

  // Add _buildLabelText if missing
  if (!content.contains('Widget _buildLabelText')) {
    final labelTextMethod = '''
  Widget _buildLabelText(String label, {double fontSize = 14}) {
    bool hasAsterisk = label.contains('*');
    String baseLabel = label.replaceAll('*', '').trim();
    String translatedLabel = baseLabel;
    
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      if (baseLabel == 'Relationship' || baseLabel == 'Husband Relationship') translatedLabel = loc.relationshipHeader ?? baseLabel;
      else if (baseLabel == 'Name' || baseLabel == 'Husband Name') translatedLabel = loc.nameHeader ?? baseLabel;
      else if (baseLabel == 'Phone Number' || baseLabel == 'Husband Phone') translatedLabel = loc.phoneNumberLabel ?? baseLabel;
      else if (baseLabel == 'Date Of Birth' || baseLabel == 'Husband Date Of Birth') translatedLabel = loc.dateOfBirthLabel ?? baseLabel;
      else if (baseLabel == 'Gender') translatedLabel = loc.genderHeader ?? baseLabel;
      else if (baseLabel == 'Blood Group') translatedLabel = loc.bloodGroupLabel ?? baseLabel;
      else if (baseLabel == 'Email') translatedLabel = loc.emailLabel ?? baseLabel;
      else if (baseLabel == 'WhatsApp Number') translatedLabel = loc.whatsappNumberLabel ?? baseLabel;
      else if (baseLabel == 'Married') translatedLabel = loc.marriedStatusLabel ?? baseLabel;
      else if (baseLabel == 'Alive Status') translatedLabel = loc.aliveStatusLabel ?? baseLabel;
      else if (baseLabel == 'Valuvu') translatedLabel = loc.valuvuLabel ?? baseLabel;
      else if (baseLabel == 'Thottam') translatedLabel = loc.thottamLabel ?? baseLabel;
      else if (baseLabel == 'Kulam' || baseLabel == 'Husband Kulam') translatedLabel = loc.kulamLabel ?? baseLabel;
      else if (baseLabel == 'Education') translatedLabel = loc.educationLabel ?? baseLabel;
      else if (baseLabel == 'Profession') translatedLabel = loc.professionLabel ?? baseLabel;
      else if (baseLabel == 'District') translatedLabel = loc.districtHeader ?? baseLabel;
      else if (baseLabel == 'Taluk') translatedLabel = loc.talukHeader ?? baseLabel;
      else if (baseLabel == 'Panchayat') translatedLabel = loc.panchayatHeader ?? baseLabel;
      else if (baseLabel == 'Village') translatedLabel = loc.villageUpperHeader ?? baseLabel;
      else if (baseLabel == 'Door No & Street Name') translatedLabel = loc.streetNameLabel ?? baseLabel;
      else if (baseLabel == 'Pin Code' || baseLabel == 'Zip / Postal Code' || baseLabel == 'Zip/Postal Code') translatedLabel = loc.pincodeLabel ?? baseLabel;
      else if (baseLabel == 'Current Address Type') translatedLabel = loc.currentAddressTypeLabel ?? baseLabel;
      else if (baseLabel == 'State') translatedLabel = loc.stateLabel ?? baseLabel;
      else if (baseLabel == 'Country') translatedLabel = loc.countryLabel ?? baseLabel;
      else if (baseLabel == 'City') translatedLabel = loc.cityVillageLabel ?? baseLabel;
      else if (baseLabel == 'Full Address') translatedLabel = loc.fullAddressLabel ?? baseLabel;
      else if (baseLabel == 'Passport size photo' || baseLabel == 'Passport Photo') translatedLabel = loc.passportPhotoLabel ?? baseLabel;
      else if (baseLabel == 'Community Certificate') translatedLabel = loc.communityCertificateLabel ?? baseLabel;
    }

    if (hasAsterisk) {
      return Text.rich(
        TextSpan(
          text: '\$translatedLabel ',
          children: const [
            TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: const Color(0xFF333333)),
      );
    }
    return Text(translatedLabel, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: const Color(0xFF333333)));
  }
}
''';
    content = content.replaceFirst('}\n', '\n$labelTextMethod');
  }

  // Replace all RichText blocks that we identified
  final RegExp richTextRegex = RegExp(r'RichText\([\s\S]*?text:\s*(?:const\s*)?TextSpan\([\s\S]*?text:\s*([^,]+),[\s\S]*?style:\s*(?:const\s*)?TextStyle\([^)]*\),[\s\S]*?(?:children:\s*\[[\s\S]*?\]\s*,)?\s*\)[\s\S]*?\),');
  
  content = content.replaceAllMapped(richTextRegex, (match) {
    String innerText = match.group(1)!;
    if (innerText.contains('label.replaceAll')) {
       return "_buildLabelText(label),";
    } else {
       // e.g. 'Email' or 'Gender'
       // remove quotes
       String label = innerText.replaceAll("'", "");
       if (label == 'Gender') return "_buildLabelText('Gender *'),";
       if (label == 'Email') return "_buildLabelText('Email'),";
       if (label == 'WhatsApp Number') return "_buildLabelText('WhatsApp Number *'),";
       return "_buildLabelText('$label'),";
    }
  });

  // Also replace 'Poondurai Kaadaikulam.org / Registration Form'
  content = content.replaceAll(
    "'Poondurai Kaadaikulam.org / Registration Form'",
    "AppLocalizations.of(context)?.registrationFormTitle ?? 'Poondurai Kaadaikulam.org / Registration Form'"
  );

  // Also replace 'Note: * Indicates Mandatory.'
  content = content.replaceAll(
    "'Note: * Indicates Mandatory.'",
    "AppLocalizations.of(context)?.indicatesMandatory ?? 'Note: * Indicates Mandatory.'"
  );

  // _buildSectionTitle translation
  if (content.contains("Widget _buildSectionTitle(IconData icon, String title) {")) {
    final newSectionTitle = '''
  Widget _buildSectionTitle(IconData icon, String title) {
    String translatedTitle = title;
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      if (title == 'Family Member Details' || title == 'Basic Details') translatedTitle = loc.basicDetails ?? title;
      else if (title == 'Education & Career Details') translatedTitle = loc.educationCareerDetails ?? title;
      else if (title == 'Native Address') translatedTitle = loc.nativeAddress ?? title;
      else if (title == 'Current Address') translatedTitle = loc.currentAddress ?? title;
      else if (title == 'Family Details') translatedTitle = loc.familyDetails ?? title;
      else if (title == 'Documents') translatedTitle = loc.documents ?? title;
      else if (title == 'Terms and Conditions') translatedTitle = loc.termsAndConditionsTitle ?? title;
    }
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: accentGold, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Icon(icon, color: primaryBrown, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(translatedTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBrown))),
    ]);
  }''';
    content = content.replaceFirst(
      RegExp(r'Widget _buildSectionTitle\(IconData icon, String title\) \{[\s\S]*?Expanded\(child: Text\(title, style: const TextStyle\(fontSize: 16, fontWeight: FontWeight\.bold, color: primaryBrown\)\)\),[\s\S]*?\]\);[\s\S]*?\}'),
      newSectionTitle
    );
  }

  // _buildDropdownField translation
  if (content.contains("Widget _buildDropdownField(String label, List<String> options, bool isMobile, {String? value, ValueChanged<String?>? onChanged, FocusNode? focusNode}) {")) {
    final newDropdown = '''
  Widget _buildDropdownField(String label, List<String> options, bool isMobile, {String? value, ValueChanged<String?>? onChanged, FocusNode? focusNode}) {
    bool hasAsterisk = label.contains('*');
    String baseLabel = label.replaceAll('*', '').trim();
    String translatedLabel = baseLabel;
    
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      if (baseLabel == 'Relationship') translatedLabel = loc.relationshipHeader ?? baseLabel;
      else if (baseLabel == 'Gender') translatedLabel = loc.genderHeader ?? baseLabel;
      else if (baseLabel == 'Blood Group') translatedLabel = loc.bloodGroupLabel ?? baseLabel;
      else if (baseLabel == 'Married') translatedLabel = loc.marriedStatusLabel ?? baseLabel;
      else if (baseLabel == 'Kulam') translatedLabel = loc.kulamLabel ?? baseLabel;
      else if (baseLabel == 'Education') translatedLabel = loc.educationLabel ?? baseLabel;
      else if (baseLabel == 'Profession') translatedLabel = loc.professionLabel ?? baseLabel;
      else if (baseLabel == 'District') translatedLabel = loc.districtHeader ?? baseLabel;
      else if (baseLabel == 'Taluk') translatedLabel = loc.talukHeader ?? baseLabel;
      else if (baseLabel == 'Panchayat') translatedLabel = loc.panchayatHeader ?? baseLabel;
      else if (baseLabel == 'Village') translatedLabel = loc.villageUpperHeader ?? baseLabel;
      else if (baseLabel == 'State') translatedLabel = loc.stateLabel ?? baseLabel;
      else if (baseLabel == 'Country') translatedLabel = loc.countryLabel ?? baseLabel;
      else if (baseLabel == 'City') translatedLabel = loc.cityVillageLabel ?? baseLabel;
    }
    String finalLabel = hasAsterisk ? "\$translatedLabel *" : translatedLabel;

    return CustomDropdownSearch(
      label: finalLabel,
      dropdownItems: options,
      value: value,
      onChanged: onChanged,
      requiredMark: label.contains('*'),
    );
  }''';
    content = content.replaceFirst(
      RegExp(r'''Widget _buildDropdownField\(String label, List<String> options, bool isMobile, \{String\? value, ValueChanged<String\?>\? onChanged, FocusNode\? focusNode\}\) \{[\s\S]*?requiredMark: label\.contains\('\*'\),[\s\S]*?\}\);[\s\S]*?\}'''),
      newDropdown
    );
  }

  // _buildRadioField translation
  if (content.contains("Widget _buildRadioField(String label, List<String> options, bool isMobile, {String? value, ValueChanged<String?>? onChanged, FocusNode? focusNode}) {")) {
    final newRadio = '''
  Widget _buildRadioField(String label, List<String> options, bool isMobile, {String? value, ValueChanged<String?>? onChanged, FocusNode? focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label),
        const SizedBox(height: 4),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: options.map((o) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: o,
                groupValue: value,
                onChanged: onChanged,
                activeColor: primaryBrown,
                focusNode: focusNode,
              ),
              Builder(
                builder: (context) {
                  String display = o;
                  final loc = AppLocalizations.of(context);
                  if (loc != null) {
                    if (o == 'Male') display = loc.maleLabel ?? o;
                    else if (o == 'Female') display = loc.femaleLabel ?? o;
                    else if (o == 'Others' || o == 'Other') display = loc.otherLabel ?? o;
                    else if (o == 'Yes') display = loc.yesLabel ?? o;
                    else if (o == 'No') display = loc.noLabel ?? o;
                    else if (o == 'Alive') display = loc.aliveLabel ?? o;
                    else if (o == 'Dead') display = loc.deadLabel ?? o;
                    else if (o == 'Tamil Nadu') display = loc.tamilNaduLabel ?? o;
                    else if (o == 'Other State') display = loc.otherStateLabel ?? o;
                    else if (o == 'NRI') display = loc.nriLabel ?? o;
                  }
                  return Text(display, style: const TextStyle(fontSize: 14));
                }
              ),
            ],
          )).toList(),
        ),
      ],
    );
  }''';
    content = content.replaceFirst(
      RegExp(r'Widget _buildRadioField\(String label, List<String> options, bool isMobile, \{String\? value, ValueChanged<String\?>\? onChanged, FocusNode\? focusNode\}\) \{[\s\S]*?Text\(o, style: const TextStyle\(fontSize: 14\)\),[\s\S]*?\]\);[\s\S]*?\}'),
      newRadio
    );
  }

  file.writeAsStringSync(content);
}
