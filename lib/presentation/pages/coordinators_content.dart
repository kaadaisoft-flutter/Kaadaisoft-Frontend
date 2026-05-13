import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/loading_spinner.dart';
import '../widgets/assign_coordinator_view.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';
import 'update_details_content.dart';
import 'coordinator_details_content.dart';
import 'member_id_card_view.dart';

class CoordinatorsContent extends StatefulWidget {
  final bool initialShowAssign;
  const CoordinatorsContent({super.key, this.initialShowAssign = false});


  @override
  State<CoordinatorsContent> createState() => _CoordinatorsContentState();
}

class _CoordinatorsContentState extends State<CoordinatorsContent> {
  List<dynamic> _coordinators = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _showIDCard = false;
  Map<String, dynamic>? _selectedCoordinatorData;

  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final ScrollController _horizontalScrollController = ScrollController();

  bool _showFilters = false;
  String _selectedDistrict = 'All Districts';
  String _selectedTaluk = 'All Taluks';
  String _selectedPanchayat = 'All Panchayats';
  String _selectedVillage = 'All Villages';
  final TextEditingController _searchController = TextEditingController();
  bool _showAssignView = false;

  List<String> _districts = ['All Districts'];
  List<String> _taluks = ['All Taluks'];
  List<String> _panchayats = ['All Panchayats'];
  List<String> _villages = ['All Villages'];

  @override
  void initState() {
    super.initState();
    _showAssignView = widget.initialShowAssign;
    _fetchDistricts();
    _fetchCoordinators();
  }


