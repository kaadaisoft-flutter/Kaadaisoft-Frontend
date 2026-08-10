import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:excel/excel.dart' as excel_pkg;
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
  final int _itemsPerPage = 10;
  final ScrollController _horizontalScrollController = ScrollController();

  // Filter State
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDistrict;
  String? _selectedTaluk;
  String? _selectedPanchayat;
  String? _selectedVillage;
  String? _selectedBloodGroup;
  String? _selectedGender = 'All';
  String? _selectedOccupation = 'All';

  List<String> _districts = [];
  List<String> _taluks = [];
  List<String> _panchayats = [];
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
  }

  @override
  void didUpdateWidget(covariant MembersContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.globalSearchQuery != oldWidget.globalSearchQuery) {
      _searchController.text = widget.globalSearchQuery ?? '';
      _fetchMembers();
    }
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RegistrationForm(submitterRole: widget.role),
    ).then((_) => _fetchMembers());
  }

  Future<void> _fetchMembers() async {

    try {
      String url = '${ApiConfig.members}?user_id=${widget.userId}&role=${widget.role}';
      
      // Append filters to URL
      if (_searchController.text.isNotEmpty) url += '&search=${Uri.encodeComponent(_searchController.text)}';
      if (_selectedDistrict != null) url += '&district=${Uri.encodeComponent(_selectedDistrict!)}';
      if (_selectedTaluk != null) url += '&taluk=${Uri.encodeComponent(_selectedTaluk!)}';
      if (_selectedPanchayat != null) url += '&panchayat=${Uri.encodeComponent(_selectedPanchayat!)}';
      if (_selectedVillage != null) url += '&village=${Uri.encodeComponent(_selectedVillage!)}';
      if (_selectedBloodGroup != null) url += '&blood_group=${Uri.encodeComponent(_selectedBloodGroup!)}';
      if (_selectedGender != null && _selectedGender != 'All') url += '&gender=${Uri.encodeComponent(_selectedGender!)}';
      if (_selectedOccupation != null && _selectedOccupation != 'All') url += '&occupation=${Uri.encodeComponent(_selectedOccupation!)}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _members = data['data'];
          _isLoading = false;
          _currentPage = 1; // Reset to first page
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
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pagination logic
    int totalPages = (_members.length / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _members.length) endIndex = _members.length;

    List<dynamic> currentPageMembers = _members.isNotEmpty 
        ? _members.sublist(startIndex, endIndex) 
        : [];

    if (_isLoading) {
      return const LoadingSpinner(message: 'Fetching members...');
    }

    final isMobile = MediaQuery.of(context).size.width < 700;
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
                              _isLoading ? '' : _members.length.toString(),
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
                    ],
                  ),
                  if (isNarrow) ...[
                    const SizedBox(height: 16),
                    _buildActionButtons(true),
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
                              _buildHeaderCell('ACTIONS', 160),
                            ],
                          ),
                        ),
                        _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(child: LoadingSpinner(message: 'Loading members...')),
                              )
                            : _members.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(child: Text('No members found.', style: TextStyle(color: Colors.black54))),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: currentPageMembers.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final member = currentPageMembers[index];
                                      return _buildScrollableTableRow(
                                        member['Role']?.toString() ?? '3',
                                        member['District'] ?? '-',
                                        member['Taluk'] ?? '-',
                                        member['Panchayat'] ?? '-',
                                        member['Village'] ?? '-',
                                        member['Id'].toString(),
                                        member['Name'] ?? '-',
                                        member['Familymembershipid'] ?? 'N/A',
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
                          width: 430, // 50+120+140+120
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
                                            return _buildFixedTableRow(
                                              (startIndex + index + 1).toString(),
                                              member['Familymembershipid'] ?? 'N/A',
                                              member['Name'] ?? '-',
                                              member['Phonenumber']?.toString() ?? '-',
                                              member['Id'].toString(),
                                            );
                                          },
                                        ),
                            ],
                          ),
                        ),
                        // Scrollable Right Part
                        isNarrow
                            ? SizedBox(width: 750, child: rightPart)
                            : Expanded(
                                  child: Scrollbar(
                                    controller: _horizontalScrollController,
                                  child: SingleChildScrollView(
                                    controller: _horizontalScrollController,
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: 750, // 110+110+110+130+130+160
                                      child: rightPart,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    );

                    if (isNarrow) {
                      return Scrollbar(
                        controller: _horizontalScrollController,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
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
                        onPageChanged: (page) => setState(() => _currentPage = page),
                      ),
                        Text('Showing page $_currentPage of $totalPages', style: const TextStyle(color: Colors.black45, fontSize: 12)),
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
                  _fetchMembers();
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

  Widget _buildActionButtons(bool isMobile) {
    if (isMobile) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        children: [
          _buildOutlinedButton(AppLocalizations.of(context)?.uploadBulkDataBtn ?? 'Upload Bulk Data', Icons.file_upload_outlined, const Color(0xFF5D1712), isMobile: true, onPressed: () => setState(() {
            _showBulkUpload = !_showBulkUpload;
            if (_showBulkUpload) _showFilters = false;
          })),
          _buildOutlinedButton(AppLocalizations.of(context)?.filterBtn ?? 'Filter', Icons.filter_alt_outlined, const Color(0xFF5D1712), isMobile: true, onPressed: () => setState(() {
            _showFilters = !_showFilters;
            if (_showFilters) _showBulkUpload = false;
          })),
          _buildOutlinedButton(AppLocalizations.of(context)?.downloadBtn ?? 'Download', Icons.download_outlined, const Color(0xFF5D1712), isMobile: true, onPressed: _downloadMembersData),
          if (widget.role == 1)
            _buildSolidButton(AppLocalizations.of(context)?.assignBtn ?? 'Assign', Icons.person_add_alt_1, const Color(0xFF5D1712), isMobile: true, onPressed: widget.onAssignPressed),
          if (widget.role == 1)
            _buildSolidButton('Send Invites', Icons.send, const Color(0xFF25D366), isMobile: true, onPressed: _showBatchInvitationDialog),
          _buildSolidButton(AppLocalizations.of(context)?.addBtn ?? 'Add', Icons.add, const Color(0xFF5D1712), isMobile: true, onPressed: _showAddMemberDialog),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.start,
      children: [
        _buildOutlinedButton(AppLocalizations.of(context)?.uploadBulkDataBtn ?? 'Upload Bulk Data', Icons.file_upload_outlined, const Color(0xFF5D1712), onPressed: () => setState(() {
          _showBulkUpload = !_showBulkUpload;
          if (_showBulkUpload) _showFilters = false;
        })),
        _buildOutlinedButton(AppLocalizations.of(context)?.filterBtn ?? 'Filter', Icons.filter_alt_outlined, const Color(0xFF5D1712), onPressed: () => setState(() {
          _showFilters = !_showFilters;
          if (_showFilters) _showBulkUpload = false;
        })),
        _buildOutlinedButton(AppLocalizations.of(context)?.downloadBtn ?? 'Download', Icons.download_outlined, const Color(0xFF5D1712), onPressed: _downloadMembersData),
        if (widget.role == 1)
          _buildSolidButton(AppLocalizations.of(context)?.assignBtn ?? 'Assign', Icons.person_add_alt_1, const Color(0xFF5D1712), onPressed: widget.onAssignPressed),
        if (widget.role == 1)
          _buildSolidButton('Send Invites', Icons.send, const Color(0xFF25D366), onPressed: _showBatchInvitationDialog),
        _buildSolidButton(AppLocalizations.of(context)?.addBtn ?? 'Add', Icons.add, const Color(0xFF5D1712), onPressed: _showAddMemberDialog),
      ],
    );
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
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 10),
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
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 10),
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

  Widget _buildFixedTableRow(String sno, String id, String name, String mobile, String memberId) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEditMemberDialog(memberId),
        hoverColor: const Color(0xFFFDECEB).withOpacity(0.5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              _buildDataCell(sno, 50),
              _buildDataCell(id, 120, isBlue: true),
              _buildDataCell(name, 140, isBold: true),
              _buildDataCell(mobile, 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableTableRow(String role, String district, String taluk, String panchayat, String village, String memberId, String name, String familyId) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEditMemberDialog(memberId),
        hoverColor: const Color(0xFFFDECEB).withOpacity(0.5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              _buildDataCell('', 110, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: role == '2' ? Colors.orange.shade50 : const Color(0xFFFDECEB),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: role == '2' ? Colors.orange.shade200 : const Color(0xFFE5A09D)),
                ),
                child: Text(
                  role == '2' ? (AppLocalizations.of(context)?.coordinatorRole?.toUpperCase() ?? 'COORDINATOR') : (AppLocalizations.of(context)?.memberRole?.toUpperCase() ?? 'MEMBER'),
                  style: TextStyle(color: role == '2' ? Colors.orange.shade700 : const Color(0xFF5D1712), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )),
              _buildDataCell(district, 110),
              _buildDataCell(taluk, 110),
              _buildDataCell(panchayat.isEmpty ? '-' : panchayat, 130),
              _buildDataCell(village, 130),
              _buildDataCell('', 160, child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionIcon(Icons.edit_outlined, const Color(0xFF5D1712), onTap: () => _showEditMemberDialog(memberId), tooltip: 'Edit'),
                  const SizedBox(width: 8),
                  _actionIcon(Icons.person_remove_outlined, Colors.red, onTap: () => _rejectMember(memberId, name), tooltip: 'Reject'),
                  const SizedBox(width: 8),
                  _actionIcon(Icons.visibility_outlined, Colors.grey, onTap: () => _showViewMemberDialog(memberId, familyId), tooltip: 'View'),
                ],
              )),
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
    if (result != null) {
      setState(() {
        _selectedFileName = result.files.single.name;
        if (kIsWeb) {
          _bulkFile = XFile.fromData(result.files.single.bytes!, name: result.files.single.name);
        } else {
          _bulkFile = XFile(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _uploadBulkData() async {
    if (_bulkFile == null) return;
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
      _villages = [];
      _selectedVillage = null;
    });
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
      _villages = [];
      _selectedVillage = null;
    });
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
        setState(() {
          _villages = List<String>.from(data['data']);
          _isLoadingVillages = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoadingVillages = false);
    }
  }

  void _downloadMembersData() {
    if (_members.isEmpty) {
      showStatusDialog(context, title: 'Note', message: 'No data available to download.', type: DialogType.info);
      return;
    }

    var excel = excel_pkg.Excel.createExcel();
    String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    var sheet = excel[defaultSheet];
    
    // Headers
    List<excel_pkg.CellValue> headers = [
      excel_pkg.TextCellValue('S.NO'),
      excel_pkg.TextCellValue('FAMILY ID'),
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
    for (int i = 0; i < _members.length; i++) {
      final member = _members[i];
      sheet.appendRow([
        excel_pkg.TextCellValue((i + 1).toString()),
        excel_pkg.TextCellValue(member['Familymembershipid'] ?? 'N/A'),
        excel_pkg.TextCellValue(member['Name'] ?? '-'),
        excel_pkg.TextCellValue(member['Role']?.toString() == '2' ? 'COORDINATOR' : 'MEMBER'),
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
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "members_data_${DateTime.now().millisecondsSinceEpoch}.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        showStatusDialog(context, title: 'Note', message: 'Data download is supported in browser.', type: DialogType.info);
      }
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
    
    // Sample Data Rows (Requested by user)
    sheet.appendRow([
      excel_pkg.TextCellValue('John Doe'),
      excel_pkg.TextCellValue('9876543210'),
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
                            if (v != null) {
                              setState(() => _selectedDistrict = v);
                              _fetchTaluks(v);
                              _fetchMembers();
                            }
                          }, isLoading: _isLoadingDistricts)),
                          SizedBox(width: itemWidth, child: _buildFilterDropdown(AppLocalizations.of(context)?.taluksLabel ?? 'Taluks:', _taluks, _selectedTaluk, (v) {
                            if (v != null) {
                              setState(() => _selectedTaluk = v);
                              _fetchPanchayats(v);
                              _fetchMembers();
                            }
                          }, isLoading: _isLoadingTaluks)),
                          SizedBox(width: itemWidth, child: _buildFilterDropdown(AppLocalizations.of(context)?.panchayatsLabel ?? 'Panchayats:', _panchayats, _selectedPanchayat, (v) {
                            if (v != null) {
                              setState(() => _selectedPanchayat = v);
                              _fetchVillages(v);
                              _fetchMembers();
                            }
                          }, isLoading: _isLoadingPanchayats)),
                          SizedBox(width: itemWidth, child: _buildFilterDropdown(AppLocalizations.of(context)?.villagesLabel ?? 'Villages:', _villages, _selectedVillage, (v) {
                            setState(() => _selectedVillage = v);
                            _fetchMembers();
                          }, isLoading: _isLoadingVillages)),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Row 2: Specific Search
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)?.specificSearchTitle ?? 'Specific Search (Name, Membership ID, Mobile, Email, Aadhar):', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          onChanged: (v) => _fetchMembers(),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)?.specificSearchHint ?? 'Type Name, Email, Mobile, Aadhar or Membership ID...',
                            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.amber),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Expanded(child: Text(AppLocalizations.of(context)?.specificSearchInfo ?? 'Search by Name, Email, Mobile, Aadhar Card, or Membership ID directly.', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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



  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDistrict = null;
      _selectedTaluk = null;
      _selectedPanchayat = null;
      _selectedVillage = null;
      _selectedBloodGroup = null;
      _selectedGender = 'All';
      _selectedOccupation = 'All';
    });
    _fetchMembers();
  }
}


