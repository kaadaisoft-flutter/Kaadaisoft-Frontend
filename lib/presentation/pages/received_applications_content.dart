import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';
import '../widgets/custom_dropdown_search.dart';
import '../widgets/pagination_widget.dart';
import '../../l10n/app_localizations.dart';

class ReceivedApplicationsContent extends StatefulWidget {
  final dynamic userId;
  final int role;
  final VoidCallback onBackToDashboard;
  final VoidCallback? onStatsUpdated;

  const ReceivedApplicationsContent({
    super.key, 
    required this.userId,
    required this.role,
    required this.onBackToDashboard,
    this.onStatsUpdated,
  });

  @override
  State<ReceivedApplicationsContent> createState() => _ReceivedApplicationsContentState();
}

class _ReceivedApplicationsContentState extends State<ReceivedApplicationsContent> {
  List<dynamic> _applications = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  List<String> _assignedVillages = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchApplications({bool resetPage = true}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
      });
    }
    setState(() {
      _isLoading = true;
    });
    try {
      String url = '${ApiConfig.baseUrl}/api/received-applications?page=$_currentPage&limit=$_itemsPerPage';
      if (widget.userId != null) {
        url += '&user_id=${widget.userId}&role=${widget.role ?? 3}';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _applications = data['data'] ?? [];
            _isLoading = false;
            if (data['pagination'] != null) {
              int totalItems = data['pagination']['total_items'] ?? 0;
              _totalPages = (totalItems / _itemsPerPage).ceil();
              if (_totalPages == 0) _totalPages = 1;
            }
          });
        }
      } else {
        if (mounted) setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = _totalPages;
    
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    List<dynamic> currentApplications = _applications;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        
        if (_isLoading) {
          return const LoadingSpinner(message: 'Loading applications...');
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: widget.onBackToDashboard,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          AppLocalizations.of(context)?.dashboard ?? 'Dashboard',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D1712),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      " / ${AppLocalizations.of(context)?.receivedApplicationsTitle ?? 'Received Applications'}",
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D1B18),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Table Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: RawScrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        thickness: 5,
                        radius: const Radius.circular(8),
                        thumbColor: const Color(0xFF5D1712).withOpacity(0.4),
                        trackVisibility: true,
                        trackColor: const Color(0x0F5D1712),
                        trackRadius: const Radius.circular(8),
                        padding: const EdgeInsets.only(bottom: 2),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 1140,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                children: [
                                  // Header Row
                                  Container(
                                    height: 50,
                                    color: const Color(0xFF2D1B18),
                                    child: Row(
                                      children: [
                                        _buildHeaderCell(AppLocalizations.of(context)?.sNo.toUpperCase() ?? 'S.NO', 60, alignment: Alignment.center),
                                        _buildHeaderCell(AppLocalizations.of(context)?.memberNameHeader ?? 'MEMBER NAME', 170),
                                        _buildHeaderCell(AppLocalizations.of(context)?.mobileNumber.toUpperCase() ?? 'MOBILE NUMBER', 140),
                                        _buildHeaderCell(AppLocalizations.of(context)?.districtHeader ?? 'DISTRICT', 140),
                                        _buildHeaderCell(AppLocalizations.of(context)?.talukHeader ?? 'TALUK', 140),
                                        _buildHeaderCell(AppLocalizations.of(context)?.panchayatHeader ?? 'PANCHAYAT', 150),
                                        _buildHeaderCell(AppLocalizations.of(context)?.villageUpperHeader ?? 'VILLAGE', 140),
                                        _buildHeaderCell(AppLocalizations.of(context)?.actionHeader.toUpperCase() ?? 'ACTIONS', 170, hasDivider: false),
                                      ],
                                    ),
                                  ),
                                  // Data Rows
                                  if (_applications.isEmpty)
                                    Container(
                                      height: 120,
                                      alignment: Alignment.center,
                                      child: Text(
                                        AppLocalizations.of(context)?.noPendingApplications ?? 'No pending applications found.',
                                        style: const TextStyle(color: Colors.black45, fontSize: 15),
                                      ),
                                    )
                                  else
                                    Column(
                                      children: [
                                        for (int index = 0; index < currentApplications.length; index++) ...[
                                          if (index > 0) const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                                          _buildApplicationRow(index, currentApplications[index], startIndex),
                                        ],
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Pagination Footer
                    if (!_isLoading && _applications.isNotEmpty)
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
                                _fetchApplications(resetPage: false);
                              },
                            ),
                            Text('Showing page $_currentPage of $totalPages', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      }
    );
  }


  Future<void> _confirmStatusUpdate(dynamic memberId, String status) async {
    final bool isApprove = status == 'Verified';
    
    if (!isApprove) {
      // Show Rejection Reason Dialog
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
            title: Text(AppLocalizations.of(context)?.rejectApplicationTitle ?? 'Reject Application'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)?.cancelDialogBtn ?? 'Cancel', style: const TextStyle(color: Colors.black54)),
              ),
              ElevatedButton(
                onPressed: selectedReason != null ? () {
                  final String finalReason = selectedReason == (AppLocalizations.of(context)?.otherEnterManually ?? 'Other (Enter manually)') ? customReason : selectedReason!;
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
        _updateStatus(memberId, status, rejectReason: result);
      }
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Application'),
        content: const Text('Are you sure you want to approve this member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)?.cancelDialogBtn ?? 'Cancel', style: const TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _updateStatus(memberId, status);
    }
  }

  Future<void> _updateStatus(dynamic memberId, String status, {String? rejectReason}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateApplicationStatus),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'member_id': memberId,
          'status': status,
          'reject_reason': rejectReason ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        _fetchApplications();
        if (widget.onStatsUpdated != null) {
          widget.onStatsUpdated!();
        }
        if (mounted) {
          String successMsg = 'Application $status successfully';
          if (status == 'Verified' && resData['new_fmid'] != null) {
            successMsg = 'Member Approved Successfully!\n\nName: ${resData['member_name']}\nMember ID: ${resData['new_fmid']}';
          }
          
          showStatusDialog(
            context,
            title: 'Success',
            message: successMsg,
            type: DialogType.success,
          );
        }
      } else {
        if (mounted) {
          final errData = jsonDecode(response.body);
          final errDetail = errData['detail'] ?? 'Failed to update application status.';
          showStatusDialog(
            context,
            title: 'Approval Denied',
            message: errDetail,
            type: DialogType.error,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplicationDetails(dynamic app) {
    bool isCertified = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              constraints: const BoxConstraints(maxWidth: 700),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(child: Text('Received application:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Name:', app['Name']?.toString() ?? ''),
                          _buildDetailRow('Mobile No:', app['Phonenumber']?.toString() ?? ''),
                          _buildAddressDetail(app),
                          _buildDetailRow('Family Membership Id:', app['Familymembershipid']?.toString() ?? '-'),
                          const SizedBox(height: 16),
                          MediaQuery.of(context).size.width < 600
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Photo:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    _buildPhotoWidget(app),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 150, child: Text('Photo:', style: TextStyle(fontWeight: FontWeight.bold))),
                                    _buildPhotoWidget(app),
                                  ],
                                ),
                          const SizedBox(height: 16),
                          MediaQuery.of(context).size.width < 600
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    _buildDocumentsWidget(app),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 150, child: Text('Documents:', style: TextStyle(fontWeight: FontWeight.bold))),
                                    _buildDocumentsWidget(app),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isCertified,
                          onChanged: (v) => setDialogState(() => isCertified = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('I hereby certify that the above registration details are accurate.'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: isCertified ? () async {
                          await _confirmStatusUpdate(app['Id'], 'Verified');
                          if (mounted) Navigator.pop(context);
                        } : null,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('Approve'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await _confirmStatusUpdate(app['Id'], 'Rejected');
                          if (mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildPhotoWidget(dynamic app) {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: app['Memberimage'] != null && app['Memberimage'].toString().isNotEmpty
          ? GestureDetector(
              onTap: () => _showFullScreenImage('${ApiConfig.baseUrl}/assets/uploads/${app['Memberimage']}'),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Image.network(
                  '${ApiConfig.baseUrl}/assets/uploads/${app['Memberimage']}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
              ),
            )
          : const Icon(Icons.person, size: 50, color: Colors.grey),
    );
  }

  Widget _buildDocumentsWidget(dynamic app) {
    return Wrap(
      spacing: 12,
      children: [
        if (app['Communitycertificate'] != null && app['Communitycertificate'].toString().isNotEmpty)
          _buildDocIcon(Icons.badge_outlined, 'Certificate'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    Widget labelWidget = SizedBox(
      width: isMobile ? 120 : 150,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: 4),
                SizedBox(width: double.infinity, child: Text(value)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                Expanded(child: Text(value)),
              ],
            ),
    );
  }

  Widget _buildAddressDetail(dynamic app) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    Widget labelWidget = SizedBox(
      width: isMobile ? 120 : 150,
      child: const Text('Address:', style: TextStyle(fontWeight: FontWeight.bold)),
    );

    Widget contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubRow('D/No', app['Doornumber']?.toString() ?? '-'),
        _buildSubRow('Street', app['Street']?.toString() ?? '-'),
        _buildSubRow('Village', app['Village']?.toString() ?? '-'),
        _buildSubRow('Panchayat', app['Panchayat']?.toString() ?? '-'),
        _buildSubRow('Taluk', app['Taluk']?.toString() ?? '-'),
        _buildSubRow('District', app['District']?.toString() ?? '-'),
        _buildSubRow('State', app['State']?.toString() ?? '-'),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: 8),
                contentWidget,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                Expanded(child: contentWidget),
              ],
            ),
    );
  }

  Widget _buildSubRow(String label, String value) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: isMobile ? 80 : 100, child: Text(label)),
          const Text(' -   '),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDocIcon(IconData icon, String label) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEB),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5A09D)),
      ),
      child: Icon(icon, color: const Color(0xFF5D1712), size: 24),
    );
  }

  Widget _buildHeaderCell(String label, double width, {bool hasDivider = true, Alignment alignment = Alignment.centerLeft}) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        border: hasDivider ? const Border(right: BorderSide(color: Colors.white24, width: 1)) : null,
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDataCell(double width, {Widget? child, String? text, TextStyle? style, bool hasDivider = true, Alignment alignment = Alignment.centerLeft}) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        border: hasDivider ? Border(right: BorderSide(color: Colors.grey.shade200, width: 1)) : null,
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: child ?? Text(
        text ?? '',
        style: style ?? const TextStyle(color: Colors.black87, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildApplicationRow(int index, dynamic app, int startIndex) {
    int sno = startIndex + index + 1;
    return InkWell(
      onTap: () => _showApplicationDetails(app),
      child: Container(
        height: 56,
        color: index % 2 == 0 ? Colors.white : const Color(0xFFF9FAFB),
        child: Row(
          children: [
            _buildDataCell(60, text: sno.toString(), alignment: Alignment.center),
            _buildDataCell(
              170,
              text: app['Name']?.toString() ?? '',
              style: const TextStyle(color: Color(0xFF5D1712), fontWeight: FontWeight.w600, fontSize: 13),
            ),
            _buildDataCell(
              140,
              text: app['Phonenumber']?.toString() ?? '',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            _buildDataCell(
              140,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildBadge(app['District']?.toString() ?? '', Colors.grey.shade200, textColor: Colors.black87),
              ),
            ),
            _buildDataCell(
              140,
              text: app['Taluk']?.toString() ?? '',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            _buildDataCell(
              150,
              text: app['Panchayat']?.toString() ?? '',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            _buildDataCell(
              140,
              text: app['Village']?.toString() ?? '',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            _buildDataCell(
              170,
              hasDivider: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _confirmStatusUpdate(app['Id'], 'Verified'),
                    child: _buildBadge('Approve', Colors.green),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmStatusUpdate(app['Id'], 'Rejected'),
                    child: _buildBadge('Reject', Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }


}
