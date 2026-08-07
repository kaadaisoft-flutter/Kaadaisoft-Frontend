import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/custom_dropdown_search.dart';
import 'package:http/http.dart' as http;
import '../widgets/loading_spinner.dart';
import '../widgets/payment_form.dart';
import '../widgets/receipt_dialog.dart';
import '../widgets/receipt_content.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';
import '../utils/pdf_generator.dart';
import 'package:screenshot/screenshot.dart';
import 'update_details_content.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

class PaymentsContent extends StatefulWidget {
  final int? userId;
  final int? role;
  final String? globalSearchQuery;

  const PaymentsContent({super.key, this.userId, this.role, this.globalSearchQuery});

  @override
  State<PaymentsContent> createState() => _PaymentsContentState();
}

class _PaymentsContentState extends State<PaymentsContent> {
  List<dynamic> _members = [];
  List<dynamic> _fullFilteredMembers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Member view (role == 3)
  Map<String, dynamic>? _memberData;
  Map<String, dynamic>? _coordinatorData;
  List<dynamic> _receipts = [];

  
  // Filter variables
  bool _isFilterVisible = false;
  List<int> _years = [];
  List<dynamic> _events = [];
  int? _selectedYear;
  int? _selectedEventId;
  String _selectedStatus = 'Pending';
  
  // Geographic filters
  List<dynamic> _districts = [];
  List<dynamic> _taluks = [];
  List<dynamic> _panchayats = [];
  List<dynamic> _villages = [];
  String? _selectedDistrict;
  String? _selectedTaluk;
  String? _selectedPanchayat;
  String? _selectedVillage;

  // Pagination
  int _currentPage = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 10;
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Column Widths
  final double colSno = 50;
  final double colFamilyId = 120;
  final double colName = 180;
  final double colRole = 120;
  // Aadhar removed
  final double colMobile = 120;
  final double colDistrict = 110;
  final double colTaluk = 110;
  final double colPanchayat = 110;
  final double colVillage = 110;
  final double colActions = 250;

  @override
  void initState() {
    super.initState();
    if (widget.globalSearchQuery != null) {
      _searchController.text = widget.globalSearchQuery!;
    }
    _fetchInitialData();
  }

  @override
  void didUpdateWidget(covariant PaymentsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.globalSearchQuery != oldWidget.globalSearchQuery) {
      _searchController.text = widget.globalSearchQuery ?? '';
      _fetchInitialData();
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    if (widget.role == 3) {
      await _fetchMemberCoordinator();
    } else {
      if (widget.role == 2 && widget.userId != null) {
        await _fetchMemberCoordinator();
        if (_memberData != null) {
          _selectedDistrict = _memberData!['District'];
          if (_selectedDistrict != null) {
            await _fetchTaluks(_selectedDistrict!);
            _selectedTaluk = _memberData!['Taluk'];
            if (_selectedTaluk != null) {
              await _fetchPanchayats(_selectedTaluk!);
              _selectedPanchayat = _memberData!['Panchayat'];
              if (_selectedPanchayat != null) {
                await _fetchVillages(_selectedPanchayat!);
                _selectedVillage = _memberData!['Village'];
              }
            }
          }
        }
      }
      await Future.wait([
        _fetchYears(),
        _fetchDistricts(),
        _fetchMembers(),
      ]);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchMemberCoordinator() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/member-coordinator/${widget.userId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _memberData = data['member'];
          _coordinatorData = data['coordinator'];
          _receipts = data['receipts'] ?? [];
        });
      } else {
        setState(() => _errorMessage = 'Failed to load payment details');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Connection error');
    }
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

