import 'dart:io';

void main() {
  final files = [
    'lib/presentation/pages/members_content.dart',
    'lib/presentation/pages/received_applications_content.dart'
  ];

  for (final path in files) {
    var content = File(path).readAsStringSync();
    
    final oldReasonsList = """      final List<String> reasons = [
        'Documents are not clear / blurry',
        'Photograph is not clear or incorrect',
        'Duplicate application or existing member',
        'Incomplete Address (Street / Door No missing)',
        'Native address not matching with documents',
        'Community details incomplete',
        'Not eligible (Out of association area)',
        'Other (Enter manually)'
      ];""";
      
    final oldReasonsList2 = """    final List<String> reasons = [
      'Documents are not clear / blurry',
      'Photograph is not clear or incorrect',
      'Duplicate application or existing member',
      'Incomplete Address (Street / Door No missing)',
      'Native address not matching with documents',
      'Community details incomplete',
      'Not eligible (Out of association area)',
      'Other (Enter manually)'
    ];""";

    final newReasonsList = """      final List<String> reasons = [
        AppLocalizations.of(context)?.rejectReasonDocsBlurry ?? 'Documents are not clear / blurry',
        AppLocalizations.of(context)?.rejectReasonPhotoIncorrect ?? 'Photograph is not clear or incorrect',
        AppLocalizations.of(context)?.rejectReasonDuplicate ?? 'Duplicate application or existing member',
        AppLocalizations.of(context)?.rejectReasonIncompleteAddress ?? 'Incomplete Address (Street / Door No missing)',
        AppLocalizations.of(context)?.rejectReasonAddressMismatch ?? 'Native address not matching with documents',
        AppLocalizations.of(context)?.rejectReasonCommunityIncomplete ?? 'Community details incomplete',
        AppLocalizations.of(context)?.rejectReasonNotEligible ?? 'Not eligible (Out of association area)',
        AppLocalizations.of(context)?.otherEnterManually ?? 'Other (Enter manually)'
      ];""";

    content = content.replaceAll(oldReasonsList, newReasonsList);
    content = content.replaceAll(oldReasonsList2, newReasonsList);
    
    content = content.replaceAll(
      "Text('Reject Member: \$name'",
      "Text('\${AppLocalizations.of(context)?.rejectMemberTitle ?? \"Reject Member: \"}\$name'"
    );
    
    content = content.replaceAll(
      "title: const Text('Reject Application')",
      "title: Text(AppLocalizations.of(context)?.rejectApplicationTitle ?? 'Reject Application')"
    );

    content = content.replaceAll(
      "const Text('Please select a reason for rejection:')",
      "Text(AppLocalizations.of(context)?.selectRejectReason ?? 'Please select a reason for rejection:')"
    );

    content = content.replaceAll(
      "hint: '-- Choose a reason --'",
      "hint: AppLocalizations.of(context)?.chooseReason ?? '-- Choose a reason --'"
    );

    content = content.replaceAll(
      "selectedReason == 'Other (Enter manually)'",
      "selectedReason == (AppLocalizations.of(context)?.otherEnterManually ?? 'Other (Enter manually)')"
    );

    content = content.replaceAll(
      "hintText: 'Enter reason manually...'",
      "hintText: AppLocalizations.of(context)?.enterReasonManuallyHint ?? 'Enter reason manually...'"
    );

    content = content.replaceAll(
      "const Text('Cancel', style: TextStyle(color: Colors.black54))",
      "Text(AppLocalizations.of(context)?.cancelDialogBtn ?? 'Cancel', style: const TextStyle(color: Colors.black54))"
    );

    content = content.replaceAll(
      "const Text('Confirm Reject')",
      "Text(AppLocalizations.of(context)?.confirmRejectBtn ?? 'Confirm Reject')"
    );

    content = content.replaceAll(
      "message: 'Please provide a reason'",
      "message: AppLocalizations.of(context)?.pleaseProvideReason ?? 'Please provide a reason'"
    );

    File(path).writeAsStringSync(content);
  }
}
