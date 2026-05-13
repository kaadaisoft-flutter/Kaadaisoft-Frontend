import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' hide Border;
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';
import '../../utils/download_helper.dart' as dl;
import 'update_details_content.dart';

class ReportsContent extends StatefulWidget {
  final int? userId;
  final int? role;

  const ReportsContent({super.key, this.userId, this.role});

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
        url = '${ApiConfig.paymentMembers}?page=1&limit=$_totalItems';
        if (widget.userId != null) {
          url += '&user_id=${widget.userId}&role=${widget.role}';
        }
      } else {
        Map<String, String> params = {
          'event_id': _selectedEventId.toString(),
          'status': _selectedStatus,
          'page': '1',
          'limit': '$_totalItems',
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

        // Apply same "Fully Paid" filtering for download
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
            const Text(
              'Report Status Filter:',
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
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _buildFilterDropdown('CHOOSE EVENT YEAR', Icons.calendar_today, Colors.blue, _years, _selectedYear, (val) {
                  setState(() => _selectedYear = val);
                  _fetchEvents(val!);
                }),
                _buildFilterDropdown('CHOOSE EVENTS', Icons.event, Colors.orange, _events, _selectedEventId, (val) {
                  setState(() => _selectedEventId = val);
                }, isEvent: true),
                _buildStatusFilter(),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: isMobile ? Alignment.center : Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _applyFilters(resetPage: true),
                icon: const Icon(Icons.filter_alt),
                label: const Text('Apply Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, IconData icon, Color iconColor, List<dynamic> items, dynamic value, Function(dynamic) onChanged, {bool isEvent = false}) {
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxWidth: 300),
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
          DropdownButtonFormField<int>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
              hintText: isEvent ? 'Choose Event' : 'Choose Year',
            ),
            items: items.map((item) {
              return DropdownMenuItem<int>(
                value: isEvent ? item['Id'] : item,
                child: Text(isEvent ? item['EventName'] : item.toString(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.payment, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Text('PAYMENT STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildRadioOption('Paid Users', 'Paid'),
              _buildRadioOption('Unpaid Users', 'Pending'),
              _buildRadioOption('All Users', 'All'),
            ],
          ),
        ),
      ],
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
          activeColor: Colors.blue,
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSummarySection(bool isMobile) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Total Members: $_totalItems',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        SizedBox(
          width: isMobile ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: _downloadReport,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download Excel'),
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
    );
  }

  Widget _buildTableSection() {
    if (_isLoading) return const Center(child: LoadingSpinner(message: 'Generating report...'));
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));

    final bool showEventCols = _selectedEventId != null;
    // Total table width (sum of columns + spacing)
    final double totalTableWidth = colSno + colFamilyId + colName + colRole + colPhone + colDistrict + colTaluk + colPanchayat + colVillage + (showEventCols ? colEventMoney + colPaidCash + colPending + colStatus + colLastPaid : 0) + 60;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalTableWidth,
            child: Column(
              children: [
                // Header
                Container(
                  color: const Color(0xFF172030),
                  height: 48, // Reduced height
                  child: Row(
                    children: [
                      _buildCell('S.NO', colSno, isHeader: true, hasDivider: true),
                      _buildCell('FAMILYMEMBERSHIP ID', colFamilyId, isHeader: true, hasDivider: true),
                      _buildCell('USER NAME', colName, isHeader: true, hasDivider: true),
                      _buildCell('ROLE', colRole, isHeader: true, hasDivider: true),
                      _buildCell('PHONE NO', colPhone, isHeader: true, hasDivider: true),
                      _buildCell('DISTRICT', colDistrict, isHeader: true, hasDivider: true),
                      _buildCell('TALUK', colTaluk, isHeader: true, hasDivider: true),
                      _buildCell('PANCHAYAT', colPanchayat, isHeader: true, hasDivider: true),
                      _buildCell('VILLAGE', colVillage, isHeader: true, hasDivider: showEventCols),
                      if (showEventCols) ...[
                        _buildCell('EVENTMONEY', colEventMoney, isHeader: true, hasDivider: true),
                        _buildCell('PAIDCASH', colPaidCash, isHeader: true, hasDivider: true),
                        _buildCell('PENDING', colPending, isHeader: true, hasDivider: true),
                        _buildCell('STATUS', colStatus, isHeader: true, hasDivider: true),
                        _buildCell('LASTPAID', colLastPaid, isHeader: true, hasDivider: false),
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
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: _reportData.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) => _buildDataRow(index),
                      ),
              ],
            ),
          ),
        ),
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
                  color: isHeader ? Colors.white : (isBlue ? Colors.blue : Colors.black87),
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

  Widget _buildDataRow(int index) {
    final member = _reportData[index];
    final sno = (_currentPage - 1) * _itemsPerPage + index + 1;

    double eventMoney = 0.0;
    if (_selectedEventId != null) {
      try {
        final event = _events.firstWhere((e) => e['Id'] == _selectedEventId);
        eventMoney = double.tryParse(event['TaxAmount']?.toString() ?? '0') ?? 0.0;
      } catch (e) {
        eventMoney = double.tryParse(member['Taxamount']?.toString() ?? member['taxamount']?.toString() ?? '0.0') ?? 0.0;
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

    return Material(
      color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
      child: Container(
        height: 46, // Reduced height for 10-item visibility
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: Row(
            children: [
              _buildCell(sno.toString(), colSno, hasDivider: true),
              _buildCell(member['Familymembershipid'] ?? '-', colFamilyId, isBlue: true, hasDivider: true),
              _buildCell(member['Name'] ?? 'N/A', colName, isBold: true, hasDivider: true),
              _buildCell(member['Role']?.toString() ?? '-', colRole, isPill: true, hasDivider: true),
              _buildCell(member['Phonenumber']?.toString() ?? '-', colPhone, hasDivider: true),
              _buildCell(member['District'] ?? '-', colDistrict, hasDivider: true),
              _buildCell(member['Taluk'] ?? '-', colTaluk, hasDivider: true),
              _buildCell(member['Panchayat'] ?? '-', colPanchayat, hasDivider: true),
              _buildCell(member['Village'] ?? '-', colVillage, hasDivider: _selectedEventId != null),
              if (_selectedEventId != null) ...[
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageBtn(Icons.chevron_left, _currentPage > 1 ? () => setState(() { _currentPage--; _applyFilters(resetPage: false); }) : null),
          const SizedBox(width: 8),
          ...List.generate(totalPages > 5 ? 5 : totalPages, (i) {
            int page = i + 1;
            return _buildPageNum(page, page == _currentPage, () => setState(() { _currentPage = page; _applyFilters(resetPage: false); }));
          }),
          if (totalPages > 5) ...[
            const Text('...'),
            _buildPageNum(totalPages, totalPages == _currentPage, () => setState(() { _currentPage = totalPages; _applyFilters(resetPage: false); })),
          ],
          const SizedBox(width: 8),
          _buildPageBtn(Icons.chevron_right, _currentPage < totalPages ? () => setState(() { _currentPage++; _applyFilters(resetPage: false); }) : null),
        ],
      ),
    );
  }

  Widget _buildPageBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: onTap == null ? Colors.grey : Colors.blue),
      ),
    );
  }

  Widget _buildPageNum(int num, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1E283C) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active ? null : Border.all(color: Colors.black12),
          ),
          alignment: Alignment.center,
          child: Text(num.toString(), style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}
