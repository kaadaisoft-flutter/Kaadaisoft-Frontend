import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';
import 'update_details_content.dart';

class PaymentsContent extends StatefulWidget {
  final int? userId;
  final int? role;

  const PaymentsContent({super.key, this.userId, this.role});

  @override
  State<PaymentsContent> createState() => _PaymentsContentState();
}

class _PaymentsContentState extends State<PaymentsContent> {
  List<dynamic> _members = [];
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
  final double colActions = 230;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    if (widget.role == 3) {
      await _fetchMemberCoordinator();
    } else {
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
          _selectedPanchayat = null;
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

  Future<void> _applyFilters() async {
    if (_selectedEventId == null) {
      showStatusDialog(
        context,
        title: 'Selection Required',
        message: 'Please select an event to filter by payment status',
        type: DialogType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      Map<String, String> params = {
        'event_id': _selectedEventId.toString(),
        'status': _selectedStatus,
        'page': '$_currentPage',
        'limit': '$_itemsPerPage',
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
        setState(() {
          _members = data['data'];
          _totalItems = data['total'];
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
    final member = _memberData;
    final coord = _coordinatorData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text('Payments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF172030))),
          const SizedBox(height: 4),
          const Text('Your profile details, assigned coordinator, and payment receipts', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),

          // Member Details Card
          if (member != null)
            _buildProfileCard(
              title: 'Member Details:',
              data: member,
              showPayNow: true,
            ),

          if (member != null) const SizedBox(height: 24),

          // Coordinator Details Card
          if (coord != null)
            _buildProfileCard(
              title: 'Coordinator Details:',
              data: coord,
              showPayNow: false,
            ),

          if (coord == null && member == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(child: Text('No details found. Please contact your admin.', style: TextStyle(color: Colors.orange))),
                ],
              ),
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
                    color: Color(0xFF172030),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text('Payment Receipt History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: Text('${_receipts.length} record(s)', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                if (_receipts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No payment receipts found.', style: TextStyle(color: Colors.black45))),
                  )
                else
                  ..._buildGroupedReceiptTables(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({required String title, required Map<String, dynamic> data, bool showPayNow = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.03),
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
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.2)),
                  ],
                ),
                if (showPayNow)
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
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
                _buildInfoRow('Full Name', data['Name'] ?? '-', icon: Icons.person_outline, isFirst: true),
                _buildInfoRow('Membership ID', data['Familymembershipid'] ?? '-', icon: Icons.badge_outlined, valueColor: Colors.blue.shade700),
                _buildInfoRow('Taluk / Region', data['Taluk'] ?? '-', icon: Icons.location_city_outlined),
                _buildInfoRow('District', data['District'] ?? '-', icon: Icons.map_outlined),
                _buildInfoRow('Pincode', data['Pincode']?.toString() ?? '-', icon: Icons.pin_drop_outlined),
                _buildInfoRow('Contact Number', data['Phonenumber']?.toString() ?? '-', icon: Icons.phone_android_outlined, valueColor: Colors.green.shade700, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required IconData icon, Color? valueColor, bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? const Color(0xFF1E293B)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedReceiptTables() {
    final Map<String, List<dynamic>> grouped = {};
    for (var r in _receipts) {
      final name = r['eventname']?.toString() ?? 'Other';
      if (!grouped.containsKey(name)) grouped[name] = [];
      grouped[name]!.add(r);
    }

    List<Widget> sections = [];
    grouped.forEach((eventName, items) {
      sections.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            border: Border(left: BorderSide(color: Colors.blue.shade700, width: 4)),
          ),
          child: Text(
            eventName.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.blue.shade900, letterSpacing: 1),
          ),
        ),
      );
      sections.add(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 64,
              horizontalMargin: 24,
              columnSpacing: 24,
              dividerThickness: 0.5,
              border: TableBorder(horizontalInside: BorderSide(color: Colors.black.withOpacity(0.05), width: 0.5)),
              columns: const [
                DataColumn(label: Text('S.NO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black54))),
                DataColumn(label: Text('TOTAL AMOUNT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black54))),
                DataColumn(label: Text('PAID', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black54))),
                DataColumn(label: Text('PENDING', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black54))),
                DataColumn(label: Text('BANK / DETAILS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black54))),
                DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black54))),
                DataColumn(label: Text('YEAR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black54))),
                DataColumn(label: Text('DUES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black54))),
                DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black54))),
                DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.black54))),
              ],
              rows: List.generate(items.length, (i) {
                final r = items[i];
                final status = r['status']?.toString() ?? 'Pending';
                final balance = (r['balanceamount'] ?? 0.0);
                final balanceVal = balance is double ? balance : double.tryParse(balance.toString()) ?? 0.0;
                final taxamt = r['Taxamount'] ?? r['taxamount'] ?? 0.0;
                final taxVal = taxamt is double ? taxamt : double.tryParse(taxamt.toString()) ?? 0.0;
                final paid = r['Collectedamount'] ?? r['paidamount'] ?? 0.0;
                final paidVal = paid is double ? paid : double.tryParse(paid.toString()) ?? 0.0;
                final dues = r['dues']?.toString() ?? '-';
                final isPaid = status.toLowerCase() == 'paid';
                
                return DataRow(
                  cells: [
                    DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 13, color: Colors.black87))),
                    DataCell(Text('${taxVal.toStringAsFixed(0)} Rs', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    DataCell(Text('${paidVal.toStringAsFixed(0)} Rs', style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600))),
                    DataCell(Text('${balanceVal.toStringAsFixed(0)} Rs', style: TextStyle(fontSize: 13, color: balanceVal > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.w700))),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['bankname']?.toString() ?? r['banknameforcheckque']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          if (r['referencenumber'] != null)
                            Text(r['referencenumber'].toString(), style: const TextStyle(fontSize: 10, color: Colors.black45)),
                        ],
                      )
                    ),
                    DataCell(Text(r['paymentdate']?.toString() ?? '-', style: const TextStyle(fontSize: 13))),
                    DataCell(Text(r['year']?.toString() ?? '-', style: const TextStyle(fontSize: 13))),
                    DataCell(Text(dues, style: const TextStyle(fontSize: 13))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(), 
                        style: TextStyle(fontSize: 10, color: isPaid ? const Color(0xFF166534) : const Color(0xFF991B1B), fontWeight: FontWeight.w800, letterSpacing: 0.5)
                      ),
                    )),
                    DataCell(Row(
                      children: [
                        _buildActionBtn(icon: Icons.remove_red_eye_outlined, color: Colors.blue, tooltip: 'View', onTap: () {}),
                        const SizedBox(width: 12),
                        _buildActionBtn(icon: Icons.file_download_outlined, color: Colors.blueGrey, tooltip: 'Download', onTap: () {}),
                      ],
                    )),
                  ],
                );
              }),
            ),
          ),
        ),
      );
    });
    return sections;
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
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '📊 Bulk Payment Upload',
              style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E283C)),
              textAlign: isMobile ? TextAlign.center : TextAlign.start,
            ),
            if (_totalItems > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total Members: $_totalItems',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
              label: const Text('Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Upload CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSection(bool isMobile) {
    return Card(
      margin: const EdgeInsets.only(top: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildFilterField('District', _buildDropdown('District', _districts, _selectedDistrict, (val) {
                  setState(() => _selectedDistrict = val);
                  _fetchTaluks(val!);
                }, icon: Icons.map, isStringList: true), isMobile),
                _buildFilterField('Taluk', _buildDropdown('Taluk', _taluks, _selectedTaluk, (val) {
                  setState(() => _selectedTaluk = val);
                  _fetchPanchayats(val!);
                }, icon: Icons.location_city, isStringList: true), isMobile),
                _buildFilterField('Panchayat', _buildDropdown('Panchayat', _panchayats, _selectedPanchayat, (val) {
                  setState(() => _selectedPanchayat = val);
                  _fetchVillages(val!);
                }, icon: Icons.business, isStringList: true), isMobile),
                _buildFilterField('Village', _buildDropdown('Village', _villages, _selectedVillage, (val) {
                  setState(() => _selectedVillage = val);
                }, icon: Icons.home, isStringList: true), isMobile),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                _buildFilterField('Event Year', DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today, size: 20, color: Colors.orange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedYear = val);
                    _fetchEvents(val!);
                  },
                ), isMobile),
                _buildFilterField('Event', DropdownButtonFormField<int>(
                  value: _selectedEventId,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.event_available, size: 20, color: Colors.orange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  items: _events.map((e) => DropdownMenuItem<int>(value: e['Id'], child: Text(e['EventName']))).toList(),
                  onChanged: (val) => setState(() => _selectedEventId = val),
                ), isMobile),
                _buildFilterField('Status', Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusRadio('Paid'),
                      _buildStatusRadio('Pending', label: 'Unpaid'),
                    ],
                  ),
                ), isMobile),
                SizedBox(
                  height: 44,
                  width: isMobile ? double.infinity : null,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Apply Filter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterField(String label, Widget child, bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, String? value, Function(String?) onChanged, {IconData? icon, bool isStringList = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.blue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          items: items.map((item) {
            String val = isStringList ? (item is String ? item : item['taluk_name'] ?? item['panchayat_name'] ?? item['village_name']) : item['district_name'];
            return DropdownMenuItem(value: val, child: Text(val, overflow: TextOverflow.ellipsis));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
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
          activeColor: Colors.blue,
          visualDensity: VisualDensity.compact,
        ),
        Text(label ?? value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTableSection() {
    if (_isLoading) return const Center(child: LoadingSpinner(message: 'Loading members...'));
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));

    // Total table width (sum of columns + padding)
    final double totalTableWidth = colSno + colFamilyId + colName + colRole + colMobile + colDistrict + colTaluk + colPanchayat + colVillage + colActions + 40;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  child: Row(
                    children: [
                      _buildCell('S.NO', colSno, isHeader: true),
                      _buildCell('FAMILY ID', colFamilyId, isHeader: true),
                      _buildCell('NAME', colName, isHeader: true),
                      _buildCell('ROLE', colRole, isHeader: true, isCentered: true),
                      _buildCell('MOBILE', colMobile, isHeader: true),
                      _buildCell('DISTRICT', colDistrict, isHeader: true),
                      _buildCell('TALUK', colTaluk, isHeader: true),
                      _buildCell('PANCHAYAT', colPanchayat, isHeader: true),
                      _buildCell('VILLAGE', colVillage, isHeader: true),
                      _buildCell('ACTIONS', colActions, isHeader: true, isActions: true),
                    ],
                  ),
                ),
                // Data
                _members.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No members found')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: _members.length,
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

  Widget _buildDataRow(int index) {
    final member = _members[index];
    final sno = (_currentPage - 1) * _itemsPerPage + index + 1;
    final role = member['Role'] == 2 ? 'Coordinator' : 'Member';

    return Material(
      color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
      child: InkWell(
        onTap: () => _showEditMemberDialog(member['Id'].toString()),
        hoverColor: Colors.blue.shade50.withOpacity(0.5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
          child: Row(
            children: [
              _buildCell(sno.toString(), colSno),
              _buildCell(member['Familymembershipid'] ?? '-', colFamilyId, isBlue: true),
              _buildCell(member['Name'] ?? 'N/A', colName),
              _buildCell('', colRole, isCentered: true, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100, 
                  borderRadius: BorderRadius.circular(4), 
                  border: Border.all(color: Colors.black12)
                ),
                child: Text(role, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
              )),
              _buildCell(member['Phonenumber']?.toString() ?? '-', colMobile),
              _buildCell(member['District'] ?? '-', colDistrict),
              _buildCell(member['Taluk'] ?? '-', colTaluk),
              _buildCell(member['Panchayat'] ?? '-', colPanchayat),
              _buildCell(member['Village'] ?? '-', colVillage),
              _buildCell('', colActions, isActions: true, child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton('Pay Now', Colors.green, () {}),
                  const SizedBox(width: 8),
                  _buildActionButton('View Receipts', Colors.blue, () {}),
                ],
              )),
            ],
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

  Widget _buildCell(String text, double width, {bool isHeader = false, bool isBlue = false, bool isActions = false, bool isCentered = true, Widget? child}) {
    return SizedBox(
      width: width,
      height: 34,
      child: Center(
        child: child ?? Text(
          text,
          style: TextStyle(
            color: isHeader ? Colors.white : (isBlue ? Colors.blue : Colors.black87),
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
                    _buildPageBtn(Icons.chevron_left, _currentPage > 1 ? () => setState(() { _currentPage--; _fetchMembers(); }) : null),
                    const SizedBox(width: 8),
                    ...List.generate(totalPages > 3 ? 3 : totalPages, (i) {
                      int page = i + 1;
                      return _buildPageNum(page, page == _currentPage, () => setState(() { _currentPage = page; _fetchMembers(); }));
                    }),
                    if (totalPages > 3) ...[
                      const Text('...'),
                      _buildPageNum(totalPages, totalPages == _currentPage, () => setState(() { _currentPage = totalPages; _fetchMembers(); })),
                    ],
                    const SizedBox(width: 8),
                    _buildPageBtn(Icons.chevron_right, _currentPage < totalPages ? () => setState(() { _currentPage++; _fetchMembers(); }) : null),
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
                  _buildPageBtn(Icons.chevron_left, _currentPage > 1 ? () => setState(() { _currentPage--; _fetchMembers(); }) : null),
                  const SizedBox(width: 8),
                  ...List.generate(totalPages > 5 ? 5 : totalPages, (i) {
                    int page = i + 1;
                    return _buildPageNum(page, page == _currentPage, () => setState(() { _currentPage = page; _fetchMembers(); }));
                  }),
                  if (totalPages > 5) ...[
                    const Text('...'),
                    _buildPageNum(totalPages, totalPages == _currentPage, () => setState(() { _currentPage = totalPages; _fetchMembers(); })),
                  ],
                  const SizedBox(width: 8),
                  _buildPageBtn(Icons.chevron_right, _currentPage < totalPages ? () => setState(() { _currentPage++; _fetchMembers(); }) : null),
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
