import 'dart:convert';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'custom_dropdown_search.dart';
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
  final TextEditingController _newTalukController = TextEditingController();
  final TextEditingController _newPanchayatController = TextEditingController();
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
  String _addSelectedVillage = 'Choose Village';
  List<String> _addVillages = ['Choose Village', '+ Add New Village'];

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
  bool _isFetchingStatus = false;

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
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages-assign/$panchayat'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<String> selectedNames = isAssign ? _assignSelectedVillageNames : _reassignSelectedVillageNames;
        final villages = (data['data'] as List).map((v) {
          final vName = v['village_name'].toString();
          final isFull = v['is_full'] == 1;
          return {
            'name': vName,
            'selected': selectedNames.contains(vName),
            'is_full': isFull
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

  Future<void> _fetchVillagesForAdd(String panchayat) async {
    if (panchayat == 'Choose Panchayat') {
      setState(() {
        _addVillages = ['Choose Village', '+ Add New Village'];
        _addSelectedVillage = 'Choose Village';
      });
      return;
    } else if (panchayat == '+ Add New Panchayat') {
      setState(() {
        _addVillages = ['Choose Village', '+ Add New Village'];
        _addSelectedVillage = '+ Add New Village';
      });
      return;
    }
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _addVillages = ['Choose Village', ...List<String>.from(data['data'])];
          if (!_addVillages.contains('+ Add New Village')) _addVillages.add('+ Add New Village');
          _addSelectedVillage = 'Choose Village';
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
    if (!isReassign) {
      setState(() => _isFetchingStatus = true);
    }
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
          if (list.isEmpty) {
            showStatusDialog(context, title: 'Info', message: 'No villages assigned to this coordinator.', type: DialogType.warning);
          }
        }
      } else {
        if (!isReassign) {
          showStatusDialog(context, title: 'Error', message: 'Failed to fetch status.', type: DialogType.error);
        }
      }
    } catch (e) {
      if (!isReassign) {
        showStatusDialog(context, title: 'Error', message: 'Connection error.', type: DialogType.error);
      }
    } finally {
      if (!isReassign) {
        setState(() => _isFetchingStatus = false);
      }
    }
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
            errorMsg = errorData['detail'].toString().replaceFirst(RegExp(r'^Server Error: \d+: '), '');
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
            errorMsg = errorData['detail'].toString().replaceFirst(RegExp(r'^Server Error: \d+: '), '');
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
    bool hasTalukError = _addTaluk == 'Choose Taluk' || (_addTaluk == '+ Add New Taluk' && _newTalukController.text.isEmpty);
    bool hasPanchayatError = _addPanchayat == 'Choose Panchayat' || (_addPanchayat == '+ Add New Panchayat' && _newPanchayatController.text.isEmpty);
    bool hasVillageError = _addSelectedVillage == 'Choose Village' || (_addSelectedVillage == '+ Add New Village' && _newVillageController.text.isEmpty);

    if (_addDistrict == 'Choose District' || hasTalukError || hasPanchayatError || hasVillageError) {
      showStatusDialog(context, title: 'Error', message: 'Please complete all required fields', type: DialogType.error);
      return;
    }

    final talukToAdd = _addTaluk == '+ Add New Taluk' ? _newTalukController.text : _addTaluk;
    final panchayatToAdd = _addPanchayat == '+ Add New Panchayat' ? _newPanchayatController.text : _addPanchayat;
    final villageNameToAdd = _addSelectedVillage == '+ Add New Village' ? _newVillageController.text : _addSelectedVillage;

    setState(() => _isAddingVillage = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/add-village'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'district': _addDistrict,
          'taluk': talukToAdd,
          'panchayat': panchayatToAdd,
          'village_name': villageNameToAdd,
        }),
      );

      if (response.statusCode == 200) {
        showStatusDialog(context, title: 'Success', message: 'Village added successfully', type: DialogType.success);
        _newTalukController.clear();
        _newPanchayatController.clear();
        _newVillageController.clear();
      } else {
        String errorMsg = 'Failed to add village';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['detail'] != null) {
            errorMsg = errorData['detail'].toString().replaceFirst(RegExp(r'^Server Error: \d+: '), '');
          }
        } catch (_) {}
        showStatusDialog(context, title: 'Error', message: errorMsg, type: DialogType.error);
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
                child: Text(AppLocalizations.of(context)?.coordinators ?? 'Coordinators', style: const TextStyle(color: Color(0xFF5D1712), fontWeight: FontWeight.w500)),
              ),
              Text(AppLocalizations.of(context)?.assignCoordinatorsBreadcrumb ?? ' / Assigncoordinators', style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Assign Coordinator Form
          _buildFormCard(
            title: AppLocalizations.of(context)?.assignCoordinatorHeader ?? 'Assign Coordinator',
            icon: Icons.person_add_alt_1,
            accentColor: const Color(0xFF5D1712),
            child: _buildAssignFormContent(),
            buttonText: AppLocalizations.of(context)?.assignAction ?? 'Assign',
            onButtonPressed: _assignCoordinator,
            isLoading: _isAssigning,
          ),

          const SizedBox(height: 32),

          // 2. Reassign Coordinator Form
          _buildFormCard(
            title: AppLocalizations.of(context)?.reassignCoordinatorHeader ?? 'Reassign Coordinator',
            icon: Icons.person_add_alt_1,
            accentColor: Colors.red,
            child: _buildReassignFormContent(),
            buttonText: AppLocalizations.of(context)?.reassignAction ?? 'Reassign',
            onButtonPressed: _reassignCoordinator,
            isLoading: _isReassigning,
          ),

          const SizedBox(height: 32),

          // 3. Remove Coordinator Form (Updated with Table)
          _buildFormCard(
            title: AppLocalizations.of(context)?.removeCoordinatorHeader ?? 'Remove Coordinator',
            icon: Icons.person_remove_alt_1,
            accentColor: Colors.grey.shade700,
            child: _buildRemoveCoordFormContent(),
            buttonText: AppLocalizations.of(context)?.removeCoordinatorAction ?? 'Remove Coordinator',
            onButtonPressed: _removeCoordinator,
            isLoading: _isRemovingCoord,
          ),

          const SizedBox(height: 32),

          // 4. Add Village Form
          _buildFormCard(
            title: AppLocalizations.of(context)?.addVillageHeader ?? 'Add Village',
            icon: Icons.add_location_alt,
            accentColor: Colors.teal,
            child: _buildAddVillageFormContent(),
            buttonText: AppLocalizations.of(context)?.addVillageAction ?? 'Add Village',
            onButtonPressed: _addVillage,
            isLoading: _isAddingVillage,
          ),

          const SizedBox(height: 32),

          // 5. Remove Village Form
          _buildFormCard(
            title: AppLocalizations.of(context)?.removeVillageHeader ?? 'Remove Village',
            icon: Icons.location_off,
            accentColor: Colors.redAccent,
            child: _buildRemoveVillageFormContent(),
            buttonText: AppLocalizations.of(context)?.removeVillageAction ?? 'Remove Village',
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
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      minimumSize: const Size(150, 45),
                    ),
                    child: isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          buttonText, 
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
            _buildField(
              label: AppLocalizations.of(context)?.searchMember ?? 'Search Member',
              child: _buildSearchField(type: 'member'),
              width: 200,
            ),
            _buildField(
              label: AppLocalizations.of(context)?.districtsLabel ?? 'Districts:',
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
              label: AppLocalizations.of(context)?.taluksLabel ?? 'Taluks:',
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
              label: AppLocalizations.of(context)?.panchayatsLabel ?? 'Panchayats:',
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
          label: AppLocalizations.of(context)?.villagesLabel ?? 'Villages:',
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
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
            _buildField(
              label: AppLocalizations.of(context)?.searchCoordinator ?? 'Search Coordinator',
              child: _buildSearchField(type: 'coordinator'),
              width: 200,
            ),
            _buildField(
              label: AppLocalizations.of(context)?.searchNewMember ?? 'Search New Member',
              child: _buildSearchField(type: 'reassign_member'),
              width: 200,
            ),
            _buildField(
              label: AppLocalizations.of(context)?.districtsLabel ?? 'Districts:',
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
              label: AppLocalizations.of(context)?.taluksLabel ?? 'Taluks:',
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
              label: AppLocalizations.of(context)?.panchayatsLabel ?? 'Panchayats:',
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
          label: AppLocalizations.of(context)?.villagesLabel ?? 'Villages:',
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
              label: AppLocalizations.of(context)?.searchCoordinator ?? 'Search Coordinator',
              child: _buildSearchField(type: 'remove_coord'),
              width: 250,
            ),
            SizedBox(
              height: 45,
              child: ElevatedButton(
                onPressed: _selectedRemoveCoordId == null || _isFetchingStatus ? null : () => _fetchCoordinatorVillages(_selectedRemoveCoordId!, isReassign: false),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade600),
                child: _isFetchingStatus 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Status', style: TextStyle(color: Colors.white)),
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
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
        _buildField(
          label: AppLocalizations.of(context)?.districtsLabel ?? 'Districts:',
          child: _buildDropdown(
            value: _addDistrict,
            items: _districts,
            onChanged: (val) async {
              final taluks = await _getTaluks(val!);
              if (!taluks.contains('+ Add New Taluk')) taluks.add('+ Add New Taluk');
              setState(() {
                _addDistrict = val;
                _addTaluks = taluks;
                _addTaluk = 'Choose Taluk';
                _addPanchayats = ['Choose Panchayat'];
                _addPanchayat = 'Choose Panchayat';
                _addVillages = ['Choose Village', '+ Add New Village'];
                _addSelectedVillage = 'Choose Village';
              });
            },
          ),
          width: 180,
        ),
        _buildField(
          label: AppLocalizations.of(context)?.taluksLabel ?? 'Taluks:',
          child: _buildDropdown(
            value: _addTaluk,
            items: _addTaluks,
            onChanged: (val) async {
              if (val != '+ Add New Taluk') {
                final panchayats = await _getPanchayats(val!);
                if (!panchayats.contains('+ Add New Panchayat')) panchayats.add('+ Add New Panchayat');
                setState(() {
                  _addTaluk = val;
                  _addPanchayats = panchayats;
                  _addPanchayat = 'Choose Panchayat';
                  _addVillages = ['Choose Village', '+ Add New Village'];
                  _addSelectedVillage = 'Choose Village';
                });
              } else {
                setState(() {
                  _addTaluk = val!;
                  _addPanchayats = ['Choose Panchayat', '+ Add New Panchayat'];
                  _addPanchayat = '+ Add New Panchayat';
                  _addVillages = ['Choose Village', '+ Add New Village'];
                  _addSelectedVillage = '+ Add New Village';
                });
              }
            },
          ),
          width: 180,
        ),
        if (_addTaluk == '+ Add New Taluk')
          _buildField(
            label: 'New Taluk Name:',
            child: TextField(
              controller: _newTalukController,
              decoration: InputDecoration(
                hintText: 'Enter new taluk',
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.black12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            width: 180,
          ),
        _buildField(
          label: AppLocalizations.of(context)?.panchayatsLabel ?? 'Panchayats:',
          child: _buildDropdown(
            value: _addPanchayat,
            items: _addPanchayats,
            onChanged: (val) {
              if (val != '+ Add New Panchayat') {
                setState(() => _addPanchayat = val!);
                _fetchVillagesForAdd(val!);
              } else {
                setState(() {
                  _addPanchayat = val!;
                  _addVillages = ['Choose Village', '+ Add New Village'];
                  _addSelectedVillage = '+ Add New Village';
                });
              }
            },
          ),
          width: 180,
        ),
        if (_addPanchayat == '+ Add New Panchayat')
          _buildField(
            label: 'New Panchayat Name:',
            child: TextField(
              controller: _newPanchayatController,
              decoration: InputDecoration(
                hintText: 'Enter new panchayat',
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.black12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            width: 180,
          ),
        _buildField(
          label: 'Villages in Panchayat:',
          child: _buildDropdown(
            value: _addSelectedVillage,
            items: _addVillages,
            onChanged: (val) {
              setState(() => _addSelectedVillage = val!);
            },
          ),
          width: 180,
        ),
        if (_addSelectedVillage == '+ Add New Village')
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
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
        _buildField(
          label: AppLocalizations.of(context)?.districtsLabel ?? 'Districts:',
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
          label: AppLocalizations.of(context)?.taluksLabel ?? 'Taluks:',
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
          label: AppLocalizations.of(context)?.panchayatsLabel ?? 'Panchayats:',
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
          label: AppLocalizations.of(context)?.villagesLabel ?? 'Village:',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    return SizedBox(
      width: isMobile ? double.infinity : width,
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
    // Treat "Choose X" placeholder strings as null so hint text shows
    final isPlaceholder = value.startsWith('Choose ');
    // Filter out placeholder items from the dropdown list
    final filteredItems = items.where((e) => !e.startsWith('Choose ')).toList();
    return CustomDropdownSearch(
      label: '',
      hint: value == 'Choose District' ? (AppLocalizations.of(context)?.chooseDistrict ?? 'Choose District') :
            value == 'Choose Taluk' ? (AppLocalizations.of(context)?.chooseTaluk ?? 'Choose Taluk') :
            value == 'Choose Panchayat' ? (AppLocalizations.of(context)?.choosePanchayat ?? 'Choose Panchayat') :
            value == 'Choose Village' ? (AppLocalizations.of(context)?.chooseVillage ?? 'Choose Village') : value,
      dropdownItems: filteredItems,
      value: isPlaceholder ? null : value,
      onChanged: (val) => onChanged(val ?? value),
      height: 45,
    );
  }

  Widget _buildSearchField({required String type}) {
    TextEditingController controller;
    String hint;
    bool isMember;
    
    if (type == 'member') {
      controller = _searchMemberController;
      hint = AppLocalizations.of(context)?.searchMember ?? 'Search Member';
      isMember = true;
    } else if (type == 'coordinator') {
      controller = _searchCoordinatorController;
      hint = AppLocalizations.of(context)?.searchCoordinator ?? 'Search Coordinator';
      isMember = false;
    } else if (type == 'reassign_member') {
      controller = _reassignNewMemberController;
      hint = AppLocalizations.of(context)?.searchNewMember ?? 'Search New Member';
      isMember = true;
    } else {
      controller = _removeCoordinatorController;
      hint = AppLocalizations.of(context)?.searchCoordinator ?? 'Search Coordinator';
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
                final isFull = village['is_full'] ?? false;
                final canSelect = (selectedNames.length < 4 || isSelected) && !isFull;

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
                    Expanded(
                      child: Text(
                        village['name'], 
                        style: TextStyle(
                          fontSize: 12, 
                          color: canSelect ? Colors.black : Colors.grey,
                          decoration: isFull ? TextDecoration.lineThrough : null,
                        ), 
                        overflow: TextOverflow.ellipsis
                      )
                    ),
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
      final endpoint = widget.isMember ? 'members?exclude_coordinators=true' : 'coordinators';
      final url = widget.isMember 
          ? '${ApiConfig.baseUrl}/api/$endpoint'
          : '${ApiConfig.baseUrl}/api/$endpoint';
      final response = await http.get(Uri.parse(url));
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
      final queryParams = widget.isMember 
          ? '?exclude_coordinators=true&search=${_controller.text}'
          : '?search=${_controller.text}';
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/$endpoint$queryParams'));
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
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isMember 
                  ? (AppLocalizations.of(context)?.searchMember ?? 'Search Member')
                  : (AppLocalizations.of(context)?.searchCoordinator ?? 'Search Coordinator'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D1712),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              onChanged: (_) => _search(),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.searchHintText ?? 'Enter name or ID...',
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF5D1712)), 
                  onPressed: _search,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF5D1712), width: 1.5),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF5D1712))))
            else if (_results.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No results found', style: TextStyle(color: Colors.black54)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final String selectedId = user['Familymembershipid']?.toString() ?? user['Id'].toString();
                          widget.onSelected(selectedId, user['Name'] ?? '');
                          Navigator.pop(context);
                        },
                        hoverColor: const Color(0xFF5D1712).withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['Name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['Familymembershipid'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.black54),
                child: Text(AppLocalizations.of(context)?.cancelDialogBtn ?? 'Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

