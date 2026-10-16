import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/api_config.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_dropdown_search.dart';

class ProfessionalsContent extends StatefulWidget {
  final int userRole;
  final String? globalSearchQuery;

  const ProfessionalsContent({
    super.key,
    required this.userRole,
    this.globalSearchQuery,
  });

  @override
  State<ProfessionalsContent> createState() => _ProfessionalsContentState();
}

class _ProfessionalsContentState extends State<ProfessionalsContent> {
  // Kaadaikulam Logo Brand Palette
  static const Color primaryMaroon = Color(0xFF5D1712);
  static const Color darkSidebarBrown = Color(0xFF2D1B18);
  static const Color logoGold = Color(0xFFC49A3C);
  static const Color lightGold = Color(0xFFFEF3C7);
  static const Color softAmber = Color(0xFFD97706);

  bool _isLoading = true;
  String _selectedCategory = 'ALL'; // 'ALL', 'Doctor', 'Lawyer'
  String _searchQuery = '';
  List<dynamic> _professionals = [];
  final TextEditingController _searchController = TextEditingController();

  bool get _canManage => widget.userRole == 1 || widget.userRole == 2;

  @override
  void initState() {
    super.initState();
    if (widget.globalSearchQuery != null && widget.globalSearchQuery!.isNotEmpty) {
      _searchQuery = widget.globalSearchQuery!;
      _searchController.text = widget.globalSearchQuery!;
    }
    _fetchProfessionals();
  }