  Future<void> _fetchDistricts() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _districts = data['data']);
      }
    } catch (e) {
      print('Error fetching districts: $e');
    }
  }

  Future<void> _fetchTaluks(String district) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _taluks = data['data'];
          _selectedTaluk = null;
          _panchayats = [];
          _selectedPanchayat = null;
          _villages = [];
          _selectedVillage = null;
        });
      }
    } catch (e) {
      print('Error fetching taluks: $e');
    }
  }

  Future<void> _fetchPanchayats(String taluk) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _panchayats = data['data'];
          _selectedPanchayat = null;
          _villages = [];
          _selectedVillage = null;
        });
      }
    } catch (e) {
      print('Error fetching panchayats: $e');
    }
  }

  Future<void> _fetchVillages(String panchayat) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _villages = data['data'];
          _selectedVillage = null;
        });
      }
    } catch (e) {
      print('Error fetching villages: $e');
    }
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      String url = '${ApiConfig.paymentMembers}?page=$_currentPage&limit=$_itemsPerPage';
      if (_searchController.text.isNotEmpty) {
        url += '&search=${_searchController.text}';
      }
      if (widget.userId != null) {
        url += '&user_id=${widget.userId}&role=${widget.role}';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _members = data['data'];
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

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    if (_selectedEventId == null) {
      _fetchMembers();
    } else {
      // Manual pagination from _fullFilteredMembers
      int start = (_currentPage - 1) * _itemsPerPage;
      int end = start + _itemsPerPage;
      if (start > _totalItems) start = 0;
      if (end > _totalItems) end = _totalItems;
      setState(() {
        _members = _fullFilteredMembers.sublist(start, end);
      });
    }
  }

  void _clearFilters() {
    setState(() {
      if (widget.role != 2) {
        _selectedDistrict = null;
        _selectedTaluk = null;
        _selectedPanchayat = null;
        _selectedVillage = null;
      }
      _selectedYear = null;
      _selectedEventId = null;
      _selectedStatus = 'Paid';
    });
    _searchController.clear();
    _currentPage = 1;
    _fetchMembers();
  }

  Future<void> _applyFilters({bool resetPage = true}) async {
    if (_selectedEventId == null) {
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

    setState(() => _isLoading = true);
    try {
      Map<String, String> params = {
        'event_id': _selectedEventId.toString(),
        'status': _selectedStatus,
        'page': '1', // Fetch everything for local filtering/pagination
        'limit': '5000',
      };

      if (_selectedDistrict != null) params['district'] = _selectedDistrict!;
      if (_selectedTaluk != null) params['taluk'] = _selectedTaluk!;
      if (_selectedPanchayat != null) params['panchayat'] = _selectedPanchayat!;
      if (_selectedVillage != null) params['village'] = _selectedVillage!;
      if (widget.userId != null) {
        params['user_id'] = widget.userId.toString();
        params['role'] = widget.role.toString();
      }

      final uri = Uri.parse(ApiConfig.filterPayments).replace(queryParameters: params);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> results = data['data'];

        // Get the selected event tax amount
        double eventMoney = 0.0;
        try {
          final event = _events.firstWhere((e) => e['Id'] == _selectedEventId);
          eventMoney = double.tryParse(event['TaxAmount']?.toString() ?? '0') ?? 0.0;
        } catch (e) {}

        // Apply "Fully Paid" vs "Pending" filtering logic
        if (_selectedStatus == 'Paid') {
          results = results.where((member) {
            final paidCash = double.tryParse(member['paidamount']?.toString() ?? '0') ?? 0.0;
            double pendingCash = (member['balanceamount'] != null) ? double.tryParse(member['balanceamount'].toString()) ?? 0.0 : eventMoney - paidCash;
            return pendingCash <= 0 && paidCash > 0;
          }).toList();
        } else if (_selectedStatus == 'Pending') {
          results = results.where((member) {
            final paidCash = double.tryParse(member['paidamount']?.toString() ?? '0') ?? 0.0;
            double pendingCash = (member['balanceamount'] != null) ? double.tryParse(member['balanceamount'].toString()) ?? 0.0 : eventMoney - paidCash;
            return pendingCash > 0;
          }).toList();
        }

        _fullFilteredMembers = results;
        _totalItems = results.length;

        // Manual pagination
        int start = (_currentPage - 1) * _itemsPerPage;
        int end = start + _itemsPerPage;
        if (start > _totalItems) start = 0;
        if (end > _totalItems) end = _totalItems;

        setState(() {
          _members = _fullFilteredMembers.sublist(start, end);
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

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    if (_isLoading) return const LoadingSpinner(message: 'Loading payment data...');
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));

    // Member view
    if (widget.role == 3) return _buildMemberView();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(isMobile),
          if (_isFilterVisible) _buildFilterSection(isMobile),
          const SizedBox(height: 8),
          _buildTableSection(),
          _buildPagination(isMobile),
        ],
      ),
    );
  }

  Widget _buildMemberView() {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    final member = _memberData;
    final coord = _coordinatorData;
    final displayReceipts = _getFilteredApprovedReceipts();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            AppLocalizations.of(context)?.myFinancialReport ?? 'My Financial Report', 
            style: TextStyle(
              fontSize: isMobile ? 20 : 24, 
              fontWeight: FontWeight.bold, 
              color: const Color(0xFF2D1B18)
            )
          ),
          const SizedBox(height: 28),

          // Payment Receipt History
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: const Color(0xFF2D1B18),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  ),
                  child: isMobile 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)?.myPaymentReceiptHistory ?? 'My Payment Receipt History', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                            child: Text('${displayReceipts.length} ${AppLocalizations.of(context)?.records ?? "record(s)"}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)?.myPaymentReceiptHistory ?? 'My Payment Receipt History', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                            child: Text('${displayReceipts.length} ${AppLocalizations.of(context)?.records ?? "record(s)"}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                ),
                if (displayReceipts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(AppLocalizations.of(context)?.noPaymentReceiptsFound ?? 'No payment receipts found.', style: const TextStyle(color: Colors.black45))),
                  )
                else
                  ..._buildGroupedReceiptTables(displayReceipts, isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({required String title, required Map<String, dynamic> data, bool showPayNow = false, bool isMobile = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D1B18).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF2D1B18), const Color(0xFF2D1B18)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: isMobile 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          data['Role'] == 2 ? Icons.admin_panel_settings_rounded : Icons.verified_user_rounded, 
                          color: data['Role'] == 2 ? Colors.orangeAccent : const Color(0xFF5D1712), 
                          size: 20
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            data['Role'] == 2 ? 'Coordinator Details:' : title, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.2),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (showPayNow) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showPaymentDialog(data),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D1712),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('PAY NOW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          data['Role'] == 2 ? Icons.admin_panel_settings_rounded : Icons.verified_user_rounded, 
                          color: data['Role'] == 2 ? Colors.orangeAccent : const Color(0xFF5D1712), 
                          size: 20
                        ),
                        const SizedBox(width: 12),
                        Text(
                          data['Role'] == 2 ? 'Coordinator Details:' : title, 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.2)
                        ),
                      ],
                    ),
                    if (showPayNow)
                      ElevatedButton(
                        onPressed: () => _showPaymentDialog(data),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D1712),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('PAY NOW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
                      ),
                  ],
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildInfoRow('Full Name', data['Name'] ?? '-', icon: Icons.person_outline, isFirst: true, isMobile: isMobile),
                _buildInfoRow('Membership ID', data['Familymembershipid'] ?? '-', icon: Icons.badge_outlined, valueColor: const Color(0xFF5D1712), isMobile: isMobile),
                _buildInfoRow('Taluk / Region', data['Taluk'] ?? '-', icon: Icons.location_city_outlined, isMobile: isMobile),
                _buildInfoRow('District', data['District'] ?? '-', icon: Icons.map_outlined, isMobile: isMobile),
                _buildInfoRow('Pincode', data['Pincode']?.toString() ?? '-', icon: Icons.pin_drop_outlined, isMobile: isMobile),
                _buildInfoRow('Contact Number', data['Phonenumber']?.toString() ?? '-', icon: Icons.phone_android_outlined, valueColor: Colors.green.shade700, isLast: true, isMobile: isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required IconData icon, Color? valueColor, bool isFirst = false, bool isLast = false, bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.black.withOpacity(0.04), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: isMobile ? 3 : 2,
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
          ),
          Expanded(
            flex: isMobile ? 4 : 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? const Color(0xFF2D1B18)),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  List<dynamic> _getFilteredApprovedReceipts() {
    final searchQuery = _searchController.text.toLowerCase();
    
    // Filter receipts: only show approved or legacy (null) receipts in the history, and apply search filter
    final approved = _receipts.where((r) {
      final approvalStatus = r['approval_status']?.toString();
      final isApproved = approvalStatus != 'Pending' && approvalStatus != 'Rejected';
      if (!isApproved) return false;

      if (searchQuery.isNotEmpty) {
        final eventName = (r['eventname']?.toString() ?? r['EventName']?.toString() ?? '').toLowerCase();
        final amount = r['amount']?.toString().toLowerCase() ?? '';
        final year = r['year']?.toString().toLowerCase() ?? '';
        final dues = r['dues']?.toString().toLowerCase() ?? '';
        final date = r['paymentdate']?.toString().toLowerCase() ?? '';
        final bank = (r['bankname']?.toString() ?? r['banknameforcheckque']?.toString() ?? '').toLowerCase();
        final refNo = r['referencenumber']?.toString().toLowerCase() ?? '';
        final paid = (r['Collectedamount']?.toString() ?? r['paidamount']?.toString() ?? '').toLowerCase();

        return eventName.contains(searchQuery) ||
               amount.contains(searchQuery) ||
               year.contains(searchQuery) ||
               dues.contains(searchQuery) ||
               date.contains(searchQuery) ||
               bank.contains(searchQuery) ||
               paid.contains(searchQuery) ||
               refNo.contains(searchQuery);
      }
      return true;
    }).toList();

    // Group receipts by event name to mimic the UI behavior (hiding pending if a paid receipt exists)
    final Map<String, List<dynamic>> grouped = {};
    for (var r in approved) {
      final name = r['eventname']?.toString() ?? r['EventName']?.toString() ?? AppLocalizations.of(context)?.otherUpper ?? 'OTHER';
      grouped.putIfAbsent(name, () => []).add(r);
    }

    final List<dynamic> finalDisplayItems = [];
    grouped.forEach((eventName, items) {
      final hasFullyPaid = items.any((r) => (r['status']?.toString() ?? '').toLowerCase() == 'paid');
      if (hasFullyPaid) {
        finalDisplayItems.addAll(items.where((r) => (r['status']?.toString() ?? '').toLowerCase() == 'paid'));
      } else {
        finalDisplayItems.addAll(items);
      }
    });

    return finalDisplayItems;
  }

  List<Widget> _buildGroupedReceiptTables(List<dynamic> approvedReceipts, bool isMobile) {

    // Group receipts by event name
    final Map<String, List<dynamic>> grouped = {};
    for (var r in approvedReceipts) {
      final name = r['eventname']?.toString() ?? r['EventName']?.toString() ?? AppLocalizations.of(context)?.otherUpper ?? 'OTHER';
      grouped.putIfAbsent(name, () => []).add(r);
    }

    List<Widget> sections = [];
    grouped.forEach((eventName, items) {
      final hasFullyPaid = items.any((r) => (r['status']?.toString() ?? '').toLowerCase() == 'paid');
      final displayItems = hasFullyPaid 
          ? items.where((r) => (r['status']?.toString() ?? '').toLowerCase() == 'paid').toList()
          : items;

      sections.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(left: BorderSide(color: Color(0xFF5D1712), width: 4)),
          ),
          child: Text(
            eventName.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF5D1712), letterSpacing: 1),
          ),
        ),
      );
      sections.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: displayItems.map((r) {
              final status = r['status']?.toString() ?? 'Pending';
              final balance = (r['balanceamount'] ?? 0.0);
              final balanceVal = balance is double ? balance : double.tryParse(balance.toString()) ?? 0.0;
              final taxamt = r['TaxAmount'] ?? r['taxamount'] ?? 0.0;
              final taxVal = taxamt is double ? taxamt : double.tryParse(taxamt.toString()) ?? 0.0;
              final paid = r['Collectedamount'] ?? r['paidamount'] ?? 0.0;
              final paidVal = paid is double ? paid : double.tryParse(paid.toString()) ?? 0.0;
              final dues = r['dues']?.toString() ?? '-';
              final isPaid = status.toLowerCase() == 'paid';
              final date = r['paymentdate']?.toString() ?? '-';
              final year = r['year']?.toString() ?? '-';
              final paymentDetails = _getPaymentDetailsStr(r);

              Widget financialSummary = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)?.paidUpper ?? 'PAID AMOUNT', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('${paidVal.toStringAsFixed(0)} ${AppLocalizations.of(context)?.rs ?? "Rs"}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isPaid ? Colors.green.shade700 : Colors.red.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text('${AppLocalizations.of(context)?.totalAmountUpper ?? 'TOTAL'}: ${taxVal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                      Text('${AppLocalizations.of(context)?.pendingUpper ?? 'PENDING'}: ${balanceVal.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: balanceVal > 0 ? Colors.red.shade600 : Colors.black54, fontWeight: FontWeight.w500)),
                    ],
                  )
                ],
              );

              Widget transactionDetails = Wrap(
                spacing: 32,
                runSpacing: 16,
                children: [
                  _buildDetailItem(Icons.calendar_today_outlined, AppLocalizations.of(context)?.dateUpper ?? 'DATE & YEAR', '$date ($year)'),
                  _buildDetailItem(Icons.account_balance_outlined, AppLocalizations.of(context)?.bankDetailsUpper ?? 'BANK / METHOD', paymentDetails),
                  if (dues != '-') _buildDetailItem(Icons.history_outlined, AppLocalizations.of(context)?.duesUpper ?? 'DUES', dues),
                ],
              );

              Widget statusBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: isPaid ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: isPaid ? Colors.green.shade200 : Colors.red.shade200)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isPaid ? Icons.check_circle : Icons.pending, size: 14, color: isPaid ? Colors.green.shade700 : Colors.red.shade700),
                    const SizedBox(width: 6),
                    Text(isPaid ? (AppLocalizations.of(context)?.paidUpper ?? 'PAID') : (AppLocalizations.of(context)?.pendingUpper ?? 'PENDING'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPaid ? Colors.green.shade700 : Colors.red.shade700, letterSpacing: 0.5)),
                  ],
                ),
              );

              Widget actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionBtn(icon: Icons.remove_red_eye_outlined, color: const Color(0xFF5D1712), tooltip: 'View', onTap: () => _viewReceipt(r, _memberData!)),
                  const SizedBox(width: 8),
                  _buildActionBtn(icon: Icons.print_outlined, color: Colors.indigo, tooltip: 'Print', onTap: () => _printReceiptHighFidelity(r, _memberData!)),
                  const SizedBox(width: 8),
                  _buildActionBtn(icon: Icons.file_download_outlined, color: Colors.blueGrey, tooltip: 'Download', onTap: () => _downloadReceiptHighFidelity(r, _memberData!)),
                ],
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: isPaid ? Colors.green.shade500 : Colors.red.shade500, width: 4))),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: financialSummary),
                                    statusBadge,
                                  ],
                                ),
                                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.black12)),
                                transactionDetails,
                                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.black12)),
                                Center(child: actions),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(flex: 3, child: financialSummary),
                                Container(width: 1, height: 60, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 24)),
                                Expanded(flex: 5, child: transactionDetails),
                                const SizedBox(width: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    statusBadge,
                                    const SizedBox(height: 12),
                                    actions,
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
    return sections;
  }

  void _viewReceipt(Map<String, dynamic> receipt, Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => ReceiptDialog(
        receiptData: receipt,
        memberData: member,
      ),
    );
  }

  Future<void> _downloadReceiptHighFidelity(Map<String, dynamic> receipt, Map<String, dynamic> member) async {
    final screenshotController = ScreenshotController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: LoadingSpinner(message: 'Generating high-fidelity PDF...')),
    );

    try {
      final image = await screenshotController.captureFromWidget(
        Container(
          width: 800,
          child: Material(
            child: ReceiptContent(
              receiptData: receipt,
              memberData: member,
              isMobile: false,
            ),
          ),
        ),
        delay: const Duration(milliseconds: 100),
        targetSize: const Size(800, 1200),
        pixelRatio: 3.0,
      );

      if (mounted) Navigator.pop(context);

      if (image != null) {
        await PdfGenerator.downloadReceiptImage(image, receipt['id']?.toString() ?? 'receipt');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error capturing high-fidelity receipt: $e');
    }
  }

  Future<void> _printReceiptHighFidelity(Map<String, dynamic> receipt, Map<String, dynamic> member) async {
    final screenshotController = ScreenshotController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: LoadingSpinner(message: 'Preparing print...')),
    );

    try {
      final image = await screenshotController.captureFromWidget(
        Container(
          width: 800,
          child: Material(
            child: ReceiptContent(
              receiptData: receipt,
              memberData: member,
              isMobile: false,
            ),
          ),
        ),
        delay: const Duration(milliseconds: 100),
        targetSize: const Size(800, 1200),
        pixelRatio: 3.0,
      );

      if (mounted) Navigator.pop(context);

      if (image != null) {
        await PdfGenerator.printReceiptImage(image);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error preparing print: $e');
    }
  }

  Widget _buildActionBtn({required IconData icon, required Color color, required String tooltip, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }


  TableRow _tableRow(String label, String value, {Color? valueColor}) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? Colors.black87)),
      ),
    ]);
  }


  Widget _buildTopBar(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)?.bulkPaymentUploadTitle ?? 'Bulk Payment Upload',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
            textAlign: TextAlign.center,
          ),
          if (_totalItems > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D1712).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${AppLocalizations.of(context)?.totalMembersHeader ?? 'Total Members: '}$_totalItems",
                  style: const TextStyle(color: Color(0xFF5D1712), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isFilterVisible = !_isFilterVisible),
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: Text(AppLocalizations.of(context)?.filterBtn ?? 'Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5D1712),
                    side: const BorderSide(color: Color(0xFF5D1712)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(AppLocalizations.of(context)?.uploadCsvBtn ?? 'Upload CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)?.bulkPaymentUploadTitle ?? 'Bulk Payment Upload',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
                textAlign: TextAlign.start,
              ),
              if (_totalItems > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D1712).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${AppLocalizations.of(context)?.totalMembersHeader ?? 'Total Members: '}$_totalItems",
                      style: const TextStyle(color: Color(0xFF5D1712), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => _isFilterVisible = !_isFilterVisible),
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(AppLocalizations.of(context)?.filterBtn ?? 'Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5D1712),
                  side: const BorderSide(color: Color(0xFF5D1712)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(AppLocalizations.of(context)?.uploadCsvBtn ?? 'Upload CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isMobile) {
    Widget buildRow(List<Widget> children) {
      if (isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: children.map((c) => Expanded(child: Padding(padding: EdgeInsets.only(right: children.last == c ? 0 : 16), child: c))).toList(),
      );
    }

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      margin: const EdgeInsets.only(top: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Opacity(
              opacity: widget.role == 2 ? 0.6 : 1.0,
              child: AbsorbPointer(
                absorbing: widget.role == 2,
                child: buildRow([
                  _buildFilterField(AppLocalizations.of(context)?.districtHeader ?? 'District', _buildDropdown(AppLocalizations.of(context)?.districtHeader ?? 'District', AppLocalizations.of(context)?.chooseDistrict ?? 'Select District', _districts, _selectedDistrict, (val) {
                    setState(() {
                      _selectedDistrict = val;
                      _selectedTaluk = null;
                      _taluks = [];
                      _selectedPanchayat = null;
                      _panchayats = [];
                      _selectedVillage = null;
                      _villages = [];
                    });
                    _fetchTaluks(val!);
                  }, icon: Icons.map, isStringList: true), isMobile),
                  _buildFilterField(AppLocalizations.of(context)?.talukHeader ?? 'Taluk', _buildDropdown(AppLocalizations.of(context)?.talukHeader ?? 'Taluk', AppLocalizations.of(context)?.chooseTaluk ?? 'Select Taluk', _taluks, _selectedTaluk, (val) {
                    setState(() {
                      _selectedTaluk = val;
                      _selectedPanchayat = null;
                      _panchayats = [];
                      _selectedVillage = null;
                      _villages = [];
                    });
                    _fetchPanchayats(val!);
                  }, icon: Icons.location_city, isStringList: true), isMobile),
                  _buildFilterField(AppLocalizations.of(context)?.panchayatHeader ?? 'Panchayat', _buildDropdown(AppLocalizations.of(context)?.panchayatHeader ?? 'Panchayat', AppLocalizations.of(context)?.choosePanchayat ?? 'Select Panchayat', _panchayats, _selectedPanchayat, (val) {
                    setState(() {
                      _selectedPanchayat = val;
                      _selectedVillage = null;
                      _villages = [];
                    });
                    _fetchVillages(val!);
                  }, icon: Icons.business, isStringList: true), isMobile),
                  _buildFilterField(AppLocalizations.of(context)?.villageUpperHeader ?? 'Village', _buildDropdown(AppLocalizations.of(context)?.villageUpperHeader ?? 'Village', AppLocalizations.of(context)?.chooseVillage ?? 'Select Village', _villages, _selectedVillage, (val) {
                    setState(() => _selectedVillage = val);
                  }, icon: Icons.home, isStringList: true), isMobile),
                ]),
              ),
            ),
            SizedBox(height: isMobile ? 0 : 20),
            buildRow([
              _buildFilterField(AppLocalizations.of(context)?.eventYearLabel ?? 'Event Year', CustomDropdownSearch(
                label: '',
                hint: AppLocalizations.of(context)?.chooseYearHint ?? 'Select Year',
                dropdownMap: { for (var y in _years) y.toString(): y.toString() },
                value: _selectedYear?.toString(),
                onChanged: (val) {
                  final intVal = val != null ? int.tryParse(val) : null;
                  setState(() => _selectedYear = intVal);
                  if (intVal != null) _fetchEvents(intVal);
                },
              ), isMobile),
              _buildFilterField(AppLocalizations.of(context)?.eventLabel ?? 'Event', CustomDropdownSearch(
                label: '',
                hint: AppLocalizations.of(context)?.chooseEventHint ?? 'Select Event',
                dropdownMap: { for (var e in _events) e['Id'].toString(): e['EventName'].toString() },
                value: _selectedEventId?.toString(),
                onChanged: (val) {
                  setState(() => _selectedEventId = val != null ? int.tryParse(val) : null);
                },
              ), isMobile),
              _buildFilterField(AppLocalizations.of(context)?.statusLabel ?? 'Status', Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildStatusRadio('Paid', label: AppLocalizations.of(context)?.paidLabel ?? 'Paid'),
                    _buildStatusRadio('Pending', label: AppLocalizations.of(context)?.unPaidLabel ?? 'Unpaid'),
                  ],
                ),
              ), isMobile),
              Container(
                width: isMobile ? double.infinity : null,
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear, size: 18),
                              label: Text(AppLocalizations.of(context)?.cancelDialogBtn ?? 'Clear'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _applyFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5D1712),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(AppLocalizations.of(context)?.applyFilterBtn ?? 'Apply Filter'),
                            ),
                          ),
                        ],
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear, size: 18),
                              label: Text(AppLocalizations.of(context)?.cancelDialogBtn ?? 'Clear'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _applyFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5D1712),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(AppLocalizations.of(context)?.applyFilterBtn ?? 'Apply'),
                            ),
                          ),
                        ],
                      ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterField(String label, Widget child, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildDropdown(String label, String hintText, List<dynamic> items, String? value, Function(String?) onChanged, {IconData? icon, bool isStringList = false}) {
    List<String> mappedItems = items.map((item) {
      String val = isStringList ? (item is String ? item : item['taluk_name'] ?? item['panchayat_name'] ?? item['village_name']) : item['district_name'];
      return val;
    }).toList();

    return CustomDropdownSearch(
      label: '',  // label is already shown by _buildFilterField wrapper
      hint: hintText,
      dropdownItems: mappedItems,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildStatusRadio(String value, {String? label}) {
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
        Text(label ?? value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }



  Widget _buildTableSection() {
    if (_isLoading) return const Center(child: LoadingSpinner(message: 'Loading members...'));
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));

    final double fixedWidth = colSno + colFamilyId + colName + colMobile + 20;
    final double scrollableWidth = colRole + colDistrict + colTaluk + colPanchayat + colVillage + colActions;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                child: Row(
                  children: [
                    _buildCell(AppLocalizations.of(context)?.roleHeader ?? 'ROLE', colRole, isHeader: true, isCentered: true),
                    _buildCell(AppLocalizations.of(context)?.districtHeader ?? 'DISTRICT', colDistrict, isHeader: true),
                    _buildCell(AppLocalizations.of(context)?.talukHeader ?? 'TALUK', colTaluk, isHeader: true),
                    _buildCell(AppLocalizations.of(context)?.panchayatHeader ?? 'PANCHAYAT', colPanchayat, isHeader: true),
                    _buildCell(AppLocalizations.of(context)?.villageUpperHeader ?? 'VILLAGE', colVillage, isHeader: true),
                    _buildCell(AppLocalizations.of(context)?.actionHeader?.toUpperCase() ?? 'ACTIONS', colActions, isHeader: true, isActions: true),
                  ],
                ),
              ),
              // Data
              _members.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No members found')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _members.length,
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
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        children: [
                          _buildCell(AppLocalizations.of(context)?.sNo?.toUpperCase() ?? 'S.NO', colSno, isHeader: true),
                          _buildCell(AppLocalizations.of(context)?.familyIdHeader ?? 'FAMILY ID', colFamilyId, isHeader: true),
                          _buildCell(AppLocalizations.of(context)?.nameHeader?.toUpperCase() ?? 'NAME', colName, isHeader: true),
                          _buildCell(AppLocalizations.of(context)?.mobileLabel?.toUpperCase() ?? 'MOBILE', colMobile, isHeader: true),
                        ],
                      ),
                    ),
                    // Data
                    _members.isEmpty
                        ? Container() // The empty state will be shown by the right scrollable side
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: _members.length,
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

  Widget _buildFixedDataRow(int index) {
    final member = _members[index];
    final sno = (_currentPage - 1) * _itemsPerPage + index + 1;

    return Material(
      color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
      child: Container(
        padding: const EdgeInsets.only(left: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          children: [
            _buildCell(sno.toString(), colSno),
            _buildCell(member['Familymembershipid'] ?? '-', colFamilyId),
            _buildCell(member['Name'] ?? 'N/A', colName),
            _buildCell(member['Phonenumber']?.toString() ?? '-', colMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableDataRow(int index) {
    final member = _members[index];
    final role = member['Role'] == 2 ? (AppLocalizations.of(context)?.coordinators ?? 'Coordinator') : (AppLocalizations.of(context)?.members ?? 'Member');

    double eventMoney = 0.0;
    if (_selectedEventId != null) {
      try {
        final event = _events.firstWhere((e) => e['Id'] == _selectedEventId);
        eventMoney = double.tryParse(event['TaxAmount']?.toString() ?? '0') ?? 0.0;
      } catch (e) {}
    }
    final paidCash = double.tryParse(member['paidamount']?.toString() ?? '0') ?? 0.0;
    final pendingCash = (member['balanceamount'] != null) ? double.tryParse(member['balanceamount'].toString()) ?? 0.0 : eventMoney - paidCash;
    final isFullyPaid = _selectedEventId != null && pendingCash <= 0 && paidCash > 0;

    final showPayNow = !isFullyPaid;
    final showViewReceipts = _selectedEventId == null || paidCash > 0 || member['payment_status'] == 'Paid';

    return Material(
      color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
      child: Container(
        padding: EdgeInsets.zero,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          children: [
            _buildCell('', colRole, isCentered: true, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100, 
                borderRadius: BorderRadius.circular(4), 
                border: Border.all(color: Colors.black12)
              ),
              child: Text(role, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
            )),
            _buildCell(member['District'] ?? '-', colDistrict),
            _buildCell(member['Taluk'] ?? '-', colTaluk),
            _buildCell(member['Panchayat'] ?? '-', colPanchayat),
            _buildCell(member['Village'] ?? '-', colVillage),
            _buildCell('', colActions, isActions: true, child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showPayNow)
                  _buildActionButton('Pay Now', Colors.green, () => _showPaymentDialog(member)),
                if (showViewReceipts) ...[
                  if (showPayNow) const SizedBox(width: 8),
                  _buildActionButton('View Receipts', const Color(0xFF5D1712), () => _showMemberReceiptsDialog(member)),
                ],
              ],
            )),
          ],
        ),
      ),
    );
  }


  void _showMemberReceiptsDialog(Map<String, dynamic> member) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: LoadingSpinner(message: 'Fetching member records...')),
    );

    try {
      // Find the actual user ID from the membership ID
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/member-coordinator-by-fid/${member['Familymembershipid']}'));
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            bool isMobile = MediaQuery.of(context).size.width < 800;
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 20),
              child: Container(
                width: isMobile ? double.infinity : 1100,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.95),
                child: StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, isMobile ? 16 : 24, isMobile ? 16 : 24, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['member'] != null && data['member']['Role'] == 2 
                                      ? 'Coordinator Financial Record' 
                                      : 'Member Financial Record', 
                                  style: TextStyle(
                                    fontSize: isMobile ? 18 : 22, 
                                    fontWeight: FontWeight.bold, 
                                    color: const Color(0xFF2D1B18)
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                          child: const Divider(height: 32),
                        ),
                        
                        Flexible(
                          child: RawScrollbar(
                            thumbVisibility: true,
                            thumbColor: const Color(0xFF5D1712),
                            radius: const Radius.circular(8),
                            thickness: 6,
                            crossAxisMargin: isMobile ? 6 : 12, // Keeps scrollbar away from the right edge
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                              child: SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 0, isMobile ? 16 : 24, isMobile ? 16 : 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Profile Cards
                          if (isMobile)
                            Column(
                              children: [
                                _buildProfileCard(
                                  title: 'Member Details:',
                                  data: data['member'],
                                  showPayNow: true,
                                  isMobile: true,
                                ),
                                const SizedBox(height: 16),
                                if (widget.role != 2 && data['coordinator'] != null && data['coordinator']['Name'] != null && data['coordinator']['Familymembershipid'] != data['member']['Familymembershipid'])
                                  _buildProfileCard(
                                    title: 'Coordinator Details:',
                                    data: data['coordinator'],
                                    showPayNow: false,
                                    isMobile: true,
                                  ),
                              ],
                            )
                          else
                            Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              children: [
                                SizedBox(
                                  width: 510,
                                  child: _buildProfileCard(
                                    title: 'Member Details:',
                                    data: data['member'],
                                    showPayNow: true,
                                  ),
                                ),
                                if (widget.role != 2 && data['coordinator'] != null && data['coordinator']['Name'] != null && data['coordinator']['Familymembershipid'] != data['member']['Familymembershipid'])
                                  SizedBox(
                                    width: 510,
                                    child: _buildProfileCard(
                                      title: 'Coordinator Details:',
                                      data: data['coordinator'],
                                      showPayNow: false,
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 32),
                          
                                    // Receipts Section
                                    _buildReceiptsHistorySection(data['receipts'] ?? [], data['member'], isMobile),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
            );
          },
        );
      } else {
        if (mounted) {
          showStatusDialog(context, title: 'Error', message: 'Failed to load member history', type: DialogType.error);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showStatusDialog(context, title: 'Connection Error', message: 'Unable to reach server', type: DialogType.error);
      }
    }
  }

  Widget _buildReceiptsHistorySection(List<dynamic> receipts, Map<String, dynamic> memberData, bool isMobile) {
    final Map<String, List<dynamic>> grouped = {};
    for (var r in receipts) {
      final name = r['eventname']?.toString() ?? r['EventName']?.toString() ?? 'Other';
      if (!grouped.containsKey(name)) grouped[name] = [];
      grouped[name]!.add(r);
    }

    int visibleCount = receipts.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: const Color(0xFF2D1B18),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: isMobile 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text('My Payment Receipt History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text('$visibleCount record(s)', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text('My Payment Receipt History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text('$visibleCount record(s)', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
          ),
          if (receipts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No payment receipts found.', style: TextStyle(color: Colors.black45))),
            )
          else
            ...grouped.entries.map((entry) => _buildEventGroupedTable(entry.key, entry.value, memberData, isMobile)),
        ],
      ),
    );
  }

  Widget _buildEventGroupedTable(String eventName, List<dynamic> items, Map<String, dynamic> memberData, bool isMobile) {
    final displayItems = items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(left: BorderSide(color: Color(0xFF5D1712), width: 4)),
          ),
          child: Text(
            eventName.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF5D1712), letterSpacing: 1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: displayItems.map((r) {
              final status = r['status']?.toString() ?? 'Pending';
              final balance = (r['balanceamount'] ?? 0.0);
              final balanceVal = balance is double ? balance : double.tryParse(balance.toString()) ?? 0.0;
              final taxamt = r['TaxAmount'] ?? r['taxamount'] ?? 0.0;
              final taxVal = taxamt is double ? taxamt : double.tryParse(taxamt.toString()) ?? 0.0;
              final paid = r['Collectedamount'] ?? r['paidamount'] ?? 0.0;
              final paidVal = paid is double ? paid : double.tryParse(paid.toString()) ?? 0.0;
              final dues = r['dues']?.toString() ?? '-';
              final isPaid = status.toLowerCase() == 'paid';
              final date = r['paymentdate']?.toString() ?? '-';
              final year = r['year']?.toString() ?? '-';
              final paymentDetails = _getPaymentDetailsStr(r);

              Widget financialSummary = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)?.paidUpper ?? 'PAID AMOUNT', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('${paidVal.toStringAsFixed(0)} ${AppLocalizations.of(context)?.rs ?? "Rs"}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isPaid ? Colors.green.shade700 : Colors.red.shade700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text('${AppLocalizations.of(context)?.totalAmountUpper ?? 'TOTAL'}: ${taxVal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                      Text('${AppLocalizations.of(context)?.pendingUpper ?? 'PENDING'}: ${balanceVal.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: balanceVal > 0 ? Colors.red.shade600 : Colors.black54, fontWeight: FontWeight.w500)),
                    ],
                  )
                ],
              );

              Widget transactionDetails = Wrap(
                spacing: 32,
                runSpacing: 16,
                children: [
                  _buildDetailItem(Icons.calendar_today_outlined, AppLocalizations.of(context)?.dateUpper ?? 'DATE & YEAR', '$date ($year)'),
                  _buildDetailItem(Icons.account_balance_outlined, AppLocalizations.of(context)?.bankDetailsUpper ?? 'BANK / METHOD', paymentDetails),
                  if (dues != '-') _buildDetailItem(Icons.history_outlined, AppLocalizations.of(context)?.duesUpper ?? 'DUES', dues),
                ],
              );

              Widget statusBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: isPaid ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: isPaid ? Colors.green.shade200 : Colors.red.shade200)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isPaid ? Icons.check_circle : Icons.pending, size: 14, color: isPaid ? Colors.green.shade700 : Colors.red.shade700),
                    const SizedBox(width: 6),
                    Text(isPaid ? (AppLocalizations.of(context)?.paidUpper ?? 'PAID') : (AppLocalizations.of(context)?.pendingUpper ?? 'PENDING'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPaid ? Colors.green.shade700 : Colors.red.shade700, letterSpacing: 0.5)),
                  ],
                ),
              );

              Widget actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionBtn(icon: Icons.remove_red_eye_outlined, color: const Color(0xFF5D1712), tooltip: 'View', onTap: () => _viewReceipt(r, memberData)),
                  const SizedBox(width: 8),
                  _buildActionBtn(icon: Icons.print_outlined, color: Colors.indigo, tooltip: 'Print', onTap: () => _printReceiptHighFidelity(r, memberData)),
                  const SizedBox(width: 8),
                  _buildActionBtn(icon: Icons.file_download_outlined, color: Colors.blueGrey, tooltip: 'Download', onTap: () => _downloadReceiptHighFidelity(r, memberData)),
                ],
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: isPaid ? Colors.green.shade500 : Colors.red.shade500, width: 4))),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: financialSummary),
                                    statusBadge,
                                  ],
                                ),
                                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.black12)),
                                transactionDetails,
                                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.black12)),
                                Center(child: actions),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(flex: 3, child: financialSummary),
                                Container(width: 1, height: 60, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 24)),
                                Expanded(flex: 5, child: transactionDetails),
                                const SizedBox(width: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    statusBadge,
                                    const SizedBox(height: 12),
                                    actions,
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


  void _showPaymentDialog(Map<String, dynamic> memberData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          width: 1000,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.95),
          child: PaymentForm(
            memberData: memberData,
            initialYear: _selectedYear,
            initialEventId: _selectedEventId,
            onPaymentSuccess: () {
              if (widget.role == 3) {
                _fetchMemberCoordinator();
              } else {
                _fetchMembers();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width, {bool isHeader = false, bool isBlue = false, bool isActions = false, bool isCentered = true, Widget? child}) {
    return Container(
      width: width,
      height: 48,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: isHeader ? Colors.white24 : Colors.black12)),
      ),
      child: Center(
        child: child ?? Text(
          text,
          style: TextStyle(
            color: isHeader ? Colors.white : (isBlue ? const Color(0xFF5D1712) : Colors.black87),
            fontWeight: isHeader || isBlue ? FontWeight.bold : FontWeight.normal,
            fontSize: isHeader ? 12 : 13,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPagination(bool isMobile) {
    if (_totalItems <= _itemsPerPage) return const SizedBox.shrink();
    int totalPages = (_totalItems / _itemsPerPage).ceil();

    return Container(
      padding: const EdgeInsets.only(top: 12),
      child: isMobile 
        ? Column(
            children: [
              Text(
                'Total $_totalItems entries',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPageBtn(Icons.chevron_left, _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null),
                    const SizedBox(width: 8),
                    ...List.generate(totalPages > 3 ? 3 : totalPages, (i) {
                      int page = i + 1;
                      return _buildPageNum(page, page == _currentPage, () => _goToPage(page));
                    }),
                    if (totalPages > 3) ...[
                      const Text('...'),
                      _buildPageNum(totalPages, totalPages == _currentPage, () => _goToPage(totalPages)),
                    ],
                    const SizedBox(width: 8),
                    _buildPageBtn(Icons.chevron_right, _currentPage < totalPages ? () => _goToPage(_currentPage + 1) : null),
                  ],
                ),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${_currentPage * _itemsPerPage > _totalItems ? _totalItems : _currentPage * _itemsPerPage} of $_totalItems entries',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Row(
                children: [
                  _buildPageBtn(Icons.chevron_left, _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null),
                  const SizedBox(width: 8),
                  ...List.generate(totalPages > 5 ? 5 : totalPages, (i) {
                    int page = i + 1;
                    return _buildPageNum(page, page == _currentPage, () => _goToPage(page));
                  }),
                  if (totalPages > 5) ...[
                    const Text('...'),
                    _buildPageNum(totalPages, totalPages == _currentPage, () => _goToPage(totalPages)),
                  ],
                  const SizedBox(width: 8),
                  _buildPageBtn(Icons.chevron_right, _currentPage < totalPages ? () => _goToPage(_currentPage + 1) : null),
                ],
              ),
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
        child: Icon(icon, size: 16, color: onTap == null ? Colors.grey : const Color(0xFF5D1712)),
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
            color: active ? const Color(0xFF2D1B18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active ? null : Border.all(color: Colors.black12),
          ),
          alignment: Alignment.center,
          child: Text(num.toString(), style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  String _getPaymentDetailsStr(Map<String, dynamic> r) {
    final paymentMethod = r['paymenttype']?.toString() ?? r['paymentmethod']?.toString() ?? r['payment_method']?.toString() ?? r['paymentmode']?.toString() ?? r['cashtype']?.toString() ?? 'Cash';
    final bankName = r['bankname']?.toString() ?? r['bank_name']?.toString() ?? r['banknameforcheckque']?.toString();
    final upiId = r['upiid']?.toString() ?? r['upi_id']?.toString() ?? r['upitransactionid']?.toString();
    final chequeNo = r['checkno']?.toString() ?? r['check_no']?.toString() ?? r['chequeno']?.toString() ?? r['checkqueno']?.toString();
    final refNumber = r['referencenumber']?.toString() ?? r['transactionid']?.toString() ?? r['transaction_id']?.toString() ?? r['bankrefid']?.toString();

    String details = paymentMethod.toUpperCase();
    if (paymentMethod.toLowerCase() == 'bank' || paymentMethod.toLowerCase() == 'cheque') {
      if (bankName != null && bankName.isNotEmpty && bankName != 'null' && bankName != '-') {
        details += ' - $bankName';
      }
      if (paymentMethod.toLowerCase() == 'cheque' && chequeNo != null && chequeNo.isNotEmpty && chequeNo != 'null') {
        details += '\nChq: $chequeNo';
      }
      if (paymentMethod.toLowerCase() == 'bank' && refNumber != null && refNumber.isNotEmpty && refNumber != 'null') {
        details += '\nRef: $refNumber';
      }
    } else if (paymentMethod.toLowerCase() == 'upi') {
      if (upiId != null && upiId.isNotEmpty && upiId != 'null') {
        details += '\nID: $upiId';
      }
    }
    return details;
  }
}

class _HorizontalScrollWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, ScrollController controller) builder;
  const _HorizontalScrollWrapper({Key? key, required this.builder}) : super(key: key);

  @override
  __HorizontalScrollWrapperState createState() => __HorizontalScrollWrapperState();
}

class __HorizontalScrollWrapperState extends State<_HorizontalScrollWrapper> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller);
  }
}

