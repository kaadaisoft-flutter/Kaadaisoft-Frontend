import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:file_picker/file_picker.dart';

import 'package:cross_file/cross_file.dart';

import 'package:excel/excel.dart' as excel_pkg;
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../widgets/loading_spinner.dart';

import '../widgets/custom_dialog.dart';

import '../../utils/api_config.dart';

import '../widgets/pagination_widget.dart';

import 'update_details_content.dart';

import 'member_details_content.dart';

import '../widgets/registration_form.dart';

import '../widgets/custom_dropdown_search.dart';

import '../../l10n/app_localizations.dart';

// Conditional import for web download

import '../../utils/web_helper_stub.dart' if (dart.library.html) 'dart:html' as html;

import '../widgets/qr_scanner_dialog.dart';





class MembersContent extends StatefulWidget {

  final dynamic userId;

  final int? role;

  final VoidCallback? onAssignPressed;

  final String? globalSearchQuery;

  const MembersContent({super.key, this.userId, this.role, this.onAssignPressed, this.globalSearchQuery});



  @override

  State<MembersContent> createState() => _MembersContentState();

}



class _MembersContentState extends State<MembersContent> {

  List<dynamic> _members = [];

  bool _isLoading = true;

  String _errorMessage = '';

  

  // Bulk Upload State

  bool _showBulkUpload = false;

  String? _selectedFileName;

  XFile? _bulkFile;

  bool _isUploadingBulk = false;



  

  // Pagination variables

  int _currentPage = 1;

  int _totalPages = 1;

  int _totalMembersCount = 0;

  final int _itemsPerPage = 10;

  final ScrollController _horizontalScrollController = ScrollController();



  // Filter State