  Future<void> _fetchDistricts() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _districts = ['All Districts', ...List<String>.from(data['data'])];
        });
      }
    } catch (e) {
      debugPrint('Error fetching districts: $e');
    }
  }

  Future<void> _fetchTaluks(String district) async {
    if (district == 'All Districts') return;
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _taluks = ['All Taluks', ...List<String>.from(data['data'])];
          _selectedTaluk = 'All Taluks';
          _panchayats = ['All Panchayats'];
          _selectedPanchayat = 'All Panchayats';
          _villages = ['All Villages'];
          _selectedVillage = 'All Villages';
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchPanchayats(String district, String taluk) async {
    if (taluk == 'All Taluks') return;
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _panchayats = ['All Panchayats', ...List<String>.from(data['data'])];
          _selectedPanchayat = 'All Panchayats';
          _villages = ['All Villages'];
          _selectedVillage = 'All Villages';
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchVillages(String district, String taluk, String panchayat) async {
    if (panchayat == 'All Panchayats') return;
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _villages = ['All Villages', ...List<String>.from(data['data'])];
          _selectedVillage = 'All Villages';
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchCoordinators() async {
    setState(() => _isLoading = true);
    try {
      final queryParams = <String, String>{};
      if (_selectedDistrict != 'All Districts') queryParams['district'] = _selectedDistrict;
      if (_selectedTaluk != 'All Taluks') queryParams['taluk'] = _selectedTaluk;
      if (_selectedPanchayat != 'All Panchayats') queryParams['panchayat'] = _selectedPanchayat;
      if (_selectedVillage != 'All Villages') queryParams['village'] = _selectedVillage;
      if (_searchController.text.isNotEmpty) queryParams['search'] = _searchController.text;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/coordinators').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _coordinators = data['data'];
            _isLoading = false;
            _currentPage = 1;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load coordinators';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error. Make sure the backend is running.';
          _isLoading = false;
        });
      }
    }
  }

  void _showCoordinatorDetailsDialog(String numericId, String familyId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 1100,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            children: [
              // Custom Close Button for the Dialog
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
                child: CoordinatorDetailsContent(
                  numericId: numericId,
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

  void _showEditCoordinatorDialog(String memberId) async {
    // Show a loading dialog while fetching details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/user-details/$memberId'));
      Navigator.pop(context); // Close loading dialog

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
                userRole: 1, // Admin/Manager role for update permission
                userData: data,
                title: 'Update Coordinator Details: ',
                onBack: () {
                  Navigator.pop(context);
                  _fetchCoordinators(); // Refresh list
                },
              ),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        showStatusDialog(
          context,
          title: 'Error',
          message: 'Failed to fetch coordinator details',
          type: DialogType.error,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showStatusDialog(
          context,
          title: 'Connection Error',
          message: 'Unable to communicate with the server.',
          type: DialogType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (_coordinators.length / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _coordinators.length) endIndex = _coordinators.length;

    List<dynamic> currentPage = _coordinators.isNotEmpty
        ? _coordinators.sublist(startIndex, endIndex)
        : [];

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchCoordinators, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_showIDCard && _selectedCoordinatorData != null) {
      return MemberIDCardView(
        userData: _selectedCoordinatorData!,
        onBack: () => setState(() => _showIDCard = false),
      );
    }

    if (_isLoading) {
      return const LoadingSpinner(message: 'Loading coordinators...');
    }

    final isMobile = MediaQuery.of(context).size.width < 700;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showAssignView)
            AssignCoordinatorView(
              onBack: () => setState(() => _showAssignView = false),
              onSuccess: _fetchCoordinators,
            )
          else ...[
            // Top bar: Title + Buttons
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              spacing: 12,
              children: [
                const Text(
                  'Coordinators Management',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E283C),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      icon: const Icon(Icons.filter_alt_outlined, size: 18),
                      label: const Text('Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _showFilters ? Colors.white : Colors.blue,
                        backgroundColor: _showFilters ? Colors.blue : Colors.transparent,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAssignView = true;
                        });
                      },
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 18),
                      label: const Text('Assign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E283C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        if (_showFilters) ...[
          const SizedBox(height: 8),
          _buildFilterBar(),
        ],
        const SizedBox(height: 8),
        // Total count
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            const Text(
              'Total Coordinators: ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E283C)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isLoading ? '' : _coordinators.length.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1170,
                      child: Column(
                        children: [
                          // Header
                          Container(
                            color: const Color(0xFF172030),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            child: const Row(
                              children: [
                                SizedBox(width: 50, child: Text('S.NO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                SizedBox(width: 110, child: Text('USER ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                SizedBox(width: 110, child: Text('NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                SizedBox(width: 120, child: Text('MOBILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                SizedBox(width: 100, child: Text('DISTRICT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                SizedBox(width: 100, child: Text('TALUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                SizedBox(width: 130, child: Text('PANCHAYAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                SizedBox(width: 130, child: Text('VILLAGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                                SizedBox(width: 140, child: Text('ASSIGNED\nVILLAGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                                SizedBox(width: 110, child: Text('ACTIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                              ],
                            ),
                          ),
                          // Rows
                          _errorMessage.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red))),
                                )
                              : _coordinators.isEmpty && !_isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Center(child: Text('No coordinators found.', style: TextStyle(color: Colors.black54))),
                                    )
                                  : ListView.separated(padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: currentPage.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final c = currentPage[index];
                                          return _buildRow(
                                            (startIndex + index + 1).toString(),
                                            c['Id']?.toString() ?? '0',
                                            c['Familymembershipid'] ?? 'N/A',
                                            c['Name'] ?? '-',
                                            c['Phonenumber']?.toString() ?? '-',
                                            c['District'] ?? '-',
                                            c['Taluk'] ?? '-',
                                            c['Panchayat'] ?? '-',
                                            c['Village'] ?? '-',
                                            c['VillageNames'] ?? '-',
                                          );
                                        },
                                    ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Pagination
                if (!_isLoading && _coordinators.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                              color: Colors.blue,
                              splashRadius: 20,
                            ),
                            ...List.generate(totalPages, (i) {
                              final page = i + 1;
                              final isActive = page == _currentPage;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: InkWell(
                                  onTap: () => setState(() => _currentPage = page),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFF1E283C) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: isActive ? null : Border.all(color: Colors.black12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('$page', style: TextStyle(color: isActive ? Colors.white : Colors.black54, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                                  ),
                                ),
                              );
                            }),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                              color: Colors.blue,
                              splashRadius: 20,
                            ),
                          ],
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
      ],
    ),
  );
}

  Widget _buildRow(String sno, String numericId, String id, String name, String mobile,
      String district, String taluk, String panchayat, String village,
      String villageNames) {
    final villages = villageNames == '-' ? <String>[] : villageNames.split(', ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEditCoordinatorDialog(numericId),
        hoverColor: Colors.blue.shade50.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            children: [
              SizedBox(width: 50, child: Text(sno, style: const TextStyle(color: Colors.black54))),
              SizedBox(width: 110, child: Text(id, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              SizedBox(width: 110, child: Text(name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              SizedBox(width: 120, child: Text(mobile, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center)),
              SizedBox(width: 100, child: Text(district, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center)),
              SizedBox(width: 100, child: Text(taluk, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center)),
              SizedBox(width: 130, child: Text(panchayat, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center)),
              SizedBox(width: 130, child: Text(village, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center)),
              // Assigned Villages - show all clearly
              SizedBox(
                width: 140,
                child: Center(
                  child: villages.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text('None', style: TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Text(
                            villages.join(', '),
                            style: const TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                            softWrap: true,
                          ),
                        ),
                ),
              ),
              // Action Icons
              SizedBox(
                width: 110,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _actionIcon(Icons.edit_outlined, Colors.blue, () => _showEditCoordinatorDialog(numericId)),
                    const SizedBox(width: 6),
                    _actionIcon(Icons.visibility_outlined, Colors.green, () => _showCoordinatorDetailsDialog(numericId, id)),
                    const SizedBox(width: 6),
                    _actionIcon(Icons.badge_outlined, Colors.teal, () {
                      final coordData = _coordinators.firstWhere((element) => element['Id'].toString() == numericId);
                      setState(() {
                        _selectedCoordinatorData = coordData;
                        _showIDCard = true;
                      });
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
  
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildDropdown('District', _selectedDistrict, _districts, (val) {
              setState(() {
                _selectedDistrict = val!;
                _taluks = ['All Taluks'];
                _selectedTaluk = 'All Taluks';
                _panchayats = ['All Panchayats'];
                _selectedPanchayat = 'All Panchayats';
                _villages = ['All Villages'];
                _selectedVillage = 'All Villages';
              });
              _fetchTaluks(val!);
              _fetchCoordinators();
            }),
            const SizedBox(width: 16),
            _buildDropdown('Taluk', _selectedTaluk, _taluks, (val) {
              setState(() {
                _selectedTaluk = val!;
                _panchayats = ['All Panchayats'];
                _selectedPanchayat = 'All Panchayats';
                _villages = ['All Villages'];
                _selectedVillage = 'All Villages';
              });
              _fetchPanchayats(_selectedDistrict, val!);
              _fetchCoordinators();
            }),
            const SizedBox(width: 16),
            _buildDropdown('Panchayat', _selectedPanchayat, _panchayats, (val) {
              setState(() {
                _selectedPanchayat = val!;
                _villages = ['All Villages'];
                _selectedVillage = 'All Villages';
              });
              _fetchVillages(_selectedDistrict, _selectedTaluk, val!);
              _fetchCoordinators();
            }),
            const SizedBox(width: 16),
            _buildDropdown('Village', _selectedVillage, _villages, (val) {
              setState(() {
                _selectedVillage = val!;
              });
              _fetchCoordinators();
            }),
            const SizedBox(width: 16),
            SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Search Name/ID/Mobile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _fetchCoordinators(),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _selectedDistrict = 'All Districts';
                              _selectedTaluk = 'All Taluks';
                              _selectedPanchayat = 'All Panchayats';
                              _selectedVillage = 'All Villages';
                            });
                            _fetchCoordinators();
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.blue)),
                      ),
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

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 6),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
