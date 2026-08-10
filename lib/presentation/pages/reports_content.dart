import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' hide Border;
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';
import '../../utils/download_helper.dart' as dl;
import '../widgets/pagination_widget.dart';
import 'update_details_content.dart';
import '../widgets/custom_dropdown_search.dart';
import '../../l10n/app_localizations.dart';

class ReportsContent extends StatefulWidget {
  final int? userId;
  final int? role;
  final String? globalSearchQuery;

  const ReportsContent({super.key, this.userId, this.role, this.globalSearchQuery});

  @override
  State<ReportsContent> createState() => _ReportsContentState();
}

class _ReportsContentState extends State<ReportsContent> {
  List<dynamic> _reportData = [];
  List<dynamic> _fullFilteredData = []; // Store all filtered results for client-side pagination
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Filter variables
  List<int> _years = [];
  List<dynamic> _events = [];
  int? _selectedYear;
  int? _selectedEventId;
  String _selectedStatus = 'All'; // 'Paid', 'Pending', 'All'
  
  // Pagination
  int _currentPage = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 10;
  final ScrollController _horizontalScrollController = ScrollController();

  // Column Widths
  final double colSno = 50;
  final double colFamilyId = 180;
  final double colName = 180;
  final double colRole = 100;
  final double colPhone = 130;
  // Aadhar removed
  final double colDistrict = 130;
  final double colTaluk = 130;
  final double colPanchayat = 130;
  final double colVillage = 130;
  final double colEventMoney = 100;
  final double colPaidCash = 100;
  final double colPending = 100;
  final double colStatus = 100;
  final double colLastPaid = 120;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await _fetchYears();
    await _fetchMembers(); // Load all members by default
    setState(() => _isLoading = false);
  }

  Future<void> _fetchYears() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.eventYears));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _years = List<int>.from(data['data']));
      }
    } catch (e) {
      print('Error fetching years: $e');
    }
  }

  Future<void> _fetchEvents(int year) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.eventsByYear}/$year'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _events = data['data'];
          _selectedEventId = null;
        });
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      String url = '${ApiConfig.paymentMembers}?page=$_currentPage&limit=$_itemsPerPage';
      if (widget.userId != null) {
        url += '&user_id=${widget.userId}&role=${widget.role}';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _reportData = data['data'];
          _totalItems = data['total'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error';
        _isLoading = false;
      });
    }
  }

  Future<void> _applyFilters({bool resetPage = true}) async {
    if (_selectedEventId == null && _selectedStatus != 'All') {
      showStatusDialog(
        context,
        title: 'Selection Required',
        message: 'Please select an event to filter by payment status',
        type: DialogType.warning,
      );
      return;
    }

    if (resetPage) {
      _currentPage = 1;
    }

    if (_selectedStatus == 'All' && _selectedEventId == null) {
      _fetchMembers();
      return;
    }

    setState(() => _isLoading = true);
    try {
      Map<String, String> params = {
        'event_id': _selectedEventId.toString(),
        'status': _selectedStatus,
        'page': '1', // Fetch everything for local filtering/pagination
        'limit': '5000',
      };

      if (widget.userId != null) {
        params['user_id'] = widget.userId.toString();
        params['role'] = widget.role.toString();
      }

      final uri = Uri.parse(ApiConfig.filterPayments).replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> results = data['data'];

        // Apply "Fully Paid" filtering logic
        if (_selectedStatus == 'Paid') {
          results = results.where((member) {
            double eventMoney = 0.0;
            try {
              final event = _events.firstWhere((e) => e['Id'] == _selectedEventId);
              eventMoney = double.tryParse(event['TaxAmount']?.toString() ?? '0') ?? 0.0;
            } catch (e) {}
            final paidCash = double.tryParse(member['paidamount']?.toString() ?? '0') ?? 0.0;
            double pendingCash = (member['balanceamount'] != null) ? double.tryParse(member['balanceamount'].toString()) ?? 0.0 : eventMoney - paidCash;
            return pendingCash <= 0 && paidCash > 0;
          }).toList();
        } else if (_selectedStatus == 'Pending') {
          results = results.where((member) {
            double eventMoney = 0.0;
            try {
              final event = _events.firstWhere((e) => e['Id'] == _selectedEventId);
              eventMoney = double.tryParse(event['TaxAmount']?.toString() ?? '0') ?? 0.0;
            } catch (e) {}
            final paidCash = double.tryParse(member['paidamount']?.toString() ?? '0') ?? 0.0;
            double pendingCash = (member['balanceamount'] != null) ? double.tryParse(member['balanceamount'].toString()) ?? 0.0 : eventMoney - paidCash;
            return pendingCash > 0;
          }).toList();
        }

        _fullFilteredData = results;
        _totalItems = results.length;
        
        // Manual pagination from the full list
        int start = (_currentPage - 1) * _itemsPerPage;
        int end = start + _itemsPerPage;
        if (start > _totalItems) start = 0;
        if (end > _totalItems) end = _totalItems;
        
        setState(() {
          _reportData = _fullFilteredData.sublist(start, end);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error applying filters';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadReport() async {
    setState(() => _isLoading = true);
    try {
      List<dynamic> allData = [];
      String url = '';
      
      if (_selectedStatus == 'All' && _selectedEventId == null) {
        url = '${ApiConfig.paymentMembers}?page=1&limit=5000';
        if (widget.userId != null) {
          url += '&user_id=${widget.userId}&role=${widget.role}';
        }
      } else {
        Map<String, String> params = {
          'event_id': _selectedEventId.toString(),
          'status': _selectedStatus,
          'page': '1',
          'limit': '5000',
        };
        if (widget.userId != null) {
          params['user_id'] = widget.userId.toString();
          params['role'] = widget.role.toString();
        }
        final uri = Uri.parse(ApiConfig.filterPayments).replace(queryParameters: params);
        url = uri.toString();
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedData = data['data'];

        // Apply same status filtering for download consistency
        if (_selectedStatus == 'Paid') {
          fetchedData = fetchedData.where((member) {
            double eventMoney = 0.0;
            try {
              final event = _events.firstWhere((e) => e['Id'] == _selectedEventId);
              eventMoney = double.tryParse(event['TaxAmount']?.toString() ?? '0') ?? 0.0;
            } catch (e) {}

            final paidCashStr = member['Collectedamount']?.toString() ?? member['paidamount']?.toString() ?? '0.0';
            final paidCash = double.tryParse(paidCashStr) ?? 0.0;
            
            double pendingCash = 0.0;
            if (member.containsKey('balanceamount') && member['balanceamount'] != null) {
              pendingCash = double.tryParse(member['balanceamount'].toString()) ?? 0.0;
            } else {
              pendingCash = eventMoney - paidCash;
            }
            
            return pendingCash <= 0 && paidCash > 0;
          }).toList();
        } else if (_selectedStatus == 'Pending') {
          fetchedData = fetchedData.where((member) {
            double eventMoney = 0.0;
            try {
              final event = _events.firstWhere((e) => e['Id'] == _selectedEventId);
              eventMoney = double.tryParse(event['TaxAmount']?.toString() ?? '0') ?? 0.0;
            } catch (e) {}

            final paidCashStr = member['Collectedamount']?.toString() ?? member['paidamount']?.toString() ?? '0.0';
            final paidCash = double.tryParse(paidCashStr) ?? 0.0;
            
            double pendingCash = 0.0;
            if (member.containsKey('balanceamount') && member['balanceamount'] != null) {
              pendingCash = double.tryParse(member['balanceamount'].toString()) ?? 0.0;
            } else {
              pendingCash = eventMoney - paidCash;
            }
            
            return pendingCash > 0;
          }).toList();
        }
        allData = fetchedData;
      }

      if (allData.isEmpty) {
        showStatusDialog(
          context,
          title: 'No Data',
          message: 'No data to download',
          type: DialogType.warning,
        );
        setState(() => _isLoading = false);
        return;
      }

      final bool showEventCols = _selectedEventId != null;
      
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      List<CellValue> headers = [
        TextCellValue('Familymembershipid'), 
        TextCellValue('Name'), 
        TextCellValue('State'), 
        TextCellValue('District'), 
        TextCellValue('Taluk'), 
        TextCellValue('Panchayat'), 
        TextCellValue('Phonenumber')
      ];
      
      if (showEventCols) {
        headers.addAll([
          TextCellValue('Event_amount'), 
          TextCellValue('Paid_Amount'), 
          TextCellValue('Pending_Amount'), 
          TextCellValue('lastPaymentdate')
        ]);
      }

      sheetObject.appendRow(headers);

      for (int i = 0; i < allData.length; i++) {
        final member = allData[i];
        
        List<CellValue> row = [
          TextCellValue(member['Familymembershipid']?.toString() ?? '-'),
          TextCellValue(member['Name']?.toString() ?? '-'),
          TextCellValue(member['State']?.toString() ?? '-'),
          TextCellValue(member['District']?.toString() ?? '-'),
          TextCellValue(member['Taluk']?.toString() ?? '-'),
          TextCellValue(member['Panchayat']?.toString() ?? '-'),
          TextCellValue(member['Phonenumber']?.toString() ?? '-'),
        ];

        if (showEventCols) {
          double eventMoney = 0.0;
          try {
            final event = _events.firstWhere((e) => e['Id'] == _selectedEventId);
            eventMoney = double.tryParse(event['TaxAmount']?.toString() ?? '0') ?? 0.0;
          } catch (e) {}

          final paidCash = double.tryParse(member['paidamount']?.toString() ?? '0') ?? 0.0;
          final pendingCash = eventMoney - paidCash;
          final lastPaid = member['paymentdate'] ?? '-';

          row.addAll([
            DoubleCellValue(eventMoney),
            DoubleCellValue(paidCash),
            DoubleCellValue(pendingCash),
            TextCellValue(lastPaid.toString())
          ]);
        }
        sheetObject.appendRow(row);
      }

      String eventName = 'All';
      if (_selectedEventId != null) {
        try {
          eventName = _events.firstWhere((e) => e['Id'] == _selectedEventId)['EventName'];
        } catch (e) {}
      }
      
      String filename = '${eventName}_${_selectedStatus}.xlsx';
      var fileBytes = excel.encode();
      if (fileBytes != null) {
        dl.downloadBytes(Uint8List.fromList(fileBytes), filename);
      }

    } catch (e) {
      showStatusDialog(
        context,
        title: 'Download Error',
        message: 'Download failed: $e',
        type: DialogType.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingSpinner(message: 'Preparing report data...');
    }
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.reportStatusFilter ?? 'Report Status Filter:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            _buildFilterSection(isMobile),
            const SizedBox(height: 20),
            _buildSummarySection(isMobile),
            const SizedBox(height: 12),
            _buildTableSection(),
            _buildPagination(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isMobile) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFilterDropdown(AppLocalizations.of(context)?.chooseEventYear ?? 'CHOOSE EVENT YEAR', Icons.calendar_today, const Color(0xFF5D1712), _years, _selectedYear, (val) {
                        setState(() => _selectedYear = val);
                        _fetchEvents(val!);
                      }, isMobile: isMobile),
                      const SizedBox(height: 16),
                      _buildFilterDropdown(AppLocalizations.of(context)?.chooseEvents ?? 'CHOOSE EVENTS', Icons.event, Colors.orange, _events, _selectedEventId, (val) {
                        setState(() => _selectedEventId = val);
                      }, isEvent: true, isMobile: isMobile),
                      const SizedBox(height: 16),
                      _buildStatusFilter(isMobile),
                    ],
                  )
                : Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _buildFilterDropdown(AppLocalizations.of(context)?.chooseEventYear ?? 'CHOOSE EVENT YEAR', Icons.calendar_today, const Color(0xFF5D1712), _years, _selectedYear, (val) {
                        setState(() => _selectedYear = val);
                        _fetchEvents(val!);
                      }, isMobile: isMobile),
                      _buildFilterDropdown(AppLocalizations.of(context)?.chooseEvents ?? 'CHOOSE EVENTS', Icons.event, Colors.orange, _events, _selectedEventId, (val) {
                        setState(() => _selectedEventId = val);
                      }, isEvent: true, isMobile: isMobile),
                      _buildStatusFilter(isMobile),
                    ],
                  ),
            const SizedBox(height: 16),
            Align(
              alignment: isMobile ? Alignment.center : Alignment.centerRight,
              child: SizedBox(
                width: isMobile ? double.infinity : null,
                child: ElevatedButton.icon(
                  onPressed: () => _applyFilters(resetPage: true),
                  icon: const Icon(Icons.filter_alt),
                  label: Text(AppLocalizations.of(context)?.applyFilterBtn ?? 'Apply Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D1712),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, IconData icon, Color iconColor, List<dynamic> items, dynamic value, Function(dynamic) onChanged, {bool isEvent = false, bool isMobile = false}) {
    // Build a Map<String, String> where key = id (as string), value = display label
    final Map<String, String> dropdownMap = {
      for (var item in items)
        (isEvent ? item['Id'].toString() : item.toString()):
        (isEvent ? item['EventName'].toString() : item.toString())
    };

    final String? selectedKey = value != null ? value.toString() : null;

    return Container(
      width: isMobile ? double.infinity : 280,
      constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          CustomDropdownSearch(
            label: '',
            hint: isEvent ? (AppLocalizations.of(context)?.chooseEventHint ?? 'Choose Event') : (AppLocalizations.of(context)?.chooseYearHint ?? 'Choose Year'),
            dropdownMap: dropdownMap,
            value: selectedKey,
            onChanged: (val) {
              if (val == null) {
                onChanged(null);
              } else {
                onChanged(int.tryParse(val));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)?.paymentStatusFilter ?? 'PAYMENT STATUS', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: isMobile ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildRadioOption(AppLocalizations.of(context)?.paidUsers ?? 'Paid Users', 'Paid'),
                _buildRadioOption(AppLocalizations.of(context)?.unpaidUsers ?? 'Unpaid Users', 'Pending'),
                _buildRadioOption(AppLocalizations.of(context)?.allUsers ?? 'All Users', 'All'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedStatus,
          onChanged: (val) => setState(() => _selectedStatus = val!),
          activeColor: const Color(0xFF5D1712),
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSummarySection(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            "${AppLocalizations.of(context)?.totalMembersHeader ?? 'Total Members: '}$_totalItems",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          SizedBox(
            width: isMobile ? double.infinity : null,
            child: ElevatedButton.icon(
              onPressed: _downloadReport,
              icon: const Icon(Icons.download, size: 18),
              label: Text(AppLocalizations.of(context)?.downloadExcelBtn ?? 'Download Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection() {
    if (_isLoading) return const Center(child: LoadingSpinner(message: 'Generating report...'));
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));

    final bool showEventCols = _selectedEventId != null;
    final double fixedWidth = colSno + colFamilyId + colName + colPhone + 20; // 20 is left padding
    final double scrollableWidth = colRole + colDistrict + colTaluk + colPanchayat + colVillage + (showEventCols ? colEventMoney + colPaidCash + colPending + colStatus + colLastPaid : 0) + 20; // 20 is right padding

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          
          Widget rightPart = Column(
            children: [
              // Header
              Container(
                color: const Color(0xFF2D1B18),
                height: 48,
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  children: [
                    _buildCell(AppLocalizations.of(context)?.roleHeader ?? 'ROLE', colRole, isHeader: true, hasDivider: true),
                    _buildCell(AppLocalizations.of(context)?.districtHeader ?? 'DISTRICT', colDistrict, isHeader: true, hasDivider: true),
                    _buildCell(AppLocalizations.of(context)?.talukHeader ?? 'TALUK', colTaluk, isHeader: true, hasDivider: true),
                    _buildCell(AppLocalizations.of(context)?.panchayatHeader ?? 'PANCHAYAT', colPanchayat, isHeader: true, hasDivider: true),
                    _buildCell(AppLocalizations.of(context)?.villageUpperHeader ?? 'VILLAGE', colVillage, isHeader: true, hasDivider: showEventCols),
                    if (showEventCols) ...[
                      _buildCell(AppLocalizations.of(context)?.eventMoneyHeader ?? 'EVENTMONEY', colEventMoney, isHeader: true, hasDivider: true),
                      _buildCell(AppLocalizations.of(context)?.paidCashHeader ?? 'PAIDCASH', colPaidCash, isHeader: true, hasDivider: true),
                      _buildCell(AppLocalizations.of(context)?.pendingHeader ?? 'PENDING', colPending, isHeader: true, hasDivider: true),
                      _buildCell(AppLocalizations.of(context)?.statusLabel?.toUpperCase() ?? 'STATUS', colStatus, isHeader: true, hasDivider: true),
                      _buildCell(AppLocalizations.of(context)?.lastPaidHeader ?? 'LASTPAID', colLastPaid, isHeader: true, hasDivider: false),
                    ],
                  ],
                ),
              ),
              // Data
              _reportData.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No data found for selected filters')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _reportData.length,
                      itemBuilder: (context, index) => _buildScrollableDataRow(index),
                    ),
            ],
          );
          
          Widget tableContent = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed Left Part
              SizedBox(
                width: fixedWidth,
                child: Column(
                  children: [
                    // Header
                    Container(
                      color: const Color(0xFF2D1B18),
                      height: 48,
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        children: [
                          _buildCell(AppLocalizations.of(context)?.sNo?.toUpperCase() ?? 'S.NO', colSno, isHeader: true, hasDivider: true),
                          _buildCell(AppLocalizations.of(context)?.familyMembershipIdHeader ?? 'FAMILYMEMBERSHIP ID', colFamilyId, isHeader: true, hasDivider: true),
                          _buildCell(AppLocalizations.of(context)?.userNameHeader ?? 'USER NAME', colName, isHeader: true, hasDivider: true),
                          _buildCell(AppLocalizations.of(context)?.phoneNoHeader ?? 'PHONE NO', colPhone, isHeader: true, hasDivider: true),
                        ],
                      ),
                    ),
                    // Data
                    _reportData.isEmpty
                        ? Container()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _reportData.length,
                            itemBuilder: (context, index) => _buildFixedDataRow(index),
                          ),
                  ],
                ),
              ),
              
              // Scrollable Right Part
              isNarrow
                  ? SizedBox(width: scrollableWidth, child: rightPart)
                  : Expanded(
                      child: Scrollbar(
                        controller: _horizontalScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: scrollableWidth,
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
              thumbVisibility: true,
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
                onBack: () {
                  Navigator.pop(context);
                  _applyFilters(resetPage: false);
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

  Widget _buildCell(String text, double width, {bool isHeader = false, bool isBlue = false, bool isBold = false, bool isPill = false, bool hasDivider = true}) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        border: hasDivider ? const Border(right: BorderSide(color: Colors.white24, width: 0.5)) : null,
      ),
      child: Center(
        child: isPill 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                text,
                style: TextStyle(
                  color: isHeader ? Colors.white : (isBlue ? const Color(0xFF5D1712) : Colors.black87),
                  fontWeight: isHeader || isBlue || isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isHeader ? 11 : 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr == '-' || dateStr == 'N/A') return '-';
    try {
      final date = DateTime.parse(dateStr.toString());
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      return dateStr.toString();
    }
  }

  Widget _buildFixedDataRow(int index) {
    final member = _reportData[index];
    final sno = (_currentPage - 1) * _itemsPerPage + index + 1;

    return Material(
      color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
      child: Container(
        height: 46,
        padding: const EdgeInsets.only(left: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: Row(
          children: [
            _buildCell(sno.toString(), colSno, hasDivider: true),
            _buildCell(member['Familymembershipid'] ?? '-', colFamilyId, isBlue: true, hasDivider: true),
            _buildCell(member['Name'] ?? 'N/A', colName, isBold: true, hasDivider: true),
            _buildCell(member['Phonenumber']?.toString() ?? '-', colPhone, hasDivider: true),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableDataRow(int index) {
    final member = _reportData[index];

    double eventMoney = 0.0;
    if (_selectedEventId != null) {
      try {
        final event = _events.firstWhere((e) => e['Id'] == _selectedEventId);
        eventMoney = double.tryParse(event['TaxAmount']?.toString() ?? '0') ?? 0.0;
      } catch (e) {
        eventMoney = double.tryParse(member['TaxAmount']?.toString() ?? member['taxamount']?.toString() ?? '0.0') ?? 0.0;
      }
    }

    final paidCashStr = member['Collectedamount']?.toString() ?? member['paidamount']?.toString() ?? '0.0';
    final paidCash = double.tryParse(paidCashStr) ?? 0.0;

    double pendingCash = 0.0;
    if (member.containsKey('balanceamount') && member['balanceamount'] != null) {
      pendingCash = double.tryParse(member['balanceamount'].toString()) ?? 0.0;
    } else {
      pendingCash = eventMoney - paidCash;
      if (pendingCash < 0) pendingCash = 0;
    }

    String status = 'Pending';
    if (eventMoney > 0) {
      if (pendingCash <= 0 && paidCash > 0) {
        status = 'Paid';
      } else if (paidCash > 0) {
        status = 'Partial';
      }
    }
    
    final lastPaidRaw = member['paymentdate']?.toString().split(' ').first ?? member['Updated_at']?.toString().split(' ').first ?? member['updated_at']?.toString().split(' ').first ?? member['created_at']?.toString().split(' ').first ?? '-';
    final lastPaid = _formatDate(lastPaidRaw);

    final bool showEventCols = _selectedEventId != null;

    return Material(
      color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
      child: Container(
        height: 46,
        padding: const EdgeInsets.only(right: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: Row(
          children: [
            _buildCell(member['Role']?.toString() ?? '-', colRole, isPill: true, hasDivider: true),
            _buildCell(member['District'] ?? '-', colDistrict, hasDivider: true),
            _buildCell(member['Taluk'] ?? '-', colTaluk, hasDivider: true),
            _buildCell(member['Panchayat'] ?? '-', colPanchayat, hasDivider: true),
            _buildCell(member['Village'] ?? '-', colVillage, hasDivider: showEventCols),
            if (showEventCols) ...[
              _buildCell(eventMoney.toStringAsFixed(1), colEventMoney, hasDivider: true),
              _buildCell(paidCash.toStringAsFixed(1), colPaidCash, hasDivider: true),
              _buildCell(pendingCash.toStringAsFixed(1), colPending, isBold: true, isBlue: pendingCash > 0, hasDivider: true),
              _buildCell(status, colStatus, isPill: true, hasDivider: true),
              _buildCell(lastPaid, colLastPaid, hasDivider: false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(bool isMobile) {
    if (_totalItems <= _itemsPerPage) return const SizedBox.shrink();
    int totalPages = (_totalItems / _itemsPerPage).ceil();

    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: isMobile 
        ? Column(
            children: [
              Text('Total $_totalItems entries', style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 12),
              _buildPaginationRow(totalPages),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${_currentPage * _itemsPerPage > _totalItems ? _totalItems : _currentPage * _itemsPerPage} of $_totalItems entries',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              _buildPaginationRow(totalPages),
            ],
          ),
    );
  }

  Widget _buildPaginationRow(int totalPages) {
    return PaginationWidget(
      currentPage: _currentPage,
      totalPages: totalPages,
      onPageChanged: (page) => setState(() { 
        _currentPage = page; 
        _applyFilters(resetPage: false); 
      }),
    );
  }
}
