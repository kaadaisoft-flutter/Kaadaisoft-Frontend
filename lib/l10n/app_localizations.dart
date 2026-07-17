import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Poondurai Kaadai Kulam'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @myDetails.
  ///
  /// In en, this message translates to:
  /// **'My Details'**
  String get myDetails;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @registerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get registerPrompt;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @coordinatorDetails.
  ///
  /// In en, this message translates to:
  /// **'My Coordinator Details'**
  String get coordinatorDetails;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @copyrightText.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Poondurai Kaadai Kulam. All rights reserved.'**
  String get copyrightText;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @forgotPasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered mobile number. We will send an OTP to the email address linked to your account.'**
  String get forgotPasswordInstruction;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @resetPasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit OTP sent to your email and your new password.'**
  String get resetPasswordInstruction;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otpHint;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordHint;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordButton;

  /// No description provided for @idCardBenefits.
  ///
  /// In en, this message translates to:
  /// **'ID Card Benefits'**
  String get idCardBenefits;

  /// No description provided for @coordinators.
  ///
  /// In en, this message translates to:
  /// **'Coordinators'**
  String get coordinators;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @updateRequests.
  ///
  /// In en, this message translates to:
  /// **'Update Requests'**
  String get updateRequests;

  /// No description provided for @paymentRequests.
  ///
  /// In en, this message translates to:
  /// **'Payment Requests'**
  String get paymentRequests;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search ...'**
  String get searchPlaceholder;

  /// No description provided for @coordinatorRole.
  ///
  /// In en, this message translates to:
  /// **'Coordinator'**
  String get coordinatorRole;

  /// No description provided for @memberRole.
  ///
  /// In en, this message translates to:
  /// **'MEMBER'**
  String get memberRole;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name: '**
  String get nameLabel;

  /// No description provided for @mobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobileLabel;

  /// No description provided for @villageLabel.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get villageLabel;

  /// No description provided for @paymentPendingDetails.
  ///
  /// In en, this message translates to:
  /// **'My Payment Pending Details'**
  String get paymentPendingDetails;

  /// No description provided for @unpaidDetails.
  ///
  /// In en, this message translates to:
  /// **'Unpaid Details'**
  String get unpaidDetails;

  /// No description provided for @paidEvents.
  ///
  /// In en, this message translates to:
  /// **'Paid Events'**
  String get paidEvents;

  /// No description provided for @totalPendingAmount.
  ///
  /// In en, this message translates to:
  /// **'TOTAL PENDING AMOUNT'**
  String get totalPendingAmount;

  /// No description provided for @totalPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'TOTAL PAID AMOUNT'**
  String get totalPaidAmount;

  /// No description provided for @pendingBalanceFromAllEvents.
  ///
  /// In en, this message translates to:
  /// **'Pending balance from all events'**
  String get pendingBalanceFromAllEvents;

  /// No description provided for @paidBalanceFromAllEvents.
  ///
  /// In en, this message translates to:
  /// **'Total amount paid for all events'**
  String get paidBalanceFromAllEvents;

  /// No description provided for @unPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'UN PAID'**
  String get unPaidLabel;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paidLabel;

  /// No description provided for @taxAmount.
  ///
  /// In en, this message translates to:
  /// **'TAX AMOUNT'**
  String get taxAmount;

  /// No description provided for @balanceAmount.
  ///
  /// In en, this message translates to:
  /// **'BALANCE AMOUNT'**
  String get balanceAmount;

  /// No description provided for @familyMembershipId.
  ///
  /// In en, this message translates to:
  /// **'Family Membership ID:'**
  String get familyMembershipId;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number:'**
  String get phoneNumber;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address:'**
  String get address;

  /// No description provided for @eventParticipation.
  ///
  /// In en, this message translates to:
  /// **'Event Participation'**
  String get eventParticipation;

  /// No description provided for @updateDetails.
  ///
  /// In en, this message translates to:
  /// **'Update Details'**
  String get updateDetails;

  /// No description provided for @addFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Add Family Member'**
  String get addFamilyMember;

  /// No description provided for @familyMembersList.
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get familyMembersList;

  /// No description provided for @tableView.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get tableView;

  /// No description provided for @treeView.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get treeView;

  /// No description provided for @sNo.
  ///
  /// In en, this message translates to:
  /// **'S.NO'**
  String get sNo;

  /// No description provided for @nameHeader.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameHeader;

  /// No description provided for @relationshipHeader.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationshipHeader;

  /// No description provided for @genderHeader.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderHeader;

  /// No description provided for @ageHeader.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageHeader;

  /// No description provided for @actionHeader.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get actionHeader;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @eventsManagement.
  ///
  /// In en, this message translates to:
  /// **'Events Management'**
  String get eventsManagement;

  /// No description provided for @upcomingTab.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingTab;

  /// No description provided for @currentTab.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentTab;

  /// No description provided for @completedTab.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTab;

  /// No description provided for @eventNameHeader.
  ///
  /// In en, this message translates to:
  /// **'EVENT NAME'**
  String get eventNameHeader;

  /// No description provided for @bannerHeader.
  ///
  /// In en, this message translates to:
  /// **'BANNER'**
  String get bannerHeader;

  /// No description provided for @durationHeader.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get durationHeader;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From:'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To:'**
  String get toDate;

  /// No description provided for @totalEvents.
  ///
  /// In en, this message translates to:
  /// **'Total Events:'**
  String get totalEvents;

  /// No description provided for @coordinatorsManagement.
  ///
  /// In en, this message translates to:
  /// **'Coordinators Management'**
  String get coordinatorsManagement;

  /// No description provided for @totalCoordinators.
  ///
  /// In en, this message translates to:
  /// **'Total Coordinators:'**
  String get totalCoordinators;

  /// No description provided for @filterBtn.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterBtn;

  /// No description provided for @assignBtn.
  ///
  /// In en, this message translates to:
  /// **'Assign Coordinator'**
  String get assignBtn;

  /// No description provided for @userIdHeader.
  ///
  /// In en, this message translates to:
  /// **'USER ID'**
  String get userIdHeader;

  /// No description provided for @districtHeader.
  ///
  /// In en, this message translates to:
  /// **'DISTRICT'**
  String get districtHeader;

  /// No description provided for @talukHeader.
  ///
  /// In en, this message translates to:
  /// **'TALUK'**
  String get talukHeader;

  /// No description provided for @panchayatHeader.
  ///
  /// In en, this message translates to:
  /// **'PANCHAYAT'**
  String get panchayatHeader;

  /// No description provided for @villageUpperHeader.
  ///
  /// In en, this message translates to:
  /// **'VILLAGE'**
  String get villageUpperHeader;

  /// No description provided for @assignedVillageHeader.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED VILLAGE'**
  String get assignedVillageHeader;

  /// No description provided for @searchHintText.
  ///
  /// In en, this message translates to:
  /// **'Search Name/ID/Mobile'**
  String get searchHintText;

  /// No description provided for @showingPage.
  ///
  /// In en, this message translates to:
  /// **'Showing page'**
  String get showingPage;

  /// No description provided for @ofPage.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofPage;

  /// No description provided for @statCoordinators.
  ///
  /// In en, this message translates to:
  /// **'COORDINATORS'**
  String get statCoordinators;

  /// No description provided for @statTotalMembers.
  ///
  /// In en, this message translates to:
  /// **'TOTAL MEMBERS'**
  String get statTotalMembers;

  /// No description provided for @statApprovals.
  ///
  /// In en, this message translates to:
  /// **'APPROVALS'**
  String get statApprovals;

  /// No description provided for @totalMembersHeader.
  ///
  /// In en, this message translates to:
  /// **'Total Members: '**
  String get totalMembersHeader;

  /// No description provided for @uploadBulkDataBtn.
  ///
  /// In en, this message translates to:
  /// **'Upload Bulk Data'**
  String get uploadBulkDataBtn;

  /// No description provided for @downloadBtn.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadBtn;

  /// No description provided for @addBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addBtn;

  /// No description provided for @familyIdHeader.
  ///
  /// In en, this message translates to:
  /// **'FAMILY ID'**
  String get familyIdHeader;

  /// No description provided for @roleHeader.
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get roleHeader;

  /// No description provided for @bulkPaymentUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk Payment Upload'**
  String get bulkPaymentUploadTitle;

  /// No description provided for @uploadCsvBtn.
  ///
  /// In en, this message translates to:
  /// **'Upload CSV'**
  String get uploadCsvBtn;

  /// No description provided for @applyFilterBtn.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get applyFilterBtn;

  /// No description provided for @eventYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Year'**
  String get eventYearLabel;

  /// No description provided for @eventLabel.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get eventLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @reportStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'Report Status Filter:'**
  String get reportStatusFilter;

  /// No description provided for @chooseEventYear.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE EVENT YEAR'**
  String get chooseEventYear;

  /// No description provided for @chooseYearHint.
  ///
  /// In en, this message translates to:
  /// **'Choose Year'**
  String get chooseYearHint;

  /// No description provided for @chooseEvents.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE EVENTS'**
  String get chooseEvents;

  /// No description provided for @chooseEventHint.
  ///
  /// In en, this message translates to:
  /// **'Choose Event'**
  String get chooseEventHint;

  /// No description provided for @paymentStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT STATUS'**
  String get paymentStatusFilter;

  /// No description provided for @paidUsers.
  ///
  /// In en, this message translates to:
  /// **'Paid Users'**
  String get paidUsers;

  /// No description provided for @unpaidUsers.
  ///
  /// In en, this message translates to:
  /// **'Unpaid Users'**
  String get unpaidUsers;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @downloadExcelBtn.
  ///
  /// In en, this message translates to:
  /// **'Download Excel'**
  String get downloadExcelBtn;

  /// No description provided for @familyMembershipIdHeader.
  ///
  /// In en, this message translates to:
  /// **'FAMILYMEMBERSHIP ID'**
  String get familyMembershipIdHeader;

  /// No description provided for @userNameHeader.
  ///
  /// In en, this message translates to:
  /// **'USER NAME'**
  String get userNameHeader;

  /// No description provided for @phoneNoHeader.
  ///
  /// In en, this message translates to:
  /// **'PHONE NO'**
  String get phoneNoHeader;

  /// No description provided for @eventMoneyHeader.
  ///
  /// In en, this message translates to:
  /// **'EVENTMONEY'**
  String get eventMoneyHeader;

  /// No description provided for @paidCashHeader.
  ///
  /// In en, this message translates to:
  /// **'PAIDCASH'**
  String get paidCashHeader;

  /// No description provided for @pendingHeader.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pendingHeader;

  /// No description provided for @lastPaidHeader.
  ///
  /// In en, this message translates to:
  /// **'LASTPAID'**
  String get lastPaidHeader;

  /// No description provided for @receivedApplicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Received Applications'**
  String get receivedApplicationsTitle;

  /// No description provided for @memberNameHeader.
  ///
  /// In en, this message translates to:
  /// **'MEMBER NAME'**
  String get memberNameHeader;

  /// No description provided for @memberIdHeader.
  ///
  /// In en, this message translates to:
  /// **'MEMBER ID'**
  String get memberIdHeader;

  /// No description provided for @noPendingApplications.
  ///
  /// In en, this message translates to:
  /// **'No pending applications found.'**
  String get noPendingApplications;

  /// No description provided for @memberUpdateRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Member Update Requests'**
  String get memberUpdateRequestsTitle;

  /// No description provided for @familyHeadHeader.
  ///
  /// In en, this message translates to:
  /// **'FAMILY HEAD'**
  String get familyHeadHeader;

  /// No description provided for @noPendingUpdateRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending update requests.'**
  String get noPendingUpdateRequests;

  /// No description provided for @updateMyDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Update My Details: '**
  String get updateMyDetailsTitle;

  /// No description provided for @updateMemberDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Member Details: '**
  String get updateMemberDetailsTitle;

  /// No description provided for @basicDetails.
  ///
  /// In en, this message translates to:
  /// **'Basic Details'**
  String get basicDetails;

  /// No description provided for @educationCareerDetails.
  ///
  /// In en, this message translates to:
  /// **'Education & Career Details'**
  String get educationCareerDetails;

  /// No description provided for @nativeAddress.
  ///
  /// In en, this message translates to:
  /// **'Native Address'**
  String get nativeAddress;

  /// No description provided for @currentAddress.
  ///
  /// In en, this message translates to:
  /// **'Current Address'**
  String get currentAddress;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date Of Birth'**
  String get dateOfBirthLabel;

  /// No description provided for @bloodGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get bloodGroupLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @whatsappNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number'**
  String get whatsappNumberLabel;

  /// No description provided for @marriedStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get marriedStatusLabel;

  /// No description provided for @aliveStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Alive Status'**
  String get aliveStatusLabel;

  /// No description provided for @valuvuLabel.
  ///
  /// In en, this message translates to:
  /// **'Valuvu'**
  String get valuvuLabel;

  /// No description provided for @thottamLabel.
  ///
  /// In en, this message translates to:
  /// **'Thottam'**
  String get thottamLabel;

  /// No description provided for @kulamLabel.
  ///
  /// In en, this message translates to:
  /// **'Kulam'**
  String get kulamLabel;

  /// No description provided for @educationLabel.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get educationLabel;

  /// No description provided for @professionLabel.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get professionLabel;

  /// No description provided for @streetNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Door No & Street Name'**
  String get streetNameLabel;

  /// No description provided for @pincodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pin Code'**
  String get pincodeLabel;

  /// No description provided for @zipPostalCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Zip / Postal Code'**
  String get zipPostalCodeLabel;

  /// No description provided for @currentAddressTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Address Type'**
  String get currentAddressTypeLabel;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @cityVillageLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityVillageLabel;

  /// No description provided for @fullAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddressLabel;

  /// No description provided for @maleLabel.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get maleLabel;

  /// No description provided for @femaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get femaleLabel;

  /// No description provided for @otherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherLabel;

  /// No description provided for @yesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesLabel;

  /// No description provided for @noLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noLabel;

  /// No description provided for @aliveLabel.
  ///
  /// In en, this message translates to:
  /// **'Alive'**
  String get aliveLabel;

  /// No description provided for @deadLabel.
  ///
  /// In en, this message translates to:
  /// **'Dead'**
  String get deadLabel;

  /// No description provided for @tamilNaduLabel.
  ///
  /// In en, this message translates to:
  /// **'Tamil Nadu'**
  String get tamilNaduLabel;

  /// No description provided for @otherStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Other State'**
  String get otherStateLabel;

  /// No description provided for @nriLabel.
  ///
  /// In en, this message translates to:
  /// **'NRI'**
  String get nriLabel;

  /// No description provided for @sameAsPhone.
  ///
  /// In en, this message translates to:
  /// **'Same as Phone'**
  String get sameAsPhone;

  /// No description provided for @saveDetailsBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Details'**
  String get saveDetailsBtn;

  /// No description provided for @passportPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Passport Photo'**
  String get passportPhotoLabel;

  /// No description provided for @communityCertificateLabel.
  ///
  /// In en, this message translates to:
  /// **'Community Certificate'**
  String get communityCertificateLabel;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file...'**
  String get chooseFile;

  /// No description provided for @confirmDetailsCorrect.
  ///
  /// In en, this message translates to:
  /// **'I confirm that the above details are correct.'**
  String get confirmDetailsCorrect;

  /// No description provided for @updateFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Update Family Member'**
  String get updateFamilyMember;

  /// No description provided for @confirmUpdatedDetails.
  ///
  /// In en, this message translates to:
  /// **'I confirm that the updated details are correct.'**
  String get confirmUpdatedDetails;

  /// No description provided for @existingFile.
  ///
  /// In en, this message translates to:
  /// **'Existing file: '**
  String get existingFile;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// No description provided for @andText.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andText;

  /// No description provided for @registerBtn.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerBtn;

  /// No description provided for @pleaseAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms and Conditions to proceed.'**
  String get pleaseAgreeToTerms;

  /// No description provided for @registrationFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Poondurai Kaadaikulam.org / Registration Form'**
  String get registrationFormTitle;

  /// No description provided for @indicatesMandatory.
  ///
  /// In en, this message translates to:
  /// **'Note: * Indicates Mandatory.'**
  String get indicatesMandatory;

  /// No description provided for @termsAndConditionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditionsTitle;

  /// No description provided for @familyDetails.
  ///
  /// In en, this message translates to:
  /// **'Family Details'**
  String get familyDetails;

  /// No description provided for @privacySubTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy and data security are our top priorities.'**
  String get privacySubTitle;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'LAST UPDATED: MAY 07, 2026'**
  String get lastUpdated;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'At **Poondurai Kaadai Kulam**, we are committed to protecting your personal data and ensuring that your privacy is respected. This policy explains how we collect, use, and safeguard your information.'**
  String get privacyIntro;

  /// No description provided for @privacySec1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Information We Collect'**
  String get privacySec1Title;

  /// No description provided for @privacySec1Desc.
  ///
  /// In en, this message translates to:
  /// **'We collect information you provide directly to us when you register for an account, including:'**
  String get privacySec1Desc;

  /// No description provided for @privacySec1Item1Title.
  ///
  /// In en, this message translates to:
  /// **'Personal Identity'**
  String get privacySec1Item1Title;

  /// No description provided for @privacySec1Item1Desc.
  ///
  /// In en, this message translates to:
  /// **'Full name and photographs.'**
  String get privacySec1Item1Desc;

  /// No description provided for @privacySec1Item2Title.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get privacySec1Item2Title;

  /// No description provided for @privacySec1Item2Desc.
  ///
  /// In en, this message translates to:
  /// **'Mobile number and physical address.'**
  String get privacySec1Item2Desc;

  /// No description provided for @privacySec1Item3Title.
  ///
  /// In en, this message translates to:
  /// **'Community Data'**
  String get privacySec1Item3Title;

  /// No description provided for @privacySec1Item3Desc.
  ///
  /// In en, this message translates to:
  /// **'Family membership details and role assignments.'**
  String get privacySec1Item3Desc;

  /// No description provided for @privacySec2Title.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Your Information'**
  String get privacySec2Title;

  /// No description provided for @privacySec2Desc.
  ///
  /// In en, this message translates to:
  /// **'The information we collect is strictly used for community management purposes:'**
  String get privacySec2Desc;

  /// No description provided for @privacySec2Item1.
  ///
  /// In en, this message translates to:
  /// **'Verifying community membership and user authenticity.'**
  String get privacySec2Item1;

  /// No description provided for @privacySec2Item2.
  ///
  /// In en, this message translates to:
  /// **'Processing tax payments and generating official receipts.'**
  String get privacySec2Item2;

  /// No description provided for @privacySec2Item3.
  ///
  /// In en, this message translates to:
  /// **'Coordinating community events and member updates.'**
  String get privacySec2Item3;

  /// No description provided for @privacySec2Item4.
  ///
  /// In en, this message translates to:
  /// **'Maintaining a secure and transparent community registry.'**
  String get privacySec2Item4;

  /// No description provided for @privacySec3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Data Sharing & Disclosure'**
  String get privacySec3Title;

  /// No description provided for @privacySec3Desc.
  ///
  /// In en, this message translates to:
  /// **'We do not sell, trade, or rent your personal information to third parties. Your data is only visible to authorized platform administrators and coordinators for verification purposes within the Poondurai Kaadai Kulam community ecosystem.'**
  String get privacySec3Desc;

  /// No description provided for @privacySec4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Security Measures'**
  String get privacySec4Title;

  /// No description provided for @privacySec4Desc.
  ///
  /// In en, this message translates to:
  /// **'We implement a variety of security measures to maintain the safety of your personal information. Your data is stored on secure servers and access is restricted to authorized personnel only. While we strive for absolute security, please note that no method of digital storage is 100% impenetrable.'**
  String get privacySec4Desc;

  /// No description provided for @privacySec5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Your Data Rights'**
  String get privacySec5Title;

  /// No description provided for @privacySec5Desc.
  ///
  /// In en, this message translates to:
  /// **'You have the right to access and update your information at any time. If you wish to correct your data or request account closure, you can manage your profile settings or contact the administrator directly.'**
  String get privacySec5Desc;

  /// No description provided for @privacySec6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Cookies & Tracking'**
  String get privacySec6Title;

  /// No description provided for @privacySec6Desc.
  ///
  /// In en, this message translates to:
  /// **'Our platform may use essential session cookies to keep you logged in and ensure the website functions correctly. We do not use tracking cookies for advertising purposes.'**
  String get privacySec6Desc;

  /// No description provided for @privacySec7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Changes to This Policy'**
  String get privacySec7Title;

  /// No description provided for @privacySec7Desc.
  ///
  /// In en, this message translates to:
  /// **'We may update this Privacy Policy to reflect changes in our practices. Any updates will be posted on this page with an updated \"Last Updated\" date.'**
  String get privacySec7Desc;

  /// No description provided for @privacySec8Title.
  ///
  /// In en, this message translates to:
  /// **'8. Contact Our Team'**
  String get privacySec8Title;

  /// No description provided for @privacySec8Desc.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions or concerns regarding this Privacy Policy or your data, please reach out to the platform administrator.'**
  String get privacySec8Desc;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Poondurai Kaadai Kulam. All rights reserved.'**
  String get allRightsReserved;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @termsSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal agreement for using Poondurai Kaadai Kulam platform'**
  String get termsSubTitle;

  /// No description provided for @termsIntro.
  ///
  /// In en, this message translates to:
  /// **'Please read these terms and conditions carefully before using our services. By using our platform, you agree to comply with and be bound by these terms.'**
  String get termsIntro;

  /// No description provided for @termsSec1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Agreement to Terms'**
  String get termsSec1Title;

  /// No description provided for @termsSec1Desc.
  ///
  /// In en, this message translates to:
  /// **'By accessing or using our website, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree with any part of these terms, you must not use our services. This agreement constitutes a legally binding contract between you and Poondurai Kaadai Kulam.'**
  String get termsSec1Desc;

  /// No description provided for @termsSec2Title.
  ///
  /// In en, this message translates to:
  /// **'2. User Registration'**
  String get termsSec2Title;

  /// No description provided for @termsSec2Desc.
  ///
  /// In en, this message translates to:
  /// **'To access certain features of the website, you are required to register for an account. You agree to provide accurate, current, and complete information during the registration process (Mobile Number, Address, etc.) and to update such information to keep it accurate, current, and complete.'**
  String get termsSec2Desc;

  /// No description provided for @termsSec3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Responsibility for Account'**
  String get termsSec3Title;

  /// No description provided for @termsSec3Desc.
  ///
  /// In en, this message translates to:
  /// **'You are solely responsible for maintaining the confidentiality of your account password and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account or any other breach of security.'**
  String get termsSec3Desc;

  /// No description provided for @termsSec4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Use of Information'**
  String get termsSec4Title;

  /// No description provided for @termsSec4Desc.
  ///
  /// In en, this message translates to:
  /// **'The information provided on this platform is for community management and membership purposes. While we strive to maintain high data accuracy, we do not warrant the completeness or reliability of user-submitted information at all times.'**
  String get termsSec4Desc;

  /// No description provided for @termsSec5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Prohibited Activities'**
  String get termsSec5Title;

  /// No description provided for @termsSec5Desc.
  ///
  /// In en, this message translates to:
  /// **'You agree not to use the platform for any unlawful purpose or any purpose prohibited under these Terms. Prohibited activities include but are not limited to: uploading false documents, attempting to breach security, or harassing other community members.'**
  String get termsSec5Desc;

  /// No description provided for @termsSec6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Intellectual Property'**
  String get termsSec6Title;

  /// No description provided for @termsSec6Desc.
  ///
  /// In en, this message translates to:
  /// **'All content included on this website, such as custom scripts, branding, UI designs, and logos, is the property of Poondurai Kaadai Kulam or its content suppliers and is protected by copyright laws.'**
  String get termsSec6Desc;

  /// No description provided for @termsSec7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Termination of Use'**
  String get termsSec7Title;

  /// No description provided for @termsSec7Desc.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to terminate or suspend your access to the platform without notice, for any conduct that we, in our sole discretion, believe is in violation of any applicable law or is harmful to the interests of the community.'**
  String get termsSec7Desc;

  /// No description provided for @termsSec8Title.
  ///
  /// In en, this message translates to:
  /// **'8. Changes to Terms'**
  String get termsSec8Title;

  /// No description provided for @termsSec8Desc.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to modify these Terms and Conditions at any time. Changes will be effective immediately upon posting. Your continued use of the website following changes will mean that you accept and agree to the modified terms.'**
  String get termsSec8Desc;

  /// No description provided for @termsSec9Title.
  ///
  /// In en, this message translates to:
  /// **'9. Contact Support'**
  String get termsSec9Title;

  /// No description provided for @termsSec9Desc.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions about these Terms and Conditions, please contact the administrator via the official community channels.'**
  String get termsSec9Desc;

  /// No description provided for @missingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing Details'**
  String get missingDetailsTitle;

  /// No description provided for @missingDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing Document'**
  String get missingDocumentTitle;

  /// No description provided for @agreementRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement Required'**
  String get agreementRequiredTitle;

  /// No description provided for @registrationSuccessfulTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Successful'**
  String get registrationSuccessfulTitle;

  /// No description provided for @registrationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Failed'**
  String get registrationFailedTitle;

  /// No description provided for @connectionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionErrorTitle;

  /// No description provided for @rejectMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Member: '**
  String get rejectMemberTitle;

  /// No description provided for @rejectApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Application'**
  String get rejectApplicationTitle;

  /// No description provided for @selectRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason for rejection:'**
  String get selectRejectReason;

  /// No description provided for @chooseReason.
  ///
  /// In en, this message translates to:
  /// **'-- Choose a reason --'**
  String get chooseReason;

  /// No description provided for @cancelDialogBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelDialogBtn;

  /// No description provided for @confirmRejectBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reject'**
  String get confirmRejectBtn;

  /// No description provided for @otherEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Other (Enter manually)'**
  String get otherEnterManually;

  /// No description provided for @enterReasonManuallyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter reason manually...'**
  String get enterReasonManuallyHint;

  /// No description provided for @rejectReasonDocsBlurry.
  ///
  /// In en, this message translates to:
  /// **'Documents are not clear / blurry'**
  String get rejectReasonDocsBlurry;

  /// No description provided for @rejectReasonPhotoIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Photograph is not clear or incorrect'**
  String get rejectReasonPhotoIncorrect;

  /// No description provided for @rejectReasonDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate application or existing member'**
  String get rejectReasonDuplicate;

  /// No description provided for @rejectReasonIncompleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Incomplete Address (Street / Door No missing)'**
  String get rejectReasonIncompleteAddress;

  /// No description provided for @rejectReasonAddressMismatch.
  ///
  /// In en, this message translates to:
  /// **'Native address not matching with documents'**
  String get rejectReasonAddressMismatch;

  /// No description provided for @rejectReasonCommunityIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Community details incomplete'**
  String get rejectReasonCommunityIncomplete;

  /// No description provided for @rejectReasonNotEligible.
  ///
  /// In en, this message translates to:
  /// **'Not eligible (Out of association area)'**
  String get rejectReasonNotEligible;

  /// No description provided for @pleaseProvideReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason'**
  String get pleaseProvideReason;

  /// No description provided for @memberDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Member Details:'**
  String get memberDetailsTitle;

  /// No description provided for @downloadIdCardBtn.
  ///
  /// In en, this message translates to:
  /// **'Download ID Card'**
  String get downloadIdCardBtn;

  /// No description provided for @tablePaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get tablePaidAmount;

  /// No description provided for @advancedSearchFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Search Filters'**
  String get advancedSearchFiltersTitle;

  /// No description provided for @specificSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Specific Search (Name, Membership ID, Mobile, Email, Aadhar):'**
  String get specificSearchTitle;

  /// No description provided for @specificSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type Name, Email, Mobile, Aadhar or Membership ID...'**
  String get specificSearchHint;

  /// No description provided for @specificSearchInfo.
  ///
  /// In en, this message translates to:
  /// **'Search by Name, Email, Mobile, Aadhar Card, or Membership ID directly.'**
  String get specificSearchInfo;

  /// No description provided for @clearFiltersBtn.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFiltersBtn;

  /// No description provided for @closeBtn.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeBtn;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @tablePaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get tablePaymentDate;

  /// No description provided for @eventParticipationTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Participation:'**
  String get eventParticipationTitle;

  /// No description provided for @assignCoordinatorHeader.
  ///
  /// In en, this message translates to:
  /// **'Assign Coordinator'**
  String get assignCoordinatorHeader;

  /// No description provided for @searchMember.
  ///
  /// In en, this message translates to:
  /// **'Search Member'**
  String get searchMember;

  /// No description provided for @searchCoordinator.
  ///
  /// In en, this message translates to:
  /// **'Search Coordinator'**
  String get searchCoordinator;

  /// No description provided for @searchNewMember.
  ///
  /// In en, this message translates to:
  /// **'Search New Member'**
  String get searchNewMember;

  /// No description provided for @districtsLabel.
  ///
  /// In en, this message translates to:
  /// **'Districts:'**
  String get districtsLabel;

  /// No description provided for @taluksLabel.
  ///
  /// In en, this message translates to:
  /// **'Taluks:'**
  String get taluksLabel;

  /// No description provided for @panchayatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Panchayats:'**
  String get panchayatsLabel;

  /// No description provided for @villagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Villages:'**
  String get villagesLabel;

  /// No description provided for @chooseDistrict.
  ///
  /// In en, this message translates to:
  /// **'Choose District'**
  String get chooseDistrict;

  /// No description provided for @chooseTaluk.
  ///
  /// In en, this message translates to:
  /// **'Choose Taluk'**
  String get chooseTaluk;

  /// No description provided for @choosePanchayat.
  ///
  /// In en, this message translates to:
  /// **'Choose Panchayat'**
  String get choosePanchayat;

  /// No description provided for @chooseVillage.
  ///
  /// In en, this message translates to:
  /// **'Choose Village'**
  String get chooseVillage;

  /// No description provided for @noVillagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No villages available'**
  String get noVillagesAvailable;

  /// No description provided for @assignAction.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignAction;

  /// No description provided for @reassignCoordinatorHeader.
  ///
  /// In en, this message translates to:
  /// **'Reassign Coordinator'**
  String get reassignCoordinatorHeader;

  /// No description provided for @reassignAction.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassignAction;

  /// No description provided for @removeCoordinatorHeader.
  ///
  /// In en, this message translates to:
  /// **'Remove Coordinator'**
  String get removeCoordinatorHeader;

  /// No description provided for @removeCoordinatorAction.
  ///
  /// In en, this message translates to:
  /// **'Remove Coordinator'**
  String get removeCoordinatorAction;

  /// No description provided for @addVillageHeader.
  ///
  /// In en, this message translates to:
  /// **'Add Village'**
  String get addVillageHeader;

  /// No description provided for @addVillageAction.
  ///
  /// In en, this message translates to:
  /// **'Add Village'**
  String get addVillageAction;

  /// No description provided for @removeVillageHeader.
  ///
  /// In en, this message translates to:
  /// **'Remove Village'**
  String get removeVillageHeader;

  /// No description provided for @removeVillageAction.
  ///
  /// In en, this message translates to:
  /// **'Remove Village'**
  String get removeVillageAction;

  /// No description provided for @assignCoordinatorsBreadcrumb.
  ///
  /// In en, this message translates to:
  /// **' / Assigncoordinators'**
  String get assignCoordinatorsBreadcrumb;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'PAID AMOUNT'**
  String get paidAmount;

  /// No description provided for @myPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'My Payment Details'**
  String get myPaymentDetails;

  /// No description provided for @myInfo.
  ///
  /// In en, this message translates to:
  /// **'My Info'**
  String get myInfo;

  /// No description provided for @nameLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Name:'**
  String get nameLabelShort;

  /// No description provided for @idLabelShort.
  ///
  /// In en, this message translates to:
  /// **'ID:'**
  String get idLabelShort;

  /// No description provided for @addressLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Address:'**
  String get addressLabelShort;

  /// No description provided for @eventInfo.
  ///
  /// In en, this message translates to:
  /// **'Event Info'**
  String get eventInfo;

  /// No description provided for @payAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay Amount *'**
  String get payAmountLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: '**
  String get dateLabel;

  /// No description provided for @rsSummary.
  ///
  /// In en, this message translates to:
  /// **'Rs Summary'**
  String get rsSummary;

  /// No description provided for @totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmountLabel;

  /// No description provided for @alreadyPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Already Paid'**
  String get alreadyPaidLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodLabel;

  /// No description provided for @bankMethod.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankMethod;

  /// No description provided for @chequeMethod.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get chequeMethod;

  /// No description provided for @upiMethod.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get upiMethod;

  /// No description provided for @cashMethod.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashMethod;

  /// No description provided for @chooseBankLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose Bank *'**
  String get chooseBankLabel;

  /// No description provided for @otherBankNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Other Bank Name *'**
  String get otherBankNameLabel;

  /// No description provided for @upiTransactionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'UPI Transaction ID *'**
  String get upiTransactionIdLabel;

  /// No description provided for @referenceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference ID *'**
  String get referenceIdLabel;

  /// No description provided for @chequeNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Cheque Number *'**
  String get chequeNumberLabel;

  /// No description provided for @saveReceiptBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Receipt'**
  String get saveReceiptBtn;

  /// No description provided for @savingBtn.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingBtn;

  /// No description provided for @confirmationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation Required'**
  String get confirmationRequiredTitle;

  /// No description provided for @confirmDetailsBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Please confirm the details before saving.'**
  String get confirmDetailsBeforeSaving;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successTitle;

  /// No description provided for @receiptSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt saved successfully.'**
  String get receiptSavedSuccess;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @unableToSaveReceipt.
  ///
  /// In en, this message translates to:
  /// **'Unable to save receipt.'**
  String get unableToSaveReceipt;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid Amount'**
  String get invalidAmount;

  /// No description provided for @chooseBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose bank'**
  String get chooseBankTitle;

  /// No description provided for @searchBankHint.
  ///
  /// In en, this message translates to:
  /// **'Search bank...'**
  String get searchBankHint;

  /// No description provided for @noBanksFound.
  ///
  /// In en, this message translates to:
  /// **'No banks found'**
  String get noBanksFound;

  /// No description provided for @requiredValidation.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredValidation;

  /// No description provided for @greaterThanZeroValidation.
  ///
  /// In en, this message translates to:
  /// **'Must be greater than 0'**
  String get greaterThanZeroValidation;

  /// No description provided for @exceedBalanceValidation.
  ///
  /// In en, this message translates to:
  /// **'Cannot exceed balance'**
  String get exceedBalanceValidation;

  /// No description provided for @receiverInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Receiver Info'**
  String get receiverInfoTitle;

  /// No description provided for @personReceivedMoneyLabel.
  ///
  /// In en, this message translates to:
  /// **'Person Received the Money *'**
  String get personReceivedMoneyLabel;

  /// No description provided for @enterReceiverNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name of receiver'**
  String get enterReceiverNameHint;

  /// No description provided for @confirmDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Details'**
  String get confirmDetailsLabel;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @addNewEvent.
  ///
  /// In en, this message translates to:
  /// **'Add New Event'**
  String get addNewEvent;

  /// No description provided for @addEventNameUpper.
  ///
  /// In en, this message translates to:
  /// **'EVENT NAME'**
  String get addEventNameUpper;

  /// No description provided for @addEventEgName.
  ///
  /// In en, this message translates to:
  /// **'e.g. Event_2026'**
  String get addEventEgName;

  /// No description provided for @addEventNoteName.
  ///
  /// In en, this message translates to:
  /// **'Note: Year should be at the end of the event name (e.g. Event_2026).'**
  String get addEventNoteName;

  /// No description provided for @addEventBannerUpper.
  ///
  /// In en, this message translates to:
  /// **'EVENT BANNER'**
  String get addEventBannerUpper;

  /// No description provided for @addEventChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get addEventChooseFile;

  /// No description provided for @addEventNoFileChosen.
  ///
  /// In en, this message translates to:
  /// **'No file chosen'**
  String get addEventNoFileChosen;

  /// No description provided for @addEventNoteBanner.
  ///
  /// In en, this message translates to:
  /// **'Note: Max file size 2MB (JPG, PNG).'**
  String get addEventNoteBanner;

  /// No description provided for @addEventDurationUpper.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get addEventDurationUpper;

  /// No description provided for @addEventFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get addEventFrom;

  /// No description provided for @addEventTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get addEventTo;

  /// No description provided for @addEventTaxAmountUpper.
  ///
  /// In en, this message translates to:
  /// **'TAX AMOUNT (₹)'**
  String get addEventTaxAmountUpper;

  /// No description provided for @addEventCreateBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get addEventCreateBtn;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @uploadReceiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload Receipt (Optional)'**
  String get uploadReceiptLabel;

  /// No description provided for @changeImageBtn.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImageBtn;

  /// No description provided for @removeImageBtn.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImageBtn;

  /// No description provided for @noImageSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelectedLabel;

  /// No description provided for @tapToUploadLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload receipt'**
  String get tapToUploadLabel;

  /// No description provided for @myFinancialReport.
  ///
  /// In en, this message translates to:
  /// **'My Financial Report'**
  String get myFinancialReport;

  /// No description provided for @myPaymentReceiptHistory.
  ///
  /// In en, this message translates to:
  /// **'My Payment Receipt History'**
  String get myPaymentReceiptHistory;

  /// No description provided for @noPaymentReceiptsFound.
  ///
  /// In en, this message translates to:
  /// **'No payment receipts found.'**
  String get noPaymentReceiptsFound;

  /// No description provided for @totalAmountUpper.
  ///
  /// In en, this message translates to:
  /// **'TOTAL AMOUNT'**
  String get totalAmountUpper;

  /// No description provided for @paidUpper.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paidUpper;

  /// No description provided for @pendingUpper.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pendingUpper;

  /// No description provided for @bankDetailsUpper.
  ///
  /// In en, this message translates to:
  /// **'BANK / DETAILS'**
  String get bankDetailsUpper;

  /// No description provided for @dateUpper.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get dateUpper;

  /// No description provided for @yearUpper.
  ///
  /// In en, this message translates to:
  /// **'YEAR'**
  String get yearUpper;

  /// No description provided for @duesUpper.
  ///
  /// In en, this message translates to:
  /// **'DUES'**
  String get duesUpper;

  /// No description provided for @statusUpper.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get statusUpper;

  /// No description provided for @actionsUpper.
  ///
  /// In en, this message translates to:
  /// **'ACTIONS'**
  String get actionsUpper;

  /// No description provided for @otherUpper.
  ///
  /// In en, this message translates to:
  /// **'OTHER'**
  String get otherUpper;

  /// No description provided for @rs.
  ///
  /// In en, this message translates to:
  /// **'Rs'**
  String get rs;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'record(s)'**
  String get records;

  /// No description provided for @noPendingPaymentRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending payment requests.'**
  String get noPendingPaymentRequests;

  /// No description provided for @totalAmountHeader.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmountHeader;

  /// No description provided for @paidAmountHeader.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmountHeader;

  /// No description provided for @methodHeader.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get methodHeader;

  /// No description provided for @dateHeader.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateHeader;

  /// No description provided for @actionsHeader.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsHeader;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
