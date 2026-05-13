import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import '../../utils/api_config.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';

class AssignCoordinatorView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  const AssignCoordinatorView({
    super.key,
    required this.onBack,
    required this.onSuccess,
  });

  @override
  State<AssignCoordinatorView> createState() => _AssignCoordinatorViewState();
}

class _AssignCoordinatorViewState extends State<AssignCoordinatorView> {
  final TextEditingController _searchMemberController = TextEditingController();
  final TextEditingController _searchCoordinatorController = TextEditingController();
  final TextEditingController _reassignNewMemberController = TextEditingController();
  final TextEditingController _removeCoordinatorController = TextEditingController();
  final TextEditingController _newVillageController = TextEditingController();
  
  String? _selectedMemberId;
  
  String? _reassignCoordId;
  String? _reassignNewMemberId;

  String? _selectedRemoveCoordId;
  List<Map<String, dynamic>> _removeCoordVillages = [];

  // --- Assign Form State ---
  String _assignDistrict = 'Choose District';
  String _assignTaluk = 'Choose Taluk';
  String _assignPanchayat = 'Choose Panchayat';
  List<String> _assignTaluks = ['Choose Taluk'];
  List<String> _assignPanchayats = ['Choose Panchayat'];
  List<Map<String, dynamic>> _assignVillagesList = [];
  List<String> _assignSelectedVillageNames = [];

  // --- Reassign Form State ---
  String _reassignDistrict = 'Choose District';
  String _reassignTaluk = 'Choose Taluk';
  String _reassignPanchayat = 'Choose Panchayat';
  List<String> _reassignTaluks = ['Choose Taluk'];
  List<String> _reassignPanchayats = ['Choose Panchayat'];
  List<Map<String, dynamic>> _reassignVillagesList = [];
  List<String> _reassignSelectedVillageNames = [];

  // --- Add/Remove Village State ---
  String _addDistrict = 'Choose District';
  String _addTaluk = 'Choose Taluk';
  String _addPanchayat = 'Choose Panchayat';
  List<String> _addTaluks = ['Choose Taluk'];
  List<String> _addPanchayats = ['Choose Panchayat'];

  String _removeDistrict = 'Choose District';
  String _removeTaluk = 'Choose Taluk';
  String _removePanchayat = 'Choose Panchayat';
  String _removeVillage = 'Choose Village';
  List<String> _removeTaluks = ['Choose Taluk'];
  List<String> _removePanchayats = ['Choose Panchayat'];
  List<String> _removeVillages = ['Choose Village'];

  List<String> _districts = ['Choose District'];

  bool _isAssigning = false;
  bool _isReassigning = false;
  bool _isRemovingCoord = false;
  bool _isAddingVillage = false;
  bool _isRemovingVillage = false;

  @override
  void initState() {
    super.initState();
    _fetchDistricts();
  }