  @override
  void didUpdateWidget(covariant ProfessionalsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.globalSearchQuery != oldWidget.globalSearchQuery &&
        widget.globalSearchQuery != null &&
        widget.globalSearchQuery != _searchQuery) {
      setState(() {
        _searchQuery = widget.globalSearchQuery!;
        _searchController.text = widget.globalSearchQuery!;
      });
      _fetchProfessionals();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfessionals() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse(ApiConfig.professionals).replace(
        queryParameters: {
          if (_selectedCategory != 'ALL') 'category': _selectedCategory,
          if (_searchQuery.trim().isNotEmpty) 'search': _searchQuery.trim(),
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _professionals = data['data'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching professionals: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _deleteProfessional(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to remove "$name" from the directory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.delete(Uri.parse(ApiConfig.professional(id)));
      if (res.statusCode == 200) {
        if (mounted) {
          showStatusDialog(
            context,
            title: 'Deleted',
            message: 'Profile removed successfully.',
            type: DialogType.success,
          );
        }
        _fetchProfessionals();
      } else {
        if (mounted) {
          showStatusDialog(
            context,
            title: 'Error',
            message: 'Failed to delete profile.',
            type: DialogType.error,
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting professional: $e');
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    String category = item?['category'] ?? 'Doctor';
    final specCtrl = TextEditingController(text: item?['specialization'] ?? '');
    final qualCtrl = TextEditingController(text: item?['qualifications'] ?? '');
    final expCtrl = TextEditingController(
      text: item?['experience_years'] != null ? item!['experience_years'].toString() : '',
    );
    final workplaceCtrl = TextEditingController(text: item?['workplace'] ?? '');
    final nativeCtrl = TextEditingController(text: item?['native_place'] ?? '');
    final birthCtrl = TextEditingController(text: item?['birth_place'] ?? '');
    final locCtrl = TextEditingController(text: item?['current_location'] ?? '');
    final phoneCtrl = TextEditingController(text: item?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: item?['email'] ?? '');
    final bioCtrl = TextEditingController(text: item?['bio_summary'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 620,
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Pinned Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryMaroon.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_note : Icons.person_add_alt_1,
                            color: primaryMaroon,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Professional Profile' : 'Add Community Professional',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkSidebarBrown,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),

                  // 2. Scrollable Form with Right-Side Padding away from scrollbar
                  Flexible(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 28, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomDropdownSearch(
                              label: 'Category',
                              requiredMark: true,
                              dropdownMap: const {
                                'Doctor': 'Doctor (மருத்துவர்)',
                                'Lawyer': 'Lawyer / Advocate (வழக்கறிஞர்)',
                              },
                              value: category,
                              height: 48,
                              borderColor: const Color(0xFFCBD5E1),
                              focusedBorderColor: primaryMaroon,
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => category = val);
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(
                                label: const Text.rich(
                                  TextSpan(
                                    text: 'Full Name with Title ',
                                    children: [
                                      TextSpan(
                                        text: '*',
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                hintText: 'e.g. Dr. Navin Ponnusamy / Adv. Chandrasekaran',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: specCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Specialization',
                                      hintText: 'e.g. Emergency Medicine / Corporate Law',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 140,
                                  child: TextField(
                                    controller: expCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Exp. (Years)',
                                      hintText: 'e.g. 25',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: qualCtrl,
                              decoration: InputDecoration(
                                labelText: 'Education & Qualifications',
                                hintText: 'e.g. MBBS, MD / B.A., B.L.',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: workplaceCtrl,
                              decoration: InputDecoration(
                                labelText: 'Current Workplace / Hospital / Chambers',
                                hintText: 'e.g. Kongunadu Hospital, Coimbatore / Legal Practice',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: nativeCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Native Place',
                                      hintText: 'e.g. Odakkalpalayam / Avalpoondurai',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: birthCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Birth Place',
                                      hintText: 'e.g. Coimbatore / Erode',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: locCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Current Residence / City',
                                      hintText: 'e.g. Chennai / Coimbatore',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'Phone Number',
                                      hintText: 'e.g. 9865707500',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'e.g. advocate@example.com',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: bioCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Bio & Career Summary',
                                hintText: 'Brief profile notes and accomplishments...',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.all(12),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Pinned Footer Actions (Can never overlap text fields)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFAF9),
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryMaroon,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Please enter a name')),
                              );
                              return;
                            }

                            final payload = {
                              'name': name,
                              'category': category,
                              'specialization': specCtrl.text.trim().isEmpty ? null : specCtrl.text.trim(),
                              'qualifications': qualCtrl.text.trim().isEmpty ? null : qualCtrl.text.trim(),
                              'experience_years': int.tryParse(expCtrl.text.trim()),
                              'workplace': workplaceCtrl.text.trim().isEmpty ? null : workplaceCtrl.text.trim(),
                              'native_place': nativeCtrl.text.trim().isEmpty ? null : nativeCtrl.text.trim(),
                              'birth_place': birthCtrl.text.trim().isEmpty ? null : birthCtrl.text.trim(),
                              'current_location': locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                              'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                              'bio_summary': bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
                            };

                            try {
                              http.Response res;
                              if (isEdit) {
                                res = await http.put(
                                  Uri.parse(ApiConfig.professional(item['id'])),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode(payload),
                                );
                              } else {
                                res = await http.post(
                                  Uri.parse(ApiConfig.professionals),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode(payload),
                                );
                              }

                              if (res.statusCode == 200 || res.statusCode == 201) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  showStatusDialog(
                                    context,
                                    title: 'Success',
                                    message: isEdit
                                        ? 'Profile updated successfully!'
                                        : 'Professional added successfully!',
                                    type: DialogType.success,
                                  );
                                }
                                _fetchProfessionals();
                              } else {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Error: ${res.body}')),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('Error saving professional: $e');
                            }
                          },
                          child: Text(
                            isEdit ? 'Save Changes' : 'Add Professional',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailModal(Map<String, dynamic> item) {
    final isTamil = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode == 'ta';
    final isDoctor = item['category'] == 'Doctor';
    final phone = item['phone'];
    final experience = item['experience_years'];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 580,
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Fixed Header (Pinned at top, never cut off)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [darkSidebarBrown, Color(0xFF4A1512), primaryMaroon],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: logoGold, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: primaryMaroon,
                          child: Icon(
                            isDoctor ? Icons.medical_services_rounded : Icons.gavel_rounded,
                            size: 26,
                            color: logoGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['specialization'] ??
                                  (isDoctor ? 'Doctor / Physician' : 'Advocate / Legal Practitioner'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFFEF3C7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white70),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                // 2. Scrollable Body (Inside dialog boundaries with visible scrollbar)
                Flexible(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges Row
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDoctor ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                                  border: Border.all(
                                    color: isDoctor ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isDoctor ? Icons.health_and_safety : Icons.balance,
                                      size: 14,
                                      color: isDoctor ? const Color(0xFF047857) : const Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isDoctor
                                          ? (isTamil ? 'மருத்துவர்' : 'Doctor')
                                          : (isTamil ? 'வழக்கறிஞர்' : 'Lawyer / Advocate'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDoctor ? const Color(0xFF047857) : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (experience != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: lightGold,
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.workspace_premium, size: 14, color: softAmber),
                                      const SizedBox(width: 5),
                                      Text(
                                        '$experience+ ${isTamil ? 'ஆண்டுகள் அனுபவம்' : 'Years Experience'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, size: 14, color: logoGold),
                                    SizedBox(width: 5),
                                    Text(
                                      'Community Verified',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Information Rows
                          _buildDetailRow(
                            icon: Icons.school_outlined,
                            label: isTamil ? 'கல்வித் தகுதிகள்' : 'Qualifications & Education',
                            value: item['qualifications'],
                            color: primaryMaroon,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.business_outlined,
                            label: isTamil ? 'பணிபுரியும் இடம்' : 'Current Workplace / Organization',
                            value: item['workplace'],
                            color: primaryMaroon,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.home_work_outlined,
                            label: isTamil ? 'சொந்த ஊர் (Native Place)' : 'Native Place',
                            value: item['native_place'],
                            color: primaryMaroon,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.location_on_outlined,
                            label: isTamil ? 'பிறந்த இடம்' : 'Birth Place',
                            value: item['birth_place'],
                            color: primaryMaroon,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.my_location_outlined,
                            label: isTamil ? 'தற்போதைய வசிப்பிடம்' : 'Current Residence / Location',
                            value: item['current_location'],
                            color: primaryMaroon,
                          ),
                          if (item['dob'] != null && item['dob'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.cake_outlined,
                              label: isTamil ? 'பிறந்த தேதி' : 'Date of Birth',
                              value: item['dob'].toString().contains('-')
                                  ? item['dob'].toString().split('-').reversed.join('/')
                                  : item['dob'],
                              color: primaryMaroon,
                            ),
                          ],
                          if (phone != null && phone.toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.phone_android_outlined,
                              label: isTamil ? 'தொலைபேசி எண்' : 'Phone Number',
                              value: phone,
                              color: primaryMaroon,
                            ),
                          ],
                          if (item['email'] != null && item['email'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.email_outlined,
                              label: isTamil ? 'மின்னஞ்சல்' : 'Email Address',
                              value: item['email'],
                              color: primaryMaroon,
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Bio Summary
                          if (item['bio_summary'] != null &&
                              item['bio_summary'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDF7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF1E6D0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTamil ? 'சுயவிவர சுருக்கம்' : 'Profile Overview',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryMaroon,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item['bio_summary'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Color(0xFF2D1B18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Fixed Footer with Close Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFAF9),
                    border: Border(top: BorderSide(color: Color(0xFFE7E5E4))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryMaroon,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          isTamil ? 'மூடுக' : 'Close',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required dynamic value,
    required Color color,
  }) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF78716C),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: darkSidebarBrown,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = Provider.of<LocaleProvider>(context).locale.languageCode == 'ta';
    final isMobile = MediaQuery.of(context).size.width < 900;

    final totalCount = _professionals.length;
    final doctorCount = _professionals.where((p) => p['category'] == 'Doctor').length;
    final lawyerCount = _professionals.where((p) => p['category'] == 'Lawyer').length;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16.0 : 32.0,
        isMobile ? 16.0 : 32.0,
        isMobile ? 16.0 : 32.0,
        isMobile ? 80.0 : 100.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner & Header with Kaadaikulam Logo Colors
          _buildHeroHeader(isTamil, isMobile, totalCount, doctorCount, lawyerCount),
          const SizedBox(height: 20),

          // Filters & Search Bar
          _buildFilterBar(isTamil),
          const SizedBox(height: 20),

          // Content body
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: CircularProgressIndicator(color: primaryMaroon),
              ),
            )
          else if (_professionals.isEmpty)
            _buildEmptyState(isTamil)
          else
            _buildProfessionalsGrid(isTamil),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(bool isTamil, bool isMobile, int total, int doctors, int lawyers) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: logoGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, color: logoGold, size: 16),
          const SizedBox(width: 8),
          Text(
            isTamil ? 'சமூக அறிஞர்கள் & வல்லுநர்கள்' : 'Community Professionals Network',
            style: const TextStyle(
              color: Color(0xFFFEF3C7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );

    final titleWidget = Text(
      isTamil
          ? 'மருத்துவர்கள் மற்றும் வழக்கறிஞர்கள் பட்டியல்'
          : 'Doctors & Lawyers Directory',
      style: TextStyle(
        fontSize: isMobile ? 22 : 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
    );

    final subtitleWidget = Text(
      isTamil
          ? 'நமது காடைக்குல சமூகத்தைச் சேர்ந்த மருத்துவர்கள் மற்றும் வழக்கறிஞர்களின் விவரங்கள் மற்றும் தொடர்பு பட்டியல்.'
          : 'A dedicated directory honoring and connecting our community’s medical doctors and legal practitioners.',
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white70,
        height: 1.4,
      ),
    );

    final addButton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: logoGold,
        foregroundColor: darkSidebarBrown,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      onPressed: () => _showAddEditDialog(),
      icon: const Icon(Icons.add, size: 20, color: darkSidebarBrown),
      label: Text(
        isTamil ? 'புதிய பதிவு' : 'Add Professional',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkSidebarBrown, Color(0xFF4A1512), primaryMaroon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkSidebarBrown.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            badge,
            const SizedBox(height: 12),
            titleWidget,
            const SizedBox(height: 6),
            subtitleWidget,
            if (_canManage) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: addButton,
              ),
            ],
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      badge,
                      const SizedBox(height: 14),
                      titleWidget,
                      const SizedBox(height: 6),
                      subtitleWidget,
                    ],
                  ),
                ),
                if (_canManage) ...[
                  const SizedBox(width: 20),
                  addButton,
                ],
              ],
            ),
          ],
          const SizedBox(height: 20),
          // Stat chips
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildStatChip(
                label: isTamil ? 'மொத்த வல்லுநர்கள்' : 'Total Registered',
                count: total,
                icon: Icons.people_alt,
                color: logoGold,
              ),
              _buildStatChip(
                label: isTamil ? 'மருத்துவர்கள்' : 'Doctors',
                count: doctors,
                icon: Icons.medical_services,
                color: const Color(0xFF34D399),
              ),
              _buildStatChip(
                label: isTamil ? 'வழக்கறிஞர்கள்' : 'Lawyers / Advocates',
                count: lawyers,
                icon: Icons.gavel,
                color: const Color(0xFFFBBF24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isTamil) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;
          return Flex(
            direction: isNarrow ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isNarrow ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
            children: [
              // Segmented Category Buttons
              Wrap(
                spacing: 8,
                children: [
                  _buildCategoryFilterChip('ALL', isTamil ? 'அனைத்தும்' : 'All', Icons.groups),
                  _buildCategoryFilterChip(
                    'Doctor',
                    isTamil ? 'மருத்துவர்கள்' : 'Doctors',
                    Icons.medical_services,
                  ),
                  _buildCategoryFilterChip(
                    'Lawyer',
                    isTamil ? 'வழக்கறிஞர்கள்' : 'Lawyers',
                    Icons.gavel,
                  ),
                ],
              ),
              if (isNarrow) const SizedBox(height: 12) else const Spacer(),
              // Search Field
              SizedBox(
                width: isNarrow ? double.infinity : 320,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: isTamil
                        ? 'பெயர், ஊர், சிறப்பு துறை தேட...'
                        : 'Search name, native, specialization...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 20, color: primaryMaroon),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _fetchProfessionals();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFFAFAF9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: primaryMaroon, width: 1.8),
                    ),
                  ),
                  onSubmitted: (val) {
                    setState(() => _searchQuery = val.trim());
                    _fetchProfessionals();
                  },
                  onChanged: (val) {
                    if (val.isEmpty && _searchQuery.isNotEmpty) {
                      setState(() => _searchQuery = '');
                      _fetchProfessionals();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilterChip(String key, String label, IconData icon) {
    final isSelected = _selectedCategory == key;
    return InkWell(
      onTap: () {
        setState(() => _selectedCategory = key);
        _fetchProfessionals();
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryMaroon : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryMaroon : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryMaroon.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? logoGold : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTamil) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isTamil ? 'பதிவுகள் எதுவும் கிடைக்கவில்லை' : 'No Professionals Found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkSidebarBrown,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isTamil
                  ? 'தேடல் வினவலை மாற்றி மீண்டும் முயற்சிக்கவும்.'
                  : 'Try adjusting your search criteria or filter.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalsGrid(bool isTamil) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1100) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = 2;
        }

        if (crossAxisCount == 1) {
          return Column(
            children: _professionals.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildProfessionalCard(p, isTamil, isGrid: false),
              );
            }).toList(),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 380,
          ),
          itemCount: _professionals.length,
          itemBuilder: (ctx, idx) => _buildProfessionalCard(_professionals[idx], isTamil, isGrid: true),
        );
      },
    );
  }

  Widget _buildProfessionalCard(Map<String, dynamic> item, bool isTamil, {bool isGrid = false}) {
    final isDoctor = item['category'] == 'Doctor';
    final phone = item['phone'];
    final experience = item['experience_years'];

    // Header styling harmonized with Logo Maroon / Gold
    final headerBg = isDoctor ? const Color(0xFFFAF7F5) : const Color(0xFFFFFDF7);
    final headerBorder = isDoctor ? const Color(0xFFEADBCE) : const Color(0xFFF1E6D0);

    final cardBody = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDoctor ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDoctor ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Text(
                  isDoctor ? 'Doctor' : 'Lawyer',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDoctor ? const Color(0xFF047857) : const Color(0xFFB45309),
                  ),
                ),
              ),
              if (experience != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: lightGold,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    '$experience+ Yrs Exp',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              if (item['current_location'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item['current_location'].toString(),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF57534E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Workplace
          if (item['workplace'] != null) ...[
            _buildCardInfoRow(
              icon: Icons.business,
              text: item['workplace'],
              maxLines: 2,
            ),
            const SizedBox(height: 6),
          ],

          // Native Place
          if (item['native_place'] != null) ...[
            _buildCardInfoRow(
              icon: Icons.home_filled,
              text: '${isTamil ? "சொந்த ஊர்: " : "Native: "}${item["native_place"]}',
              maxLines: 1,
            ),
            const SizedBox(height: 6),
          ],

          // Qualifications
          if (item['qualifications'] != null) ...[
            _buildCardInfoRow(
              icon: Icons.school,
              text: item['qualifications'],
              maxLines: 2,
            ),
            const SizedBox(height: 6),
          ],

          // Phone
          if (phone != null && phone.toString().isNotEmpty) ...[
            _buildCardInfoRow(
              icon: Icons.phone_android,
              text: phone.toString(),
              maxLines: 1,
              isBold: true,
            ),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E5E4)),
        boxShadow: [
          BoxShadow(
            color: darkSidebarBrown.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: headerBorder)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: logoGold, width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: primaryMaroon,
                    child: Icon(
                      isDoctor ? Icons.medical_services_rounded : Icons.gavel_rounded,
                      color: logoGold,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: darkSidebarBrown,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.verified, size: 16, color: logoGold),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['specialization'] ??
                            (isDoctor ? 'Doctor / Physician' : 'Advocate / Legal Practitioner'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: primaryMaroon,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_canManage)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF78716C)),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showAddEditDialog(item: item);
                      } else if (val == 'delete') {
                        _deleteProfessional(item['id'], item['name'] ?? '');
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: primaryMaroon),
                            SizedBox(width: 8),
                            Text('Edit Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Card Body: expanded only in fixed-height GridView, natural height on mobile
          if (isGrid) Expanded(child: cardBody) else cardBody,

          // Card Footer Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF5F5F4))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryMaroon,
                  side: BorderSide(color: primaryMaroon.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showDetailModal(item),
                child: Text(
                  isTamil ? 'விவரங்கள்' : 'View Profile',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfoRow({
    required IconData icon,
    required String text,
    int maxLines = 1,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFA8A29E)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isBold ? darkSidebarBrown : const Color(0xFF44403C),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              height: 1.3,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