  bool _showFilters = false;
  bool _showMobileOptions = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _fetchMembers(resetPage: true);
      }
    });
    setState(() {});
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    _fetchMembers(resetPage: true);
    setState(() {});
  }

  String? _selectedDistrict;

  String? _selectedTaluk;

  String? _selectedPanchayat;

  String? _selectedVillage;

  String? _selectedBloodGroup;

  String? _selectedGender = 'All';

  String? _selectedOccupation = 'All';

  String? _selectedLastLoginDate;

  String? _selectedPhotoStatus = 'All';

  final List<String> _photoStatuses = ['All', 'With Photo', 'Without Photo'];

  String? _selectedLoginStatus = 'All';

  final List<String> _loginStatuses = ['All', 'Logged In', 'Never Logged In'];

  String? _selectedLoginMonth;

  String? _selectedPrivilegeType = 'All';

  final List<String> _privilegeTypes = ['All', 'Privilege Member', 'Standard Member', 'Rejected Member'];



  List<String> _districts = [];

  List<String> _taluks = [];

  List<String> _panchayats = [];

  List<String> _allVillages = [];

  List<String> _villages = [];

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  final List<String> _genders = ['All', 'Male', 'Female', 'Other'];

  final List<String> _occupations = [

    'All', 'Doctor', 'Lawyer', 'Police', 'Teacher / Lecturer', 'Engineer', 'Government Employee',

    'Private Employee', 'Student', 'Farmer', 'Textile Mill Worker', 'Garment Factory Worker',

    'Tailor', 'Pattern Master', 'Textile Machinery Technician', 'Loom Operator', 'Truck Driver',

    'Dairy Farmer', 'Poultry Farmer', 'Animal Husbandry', 'Pump Technician', 'Electrical Technician',

    'Grocery Shop Staff', 'IT / Software Employee', 'Home Maker', 'Retired', 'Others'

  ];



  bool _isLoadingDistricts = false;

  bool _isLoadingTaluks = false;

  bool _isLoadingPanchayats = false;

  bool _isLoadingVillages = false;







  @override

  void initState() {

    super.initState();

    if (widget.globalSearchQuery != null) {

      _searchController.text = widget.globalSearchQuery!;

    }

    _fetchMembers();

    _fetchDistricts();

    _fetchAllVillages();

  }



  @override
  void didUpdateWidget(covariant MembersContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.globalSearchQuery != oldWidget.globalSearchQuery) {
      _searchController.text = widget.globalSearchQuery ?? '';
      _fetchMembers(resetPage: true);
    }
  }



  void _showAddMemberDialog() {

    if (widget.role == 1) {

      final isTa = Localizations.localeOf(context).languageCode == 'ta';

      showDialog(

        context: context,

        builder: (ctx) => AlertDialog(

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

          title: Row(

            children: [

              const Icon(Icons.person_add_alt_1, color: Color(0xFF5D1712)),

              const SizedBox(width: 10),

              Expanded(

                child: Text(

                  isTa ? '\u0B89\u0BB1\u0BCD\u0BAA\u0BBF\u0BA9\u0BB0\u0BCD \u0BB5\u0B95\u0BC8' : 'Select Member Type',

                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),

                ),

              ),

              IconButton(

                icon: const Icon(Icons.close, color: Colors.black54, size: 22),

                onPressed: () => Navigator.pop(ctx),

                tooltip: isTa ? '\u0BAE\u0BC2\u0B9F\u0BC1' : 'Close',

                padding: EdgeInsets.zero,

                constraints: const BoxConstraints(),

              ),

            ],

          ),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Text(

                isTa 

                    ? 'à®¨à¯€à®™à¯à®•à®³à¯ à®šà¯‡à®°à¯à®•à¯à®• à®µà®¿à®°à¯à®®à¯à®ªà¯à®®à¯ à®‰à®±à¯à®ªà¯à®ªà®¿à®©à®°à¯ à®µà®•à¯ˆà®¯à¯ˆà®¤à¯ à®¤à¯‡à®°à¯à®¨à¯à®¤à¯†à®Ÿà¯à®•à¯à®•à®µà¯à®®à¯:'

                    : 'Choose whether this member is a Standard or Privileged member:',

                style: const TextStyle(fontSize: 13, color: Colors.black87),

              ),

              const SizedBox(height: 16),

              ListTile(

                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(12),

                  side: BorderSide(color: Colors.grey.shade300),

                ),

                leading: Container(

                  padding: const EdgeInsets.all(8),

                  decoration: BoxDecoration(color: const Color(0xFF5D1712).withOpacity(0.1), shape: BoxShape.circle),

                  child: const Icon(Icons.person_outline, color: Color(0xFF5D1712)),

                ),

                title: Text(

                  isTa ? 'à®µà®´à®•à¯à®•à®®à®¾à®© à®‰à®±à¯à®ªà¯à®ªà®¿à®©à®°à¯ (Standard Member)' : 'Standard Member (Non-Privilege)',

                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),

                ),

                subtitle: Text(

                  isTa ? 'à®¨à®¿à®°à®¨à¯à®¤à®° à®‰à®±à¯à®ªà¯à®ªà®¿à®©à®°à¯ à®Žà®£à¯ à®µà®´à®™à¯à®•à®ªà¯à®ªà®Ÿà¯à®®à¯' : 'Assigned permanent district Member ID',

                  style: const TextStyle(fontSize: 11.5, color: Colors.black54),

                ),

                onTap: () {

                  Navigator.pop(ctx);

                  _openRegistrationDialog(isPrivilege: false);

                },

              ),

              const SizedBox(height: 12),

              ListTile(

                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(12),

                  side: const BorderSide(color: Color(0xFFC49A3C), width: 1.5),

                ),

                tileColor: const Color(0xFFFFFDF5),

                leading: Container(

                  padding: const EdgeInsets.all(8),

                  decoration: const BoxDecoration(color: Color(0xFFFFF8E1), shape: BoxShape.circle),

                  child: const Icon(Icons.workspace_premium, color: Color(0xFFC49A3C)),

                ),

                title: Text(

                  isTa ? 'à®šà®¿à®±à®ªà¯à®ªà¯ à®‰à®±à¯à®ªà¯à®ªà®¿à®©à®°à¯ (Privilege Member)' : 'Privilege Member (VIP / PRV ID)',

                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF8D6E18)),

                ),

                subtitle: Text(

                  isTa ? 'à®¨à®¿à®°à®¨à¯à®¤à®° à®‰à®±à¯à®ªà¯à®ªà®¿à®©à®°à¯ à®Žà®£à¯ + à®šà®¿à®±à®ªà¯à®ªà¯ à®Žà®£à¯ (001PRV) à®µà®´à®™à¯à®•à®ªà¯à®ªà®Ÿà¯à®®à¯' : 'Dual ID: Permanent Member ID + Privilege ID (PRV)',

                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF8D6E18)),

                ),

                onTap: () {

                  Navigator.pop(ctx);

                  _openRegistrationDialog(isPrivilege: true);

                },

              ),

            ],

          ),

          actions: [

            TextButton(

              onPressed: () => Navigator.pop(ctx),

              child: Text(isTa ? 'à®°à®¤à¯à®¤à¯' : 'Cancel'),

            ),

          ],

        ),

      );

    } else {

      _openRegistrationDialog(isPrivilege: false);

    }

  }



  void _openRegistrationDialog({required bool isPrivilege}) {

    showDialog(

      context: context,

      barrierDismissible: false,

      builder: (context) => RegistrationForm(submitterRole: widget.role, isPrivilege: isPrivilege),

    ).then((_) => _fetchMembers());

  }





  String _buildFilterQueryParams({int? page, int? limit, String? origin}) {
    List<String> queryParts = [
      'user_id=${widget.userId}',
      'role=${widget.role}',
    ];
    if (origin != null && origin.isNotEmpty) queryParts.add('origin=$origin');
    if (page != null) queryParts.add('page=$page');
    if (limit != null) queryParts.add('limit=$limit');

    if (_searchController.text.trim().isNotEmpty) {
      queryParts.add('search=${Uri.encodeComponent(_searchController.text.trim())}');
    }
    if (_selectedDistrict != null) {
      queryParts.add('district=${Uri.encodeComponent(_selectedDistrict!)}');
    }
    if (_selectedTaluk != null) {
      queryParts.add('taluk=${Uri.encodeComponent(_selectedTaluk!)}');
    }
    if (_selectedPanchayat != null) {
      queryParts.add('panchayat=${Uri.encodeComponent(_selectedPanchayat!)}');
    }
    if (_selectedVillage != null) {
      queryParts.add('village=${Uri.encodeComponent(_selectedVillage!)}');
    }
    if (_selectedBloodGroup != null) {
      queryParts.add('blood_group=${Uri.encodeComponent(_selectedBloodGroup!)}');
    }
    if (_selectedGender != null && _selectedGender != 'All') {
      queryParts.add('gender=${Uri.encodeComponent(_selectedGender!)}');
    }
    if (_selectedOccupation != null && _selectedOccupation != 'All') {
      queryParts.add('occupation=${Uri.encodeComponent(_selectedOccupation!)}');
    }
    if (_selectedLoginStatus == 'Logged In') {
      queryParts.add('login_status=logged_in');
    } else if (_selectedLoginStatus == 'Never Logged In') {
      queryParts.add('login_status=never_logged_in');
    }
    if (_selectedLoginMonth != null) {
      queryParts.add('last_login_month=${Uri.encodeComponent(_selectedLoginMonth!)}');
    } else if (_selectedLastLoginDate != null) {
      queryParts.add('last_login_date=${Uri.encodeComponent(_selectedLastLoginDate!)}');
    }
    if (_selectedPhotoStatus == 'With Photo') {
      queryParts.add('photo_status=with_photo');
    } else if (_selectedPhotoStatus == 'Without Photo') {
      queryParts.add('photo_status=without_photo');
    }
    if (_selectedPrivilegeType == 'Privilege Member') {
      queryParts.add('privilege_type=privilege');
    } else if (_selectedPrivilegeType == 'Standard Member') {
      queryParts.add('privilege_type=standard');
    } else if (_selectedPrivilegeType == 'Rejected Member') {
      queryParts.add('privilege_type=rejected');
    }

    return queryParts.join('&');
  }

  Future<void> _fetchMembers({bool resetPage = true}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
      });
    }
    try {
      final query = _buildFilterQueryParams(page: _currentPage, limit: _itemsPerPage);
      final String url = '${ApiConfig.members}?$query';

      final response = await http.get(Uri.parse(url));



      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        setState(() {

          _members = data['data'];

          _isLoading = false;

          if (data['pagination'] != null) {

            int totalItems = data['pagination']['total_items'] ?? 0;

            _totalMembersCount = totalItems;

            _totalPages = (totalItems / _itemsPerPage).ceil();

            if (_totalPages == 0) _totalPages = 1;

          } else {

            _totalMembersCount = _members.length;

          }

        });

      } else {

        setState(() {

          _errorMessage = 'Failed to load members';

          _isLoading = false;

        });

      }

    } catch (e) {

      setState(() {

        _errorMessage = 'Connection error. Make sure the backend is running.';

        _isLoading = false;

      });

    }

  }



  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }



  @override

  Widget build(BuildContext context) {

    // Pagination logic

    int totalPages = _totalPages;



    int startIndex = (_currentPage - 1) * _itemsPerPage;



    List<dynamic> currentPageMembers = _members;



    if (_isLoading) {

      return const LoadingSpinner(message: 'Fetching members...');

    }



    final isMobile = MediaQuery.of(context).size.width < 700;

    final isTa = Localizations.localeOf(context).languageCode == 'ta';

    return SingleChildScrollView(

      padding: EdgeInsets.all(isMobile ? 8 : 16),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [



          // Top Action Bar

          LayoutBuilder(

            builder: (context, constraints) {

              final isNarrow = constraints.maxWidth < 600;

              return Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(

                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [

                      Row(

                        children: [

                          Text(

                            AppLocalizations.of(context)?.totalMembersHeader ?? 'Total Members: ',

                            style: TextStyle(

                              fontSize: 18,

                              fontWeight: FontWeight.bold,

                              color: const Color(0xFF2D1B18),

                            ),

                          ),

                          Container(

                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                            decoration: BoxDecoration(

                              color: const Color(0xFF5D1712),

                              borderRadius: BorderRadius.circular(12),

                            ),

                            child: Text(

                              _isLoading ? '' : _totalMembersCount.toString(),

                              style: const TextStyle(

                                color: Colors.white,

                                fontWeight: FontWeight.bold,

                                fontSize: 13,

                              ),

                            ),

                          ),

                        ],

                      ),

                      if (!isNarrow)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: _buildActionButtons(false),
                          ),
                        ),
                      if (isNarrow)
                        _buildMobileOptionsToggle(isTa),
                    ],
                  ),
                  if (isNarrow && _showMobileOptions) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildActionButtons(true),
                    ),
                  ],

                ],

              );

            },

          ),

          if (_showBulkUpload) ...[

            const SizedBox(height: 16),

            _buildBulkUploadSection(),

          ],

          if (_showFilters) ...[

            const SizedBox(height: 16),

            _buildFilterSection(),

          ],

          const SizedBox(height: 16),

          // Search & Member Type Quick Filter Bar
          _buildSearchAndFiltersBar(isTa),

          const SizedBox(height: 16),

          // Members Table

          Container(

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius: BorderRadius.circular(8),

              boxShadow: [

                BoxShadow(

                  color: Colors.black.withOpacity(0.05),

                  blurRadius: 10,

                offset: const Offset(0, 4),

              ),

            ],

          ),

          child: ClipRRect(

            borderRadius: BorderRadius.circular(8),

            child: Column(

              children: [

                LayoutBuilder(

                  builder: (context, constraints) {

                    final isNarrow = constraints.maxWidth < 600;



                    Widget rightPart = Column(

                      children: [

                        Container(

                          height: 50, // Fixed height to align with left header

                          color: const Color(0xFF2D1B18),

                          padding: const EdgeInsets.symmetric(vertical: 8),

                          child: Row(

                            children: [

                              _buildHeaderCell(AppLocalizations.of(context)?.roleHeader ?? 'ROLE', 110),

                              _buildHeaderCell(AppLocalizations.of(context)?.districtHeader ?? 'DISTRICT', 110),

                              _buildHeaderCell(AppLocalizations.of(context)?.talukHeader ?? 'TALUK', 110),

                              _buildHeaderCell(AppLocalizations.of(context)?.panchayatHeader ?? 'PANCHAYAT', 130),

                              _buildHeaderCell(AppLocalizations.of(context)?.villageUpperHeader ?? 'VILLAGE', 130),

                              _buildHeaderCell(isTa ? 'à®•à®Ÿà¯ˆà®šà®¿ à®‰à®³à¯à®¨à¯à®´à¯ˆà®µà¯' : 'LAST LOGIN', 150),

                            ],

                          ),

                        ),

                        _isLoading

                            ? const Padding(

                                padding: EdgeInsets.all(32),

                                child: Center(child: LoadingSpinner(message: 'Loading members...')),

                              )

                            : _members.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade400),
                                          const SizedBox(height: 8),
                                          Text(
                                            _searchController.text.trim().isNotEmpty
                                                ? (isTa
                                                    ? '"${_searchController.text.trim()}" என்ற தேடலுக்கு முடிவுகள் இல்லை.'
                                                    : 'No members found matching "${_searchController.text.trim()}".')
                                                : (isTa ? 'உறுப்பினர்கள் யாரும் இல்லை.' : 'No members found.'),
                                            style: const TextStyle(color: Colors.black54, fontSize: 14),
                                            textAlign: TextAlign.center,
                                          ),
                                          if (_searchController.text.trim().isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            TextButton.icon(
                                              onPressed: _clearSearch,
                                              icon: const Icon(Icons.clear, size: 16),
                                              label: Text(isTa ? 'தேடலை அழி' : 'Clear Search'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: const Color(0xFF5D1712),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  )

                                : ListView.separated(

                                    padding: EdgeInsets.zero,

                                    shrinkWrap: true,

                                    physics: const NeverScrollableScrollPhysics(),

                                    itemCount: currentPageMembers.length,

                                    separatorBuilder: (_, __) => const Divider(height: 1),

                                    itemBuilder: (context, index) {

                                      final member = currentPageMembers[index];

                                      final bool isDisabled = member['is_disabled'] == true || member['is_disabled'] == 1 || member['is_disabled']?.toString().toLowerCase() == 'true';

                                      final bool isPrivilege = member['is_privilege'] == true || member['is_privilege'] == 1 || member['is_privilege']?.toString().toLowerCase() == 'true';

                                      final bool isRejected = (member['Approvedstatus'] ?? member['approvedstatus'] ?? '').toString().trim().toLowerCase() == 'rejected';

                                      final String rejectReason = (member['RejectReason'] ?? member['rejectreason'] ?? member['reject_reason'] ?? '').toString();

                                      return _buildScrollableTableRow(

                                        member['Role']?.toString() ?? '3',

                                        member['District'] ?? '-',

                                        member['Taluk'] ?? '-',

                                        member['Panchayat'] ?? '-',

                                        member['Village'] ?? '-',

                                        member['Id'].toString(),

                                        member['Name'] ?? '-',

                                        member['Familymembershipid'] ?? 'N/A',

                                        member['last_login'] != null ? member['last_login'].toString().replaceAll('T', ' ').substring(0, 16) : (isTa ? 'உள்நுழையவில்லை' : 'Never'),

                                        isDisabled,

                                        member['Phonenumber']?.toString() ?? '-',

                                        isPrivilege: isPrivilege && !isDisabled && !isRejected,

                                        isRejected: isRejected,

                                        rejectReason: rejectReason,

                                      );

                                    },

                                  ),

                      ],

                    );



                    Widget tableContent = Row(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        // Fixed Left Part

                        SizedBox(

                          width: 560, // 50+120+140+130+120

                          child: Column(

                            children: [

                              Container(

                                height: 50, // Fixed height to align with right header

                                color: const Color(0xFF2D1B18),

                                padding: const EdgeInsets.symmetric(vertical: 8),

                                child: Row(

                                  children: [

                                    _buildHeaderCell(AppLocalizations.of(context)?.sNo?.toUpperCase() ?? 'S.NO', 50),

                                    _buildHeaderCell(AppLocalizations.of(context)?.familyIdHeader ?? 'FAMILY ID', 120),

                                    _buildHeaderCell(AppLocalizations.of(context)?.nameHeader?.toUpperCase() ?? 'NAME', 140),

                                    _buildHeaderCell(isTa ? 'à®šà¯†à®¯à®²à¯à®•à®³à¯' : 'ACTIONS', 130),

                                    _buildHeaderCell(AppLocalizations.of(context)?.mobileLabel?.toUpperCase() ?? 'MOBILE', 120),

                                  ],

                                ),

                              ),

                              _isLoading

                                  ? const SizedBox.shrink()

                                  : _members.isEmpty

                                      ? const SizedBox.shrink()

                                      : ListView.separated(

                                          padding: EdgeInsets.zero,

                                          shrinkWrap: true,

                                          physics: const NeverScrollableScrollPhysics(),

                                          itemCount: currentPageMembers.length,

                                          separatorBuilder: (_, __) => const Divider(height: 1),

                                          itemBuilder: (context, index) {

                                            final member = currentPageMembers[index];

                                            final bool isDisabled = member['is_disabled'] == true || member['is_disabled'] == 1 || member['is_disabled']?.toString().toLowerCase() == 'true';

                                            final bool isPrivilege = member['is_privilege'] == true || member['is_privilege'] == 1 || member['is_privilege']?.toString().toLowerCase() == 'true';

                                            final bool isRejected = (member['Approvedstatus'] ?? member['approvedstatus'] ?? '').toString().trim().toLowerCase() == 'rejected';

                                            final String rejectReason = (member['RejectReason'] ?? member['rejectreason'] ?? member['reject_reason'] ?? '').toString();

                                            final String? privilegeId = member['privilege_id']?.toString();

                                            final String approvedStatus = (member['Approvedstatus'] ?? member['approvedstatus'] ?? 'Verified').toString().trim().toLowerCase();

                                            final bool isStatusActive = !isDisabled && !isRejected && (approvedStatus == 'verified' || approvedStatus == 'approved');

                                            final bool showPrivilegeId = isPrivilege && isStatusActive && privilegeId != null && privilegeId.isNotEmpty;

                                            final bool hasPhoto = member['Memberimage'] != null && member['Memberimage'].toString().isNotEmpty && member['Memberimage'].toString() != 'null';

                                            return _buildFixedTableRow(

                                              (startIndex + index + 1).toString(),

                                              member['Familymembershipid'] ?? 'N/A',

                                              member['Name'] ?? '-',

                                              member['Phonenumber']?.toString() ?? '-',

                                              member['Id'].toString(),

                                              isPrivilege: isPrivilege && !isDisabled && !isRejected,

                                              privilegeId: showPrivilegeId ? privilegeId : null,

                                              isDisabled: isDisabled,

                                              hasPhoto: hasPhoto,

                                              isRejected: isRejected,

                                              rejectReason: rejectReason,

                                            );

                                          },

                                        ),

                            ],

                          ),

                        ),

                        // Scrollable Right Part

                        isNarrow

                            ? SizedBox(width: 740, child: rightPart)

                            : Expanded(

                                child: kIsWeb

                                    ? Scrollbar(

                                        controller: _horizontalScrollController,

                                        child: SingleChildScrollView(

                                          controller: _horizontalScrollController,

                                          scrollDirection: Axis.horizontal,

                                          child: SizedBox(

                                            width: 740,

                                            child: rightPart,

                                          ),

                                        ),

                                      )

                                    : ScrollConfiguration(

                                        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),

                                        child: SingleChildScrollView(

                                          controller: _horizontalScrollController,

                                          scrollDirection: Axis.horizontal,

                                          physics: const BouncingScrollPhysics(),

                                          child: SizedBox(

                                            width: 740,

                                            child: rightPart,

                                          ),

                                        ),

                                      ),

                              ),

                      ],

                    );



                    if (isNarrow) {

                      return kIsWeb

                          ? Scrollbar(

                              controller: _horizontalScrollController,

                              child: SingleChildScrollView(

                                controller: _horizontalScrollController,

                                scrollDirection: Axis.horizontal,

                                child: Padding(

                                  padding: const EdgeInsets.only(bottom: 10),

                                  child: tableContent,

                                ),

                              ),

                            )

                          : ScrollConfiguration(

                              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),

                              child: SingleChildScrollView(

                                controller: _horizontalScrollController,

                                scrollDirection: Axis.horizontal,

                                physics: const BouncingScrollPhysics(),

                                child: tableContent,

                              ),

                            );

                    }



                    return tableContent;

                  },

                ),

                // Pagination

                if (!_isLoading && _members.isNotEmpty)

                  Container(

                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),

                    decoration: const BoxDecoration(

                      color: Colors.white,

                      border: Border(top: BorderSide(color: Colors.black12)),

                    ),

                    child: Wrap(

                      alignment: WrapAlignment.center,

                      crossAxisAlignment: WrapCrossAlignment.center,

                      spacing: 8,

                      runSpacing: 8,

                      children: [

                      PaginationWidget(

                        currentPage: _currentPage,

                        totalPages: totalPages,

                        onPageChanged: (page) {

                          setState(() => _currentPage = page);

                          _fetchMembers(resetPage: false);

                        },

                      ),

                        Text(isTa ? 'à®ªà®•à¯à®•à®®à¯ $_currentPage / $totalPages' : 'Showing page $_currentPage of $totalPages', style: const TextStyle(color: Colors.black45, fontSize: 12)),

                      ],

                    ),

                  ),

              ],

            ),

            ),

          ),

        ],

      ),

    );

  }



  void _showEditMemberDialog(String memberId) async {

    showDialog(

      context: context,

      barrierDismissible: false,

      builder: (context) => const Center(child: CircularProgressIndicator()),

    );



    try {

      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/user-details/$memberId'));

      if (mounted) Navigator.pop(context);



      if (response.statusCode == 200) {

        final data = jsonDecode(response.body)['data'];

        if (!mounted) return;

        

        showDialog(

          context: context,

          barrierDismissible: false,

          builder: (context) => Dialog(

            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),

            child: Container(

              width: 1000,

              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),

              child: UpdateDetailsContent(

                userId: memberId,

                userRole: 1, // Admin/Manager

                userData: data,

                title: 'Update Member Details: ',

                onBack: () {

                  Navigator.pop(context);

                  _fetchMembers(resetPage: false);

                },

              ),

            ),

          ),

        );

      } else {

        if (mounted) {

          showStatusDialog(

            context,

            title: 'Error',

            message: 'Failed to fetch member details',

            type: DialogType.error,

          );

        }

      }

    } catch (e) {

      if (mounted) Navigator.pop(context);

      if (mounted) {

        showStatusDialog(

          context,

          title: 'Connection Error',

          message: 'Unable to load member details.',

          type: DialogType.error,

        );

      }

    }

  }



  Future<void> _approveMember(String memberId, String name) async {
    final bool isTa = Localizations.localeOf(context).languageCode == 'ta';
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isTa ? 'உறுப்பினரை அங்கீகரி: $name' : 'Approve Member: $name',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isTa
              ? 'இந்த உறுப்பினரை நீங்கள் நிச்சயமாக அங்கீகரிக்க விரும்புகிறீர்களா? அவரது விண்ணப்ப நிலை "சரிபார்க்கப்பட்டது" என மீட்டமைக்கப்படும்.'
              : 'Are you sure you want to approve this member? Their application status will be restored to "Verified".',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              isTa ? 'ரத்து செய்' : 'Cancel',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(isTa ? 'அங்கீகரி' : 'Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateApplicationStatus),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'member_id': memberId,
          'status': 'Verified',
        }),
      );

      final resData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final int idx = _members.indexWhere((m) => m['Id'].toString() == memberId.toString());
        if (idx != -1) {
          setState(() {
            _members[idx]['Approvedstatus'] = 'Verified';
            _members[idx]['approvedstatus'] = 'Verified';
            _members[idx]['RejectReason'] = '';
            _members[idx]['rejectreason'] = '';
            _members[idx]['reject_reason'] = '';
            if (resData['new_fmid'] != null) {
              _members[idx]['Familymembershipid'] = resData['new_fmid'];
            }
          });
        }
        if (mounted) {
          final String fmid = resData['new_fmid'] ?? '';
          final String successMsg = isTa
              ? 'உறுப்பினர் வெற்றிகரமாக அங்கீகரிக்கப்பட்டார்!${fmid.isNotEmpty ? '\nகுடும்ப அடையாள எண்: $fmid' : ''}'
              : 'Member approved successfully!${fmid.isNotEmpty ? '\nFamily ID: $fmid' : ''}';
          showStatusDialog(
            context,
            title: isTa ? 'வெற்றி' : 'Success',
            message: successMsg,
            type: DialogType.success,
          );
          _fetchMembers();
        }
      } else {
        if (mounted) {
          final String errorMsg = resData['detail'] ?? (isTa ? 'அங்கீகரிப்பதில் பிழை ஏற்பட்டது' : 'Failed to approve member');
          showStatusDialog(
            context,
            title: isTa ? 'பிழை' : 'Error',
            message: errorMsg,
            type: DialogType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showStatusDialog(
          context,
          title: isTa ? 'பிழை' : 'Error',
          message: e.toString(),
          type: DialogType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectMember(String memberId, String name) async {

    String? selectedReason;

    String customReason = "";

    final List<String> reasons = [

      'Documents are not clear / blurry',

      'Photograph is not clear or incorrect',

      'Duplicate application or existing member',

      'Incomplete Address (Street / Door No missing)',

      'Native address not matching with documents',

      'Community details incomplete',

      'Not eligible (Out of association area)',

      'Other (Enter manually)'

    ];



    final String? result = await showDialog<String>(

      context: context,

      builder: (context) => StatefulBuilder(

        builder: (context, setDialogState) => AlertDialog(

          backgroundColor: Colors.white,

          surfaceTintColor: Colors.white,

          title: Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Expanded(

                child: Padding(

                  padding: const EdgeInsets.only(top: 4.0),

                  child: Text('${AppLocalizations.of(context)?.rejectMemberTitle ?? "Reject Member: "}$name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                ),

              ),

              IconButton(

                icon: const Icon(Icons.close, size: 20),

                padding: EdgeInsets.zero,

                constraints: const BoxConstraints(),

                onPressed: () => Navigator.pop(context),

              ),

            ],

          ),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(AppLocalizations.of(context)?.selectRejectReason ?? 'Please select a reason for rejection:'),

              const SizedBox(height: 16),

              CustomDropdownSearch(

                label: '',

                hint: AppLocalizations.of(context)?.chooseReason ?? '-- Choose a reason --',

                value: selectedReason,

                dropdownItems: reasons,

                onChanged: (val) => setDialogState(() => selectedReason = val),

              ),

              if (selectedReason == (AppLocalizations.of(context)?.otherEnterManually ?? 'Other (Enter manually)')) ...[

                const SizedBox(height: 16),

                TextField(

                  onChanged: (val) => customReason = val,

                  decoration: InputDecoration(

                    hintText: AppLocalizations.of(context)?.enterReasonManuallyHint ?? 'Enter reason manually...',

                    border: OutlineInputBorder(),

                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                  ),

                  maxLength: 255,

                  maxLines: 2,

                ),

              ],

            ],

          ),

          actions: [

            TextButton(

              onPressed: () => Navigator.pop(context),

              child: Text(AppLocalizations.of(context)?.cancelDialogBtn ?? 'Cancel', style: const TextStyle(color: Colors.black54)),

            ),

            ElevatedButton(

              onPressed: selectedReason != null ? () {

                final String finalReason = selectedReason == (AppLocalizations.of(context)?.otherEnterManually ?? 'Other (Enter manually)') ? customReason : selectedReason!;

                if (selectedReason == (AppLocalizations.of(context)?.otherEnterManually ?? 'Other (Enter manually)') && finalReason.isEmpty) {

                   showStatusDialog(context, title: 'Required', message: AppLocalizations.of(context)?.pleaseProvideReason ?? 'Please provide a reason', type: DialogType.error);

                   return;

                }

                Navigator.pop(context, finalReason);

              } : null,

              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),

              child: Text(AppLocalizations.of(context)?.confirmRejectBtn ?? 'Confirm Reject'),

            ),

          ],

        ),

      ),

    );



    if (result != null && result.isNotEmpty) {

      setState(() => _isLoading = true);

      try {

        final response = await http.post(

          Uri.parse(ApiConfig.updateApplicationStatus),

          headers: {'Content-Type': 'application/json'},

          body: jsonEncode({

            'member_id': memberId, 

            'status': 'Rejected',

            'reject_reason': result

          }),

        );

        if (response.statusCode == 200) {

          final int idx = _members.indexWhere((m) => m['Id'].toString() == memberId.toString());

          if (idx != -1) {

            setState(() {

              _members[idx]['Approvedstatus'] = 'Rejected';

            });

          }

          if (mounted) {

            showStatusDialog(context, title: 'Success', message: 'Member rejected successfully', type: DialogType.success);

            _fetchMembers();

          }

        } else {

          if (mounted) {

            showStatusDialog(context, title: 'Error', message: 'Failed to reject member', type: DialogType.error);

            setState(() => _isLoading = false);

          }

        }

      } catch (e) {

        if (mounted) {

          showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);

          setState(() => _isLoading = false);

        }

      }

    }

  }



  Future<void> _toggleMemberDisabledStatus(String memberId, String name, bool currentDisabledState) async {

    final bool newDisabledState = !currentDisabledState;

    final String actionTitle = newDisabledState ? 'Disable ID Card' : 'Enable ID Card';



    String? enteredReason;

    bool confirm = false;



    if (newDisabledState) {

      final TextEditingController reasonController = TextEditingController();

      String? errorMessage;



      final result = await showDialog<Map<String, dynamic>>(

        context: context,

        builder: (context) => StatefulBuilder(

          builder: (context, setDialogState) => AlertDialog(

            backgroundColor: Colors.white,

            surfaceTintColor: Colors.white,

            title: Text(actionTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

            content: SingleChildScrollView(

              child: Column(

                mainAxisSize: MainAxisSize.min,

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    'Are you sure you want to disable the ID card and account for "$name"?\n\nThe member will NOT be able to log in or populate their details.',

                    style: const TextStyle(fontSize: 14),

                  ),

                  const SizedBox(height: 16),

                  TextField(

                    controller: reasonController,

                    maxLines: 3,

                    decoration: InputDecoration(

                      labelText: 'Reason for disabling *',

                      hintText: 'Enter reason for disabling member...',

                      alignLabelWithHint: true,

                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),

                      errorText: errorMessage,

                    ),

                    onChanged: (val) {

                      if (errorMessage != null && val.trim().isNotEmpty) {

                        setDialogState(() => errorMessage = null);

                      }

                    },

                  ),

                ],

              ),

            ),

            actions: [

              TextButton(

                onPressed: () => Navigator.pop(context, {'confirm': false}),

                child: const Text('Cancel', style: TextStyle(color: Colors.black54)),

              ),

              ElevatedButton(

                onPressed: () {

                  final reasonText = reasonController.text.trim();

                  if (reasonText.isEmpty) {

                    setDialogState(() {

                      errorMessage = 'Reason is required';

                    });

                    return;

                  }

                  Navigator.pop(context, {'confirm': true, 'reason': reasonText});

                },

                style: ElevatedButton.styleFrom(

                  backgroundColor: Colors.red,

                  foregroundColor: Colors.white,

                ),

                child: const Text('Disable'),

              ),

            ],

          ),

        ),

      );



      if (result != null && result['confirm'] == true) {

        confirm = true;

        enteredReason = result['reason'];

      }

    } else {

      final bool? res = await showDialog<bool>(

        context: context,

        builder: (context) => AlertDialog(

          backgroundColor: Colors.white,

          surfaceTintColor: Colors.white,

          title: Text(actionTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

          content: Text('Are you sure you want to re-enable the ID card and account for "$name"?', style: const TextStyle(fontSize: 14)),

          actions: [

            TextButton(

              onPressed: () => Navigator.pop(context, false),

              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),

            ),

            ElevatedButton(

              onPressed: () => Navigator.pop(context, true),

              style: ElevatedButton.styleFrom(

                backgroundColor: Colors.green,

                foregroundColor: Colors.white,

              ),

              child: const Text('Enable'),

            ),

          ],

        ),

      );

      confirm = res == true;

    }



    if (confirm) {

      setState(() => _isLoading = true);

      try {

        final Map<String, dynamic> bodyData = {

          'member_id': memberId,

          'is_disabled': newDisabledState,

        };

        if (newDisabledState && enteredReason != null) {

          bodyData['disabled_reason'] = enteredReason;

        }



        final response = await http.post(

          Uri.parse(ApiConfig.toggleMemberDisabledStatus),

          headers: {'Content-Type': 'application/json'},

          body: jsonEncode(bodyData),

        );



        if (response.statusCode == 200) {

          final int idx = _members.indexWhere((m) => m['Id'].toString() == memberId.toString());

          if (idx != -1) {

            setState(() {

              _members[idx]['is_disabled'] = newDisabledState;

            });

          }

          if (mounted) {

            showStatusDialog(

              context,

              title: 'Success',

              message: 'Member ID card has been ${newDisabledState ? "disabled" : "enabled"} successfully.',

              type: DialogType.success,

            );

            _fetchMembers(resetPage: false);

          }

        } else {

          if (mounted) {

            showStatusDialog(

              context,

              title: 'Error',

              message: 'Failed to update member status.',

              type: DialogType.error,

            );

            setState(() => _isLoading = false);

          }

        }

      } catch (e) {

        if (mounted) {

          showStatusDialog(

            context,

            title: 'Error',

            message: 'Connection error while updating member status.',

            type: DialogType.error,

          );

          setState(() => _isLoading = false);

        }

      }

    }

  }



  void _showViewMemberDialog(String memberId, String familyId) {

    showDialog(

      context: context,

      barrierDismissible: true,

      builder: (context) => Dialog(

        backgroundColor: Colors.white,

        surfaceTintColor: Colors.white,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),

        child: Container(

          width: 1100,

          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),

          child: Column(

            children: [

              Align(

                alignment: Alignment.topRight,

                child: Padding(

                  padding: const EdgeInsets.all(8.0),

                  child: IconButton(

                    icon: const Icon(Icons.close),

                    onPressed: () => Navigator.pop(context),

                  ),

                ),

              ),

              Expanded(

                child: MemberDetailsContent(

                  numericId: memberId,

                  familyId: familyId,

                  onBack: () => Navigator.pop(context),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildDetailRow(String label, String value) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),

          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),

        ],

      ),

    );

  }



  void _showBatchInvitationDialog() {

    final TextEditingController startController = TextEditingController(text: '1');

    final TextEditingController endController = TextEditingController(text: '100');

    bool isSending = false;



    showDialog(

      context: context,

      barrierDismissible: false,

      builder: (context) => StatefulBuilder(

        builder: (context, setDialogState) => AlertDialog(

          backgroundColor: Colors.white,

          surfaceTintColor: Colors.white,

          title: Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              const Text('Send WhatsApp Invitations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              if (!isSending)

                IconButton(

                  icon: const Icon(Icons.close),

                  onPressed: () => Navigator.pop(context),

                  padding: EdgeInsets.zero,

                  constraints: const BoxConstraints(),

                ),

            ],

          ),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              if (isSending) ...[

                const Padding(

                  padding: EdgeInsets.all(16.0),

                  child: CircularProgressIndicator(color: Color(0xFF25D366)),

                ),

                const Text('Sending messages...', style: TextStyle(color: Colors.black54)),

                const SizedBox(height: 8),

                const Text('Please do not close this window.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),

              ] else ...[

                const Text('Specify the batch range of members to send invitations to (ordered by Member ID).'),

                const SizedBox(height: 16),

                Row(

                  children: [

                    Expanded(

                      child: TextField(

                        controller: startController,

                        decoration: const InputDecoration(labelText: 'Start Index (e.g. 1)', border: OutlineInputBorder()),

                        keyboardType: TextInputType.number,

                      ),

                    ),

                    const SizedBox(width: 16),

                    Expanded(

                      child: TextField(

                        controller: endController,

                        decoration: const InputDecoration(labelText: 'End Index (e.g. 100)', border: OutlineInputBorder()),

                        keyboardType: TextInputType.number,

                      ),

                    ),

                  ],

                ),

              ],

            ],

          ),

          actions: isSending

              ? []

              : [

                  TextButton(

                    onPressed: () => Navigator.pop(context),

                    child: const Text('Cancel', style: TextStyle(color: Colors.black54)),

                  ),

                  ElevatedButton.icon(

                    onPressed: () async {

                      int? start = int.tryParse(startController.text);

                      int? end = int.tryParse(endController.text);

                      

                      if (start == null || end == null || start < 1 || end < start) {

                        showStatusDialog(context, title: 'Error', message: 'Please enter a valid range.', type: DialogType.error);

                        return;

                      }



                      setDialogState(() => isSending = true);



                      try {

                        final response = await http.post(

                          Uri.parse(ApiConfig.sendWhatsappInvitations),

                          headers: {'Content-Type': 'application/json'},

                          body: jsonEncode({

                            'start_index': start,

                            'end_index': end,

                          }),

                        );

                        

                        setDialogState(() => isSending = false);

                        

                        if (response.statusCode == 200) {

                          final data = jsonDecode(response.body);

                          if (mounted) {

                            Navigator.pop(context);

                            showStatusDialog(

                              context,

                              title: 'Invitations Sent',

                              message: data['message'] ?? 'Successfully processed the batch.',

                              type: DialogType.success,

                            );

                          }

                        } else {

                          final data = jsonDecode(response.body);

                          if (mounted) {

                            showStatusDialog(context, title: 'Error', message: data['detail'] ?? 'Failed to send invitations', type: DialogType.error);

                          }

                        }

                      } catch (e) {

                        setDialogState(() => isSending = false);

                        if (mounted) {

                          showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);

                        }

                      }

                    },

                    icon: const Icon(Icons.send, size: 18),

                    label: const Text('Send'),

                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),

                  ),

                ],

        ),

      ),

    );

  }



  Widget _buildMobileOptionsToggle(bool isTa) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _showMobileOptions = !_showMobileOptions;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _showMobileOptions ? const Color(0xFF5D1712) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _showMobileOptions ? const Color(0xFF5D1712) : Colors.grey.shade300,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 16,
                color: _showMobileOptions ? Colors.white : const Color(0xFF5D1712),
              ),
              const SizedBox(width: 6),
              Text(
                isTa ? 'விருப்பங்கள்' : 'Options',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _showMobileOptions ? Colors.white : const Color(0xFF5D1712),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showMobileOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: _showMobileOptions ? Colors.white : const Color(0xFF5D1712),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile) {

    final isTa = Localizations.localeOf(context).languageCode == 'ta';

    if (isMobile) {

      return Wrap(

        spacing: 8,

        runSpacing: 8,

        alignment: WrapAlignment.start,

        children: [

          if (!kIsWeb)

            _buildOutlinedButton('Scan QR', Icons.qr_code_scanner, const Color(0xFFC49A3C), isMobile: true, onPressed: _openQrScannerInMembers),

          _buildOutlinedButton(AppLocalizations.of(context)?.uploadBulkDataBtn ?? 'Upload Bulk Data', Icons.file_upload_outlined, const Color(0xFF5D1712), isMobile: true, onPressed: () => setState(() {

            _showBulkUpload = !_showBulkUpload;

            if (_showBulkUpload) _showFilters = false;

          })),

          _buildOutlinedButton(AppLocalizations.of(context)?.filterBtn ?? 'Filter', Icons.filter_alt_outlined, const Color(0xFF5D1712), isMobile: true, onPressed: () => setState(() {

            _showFilters = !_showFilters;

            if (_showFilters) _showBulkUpload = false;

          })),

          _buildOutlinedButton(AppLocalizations.of(context)?.downloadBtn ?? 'Download', Icons.download_outlined, const Color(0xFF5D1712), isMobile: true, onPressed: _downloadMembersData),

          _buildOutlinedButton(isTa ? 'அடையாள அட்டை அச்சிடு' : 'Print ID Cards', Icons.badge_outlined, const Color(0xFFC49A3C), isMobile: true, onPressed: _downloadBulkIdCards),

          if (widget.role == 1)

            _buildSolidButton(AppLocalizations.of(context)?.assignBtn ?? 'Assign', Icons.person_add_alt_1, const Color(0xFF5D1712), isMobile: true, onPressed: widget.onAssignPressed),

          if (widget.role == 1)

            _buildSolidButton(isTa ? 'à®…à®´à¯ˆà®ªà¯à®ªà¯ à®…à®©à¯à®ªà¯à®ªà¯à®•' : 'Send Invites', Icons.send, const Color(0xFF25D366), isMobile: true, onPressed: _showBatchInvitationDialog),

          if (widget.role == 1)

            _buildSolidButton(isTa ? 'à®…à®´à¯ˆà®ªà¯à®ªà¯ à®…à®±à®¿à®•à¯à®•à¯ˆ' : 'Invite Report', Icons.assessment, const Color(0xFF1E88E5), isMobile: true, onPressed: _showDownloadReportDialog),

          _buildSolidButton(AppLocalizations.of(context)?.addBtn ?? 'Add', Icons.add, const Color(0xFF5D1712), isMobile: true, onPressed: _showAddMemberDialog),



        ],

      );

    }



    return Wrap(

      spacing: 8,

      runSpacing: 8,

      alignment: WrapAlignment.start,

      children: [

        if (!kIsWeb)

          _buildOutlinedButton('Scan QR', Icons.qr_code_scanner, const Color(0xFFC49A3C), onPressed: _openQrScannerInMembers),

        _buildOutlinedButton(AppLocalizations.of(context)?.uploadBulkDataBtn ?? 'Upload Bulk Data', Icons.file_upload_outlined, const Color(0xFF5D1712), onPressed: () => setState(() {

          _showBulkUpload = !_showBulkUpload;

          if (_showBulkUpload) _showFilters = false;

        })),

        _buildOutlinedButton(AppLocalizations.of(context)?.filterBtn ?? 'Filter', Icons.filter_alt_outlined, const Color(0xFF5D1712), onPressed: () => setState(() {

          _showFilters = !_showFilters;

          if (_showFilters) _showBulkUpload = false;

        })),

        _buildOutlinedButton(AppLocalizations.of(context)?.downloadBtn ?? 'Download', Icons.download_outlined, const Color(0xFF5D1712), onPressed: _downloadMembersData),

        _buildOutlinedButton(isTa ? 'அடையாள அட்டை அச்சிடு' : 'Print ID Cards', Icons.badge_outlined, const Color(0xFFC49A3C), onPressed: _downloadBulkIdCards),

        if (widget.role == 1)

          _buildSolidButton(isTa ? 'à®…à®´à¯ˆà®ªà¯à®ªà¯ à®…à®©à¯à®ªà¯à®ªà¯à®•' : 'Send Invites', Icons.send, const Color(0xFF25D366), onPressed: _showBatchInvitationDialog),

        if (widget.role == 1)

          _buildSolidButton(isTa ? 'à®…à®´à¯ˆà®ªà¯à®ªà¯ à®…à®±à®¿à®•à¯à®•à¯ˆ' : 'Invite Report', Icons.assessment, const Color(0xFF1E88E5), onPressed: _showDownloadReportDialog),

        _buildSolidButton(AppLocalizations.of(context)?.addBtn ?? 'Add', Icons.add, const Color(0xFF5D1712), onPressed: _showAddMemberDialog),



      ],

    );

  }



  Future<void> _openQrScannerInMembers() async {

    final scannedMemberId = await QrScannerDialog.show(context);

    if (scannedMemberId != null && scannedMemberId.isNotEmpty && mounted) {

      showDialog(

        context: context,

        barrierDismissible: true,

        builder: (context) => Dialog(

          backgroundColor: Colors.white,

          surfaceTintColor: Colors.white,

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),

          child: Container(

            width: 1100,

            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),

            child: Column(

              children: [

                Align(

                  alignment: Alignment.topRight,

                  child: Padding(

                    padding: const EdgeInsets.all(8.0),

                    child: IconButton(

                      icon: const Icon(Icons.close),

                      onPressed: () => Navigator.pop(context),

                    ),

                  ),

                ),

                Expanded(

                  child: MemberDetailsContent(

                    numericId: scannedMemberId,

                    familyId: '',

                    onBack: () => Navigator.pop(context),

                  ),

                ),

              ],

            ),

          ),

        ),

      );

    }

  }



  Widget _buildOutlinedButton(String label, IconData icon, Color color, {VoidCallback? onPressed, bool isMobile = false}) {

    return OutlinedButton.icon(

      onPressed: onPressed ?? () {},

      icon: Icon(icon, color: color, size: isMobile ? 16 : 18),

      label: FittedBox(

        fit: BoxFit.scaleDown,

        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 13)),

      ),

      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 8 : 10),
        minimumSize: isMobile ? const Size(0, 38) : null,
      ),
    );
  }

  Widget _buildSolidButton(String label, IconData icon, Color color, {VoidCallback? onPressed, bool isMobile = false}) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, color: Colors.white, size: isMobile ? 16 : 18),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 13)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: isMobile ? 8 : 10),
        minimumSize: isMobile ? const Size(0, 38) : null,
        elevation: 0,
      ),

    );

  }



  Widget _buildHeaderCell(String label, double width) {

    return Container(

      width: width,

      decoration: const BoxDecoration(

        border: Border(right: BorderSide(color: Colors.white24, width: 1)),

      ),

      child: Center(

        child: Text(

          label,

          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),

          textAlign: TextAlign.center,

        ),

      ),

    );

  }



  Widget _buildFixedTableRow(String sno, String id, String name, String mobile, String memberId, {bool isPrivilege = false, String? privilegeId, bool isDisabled = false, bool hasPhoto = false, bool isRejected = false, String rejectReason = ''}) {

    final isTa = Localizations.localeOf(context).languageCode == 'ta';

    final bool showPriv = isPrivilege && !isDisabled && privilegeId != null && privilegeId.isNotEmpty;

    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: () => _showEditMemberDialog(memberId),

        hoverColor: const Color(0xFFFDECEB).withOpacity(0.5),

        child: Container(

          padding: const EdgeInsets.symmetric(vertical: 4),

          decoration: BoxDecoration(

            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),

            color: isRejected ? Colors.red.shade50.withOpacity(0.4) : (showPriv ? const Color(0xFFFFFDE7).withOpacity(0.35) : (isDisabled ? Colors.red.shade50.withOpacity(0.3) : null)),

          ),

          child: Row(

            children: [

              _buildDataCell(sno, 50),

              _buildDataCell(
                id,
                120,
                isBlue: !showPriv && !isRejected,
                child: isRejected
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            id,
                            style: const TextStyle(
                              color: Color(0xFF2D1B18),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.red.shade400, width: 0.8),
                            ),
                            child: Tooltip(
                              message: rejectReason.isNotEmpty ? (isTa ? 'காரணம்: $rejectReason' : 'Reason: $rejectReason') : (isTa ? 'நிராகரிக்கப்பட்ட பதிவு' : 'Rejected Registration'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cancel_outlined, size: 9, color: Colors.red.shade700),
                                  const SizedBox(width: 2),
                                  Text(
                                    isTa ? 'நிராகரிக்கப்பட்டது' : 'REJECTED',
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 8.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : (showPriv
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                id,
                                style: const TextStyle(
                                  color: Color(0xFF2D1B18),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: const Color(0xFFC49A3C), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.workspace_premium, size: 10, color: Color(0xFF8D6E18)),
                                    const SizedBox(width: 2),
                                    Text(
                                      privilegeId!,
                                      style: const TextStyle(
                                        color: Color(0xFF8D6E18),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : null),
              ),

              _buildDataCell(name, 140, isBold: true),

              _buildDataCell('', 130, child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Edit
                  _actionIcon(
                    Icons.edit_outlined,
                    const Color(0xFF5D1712),
                    onTap: () => _showEditMemberDialog(memberId),
                    tooltip: isTa ? 'திருத்து' : 'Edit',
                  ),
                  const SizedBox(width: 6),

                  // 2. View
                  _actionIcon(
                    Icons.visibility_outlined,
                    Colors.blueGrey.shade700,
                    onTap: () => _showViewMemberDialog(memberId, id),
                    tooltip: isTa ? 'பார்' : 'View',
                  ),
                  const SizedBox(width: 6),

                  // 3. More Options (3-dots)
                  Theme(
                    data: Theme.of(context).copyWith(
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                    ),
                    child: PopupMenuButton<String>(
                      tooltip: isTa ? 'கூடுதல் செயல்கள்' : 'More Options',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      elevation: 4,
                      offset: const Offset(0, 36),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.grey.shade700,
                          size: 16,
                        ),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'approve':
                            _approveMember(memberId, name);
                            break;
                          case 'id_card':
                            _downloadSingleIdCard(memberId, id);
                            break;
                          case 'invite':
                            _sendIndividualInvite(memberId, name, mobile);
                            break;
                          case 'toggle_disable':
                            _toggleMemberDisabledStatus(memberId, name, isDisabled);
                            break;
                          case 'rejection_reason':
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: Row(
                                  children: [
                                    const Icon(Icons.cancel, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(
                                      isTa ? 'நிராகரிப்பு காரணம்' : 'Rejection Reason',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTa ? 'உறுப்பினர்: $name' : 'Member: $name',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isTa ? 'காரணம்:' : 'Reason:',
                                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Text(
                                        rejectReason.isNotEmpty ? rejectReason : (isTa ? 'காரணம் குறிப்பிடப்படவில்லை' : 'No reason specified'),
                                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w500, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(isTa ? 'மூடு' : 'Close'),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _approveMember(memberId, name);
                                    },
                                    icon: const Icon(Icons.check_circle_outline, size: 16),
                                    label: Text(isTa ? 'அங்கீகரி' : 'Approve Member'),
                                  ),
                                ],
                              ),
                            );
                            break;
                          case 'reject':
                            _rejectMember(memberId, name);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        if (isRejected) ...[
                          PopupMenuItem<String>(
                            value: 'approve',
                            height: 38,
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 10),
                                Text(
                                  isTa ? 'உறுப்பினரை அங்கீகரி' : 'Approve Member',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'rejection_reason',
                            height: 38,
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
                                const SizedBox(width: 10),
                                Text(
                                  isTa ? 'நிராகரிப்பு காரணம்' : 'View Rejection Reason',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 8),
                        ],
                        PopupMenuItem<String>(
                          value: 'id_card',
                          height: 38,
                          child: Row(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 16,
                                color: hasPhoto ? const Color(0xFFC49A3C) : Colors.blueGrey,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isTa ? 'அடையாள அட்டை பதிவிறக்கு' : 'Download ID Card',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'invite',
                          height: 38,
                          child: Row(
                            children: [
                              const Icon(Icons.send_rounded, size: 16, color: Color(0xFF25D366)),
                              const SizedBox(width: 10),
                              Text(
                                isTa ? 'அழைப்பு அனுப்பு' : 'Send Invite',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 8),
                        PopupMenuItem<String>(
                          value: 'toggle_disable',
                          height: 38,
                          child: Row(
                            children: [
                              Icon(
                                isDisabled ? Icons.check_circle_outline : Icons.block,
                                size: 16,
                                color: isDisabled ? Colors.green : Colors.orange.shade800,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isDisabled
                                    ? (isTa ? 'அடையாள அட்டை இயக்கு' : 'Enable ID Card')
                                    : (isTa ? 'அடையாள அட்டை முடக்கு' : 'Disable ID Card'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDisabled ? Colors.green.shade800 : Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isRejected)
                          PopupMenuItem<String>(
                            value: 'reject',
                            height: 38,
                            child: Row(
                              children: [
                                const Icon(Icons.person_remove_outlined, size: 16, color: Colors.red),
                                const SizedBox(width: 10),
                                Text(
                                  isTa ? 'உறுப்பினரை நிராகரி' : 'Reject Member',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              )),

              _buildDataCell(mobile, 120),

            ],

          ),

        ),

      ),

    );

  }



  Future<void> _sendIndividualInvite(String memberId, String name, String mobile) async {

    final bool? confirm = await showDialog<bool>(

      context: context,

      builder: (context) => AlertDialog(

        backgroundColor: Colors.white,

        surfaceTintColor: Colors.white,

        title: Row(

          children: const [

            Icon(Icons.send_rounded, color: Color(0xFF25D366)),

            SizedBox(width: 8),

            Text('Send WhatsApp Invite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

          ],

        ),

        content: Text(

          'Are you sure you want to send a WhatsApp invitation message to "$name" ($mobile)?',

          style: const TextStyle(fontSize: 14),

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context, false),

            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),

          ),

          ElevatedButton.icon(

            onPressed: () => Navigator.pop(context, true),

            icon: const Icon(Icons.send, size: 16),

            label: const Text('Send Invite'),

            style: ElevatedButton.styleFrom(

              backgroundColor: const Color(0xFF25D366),

              foregroundColor: Colors.white,

            ),

          ),

        ],

      ),

    );



    if (confirm == true) {

      setState(() => _isLoading = true);

      try {

        final response = await http.post(

          Uri.parse(ApiConfig.sendIndividualInvite(memberId)),

          headers: {'Content-Type': 'application/json'},

        );



        final data = jsonDecode(response.body);



        if (response.statusCode == 200) {

          if (mounted) {

            showStatusDialog(

              context,

              title: 'Success',

              message: data['message'] ?? 'Invitation sent successfully.',

              type: DialogType.success,

            );

          }

        } else {

          if (mounted) {

            showStatusDialog(

              context,

              title: 'Error',

              message: data['detail'] ?? data['message'] ?? 'Failed to send invitation.',

              type: DialogType.error,

            );

          }

        }

      } catch (e) {

        if (mounted) {

          showStatusDialog(

            context,

            title: 'Error',

            message: 'Connection error while sending invitation.',

            type: DialogType.error,

          );

        }

      } finally {

        if (mounted) setState(() => _isLoading = false);

      }

    }

  }



  Widget _buildScrollableTableRow(String role, String district, String taluk, String panchayat, String village, String memberId, String name, String familyId, String lastLogin, bool isDisabled, String mobile, {bool isPrivilege = false, bool isRejected = false, String rejectReason = ''}) {

    final isTa = Localizations.localeOf(context).languageCode == 'ta';

    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: () => _showEditMemberDialog(memberId),

        hoverColor: const Color(0xFFFDECEB).withOpacity(0.5),

        child: Container(

          padding: const EdgeInsets.symmetric(vertical: 4),

          decoration: BoxDecoration(

            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),

            color: isRejected ? Colors.red.shade50.withOpacity(0.4) : (isDisabled ? Colors.red.shade50.withOpacity(0.3) : (isPrivilege ? const Color(0xFFFFFDE7).withOpacity(0.35) : null)),

          ),

          child: Row(

            children: [

              _buildDataCell('', 110, child: Container(

                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.red.shade50
                      : (isRejected
                          ? const Color(0xFFFFEBEE)
                          : (isPrivilege
                              ? const Color(0xFFFFF8E1)
                              : ((role == '1' || role == '4')
                                  ? const Color(0xFFF3E5F5)
                                  : (role == '2' ? Colors.orange.shade50 : const Color(0xFFFDECEB))))),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDisabled
                        ? Colors.red.shade300
                        : (isRejected
                            ? Colors.red.shade400
                            : (isPrivilege
                                ? const Color(0xFFC49A3C)
                                : ((role == '1' || role == '4')
                                    ? const Color(0xFFCE93D8)
                                    : (role == '2' ? Colors.orange.shade200 : const Color(0xFFE5A09D))))),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRejected) ...[
                        Icon(Icons.cancel_outlined, size: 11, color: Colors.red.shade800),
                        const SizedBox(width: 3),
                      ] else if (isPrivilege && !isDisabled) ...[
                        const Icon(Icons.stars_rounded, size: 12, color: Color(0xFF8D6E18)),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        isDisabled
                            ? 'DISABLED'
                            : (isRejected
                                ? (isTa ? 'நிராகரிக்கப்பட்டது' : 'REJECTED')
                                : (isPrivilege
                                    ? (isTa ? 'சிறப்பு' : 'PRIVILEGE')
                                    : ((role == '1' || role == '4')
                                        ? (isTa ? 'மேலாளர்' : 'MANAGER')
                                        : (role == '2'
                                            ? (isTa ? 'ஒருங்கிணைப்பாளர்' : 'COORDINATOR')
                                            : (isTa ? 'உறுப்பினர்' : 'MEMBER'))))),
                        style: TextStyle(
                          color: isDisabled
                              ? Colors.red.shade700
                              : (isRejected
                                  ? Colors.red.shade800
                                  : (isPrivilege
                                      ? const Color(0xFF8D6E18)
                                      : ((role == '1' || role == '4')
                                          ? const Color(0xFF6A1B9A)
                                          : (role == '2' ? Colors.orange.shade700 : const Color(0xFF5D1712))))),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    ],

                  ),

                ),

              )),

              _buildDataCell(district, 110),

              _buildDataCell(taluk, 110),

              _buildDataCell(panchayat.isEmpty ? '-' : panchayat, 130),

              _buildDataCell(village, 130),

              _buildDataCell(lastLogin, 150),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildDataCell(String text, double width, {bool isBlue = false, bool isBold = false, Widget? child}) {

    return Container(

      width: width,

      height: 34,

      decoration: BoxDecoration(

        border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),

      ),

      child: Center(

        child: child ?? Text(

          text,

          style: TextStyle(

            color: isBlue ? const Color(0xFF5D1712) : Colors.black87,

            fontWeight: isBlue || isBold ? FontWeight.bold : FontWeight.normal,

            fontSize: 12,

          ),

          textAlign: TextAlign.center,

          overflow: TextOverflow.ellipsis,

        ),

      ),

    );

  }



  Widget _actionIcon(IconData icon, Color color, {VoidCallback? onTap, String? tooltip}) {

    Widget iconWidget = Container(

      padding: const EdgeInsets.all(6),

      decoration: BoxDecoration(

        shape: BoxShape.circle,

        color: color.withOpacity(0.05),

        border: Border.all(color: color.withOpacity(0.3)),

      ),

      child: Icon(icon, color: color, size: 16),

    );



    if (tooltip != null) {

      iconWidget = Tooltip(message: tooltip, child: iconWidget);

    }



    return MouseRegion(

      cursor: SystemMouseCursors.click,

      child: GestureDetector(

        onTap: onTap,

        child: iconWidget,

      ),

    );

  }



  Widget _buildBulkUploadSection() {

    return Container(

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.cyan.shade100),

        boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),

            decoration: BoxDecoration(

              color: const Color(0xFF5D1712),

              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),

            ),

            child: Row(

              children: [

                const Icon(Icons.description, color: Colors.white, size: 20),

                const SizedBox(width: 12),

                const Expanded(

                  child: Text(

                    'Upload Members Bulk Data', 

                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),

                    overflow: TextOverflow.ellipsis,

                  ),

                ),

                IconButton(

                  onPressed: () => setState(() => _showBulkUpload = false),

                  icon: const Icon(Icons.close, color: Colors.white, size: 18),

                  padding: EdgeInsets.zero,

                  constraints: const BoxConstraints(),

                ),

              ],

            ),

          ),

          Padding(

            padding: const EdgeInsets.all(24),

            child: LayoutBuilder(

              builder: (context, constraints) {

                final isNarrow = constraints.maxWidth < 600;

                

                return Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text('Select Excel File (.xlsx, .xls)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),

                    const SizedBox(height: 12),

                    if (isNarrow) ...[

                      // Stack for mobile

                      Container(

                        height: 45,

                        decoration: BoxDecoration(

                          border: Border.all(color: Colors.grey.shade300),

                          borderRadius: BorderRadius.circular(8),

                        ),

                        child: Row(

                          children: [

                            ElevatedButton(

                              onPressed: _pickBulkFile,

                              style: ElevatedButton.styleFrom(

                                backgroundColor: Colors.grey.shade100,

                                foregroundColor: Colors.black87,

                                elevation: 0,

                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))),

                              ),

                              child: const Text('Choose File'),

                            ),

                            const SizedBox(width: 12),

                            Expanded(child: Text(_selectedFileName ?? 'No file chosen', style: const TextStyle(color: Colors.black54), overflow: TextOverflow.ellipsis)),

                          ],

                        ),

                      ),

                      const SizedBox(height: 16),

                      SizedBox(

                        width: double.infinity,

                        child: ElevatedButton.icon(

                          onPressed: _bulkFile == null || _isUploadingBulk ? null : _uploadBulkData,

                          icon: _isUploadingBulk ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_upload, size: 18),

                          label: Text(_isUploadingBulk ? 'Uploading...' : 'Upload Data'),

                          style: ElevatedButton.styleFrom(

                            backgroundColor: const Color(0xFF5D1712),

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(vertical: 14),

                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

                          ),

                        ),

                      ),

                    ] else ...[

                      // Row for desktop

                      Row(

                        children: [

                          Expanded(

                            child: Container(

                              height: 45,

                              decoration: BoxDecoration(

                                border: Border.all(color: Colors.grey.shade300),

                                borderRadius: BorderRadius.circular(8),

                              ),

                              child: Row(

                                children: [

                                  ElevatedButton(

                                    onPressed: _pickBulkFile,

                                    style: ElevatedButton.styleFrom(

                                      backgroundColor: Colors.grey.shade100,

                                      foregroundColor: Colors.black87,

                                      elevation: 0,

                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))),

                                    ),

                                    child: const Text('Choose File'),

                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(child: Text(_selectedFileName ?? 'No file chosen', style: const TextStyle(color: Colors.black54), overflow: TextOverflow.ellipsis)),

                                ],

                              ),

                            ),

                          ),

                          const SizedBox(width: 16),

                          ElevatedButton.icon(

                            onPressed: _bulkFile == null || _isUploadingBulk ? null : _uploadBulkData,

                            icon: _isUploadingBulk ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_upload, size: 18),

                            label: Text(_isUploadingBulk ? 'Uploading...' : 'Upload Data'),

                            style: ElevatedButton.styleFrom(

                              backgroundColor: const Color(0xFF5D1712),

                              foregroundColor: Colors.white,

                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),

                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

                            ),

                          ),

                        ],

                      ),

                    ],

                    const SizedBox(height: 20),

                    Wrap(

                      crossAxisAlignment: WrapCrossAlignment.center,

                      spacing: 8,

                      runSpacing: 8,

                      children: [

                        const Icon(Icons.info_outline, color: const Color(0xFF5D1712), size: 16),

                        const Text('Please ensure your Excel file matches the required template format before uploading. ', style: TextStyle(color: Colors.black54, fontSize: 13)),

                        InkWell(

                          onTap: _downloadSampleFormat,

                          child: const Row(

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              Icon(Icons.download, color: const Color(0xFF5D1712), size: 16),

                              const SizedBox(width: 4),

                              Text('Download Sample Format', style: TextStyle(color: const Color(0xFF5D1712), fontWeight: FontWeight.bold, fontSize: 13)),

                            ],

                          ),

                        ),

                      ],

                    ),

                  ],

                );

              },

            ),

          ),

        ],

      ),

    );

  }



  Future<void> _pickBulkFile() async {

    final result = await FilePicker.pickFiles(

      type: FileType.custom,

      allowedExtensions: ['xlsx', 'xls'],

      withData: true,

    );

    if (result != null && result.files.isNotEmpty) {

      final fileName = result.files.single.name;

      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

      if (ext != 'xlsx' && ext != 'xls') {

        setState(() {

          _selectedFileName = null;

          _bulkFile = null;

        });

        if (mounted) {

          showStatusDialog(

            context,

            title: 'Invalid File',

            message: 'Unsupported file format "$fileName". Only Excel spreadsheet files (.xlsx or .xls) are allowed.',

            type: DialogType.error,

          );

        }

        return;

      }



      setState(() {

        _selectedFileName = fileName;

        if (kIsWeb) {

          _bulkFile = XFile.fromData(result.files.single.bytes!, name: fileName);

        } else {

          _bulkFile = XFile(result.files.single.path!);

        }

      });

    }

  }



  Future<void> _uploadBulkData() async {

    if (_bulkFile == null) return;

    final ext = _bulkFile!.name.contains('.') ? _bulkFile!.name.split('.').last.toLowerCase() : '';

    if (ext != 'xlsx' && ext != 'xls') {

      showStatusDialog(

        context,

        title: 'Invalid File',

        message: 'Unsupported file format "${_bulkFile!.name}". Only Excel spreadsheet files (.xlsx or .xls) are allowed.',

        type: DialogType.error,

      );

      return;

    }

    setState(() => _isUploadingBulk = true);

    try {

      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.bulkUploadMembers));

      if (kIsWeb) {

        request.files.add(http.MultipartFile.fromBytes('file', await _bulkFile!.readAsBytes(), filename: _bulkFile!.name));

      } else {

        request.files.add(await http.MultipartFile.fromPath('file', _bulkFile!.path));

      }

      

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      

      if (mounted) {

        if (response.statusCode == 200) {

          final resData = jsonDecode(response.body);

          final isError = resData['status'] == 'error';

          showStatusDialog(

            context, 

            title: isError ? 'Error' : 'Success', 

            message: resData['message'] ?? 'Bulk data processed successfully!', 

            type: isError ? DialogType.error : DialogType.success

          );

          setState(() {

            _showBulkUpload = false;

            _bulkFile = null;

            _selectedFileName = null;

          });

          _fetchMembers();

        } else {

          final err = jsonDecode(response.body)['detail'] ?? 'Upload failed';

          showStatusDialog(context, title: 'Error', message: err, type: DialogType.error);

        }

      }

    } catch (e) {

      if (mounted) showStatusDialog(context, title: 'Error', message: 'Connection error during upload.', type: DialogType.error);

    } finally {

      if (mounted) setState(() => _isUploadingBulk = false);

    }

  }



  List<String> _cleanVillagesList(dynamic dataList) {
    if (dataList == null) return [];
    return List<String>.from(dataList)
        .map((e) => e.trim())
        .where((v) => v.isNotEmpty && v != '-' && v != '--' && v != '---' && v.toLowerCase() != 'n/a' && v.toLowerCase() != 'na' && v.toLowerCase() != 'null' && v.toLowerCase() != 'none')
        .toList();
  }

  Future<void> _fetchAllVillages() async {
    setState(() => _isLoadingVillages = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = _cleanVillagesList(data['data']);
        if (mounted) {
          setState(() {
            _allVillages = list;
            if (_selectedDistrict == null && _selectedTaluk == null && _selectedPanchayat == null) {
              _villages = List.from(list);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching all villages: $e');
    } finally {
      if (mounted) setState(() => _isLoadingVillages = false);
    }
  }

  Future<void> _fetchVillagesForDistrict(String district) async {
    setState(() => _isLoadingVillages = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages?district=${Uri.encodeComponent(district)}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _villages = _cleanVillagesList(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching villages for district: $e');
    } finally {
      if (mounted) setState(() => _isLoadingVillages = false);
    }
  }

  Future<void> _fetchVillagesForTaluk(String taluk) async {
    setState(() => _isLoadingVillages = true);
    try {
      final query = _selectedDistrict != null
          ? 'taluk=${Uri.encodeComponent(taluk)}&district=${Uri.encodeComponent(_selectedDistrict!)}'
          : 'taluk=${Uri.encodeComponent(taluk)}';
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages?$query'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _villages = _cleanVillagesList(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching villages for taluk: $e');
    } finally {
      if (mounted) setState(() => _isLoadingVillages = false);
    }
  }

  Future<void> _fetchDistricts() async {

    setState(() => _isLoadingDistricts = true);

    try {

      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));

      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        setState(() {

          _districts = List<String>.from(data['data']);

          _isLoadingDistricts = false;

        });

      }

    } catch (e) {

      debugPrint('Error: $e');

      setState(() => _isLoadingDistricts = false);

    }

  }



  Future<void> _fetchTaluks(String district) async {

    setState(() {

      _isLoadingTaluks = true;

      _taluks = [];

      _selectedTaluk = null;

      _panchayats = [];

      _selectedPanchayat = null;

      _selectedVillage = null;

    });

    _fetchVillagesForDistrict(district);

    try {

      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));

      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        setState(() {

          _taluks = List<String>.from(data['data']);

          _isLoadingTaluks = false;

        });

      }

    } catch (e) {

      debugPrint('Error: $e');

      setState(() => _isLoadingTaluks = false);

    }

  }



  Future<void> _fetchPanchayats(String taluk) async {

    setState(() {

      _isLoadingPanchayats = true;

      _panchayats = [];

      _selectedPanchayat = null;

      _selectedVillage = null;

    });

    _fetchVillagesForTaluk(taluk);

    try {

      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));

      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        setState(() {

          _panchayats = List<String>.from(data['data']);

          _isLoadingPanchayats = false;

        });

      }

    } catch (e) {

      debugPrint('Error: $e');

      setState(() => _isLoadingPanchayats = false);

    }

  }



  Future<void> _fetchVillages(String panchayat) async {
    setState(() {
      _isLoadingVillages = true;
      _villages = [];
      _selectedVillage = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _villages = _cleanVillagesList(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingVillages = false);
    }
  }



  void _showDownloadReportDialog() {

    final TextEditingController startController = TextEditingController(text: '1');

    final TextEditingController endController = TextEditingController(text: '100');



    showDialog(

      context: context,

      barrierDismissible: false,

      builder: (context) => AlertDialog(

        backgroundColor: Colors.white,

        surfaceTintColor: Colors.white,

        title: Row(

          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [

            const Text('Download Invite Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            IconButton(

              icon: const Icon(Icons.close),

              onPressed: () => Navigator.pop(context),

              padding: EdgeInsets.zero,

              constraints: const BoxConstraints(),

            ),

          ],

        ),

        content: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            const Text('Specify the record range to download from the report (Newest first).'),

            const SizedBox(height: 16),

            Row(

              children: [

                Expanded(

                  child: TextField(

                    controller: startController,

                    decoration: const InputDecoration(labelText: 'Start Index (e.g. 1)', border: OutlineInputBorder()),

                    keyboardType: TextInputType.number,

                  ),

                ),

                const SizedBox(width: 16),

                Expanded(

                  child: TextField(

                    controller: endController,

                    decoration: const InputDecoration(labelText: 'End Index (e.g. 100)', border: OutlineInputBorder()),

                    keyboardType: TextInputType.number,

                  ),

                ),

              ],

            ),

          ],

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context),

            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),

          ),

          ElevatedButton(

            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),

            onPressed: () {

              int start = int.tryParse(startController.text) ?? 1;

              int end = int.tryParse(endController.text) ?? 100;

              if (start > 0 && end >= start) {

                Navigator.pop(context);

                _downloadWhatsAppReport(start, end);

              } else {

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid range')));

              }

            },

            child: const Text('Download', style: TextStyle(color: Colors.white)),

          ),

        ],

      ),

    );

  }



  Future<void> _downloadWhatsAppReport(int start, int end) async {

    try {

      showStatusDialog(context, title: 'Processing', message: 'Generating report, please wait...', type: DialogType.info);

      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/whatsapp-report?start=$start&end=$end'));

      Navigator.pop(context); // Close dialog



      if (response.statusCode == 200) {

        if (kIsWeb) {

          final blob = html.Blob([response.bodyBytes]);

          final url = html.Url.createObjectUrlFromBlob(blob);

          html.AnchorElement(href: url)

            ..setAttribute("download", "whatsapp_invitation_report_${DateTime.now().millisecondsSinceEpoch}.xlsx")

            ..click();

          html.Url.revokeObjectUrl(url);

        } else {

          showStatusDialog(context, title: 'Note', message: 'Report download is supported in browser.', type: DialogType.info);

        }

      } else {

        showStatusDialog(context, title: 'Error', message: 'Failed to download report.', type: DialogType.error);

      }

    } catch (e) {

      debugPrint('Error downloading report: $e');

      if (mounted) Navigator.pop(context); // Close dialog if still open

      showStatusDialog(context, title: 'Error', message: 'An error occurred while downloading the report.', type: DialogType.error);

    }

  }




  void _downloadSingleIdCard(String memberId, String familyId) async {
    final url = '${ApiConfig.downloadIdCard(memberId)}';
    final uri = Uri.parse(url);
    if (kIsWeb) {
      html.window.open(url, '_blank');
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _downloadBulkIdCards() async {
    if (_members.isEmpty) {
      showStatusDialog(context, title: 'Note', message: 'No members found to print ID cards.', type: DialogType.info);
      return;
    }

    final isTa = Localizations.localeOf(context).languageCode == 'ta';
    final int count = _totalMembersCount > 0 ? _totalMembersCount : _members.length;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.badge_outlined, color: Color(0xFFC49A3C)),
            const SizedBox(width: 8),
            Text(isTa ? 'அடையாள அட்டைகளை அச்சிடவா?' : 'Print ID Cards?'),
          ],
        ),
        content: Text(
          isTa
              ? 'தற்போது வடிகட்டப்பட்ட உறுப்பினர்களுக்கு ($count உறுப்பினர்கள்) அடையாள அட்டைகளின் ஒருங்கிணைந்த PDF பதிவிறக்கப்படும். தொடரவா?'
              : 'A combined printable PDF with ID cards for the currently filtered members ($count members) will be generated. Continue?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isTa ? 'ரத்து' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC49A3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isTa ? 'அச்சிடு / பதிவிறக்கு' : 'Print / Download'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final query = _buildFilterQueryParams(origin: Uri.base.origin);
    final url = '${ApiConfig.downloadBulkIdCards}?$query';
    final uri = Uri.parse(url);

    if (kIsWeb) {
      html.window.open(url, '_blank');
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _downloadMembersData() async {
    final bool isTa = Localizations.localeOf(context).languageCode == 'ta';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Color(0xFF5D1712), strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Text(
                isTa ? 'அனைத்து உறுப்பினர்களின் தரவு பதிவிறக்கப்படுகிறது...' : 'Downloading all members data...',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18), decoration: TextDecoration.none),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final query = _buildFilterQueryParams(page: 1, limit: 10000);
      final url = '${ApiConfig.members}?$query';
      final response = await http.get(Uri.parse(url));

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final List allMembers = resData['data'] ?? [];

        if (allMembers.isEmpty) {
          showStatusDialog(
            context,
            title: isTa ? 'குறிப்பு' : 'Note',
            message: isTa ? 'பதிவிறக்க தரவு எதுவும் இல்லை.' : 'No data available to download.',
            type: DialogType.info,
          );
          return;
        }

        var excel = excel_pkg.Excel.createExcel();
        String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
        var sheet = excel[defaultSheet];

        // Headers
        List<excel_pkg.CellValue> headers = [
          excel_pkg.TextCellValue('S.NO'),
          excel_pkg.TextCellValue('FAMILY ID'),
          excel_pkg.TextCellValue('PRIVILEGE ID'),
          excel_pkg.TextCellValue('NAME'),
          excel_pkg.TextCellValue('ROLE'),
          excel_pkg.TextCellValue('MOBILE'),
          excel_pkg.TextCellValue('DISTRICT'),
          excel_pkg.TextCellValue('TALUK'),
          excel_pkg.TextCellValue('PANCHAYAT'),
          excel_pkg.TextCellValue('VILLAGE'),
          excel_pkg.TextCellValue('BLOOD GROUP'),
          excel_pkg.TextCellValue('GENDER'),
          excel_pkg.TextCellValue('OCCUPATION'),
        ];

        sheet.appendRow(headers);

        // Data Rows
        for (int i = 0; i < allMembers.length; i++) {
          final member = allMembers[i];
          final bool isPrivilege = member['is_privilege'] == true ||
              member['is_privilege'] == 1 ||
              member['is_privilege']?.toString().toLowerCase() == 'true';
          final String? privilegeId = member['privilege_id']?.toString();
          final bool hasPrivId = privilegeId != null &&
              privilegeId.trim().isNotEmpty &&
              privilegeId.trim().toLowerCase() != 'null';
          final bool isManager = member['Role']?.toString() == '1' || member['Role']?.toString() == '4';
          final bool isCoordinator = member['Role']?.toString() == '2';

          String roleText = 'MEMBER';
          if (isPrivilege || hasPrivId) {
            roleText = isManager
                ? 'MANAGER (PRIVILEGE)'
                : (isCoordinator ? 'COORDINATOR (PRIVILEGE)' : 'PRIVILEGE');
          } else if (isManager) {
            roleText = 'MANAGER';
          } else if (isCoordinator) {
            roleText = 'COORDINATOR';
          }

          sheet.appendRow([
            excel_pkg.TextCellValue((i + 1).toString()),
            excel_pkg.TextCellValue(member['Familymembershipid'] ?? 'N/A'),
            excel_pkg.TextCellValue(hasPrivId ? privilegeId!.trim() : '-'),
            excel_pkg.TextCellValue(member['Name'] ?? '-'),
            excel_pkg.TextCellValue(roleText),
            excel_pkg.TextCellValue(member['Phonenumber']?.toString() ?? '-'),
            excel_pkg.TextCellValue(member['District'] ?? '-'),
            excel_pkg.TextCellValue(member['Taluk'] ?? '-'),
            excel_pkg.TextCellValue(member['Panchayat'] ?? '-'),
            excel_pkg.TextCellValue(member['Village'] ?? '-'),
            excel_pkg.TextCellValue(member['Bloodgroup'] ?? '-'),
            excel_pkg.TextCellValue(member['Gender'] ?? '-'),
            excel_pkg.TextCellValue(member['Profession'] ?? '-'),
          ]);
        }

        final bytes = excel.encode();
        if (bytes != null) {
          if (kIsWeb) {
            final blob = html.Blob([bytes]);
            final blobUrl = html.Url.createObjectUrlFromBlob(blob);
            html.AnchorElement(href: blobUrl)
              ..setAttribute("download", "members_data_${DateTime.now().millisecondsSinceEpoch}.xlsx")
              ..click();
            html.Url.revokeObjectUrl(blobUrl);
          } else {
            showStatusDialog(context, title: 'Note', message: 'Data download is supported in browser.', type: DialogType.info);
          }
        }
      } else {
        showStatusDialog(
          context,
          title: isTa ? 'பிழை' : 'Error',
          message: isTa ? 'தரவைப் பெற முடியவில்லை.' : 'Failed to fetch data.',
          type: DialogType.error,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      showStatusDialog(
        context,
        title: isTa ? 'பிழை' : 'Error',
        message: 'Download failed: $e',
        type: DialogType.error,
      );
    }
  }



  void _downloadSampleFormat() {





    var excel = excel_pkg.Excel.createExcel();

    // In excel 4.0+, createExcel() creates a default sheet usually named 'Sheet1'

    String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

    var sheet = excel[defaultSheet];

    

    // Headers (Removing Aadhar number as requested)

    List<excel_pkg.CellValue> headers = [

      excel_pkg.TextCellValue('Name'),

      excel_pkg.TextCellValue('Phonenumber'),

      excel_pkg.TextCellValue('Gender'),

      excel_pkg.TextCellValue('Bloodgroup'),

      excel_pkg.TextCellValue('Profession'),

      excel_pkg.TextCellValue('State'),

      excel_pkg.TextCellValue('District'),

      excel_pkg.TextCellValue('Taluk'),

      excel_pkg.TextCellValue('Panchayat'),

      excel_pkg.TextCellValue('Village'),

      excel_pkg.TextCellValue('Street'),

      excel_pkg.TextCellValue('Doornumber'),

      excel_pkg.TextCellValue('Pincode'),

      excel_pkg.TextCellValue('Approvedstatus'),

    ];

    sheet.appendRow(headers);

    

    // Sample Data Rows

    sheet.appendRow([

      excel_pkg.TextCellValue('John Doe'),

      excel_pkg.TextCellValue('9876543210'),

      excel_pkg.TextCellValue('Male'),

      excel_pkg.TextCellValue('O+'),

      excel_pkg.TextCellValue('Farmer'),

      excel_pkg.TextCellValue('Tamil Nadu'),

      excel_pkg.TextCellValue('Erode'),

      excel_pkg.TextCellValue('Erode'),

      excel_pkg.TextCellValue('Example Panchayat'),

      excel_pkg.TextCellValue('Example Village'),

      excel_pkg.TextCellValue('Main Street'),

      excel_pkg.TextCellValue('123/A'),

      excel_pkg.TextCellValue('638001'),

      excel_pkg.TextCellValue('Verified'),

    ]);

    

    sheet.appendRow([

      excel_pkg.TextCellValue('Jane Smith'),

      excel_pkg.TextCellValue('9123456789'),

      excel_pkg.TextCellValue('Female'),

      excel_pkg.TextCellValue('A+'),

      excel_pkg.TextCellValue('Teacher'),

      excel_pkg.TextCellValue('Tamil Nadu'),

      excel_pkg.TextCellValue('Coimbatore'),

      excel_pkg.TextCellValue('Coimbatore North'),

      excel_pkg.TextCellValue('Example Panchayat'),

      excel_pkg.TextCellValue('Example Village'),

      excel_pkg.TextCellValue('Second Street'),

      excel_pkg.TextCellValue('45'),

      excel_pkg.TextCellValue('641001'),

      excel_pkg.TextCellValue('Pending'),

    ]);





    

    final bytes = excel.encode();



    if (bytes != null) {

      if (kIsWeb) {

        final blob = html.Blob([bytes]);

        final url = html.Url.createObjectUrlFromBlob(blob);

        html.AnchorElement(href: url)

          ..setAttribute("download", "sample_members_bulk_upload_format.xlsx")

          ..click();

        html.Url.revokeObjectUrl(url);

      } else {

        // For mobile/desktop we might need path_provider and permission_handler

        // but since the user is on Web (judging by local time and screenshots), this works.

        showStatusDialog(context, title: 'Note', message: 'Sample format download is supported in browser.', type: DialogType.info);

      }

    }

  }



  Widget _buildFilterSection() {

    final bool isTa = Localizations.localeOf(context).languageCode == 'ta';

    return Container(

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.amber.shade200, width: 1.5),

        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Padding(

            padding: const EdgeInsets.all(20),

            child: Row(

              children: [

                Icon(Icons.search_rounded, color: Colors.amber.shade700, size: 24),

                const SizedBox(width: 12),

                Text(AppLocalizations.of(context)?.advancedSearchFiltersTitle ?? 'Advanced Search Filters', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18))),

              ],

            ),

          ),

          Padding(

            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),

            child: LayoutBuilder(

              builder: (context, constraints) {

                final isNarrow = constraints.maxWidth < 600;

                final itemWidth = isNarrow ? constraints.maxWidth : (constraints.maxWidth - 48) / 4;

                

                return Column(

                  children: [

                    // Location Filters

                    if (widget.role == 1) ...[

                      Wrap(

                        spacing: 16,

                        runSpacing: 16,

                        children: [

                          SizedBox(width: itemWidth, child: _buildFilterDropdown(AppLocalizations.of(context)?.districtsLabel ?? 'Districts:', _districts, _selectedDistrict, (v) {
                            if (v != null && v.isNotEmpty) {
                              setState(() => _selectedDistrict = v);
                              _fetchTaluks(v);
                              _fetchMembers();
                            } else {
                              setState(() {
                                _selectedDistrict = null;
                                _selectedTaluk = null;
                                _selectedPanchayat = null;
                                _selectedVillage = null;
                                _taluks = [];
                                _panchayats = [];
                                _villages = List.from(_allVillages);
                              });
                              _fetchMembers();
                            }
                          }, isLoading: _isLoadingDistricts)),

                          SizedBox(width: itemWidth, child: _buildFilterDropdown(AppLocalizations.of(context)?.taluksLabel ?? 'Taluks:', _taluks, _selectedTaluk, (v) {
                            if (v != null && v.isNotEmpty) {
                              setState(() => _selectedTaluk = v);
                              _fetchPanchayats(v);
                              _fetchMembers();
                            } else {
                              setState(() {
                                _selectedTaluk = null;
                                _selectedPanchayat = null;
                                _selectedVillage = null;
                                _panchayats = [];
                              });
                              if (_selectedDistrict != null) {
                                _fetchVillagesForDistrict(_selectedDistrict!);
                              } else {
                                setState(() => _villages = List.from(_allVillages));
                              }
                              _fetchMembers();
                            }
                          }, isLoading: _isLoadingTaluks)),

                          SizedBox(width: itemWidth, child: _buildFilterDropdown(AppLocalizations.of(context)?.panchayatsLabel ?? 'Panchayats:', _panchayats, _selectedPanchayat, (v) {
                            if (v != null && v.isNotEmpty) {
                              setState(() => _selectedPanchayat = v);
                              _fetchVillages(v);
                              _fetchMembers();
                            } else {
                              setState(() {
                                _selectedPanchayat = null;
                                _selectedVillage = null;
                              });
                              if (_selectedTaluk != null) {
                                _fetchVillagesForTaluk(_selectedTaluk!);
                              } else if (_selectedDistrict != null) {
                                _fetchVillagesForDistrict(_selectedDistrict!);
                              } else {
                                setState(() => _villages = List.from(_allVillages));
                              }
                              _fetchMembers();
                            }
                          }, isLoading: _isLoadingPanchayats)),

                          SizedBox(width: itemWidth, child: _buildFilterDropdown(AppLocalizations.of(context)?.villagesLabel ?? 'Villages:', _villages, _selectedVillage, (v) {
                            setState(() => _selectedVillage = (v != null && v.isNotEmpty) ? v : null);
                            _fetchMembers();
                          }, isLoading: _isLoadingVillages)),

                        ],

                      ),

                      const SizedBox(height: 24),

                    ],







                    // Personal Filters

                    Wrap(

                      spacing: 16,

                      runSpacing: 16,

                      children: [

                        SizedBox(width: itemWidth, child: _buildFilterDropdown(AppLocalizations.of(context)?.bloodGroupLabel ?? 'Blood Group:', _bloodGroups, _selectedBloodGroup, (v) {

                          setState(() => _selectedBloodGroup = v);

                          _fetchMembers();

                        })),

                        SizedBox(width: itemWidth, child: _buildFilterDropdown(AppLocalizations.of(context)?.genderHeader ?? 'Gender:', _genders, _selectedGender, (v) {

                          setState(() => _selectedGender = v!);

                          _fetchMembers();

                        })),

                        SizedBox(width: itemWidth, child: _buildFilterDropdown(AppLocalizations.of(context)?.professionLabel ?? 'Occupation:', _occupations, _selectedOccupation, (v) {

                          setState(() => _selectedOccupation = v!);

                          _fetchMembers();

                        })),

                        SizedBox(
                          width: itemWidth,
                          child: _buildFilterDropdown(
                            isTa ? 'உள்நுழைவு நிலை:' : 'Login Status:',
                            isTa ? ['அனைத்தும்', 'உள்நுழைந்தவர்கள்', 'உள்நுழையாதவர்கள்'] : _loginStatuses,
                            isTa
                                ? (_selectedLoginStatus == 'Logged In'
                                    ? 'உள்நுழைந்தவர்கள்'
                                    : (_selectedLoginStatus == 'Never Logged In' ? 'உள்நுழையாதவர்கள்' : 'அனைத்தும்'))
                                : _selectedLoginStatus,
                            (v) {
                              if (v != null) {
                                if (isTa) {
                                  if (v == 'உள்நுழைந்தவர்கள்') _selectedLoginStatus = 'Logged In';
                                  else if (v == 'உள்நுழையாதவர்கள்') {
                                    _selectedLoginStatus = 'Never Logged In';
                                    _selectedLoginMonth = null;
                                  } else {
                                    _selectedLoginStatus = 'All';
                                  }
                                } else {
                                  _selectedLoginStatus = v;
                                  if (v == 'Never Logged In') _selectedLoginMonth = null;
                                }
                                setState(() {});
                                _fetchMembers();
                              }
                            },
                          ),
                        ),

                        SizedBox(
                          width: itemWidth,
                          child: _buildMonthFilter(
                            isTa ? 'கடைசி உள்நுழைவு மாதம்:' : 'Last Login Month:',
                            _selectedLoginMonth,
                            isTa,
                            isDisabled: _selectedLoginStatus == 'Never Logged In',
                          ),
                        ),

                        SizedBox(
                          width: itemWidth,
                          child: _buildFilterDropdown(
                            isTa ? 'சுயவிவரப் படம்:' : 'Profile Photo:',
                            isTa ? ['அனைத்தும்', 'புகைப்படம் உள்ளது', 'புகைப்படம் இல்லை'] : _photoStatuses,
                            isTa
                                ? (_selectedPhotoStatus == 'With Photo'
                                    ? 'புகைப்படம் உள்ளது'
                                    : (_selectedPhotoStatus == 'Without Photo' ? 'புகைப்படம் இல்லை' : 'அனைத்தும்'))
                                : _selectedPhotoStatus,
                            (v) {
                              if (v != null) {
                                if (isTa) {
                                  if (v == 'புகைப்படம் உள்ளது') _selectedPhotoStatus = 'With Photo';
                                  else if (v == 'புகைப்படம் இல்லை') _selectedPhotoStatus = 'Without Photo';
                                  else _selectedPhotoStatus = 'All';
                                } else {
                                  _selectedPhotoStatus = v;
                                }
                                setState(() {});
                                _fetchMembers();
                              }
                            },
                          ),
                        ),

                        SizedBox(
                          width: itemWidth,
                          child: _buildFilterDropdown(
                            isTa ? 'உறுப்பினர் வகை:' : 'Member Type:',
                            isTa ? ['அனைத்தும்', 'சிறப்பு உறுப்பினர் (Privilege)', 'வழக்கமான உறுப்பினர் (Standard)', 'நிராகரிக்கப்பட்டவை (Rejected)'] : _privilegeTypes,
                            isTa
                                ? (_selectedPrivilegeType == 'Privilege Member'
                                    ? 'சிறப்பு உறுப்பினர் (Privilege)'
                                    : (_selectedPrivilegeType == 'Standard Member'
                                        ? 'வழக்கமான உறுப்பினர் (Standard)'
                                        : (_selectedPrivilegeType == 'Rejected Member'
                                            ? 'நிராகரிக்கப்பட்டவை (Rejected)'
                                            : 'அனைத்தும்')))
                                : _selectedPrivilegeType,
                            (v) {
                              if (v != null) {
                                if (isTa) {
                                  if (v == 'சிறப்பு உறுப்பினர் (Privilege)') _selectedPrivilegeType = 'Privilege Member';
                                  else if (v == 'வழக்கமான உறுப்பினர் (Standard)') _selectedPrivilegeType = 'Standard Member';
                                  else if (v == 'நிராகரிக்கப்பட்டவை (Rejected)') _selectedPrivilegeType = 'Rejected Member';
                                  else _selectedPrivilegeType = 'All';
                                } else {
                                  _selectedPrivilegeType = v;
                                }
                                setState(() {});
                                _fetchMembers();
                              }
                            },
                          ),
                        ),

                      ],

                    ),

                    const SizedBox(height: 32),



                    // Buttons

                    Wrap(

                      alignment: WrapAlignment.end,

                      spacing: 12,

                      runSpacing: 12,

                      children: [

                        SizedBox(

                          width: isNarrow ? (constraints.maxWidth - 12) / 2 : null,

                          child: OutlinedButton(

                            onPressed: _clearFilters,

                            style: OutlinedButton.styleFrom(

                              side: const BorderSide(color: Colors.amber),

                              foregroundColor: Colors.amber.shade700,

                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

                            ),

                            child: Text(AppLocalizations.of(context)?.clearFiltersBtn ?? 'Clear Filters', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),

                          ),

                        ),

                        SizedBox(

                          width: isNarrow ? (constraints.maxWidth - 12) / 2 : null,

                          child: ElevatedButton(

                            onPressed: () => setState(() => _showFilters = false),

                            style: ElevatedButton.styleFrom(

                              backgroundColor: const Color(0xFF64748B),

                              foregroundColor: Colors.white,

                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

                            ),

                            child: Text(AppLocalizations.of(context)?.closeBtn ?? 'Close', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 16),

                  ],

                );

              },

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildFilterDropdown(String label, List<String> items, String? value, Function(String?) onChanged, {bool isLoading = false}) {

    return CustomDropdownSearch(

      label: label,

      dropdownItems: items,

      value: value,

      onChanged: (v) {

        onChanged(v);

        _fetchMembers();

      },

      isLoading: isLoading,

    );

  }




  String _formatMonthDisplay(String yyyyMm, bool isTa) {
    try {
      final parts = yyyyMm.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final monthIdx = int.tryParse(parts[1]) ?? 1;
        final List<String> tamilMonths = [
          'ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்',
          'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்'
        ];
        final List<String> engMonths = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final mName = isTa ? tamilMonths[monthIdx - 1] : engMonths[monthIdx - 1];
        return '$mName $year';
      }
    } catch (_) {}
    return yyyyMm;
  }

  void _showMonthYearPicker(bool isTa) {
    int currentYear = DateTime.now().year;
    if (_selectedLoginMonth != null) {
      final p = _selectedLoginMonth!.split('-');
      if (p.isNotEmpty) currentYear = int.tryParse(p[0]) ?? currentYear;
    }

    final List<String> tamilMonths = [
      'ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்',
      'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்'
    ];
    final List<String> engMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        int tempYear = currentYear;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTa ? 'மாதம் தேர்ந்தெடுக்க' : 'Select Month & Year',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Color(0xFF5D1712)),
                            onPressed: () => setModalState(() => tempYear--),
                          ),
                          Text(
                            '$tempYear',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D1712)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Color(0xFF5D1712)),
                            onPressed: tempYear < DateTime.now().year
                                ? () => setModalState(() => tempYear++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, idx) {
                        final mNum = idx + 1;
                        final String yyyyMm = "$tempYear-${mNum.toString().padLeft(2, '0')}";
                        final bool isSelected = _selectedLoginMonth == yyyyMm;
                        final bool isFuture = tempYear == DateTime.now().year && mNum > DateTime.now().month;

                        return InkWell(
                          onTap: isFuture
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _selectedLoginMonth = yyyyMm;
                                    _selectedLastLoginDate = null;
                                    if (_selectedLoginStatus == 'Never Logged In') {
                                      _selectedLoginStatus = 'Logged In';
                                    }
                                  });
                                  _fetchMembers();
                                },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFC49A3C)
                                  : (isFuture ? Colors.grey.shade100 : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFC49A3C)
                                    : (isFuture ? Colors.grey.shade200 : Colors.grey.shade300),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isTa ? tamilMonths[idx] : engMonths[idx],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isFuture ? Colors.grey.shade400 : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (_selectedLoginMonth != null)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedLoginMonth = null);
                      _fetchMembers();
                    },
                    child: Text(isTa ? 'வடிகட்டியை நீக்கு' : 'Clear Month', style: const TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isTa ? 'மூடு' : 'Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMonthFilter(String label, String? selectedMonth, bool isTa, {bool isDisabled = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        InkWell(
          onTap: isDisabled ? null : () => _showMonthYearPicker(isTa),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDisabled ? Colors.grey.shade100 : Colors.white,
              border: Border.all(color: selectedMonth != null ? const Color(0xFFC49A3C) : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isDisabled
                        ? (isTa ? 'பொருந்தாது' : 'Not Applicable')
                        : (selectedMonth != null
                            ? _formatMonthDisplay(selectedMonth, isTa)
                            : (isTa ? 'மாதம் தேர்ந்தெடுக்க...' : 'Select Month...')),
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.grey.shade400
                          : (selectedMonth == null ? Colors.grey.shade600 : Colors.black87),
                      fontSize: 13,
                      fontWeight: selectedMonth != null ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedMonth != null && !isDisabled)
                  InkWell(
                    onTap: () {
                      setState(() => _selectedLoginMonth = null);
                      _fetchMembers();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  )
                else
                  Icon(Icons.calendar_month, size: 16, color: isDisabled ? Colors.grey.shade400 : Colors.amber.shade700),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter(String label, String? selectedDate) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),

        const SizedBox(height: 6),

        InkWell(

          onTap: () async {

            final DateTime? picked = await showDatePicker(

              context: context,

              initialDate: DateTime.now(),

              firstDate: DateTime(2020),

              lastDate: DateTime.now(),

            );

            if (picked != null) {

              setState(() => _selectedLastLoginDate = picked.toIso8601String().split('T').first);

              _fetchMembers();

            }

          },

          child: Container(

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

            decoration: BoxDecoration(

              color: Colors.white,

              border: Border.all(color: Colors.grey.shade300),

              borderRadius: BorderRadius.circular(8),

            ),

            child: Row(

              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [

                Text(selectedDate ?? 'Select Date', style: TextStyle(color: selectedDate == null ? Colors.grey.shade600 : Colors.black87, fontSize: 13)),

                Icon(Icons.calendar_today, size: 16, color: Colors.amber.shade700),

              ],

            ),

          ),

        ),

      ],

    );

  }







  void _clearFilters() {

    setState(() {

      _searchController.clear();

      _selectedPhotoStatus = 'All';

      _selectedLoginStatus = 'All';

      _selectedLoginMonth = null;

      _selectedLastLoginDate = null;

      _selectedDistrict = null;

      _selectedTaluk = null;

      _selectedPanchayat = null;

      _selectedVillage = null;

      _taluks = [];

      _panchayats = [];

      _villages = List.from(_allVillages);

      _selectedBloodGroup = null;

      _selectedGender = 'All';

      _selectedOccupation = 'All';

      _selectedPrivilegeType = 'All';

      _selectedLastLoginDate = null;

    });

    _fetchMembers();
  }

  Widget _buildSearchBar(bool isTa) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onSubmitted: (v) {
          _searchDebounce?.cancel();
          _fetchMembers(resetPage: true);
        },
        style: const TextStyle(fontSize: 14, color: Color(0xFF2D1B18)),
        decoration: InputDecoration(
          isDense: true,
          hintText: isTa
              ? 'பெயர், எண், கைபேசி, மின்னஞ்சல் மூலம் தேடுக...'
              : 'Search by Name, ID, Mobile, or Email...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF5D1712)),
          prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 44),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: _clearSearch,
                  tooltip: isTa ? 'அழி' : 'Clear',
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 44),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSearchAndFiltersBar(bool isTa) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 950;
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: _buildSearchBar(isTa),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 6,
                child: _buildMemberTypeQuickFilter(isTa),
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBar(isTa),
              const SizedBox(height: 12),
              _buildMemberTypeQuickFilter(isTa),
            ],
          );
        }
      },
    );
  }

  Widget _buildMemberTypeQuickFilter(bool isTa) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Text(
                          isTa ? 'உறுப்பினர் வகை:' : 'Member Type:',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D1B18),
                          ),
                        ),
                      ],
                    ),
                    _buildQuickFilterPill(
                      label: isTa ? 'அனைத்தும்' : 'All',
                      isSelected: _selectedPrivilegeType == 'All',
                      onTap: () {
                        if (_selectedPrivilegeType != 'All') {
                          setState(() => _selectedPrivilegeType = 'All');
                          _fetchMembers();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickFilterPill(
                        label: isTa ? 'சிறப்பு உறுப்பினர்' : 'Privilege Members',
                        icon: Icons.stars_rounded,
                        iconColor: const Color(0xFFC49A3C),
                        isSelected: _selectedPrivilegeType == 'Privilege Member',
                        selectedBgColor: const Color(0xFFFFF8E7),
                        selectedBorderColor: const Color(0xFFC49A3C),
                        selectedTextColor: const Color(0xFF7A5800),
                        isFullWidth: true,
                        onTap: () {
                          if (_selectedPrivilegeType != 'Privilege Member') {
                            setState(() => _selectedPrivilegeType = 'Privilege Member');
                            _fetchMembers();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickFilterPill(
                        label: isTa ? 'வழக்கமான உறுப்பினர்' : 'Standard Members',
                        icon: Icons.person_outline,
                        isSelected: _selectedPrivilegeType == 'Standard Member',
                        isFullWidth: true,
                        onTap: () {
                          if (_selectedPrivilegeType != 'Standard Member') {
                            setState(() => _selectedPrivilegeType = 'Standard Member');
                            _fetchMembers();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickFilterPill(
                        label: isTa ? 'நிராகரிக்கப்பட்டவை' : 'Rejected Members',
                        icon: Icons.cancel_outlined,
                        iconColor: Colors.red.shade700,
                        isSelected: _selectedPrivilegeType == 'Rejected Member',
                        selectedBgColor: const Color(0xFFFFEBEE),
                        selectedBorderColor: Colors.red.shade700,
                        selectedTextColor: Colors.red.shade800,
                        isFullWidth: true,
                        onTap: () {
                          if (_selectedPrivilegeType != 'Rejected Member') {
                            setState(() => _selectedPrivilegeType = 'Rejected Member');
                            _fetchMembers();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final pills = [
          _buildQuickFilterPill(
            label: isTa ? 'அனைத்தும்' : 'All',
            isSelected: _selectedPrivilegeType == 'All',
            onTap: () {
              if (_selectedPrivilegeType != 'All') {
                setState(() => _selectedPrivilegeType = 'All');
                _fetchMembers();
              }
            },
          ),
          const SizedBox(width: 8),
          _buildQuickFilterPill(
            label: isTa ? 'சிறப்பு உறுப்பினர் (Privilege)' : 'Privilege Members',
            icon: Icons.stars_rounded,
            iconColor: const Color(0xFFC49A3C),
            isSelected: _selectedPrivilegeType == 'Privilege Member',
            selectedBgColor: const Color(0xFFFFF8E7),
            selectedBorderColor: const Color(0xFFC49A3C),
            selectedTextColor: const Color(0xFF7A5800),
            onTap: () {
              if (_selectedPrivilegeType != 'Privilege Member') {
                setState(() => _selectedPrivilegeType = 'Privilege Member');
                _fetchMembers();
              }
            },
          ),
          const SizedBox(width: 8),
          _buildQuickFilterPill(
            label: isTa ? 'வழக்கமான உறுப்பினர் (Standard)' : 'Standard Members',
            icon: Icons.person_outline,
            isSelected: _selectedPrivilegeType == 'Standard Member',
            onTap: () {
              if (_selectedPrivilegeType != 'Standard Member') {
                setState(() => _selectedPrivilegeType = 'Standard Member');
                _fetchMembers();
              }
            },
          ),
          const SizedBox(width: 8),
          _buildQuickFilterPill(
            label: isTa ? 'நிராகரிக்கப்பட்டவை' : 'Rejected Members',
            icon: Icons.cancel_outlined,
            iconColor: Colors.red.shade700,
            isSelected: _selectedPrivilegeType == 'Rejected Member',
            selectedBgColor: const Color(0xFFFFEBEE),
            selectedBorderColor: Colors.red.shade700,
            selectedTextColor: Colors.red.shade800,
            onTap: () {
              if (_selectedPrivilegeType != 'Rejected Member') {
                setState(() => _selectedPrivilegeType = 'Rejected Member');
                _fetchMembers();
              }
            },
          ),
        ];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.filter_list, size: 18, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Text(
                isTa ? 'உறுப்பினர் வகை:' : 'Member Type:',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: pills,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickFilterPill({
    required String label,
    IconData? icon,
    Color? iconColor,
    required bool isSelected,
    Color? selectedBgColor,
    Color? selectedBorderColor,
    Color? selectedTextColor,
    bool isFullWidth = false,
    required VoidCallback onTap,
  }) {
    final activeBg = selectedBgColor ?? const Color(0xFF5D1712);
    final activeBorder = selectedBorderColor ?? const Color(0xFF5D1712);
    final activeText = selectedTextColor ?? Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeBorder : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? (selectedTextColor != null ? iconColor ?? activeText : Colors.white)
                    : (iconColor ?? Colors.black54),
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeText : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}