  Future<void> _fetchDistricts() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _districts = ['Choose District', ...List<String>.from(data['data'])];
        });
      }
    } catch (e) {}
  }

  Future<List<String>> _getTaluks(String district) async {
    if (district == 'Choose District') return ['Choose Taluk'];
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ['Choose Taluk', ...List<String>.from(data['data'])];
      }
    } catch (e) {}
    return ['Choose Taluk'];
  }

  Future<List<String>> _getPanchayats(String taluk) async {
    if (taluk == 'Choose Taluk') return ['Choose Panchayat'];
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ['Choose Panchayat', ...List<String>.from(data['data'])];
      }
    } catch (e) {}
    return ['Choose Panchayat'];
  }

  Future<void> _fetchVillages(String panchayat, bool isAssign) async {
    if (panchayat == 'Choose Panchayat') return;
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<String> selectedNames = isAssign ? _assignSelectedVillageNames : _reassignSelectedVillageNames;
        final villages = (data['data'] as List).map((v) {
          final vName = v.toString();
          return {
            'name': vName,
            'selected': selectedNames.contains(vName)
          };
        }).toList();
        
        setState(() {
          if (isAssign) {
            _assignVillagesList = villages;
          } else {
            _reassignVillagesList = villages;
          }
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchVillagesForRemove(String panchayat) async {
    if (panchayat == 'Choose Panchayat') return;
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _removeVillages = ['Choose Village', ...List<String>.from(data['data'])];
          _removeVillage = 'Choose Village';
        });
      }
    } catch (e) {}
  }

  Future<void> _fetchCoordinatorVillages(String coordId, {bool isReassign = true}) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/coordinator-villages/$coordId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] as List;
        
        if (isReassign) {
          if (list.isNotEmpty) {
            final first = list[0];
            final d = first['district_name'];
            final t = first['taluk_name'];
            final p = first['panchayat_name'];
            
            final taluks = await _getTaluks(d);
            final panchayats = await _getPanchayats(t);
            
            setState(() {
              _reassignDistrict = d;
              _reassignTaluks = taluks;
              _reassignTaluk = t;
              _reassignPanchayats = panchayats;
              _reassignPanchayat = p;
              _reassignSelectedVillageNames = list.map((v) => v['village_name'].toString()).toList();
            });
            
            await _fetchVillages(p, false);
          }
        } else {
          setState(() {
            _removeCoordVillages = list.map((v) => v as Map<String, dynamic>).toList();
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _assignCoordinator() async {
    if (_selectedMemberId == null) {
      showStatusDialog(context, title: 'Error', message: 'Please select a member', type: DialogType.error);
      return;
    }
    if (_assignSelectedVillageNames.isEmpty) {
      showStatusDialog(context, title: 'Error', message: 'Please select at least 1 village', type: DialogType.error);
      return;
    }
    if (_assignSelectedVillageNames.length > 4) {
      showStatusDialog(context, title: 'Error', message: 'Maximum 4 villages can be assigned to a coordinator', type: DialogType.error);
      return;
    }

    setState(() => _isAssigning = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/assign-coordinator'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'member_id': _selectedMemberId,
          'villages': _assignSelectedVillageNames,
          'panchayat': _assignPanchayat,
        }),
      );

      if (response.statusCode == 200) {
        showStatusDialog(context, title: 'Success', message: 'Coordinator assigned successfully', type: DialogType.success);
        widget.onSuccess();
        widget.onBack();
      } else {
        String errorMsg = 'Failed to assign coordinator';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['detail'] != null) {
            errorMsg = errorData['detail'];
          }
        } catch (_) {}
        showStatusDialog(context, title: 'Error', message: errorMsg, type: DialogType.error);
      }
    } catch (e) {
      showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);
    } finally {
      setState(() => _isAssigning = false);
    }
  }

  Future<void> _reassignCoordinator() async {
     if (_reassignCoordId == null) {
      showStatusDialog(context, title: 'Error', message: 'Please select a coordinator to replace', type: DialogType.error);
      return;
    }
    if (_reassignNewMemberId == null) {
      showStatusDialog(context, title: 'Error', message: 'Please select a new member to assign', type: DialogType.error);
      return;
    }
    if (_reassignSelectedVillageNames.isEmpty) {
      showStatusDialog(context, title: 'Error', message: 'Please select at least 1 village', type: DialogType.error);
      return;
    }
    if (_reassignSelectedVillageNames.length > 4) {
      showStatusDialog(context, title: 'Error', message: 'Maximum 4 villages can be assigned to a coordinator', type: DialogType.error);
      return;
    }

    setState(() => _isReassigning = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/reassign-coordinator'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'old_coordinator_id': _reassignCoordId,
          'new_member_id': _reassignNewMemberId,
          'villages': _reassignSelectedVillageNames,
          'panchayat': _reassignPanchayat,
        }),
      );

      if (response.statusCode == 200) {
        showStatusDialog(context, title: 'Success', message: 'Coordinator reassigned successfully', type: DialogType.success);
        widget.onSuccess();
        widget.onBack();
      } else {
        String errorMsg = 'Failed to reassign coordinator';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['detail'] != null) {
            errorMsg = errorData['detail'];
          }
        } catch (_) {}
        showStatusDialog(context, title: 'Error', message: errorMsg, type: DialogType.error);
      }
    } catch (e) {
      showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);
    } finally {
      setState(() => _isReassigning = false);
    }
  }

  Future<void> _removeCoordinator() async {
    if (_selectedRemoveCoordId == null) {
      showStatusDialog(context, title: 'Error', message: 'Please select a coordinator to remove', type: DialogType.error);
      return;
    }

    setState(() => _isRemovingCoord = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/remove-coordinator'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'coordinator_id': _selectedRemoveCoordId,
        }),
      );

      if (response.statusCode == 200) {
        showStatusDialog(context, title: 'Success', message: 'Coordinator removed successfully', type: DialogType.success);
        widget.onSuccess();
        setState(() {
          _selectedRemoveCoordId = null;
          _removeCoordinatorController.clear();
          _removeCoordVillages = [];
        });
      } else {
        showStatusDialog(context, title: 'Error', message: 'Failed to remove coordinator', type: DialogType.error);
      }
    } catch (e) {
      showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);
    } finally {
      setState(() => _isRemovingCoord = false);
    }
  }

  Future<void> _removeSingleAssignment(String vName, String panchayat) async {
    setState(() => _isRemovingCoord = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/remove-village-assignment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'coordinator_id': _selectedRemoveCoordId,
          'village_name': vName,
          'panchayat': panchayat,
        }),
      );

      if (response.statusCode == 200) {
        showStatusDialog(context, title: 'Success', message: 'Village assignment removed', type: DialogType.success);
        widget.onSuccess();
        _fetchCoordinatorVillages(_selectedRemoveCoordId!, isReassign: false);
      }
    } catch (e) {}
    finally {
      setState(() => _isRemovingCoord = false);
    }
  }

  Future<void> _addVillage() async {
    if (_addPanchayat == 'Choose Panchayat' || _newVillageController.text.isEmpty) {
      showStatusDialog(context, title: 'Error', message: 'Please select Panchayat and enter village name', type: DialogType.error);
      return;
    }

    setState(() => _isAddingVillage = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/add-village'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'district': _addDistrict,
          'taluk': _addTaluk,
          'panchayat': _addPanchayat,
          'village_name': _newVillageController.text,
        }),
      );

      if (response.statusCode == 200) {
        showStatusDialog(context, title: 'Success', message: 'Village added successfully', type: DialogType.success);
        _newVillageController.clear();
      } else {
        showStatusDialog(context, title: 'Error', message: 'Failed to add village', type: DialogType.error);
      }
    } catch (e) {
      showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);
    } finally {
      setState(() => _isAddingVillage = false);
    }
  }

  Future<void> _removeVillageAction() async {
    if (_removeVillage == 'Choose Village') {
      showStatusDialog(context, title: 'Error', message: 'Please select a village to remove', type: DialogType.error);
      return;
    }

    setState(() => _isRemovingVillage = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/remove-village'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'panchayat': _removePanchayat,
          'village_name': _removeVillage,
        }),
      );

      if (response.statusCode == 200) {
        showStatusDialog(context, title: 'Success', message: 'Village removed successfully', type: DialogType.success);
        _fetchVillagesForRemove(_removePanchayat);
      } else {
        showStatusDialog(context, title: 'Error', message: 'Failed to remove village', type: DialogType.error);
      }
    } catch (e) {
      showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);
    } finally {
      setState(() => _isRemovingVillage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs
          Row(
            children: [
              InkWell(
                onTap: widget.onBack,
                child: const Text('Coordinators', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
              ),
              const Text(' / Assigncoordinators', style: TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Assign Coordinator Form
          _buildFormCard(
            title: 'Assign Coordinator',
            icon: Icons.person_add_alt_1,
            accentColor: Colors.blue,
            child: _buildAssignFormContent(),
            buttonText: 'Assign',
            onButtonPressed: _assignCoordinator,
            isLoading: _isAssigning,
          ),

          const SizedBox(height: 32),

          // 2. Reassign Coordinator Form
          _buildFormCard(
            title: 'Reassign Coordinator',
            icon: Icons.person_add_alt_1,
            accentColor: Colors.red,
            child: _buildReassignFormContent(),
            buttonText: 'Reassign',
            onButtonPressed: _reassignCoordinator,
            isLoading: _isReassigning,
          ),

          const SizedBox(height: 32),

          // 3. Remove Coordinator Form (Updated with Table)
          _buildFormCard(
            title: 'Remove Coordinator',
            icon: Icons.person_remove_alt_1,
            accentColor: Colors.grey.shade700,
            child: _buildRemoveCoordFormContent(),
            buttonText: 'Remove Coordinator',
            onButtonPressed: _removeCoordinator,
            isLoading: _isRemovingCoord,
          ),

          const SizedBox(height: 32),

          // 4. Add Village Form
          _buildFormCard(
            title: 'Add Village',
            icon: Icons.add_location_alt,
            accentColor: Colors.teal,
            child: _buildAddVillageFormContent(),
            buttonText: 'Add Village',
            onButtonPressed: _addVillage,
            isLoading: _isAddingVillage,
          ),

          const SizedBox(height: 32),

          // 5. Remove Village Form
          _buildFormCard(
            title: 'Remove Village',
            icon: Icons.location_off,
            accentColor: Colors.redAccent,
            child: _buildRemoveVillageFormContent(),
            buttonText: 'Remove Village',
            onButtonPressed: _removeVillageAction,
            isLoading: _isRemovingVillage,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
    required String buttonText,
    required VoidCallback onButtonPressed,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(top: BorderSide(color: accentColor, width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child,
                const SizedBox(height: 24),
                // Action Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24, runSpacing: 24,
          children: [
            _buildField(
              label: 'Search Member',
              child: _buildSearchField(type: 'member'),
              width: 200,
            ),
            _buildField(
              label: 'Districts:',
              child: _buildDropdown(
                value: _assignDistrict,
                items: _districts,
                onChanged: (val) async {
                  final taluks = await _getTaluks(val!);
                  setState(() {
                    _assignDistrict = val;
                    _assignTaluks = taluks;
                    _assignTaluk = 'Choose Taluk';
                    _assignPanchayats = ['Choose Panchayat'];
                    _assignPanchayat = 'Choose Panchayat';
                    _assignVillagesList = [];
                  });
                },
              ),
              width: 180,
            ),
            _buildField(
              label: 'Taluks:',
              child: _buildDropdown(
                value: _assignTaluk,
                items: _assignTaluks,
                onChanged: (val) async {
                  final panchayats = await _getPanchayats(val!);
                  setState(() {
                    _assignTaluk = val;
                    _assignPanchayats = panchayats;
                    _assignPanchayat = 'Choose Panchayat';
                    _assignVillagesList = [];
                  });
                },
              ),
              width: 180,
            ),
            _buildField(
              label: 'Panchayats:',
              child: _buildDropdown(
                value: _assignPanchayat,
                items: _assignPanchayats,
                onChanged: (val) {
                  setState(() {
                    _assignPanchayat = val!;
                    _assignVillagesList = [];
                  });
                  _fetchVillages(val!, true);
                },
              ),
              width: 180,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildField(
          label: 'Villages:',
          child: _buildVillageSelection(isAssign: true),
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildReassignFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24, runSpacing: 24,
          children: [
            _buildField(
              label: 'Search Coordinator',
              child: _buildSearchField(type: 'coordinator'),
              width: 200,
            ),
            _buildField(
              label: 'Search New Member',
              child: _buildSearchField(type: 'reassign_member'),
              width: 200,
            ),
            _buildField(
              label: 'Districts:',
              child: _buildDropdown(
                value: _reassignDistrict,
                items: _districts,
                onChanged: (val) async {
                   final taluks = await _getTaluks(val!);
                   setState(() {
                    _reassignDistrict = val;
                    _reassignTaluks = taluks;
                    _reassignTaluk = 'Choose Taluk';
                    _reassignPanchayats = ['Choose Panchayat'];
                    _reassignPanchayat = 'Choose Panchayat';
                    _reassignVillagesList = [];
                  });
                },
              ),
              width: 180,
            ),
            _buildField(
              label: 'Taluks:',
              child: _buildDropdown(
                value: _reassignTaluk,
                items: _reassignTaluks,
                onChanged: (val) async {
                  final panchayats = await _getPanchayats(val!);
                  setState(() {
                    _reassignTaluk = val;
                    _reassignPanchayats = panchayats;
                    _reassignPanchayat = 'Choose Panchayat';
                    _reassignVillagesList = [];
                  });
                },
              ),
              width: 180,
            ),
            _buildField(
              label: 'Panchayats:',
              child: _buildDropdown(
                value: _reassignPanchayat,
                items: _reassignPanchayats,
                onChanged: (val) {
                  setState(() {
                    _reassignPanchayat = val!;
                    _reassignVillagesList = [];
                  });
                  _fetchVillages(val!, false);
                },
              ),
              width: 180,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildField(
          label: 'Villages:',
          child: _buildVillageSelection(isAssign: false),
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildRemoveCoordFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24, runSpacing: 24,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _buildField(
              label: 'Search Coordinator',
              child: _buildSearchField(type: 'remove_coord'),
              width: 250,
            ),
            SizedBox(
              height: 45,
              child: ElevatedButton(
                onPressed: _selectedRemoveCoordId == null ? null : () => _fetchCoordinatorVillages(_selectedRemoveCoordId!, isReassign: false),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade600),
                child: const Text('Status', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        if (_removeCoordVillages.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Current Assignments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                constraints: const BoxConstraints(minWidth: 600),
                decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
                child: DataTable(
                  columnSpacing: 20,
                  horizontalMargin: 12,
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('District', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Taluk', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Panchayat', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Village', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _removeCoordVillages.map((v) => DataRow(cells: [
                    DataCell(Text(v['district_name'] ?? '-')),
                    DataCell(Text(v['taluk_name'] ?? '-')),
                    DataCell(Text(v['panchayat_name'] ?? '-')),
                    DataCell(Text(v['village_name'] ?? '-')),
                    DataCell(ElevatedButton(
                      onPressed: () => _removeSingleAssignment(v['village_name'], v['panchayat_name']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 8)),
                      child: const Text('Remove', style: TextStyle(color: Colors.white, fontSize: 12)),
                    )),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddVillageFormContent() {
    return Wrap(
      spacing: 24, runSpacing: 24,
      children: [
        _buildField(
          label: 'Districts:',
          child: _buildDropdown(
            value: _addDistrict,
            items: _districts,
            onChanged: (val) async {
              final taluks = await _getTaluks(val!);
              setState(() {
                _addDistrict = val;
                _addTaluks = taluks;
                _addTaluk = 'Choose Taluk';
                _addPanchayats = ['Choose Panchayat'];
                _addPanchayat = 'Choose Panchayat';
              });
            },
          ),
          width: 180,
        ),
        _buildField(
          label: 'Taluks:',
          child: _buildDropdown(
            value: _addTaluk,
            items: _addTaluks,
            onChanged: (val) async {
              final panchayats = await _getPanchayats(val!);
              setState(() {
                _addTaluk = val;
                _addPanchayats = panchayats;
                _addPanchayat = 'Choose Panchayat';
              });
            },
          ),
          width: 180,
        ),
        _buildField(
          label: 'Panchayats:',
          child: _buildDropdown(
            value: _addPanchayat,
            items: _addPanchayats,
            onChanged: (val) {
              setState(() => _addPanchayat = val!);
            },
          ),
          width: 180,
        ),
        _buildField(
          label: 'New Village Name:',
          child: TextField(
            controller: _newVillageController,
            decoration: InputDecoration(
              hintText: 'Enter new village',
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.black12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          width: 250,
        ),
      ],
    );
  }

  Widget _buildRemoveVillageFormContent() {
    return Wrap(
      spacing: 24, runSpacing: 24,
      children: [
        _buildField(
          label: 'Districts:',
          child: _buildDropdown(
            value: _removeDistrict,
            items: _districts,
            onChanged: (val) async {
              final taluks = await _getTaluks(val!);
              setState(() {
                _removeDistrict = val;
                _removeTaluks = taluks;
                _removeTaluk = 'Choose Taluk';
                _removePanchayats = ['Choose Panchayat'];
                _removePanchayat = 'Choose Panchayat';
                _removeVillages = ['Choose Village'];
              });
            },
          ),
          width: 180,
        ),
        _buildField(
          label: 'Taluks:',
          child: _buildDropdown(
            value: _removeTaluk,
            items: _removeTaluks,
            onChanged: (val) async {
              final panchayats = await _getPanchayats(val!);
              setState(() {
                _removeTaluk = val;
                _removePanchayats = panchayats;
                _removePanchayat = 'Choose Panchayat';
                _removeVillages = ['Choose Village'];
              });
            },
          ),
          width: 180,
        ),
        _buildField(
          label: 'Panchayats:',
          child: _buildDropdown(
            value: _removePanchayat,
            items: _removePanchayats,
            onChanged: (val) {
              setState(() {
                _removePanchayat = val!;
                _removeVillages = ['Choose Village'];
              });
              _fetchVillagesForRemove(val!);
            },
          ),
          width: 180,
        ),
        _buildField(
          label: 'Village:',
          child: _buildDropdown(
            value: _removeVillage,
            items: _removeVillages,
            onChanged: (val) {
              setState(() => _removeVillage = val!);
            },
          ),
          width: 180,
        ),
      ],
    );
  }

  Widget _buildField({required String label, required Widget child, required double width}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required void Function(String?) onChanged}) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownSearch<String>(
        items: (filter, loadProps) => items,
        selectedItem: value,
        onSelected: (String? val) => onChanged(val),
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search...",
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          itemBuilder: (context, item, isSelected, isHighlighted) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                border: const Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.blue : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          },
        ),
        decoratorProps: DropDownDecoratorProps(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.black12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.black12)),
          ),
        ),
        dropdownBuilder: (context, selectedItem) {
          return Text(
            selectedItem ?? "",
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    );
  }

  Widget _buildSearchField({required String type}) {
    TextEditingController controller;
    String hint;
    bool isMember;
    
    if (type == 'member') {
      controller = _searchMemberController;
      hint = 'Search Member';
      isMember = true;
    } else if (type == 'coordinator') {
      controller = _searchCoordinatorController;
      hint = 'Search Coordinator';
      isMember = false;
    } else if (type == 'reassign_member') {
      controller = _reassignNewMemberController;
      hint = 'Search New Member';
      isMember = true;
    } else {
      controller = _removeCoordinatorController;
      hint = 'Search Coordinator';
      isMember = false;
    }

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13),
        border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search, size: 18),
          onPressed: () => _showSearchDialog(isMember, type),
        ),
      ),
      readOnly: true,
      onTap: () => _showSearchDialog(isMember, type),
    );
  }

  void _showSearchDialog(bool isMember, String type) {
    showDialog(
      context: context,
      builder: (context) => _SearchUserDialog(
        isMember: isMember,
        onSelected: (id, name) {
          setState(() {
            if (type == 'member') {
              _selectedMemberId = id;
              _searchMemberController.text = name;
            } else if (type == 'coordinator') {
              _reassignCoordId = id;
              _searchCoordinatorController.text = name;
              _fetchCoordinatorVillages(id);
            } else if (type == 'reassign_member') {
              _reassignNewMemberId = id;
              _reassignNewMemberController.text = name;
            } else {
              _selectedRemoveCoordId = id;
              _removeCoordinatorController.text = name;
              _removeCoordVillages = [];
            }
          });
        },
      ),
    );
  }

  Widget _buildVillageSelection({required bool isAssign}) {
    final villages = isAssign ? _assignVillagesList : _reassignVillagesList;
    final selectedNames = isAssign ? _assignSelectedVillageNames : _reassignSelectedVillageNames;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: villages.isEmpty
          ? const Center(child: Text('No villages available', style: TextStyle(color: Colors.black38, fontSize: 13)))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 2 : 4,
                childAspectRatio: isMobile ? 3 : 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: villages.length,
              itemBuilder: (context, index) {
                final village = villages[index];
                final isSelected = village['selected'] ?? false;
                final canSelect = selectedNames.length < 4 || isSelected;

                return Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: canSelect ? (val) {
                          setState(() {
                            village['selected'] = val;
                            if (val!) {
                              selectedNames.add(village['name']);
                            } else {
                              selectedNames.remove(village['name']);
                            }
                          });
                        } : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(village['name'], style: TextStyle(fontSize: 12, color: canSelect ? Colors.black : Colors.grey), overflow: TextOverflow.ellipsis)),
                  ],
                );
              },
            ),
    );
  }
}

class _SearchUserDialog extends StatefulWidget {
  final bool isMember;
  final Function(String id, String name) onSelected;

  const _SearchUserDialog({required this.isMember, required this.onSelected});

  @override
  State<_SearchUserDialog> createState() => _SearchUserDialogState();
}

class _SearchUserDialogState extends State<_SearchUserDialog> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    setState(() => _isLoading = true);
    try {
      final endpoint = widget.isMember ? 'members' : 'coordinators';
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/$endpoint'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _search() async {
    if (_controller.text.isEmpty) {
      _fetchInitial();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final endpoint = widget.isMember ? 'members' : 'coordinators';
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/$endpoint?search=${_controller.text}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isMember ? 'Search Member' : 'Search Coordinator'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onChanged: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Enter name or ID...',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return ListTile(
                      title: Text(user['Name'] ?? 'N/A'),
                      subtitle: Text(user['Familymembershipid'] ?? 'N/A'),
                      onTap: () {
                        widget.onSelected(user['Familymembershipid'], user['Name']);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
