import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/api_config.dart';
import '../widgets/custom_dialog.dart';
import 'doctor_profile_page.dart';
import 'lawyer_profile_page.dart';

class ProfessionalsContent extends StatefulWidget {
  final int userRole;
  final String? globalSearchQuery;
  final String initialCategory; // 'Doctor', 'Lawyer', or 'ALL'

  const ProfessionalsContent({
    super.key,
    required this.userRole,
    this.globalSearchQuery,
    this.initialCategory = 'ALL',
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

  bool _isLoading = true;
  late String _selectedCategory; // 'ALL', 'Doctor', 'Lawyer'
  String _searchQuery = '';
  List<dynamic> _professionals = [];
  final TextEditingController _searchController = TextEditingController();

  bool get _canManage => widget.userRole == 1 || widget.userRole == 2;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    if (widget.globalSearchQuery != null && widget.globalSearchQuery!.isNotEmpty) {
      _searchQuery = widget.globalSearchQuery!;
      _searchController.text = widget.globalSearchQuery!;
    }
    _fetchProfessionals();
  }

  @override
  void didUpdateWidget(covariant ProfessionalsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool shouldRefetch = false;
    if (widget.initialCategory != oldWidget.initialCategory && widget.initialCategory != _selectedCategory) {
      _selectedCategory = widget.initialCategory;
      shouldRefetch = true;
    }
    if (widget.globalSearchQuery != oldWidget.globalSearchQuery &&
        widget.globalSearchQuery != null &&
        widget.globalSearchQuery != _searchQuery) {
      _searchQuery = widget.globalSearchQuery!;
      _searchController.text = widget.globalSearchQuery!;
      shouldRefetch = true;
    }
    if (shouldRefetch) {
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
    final isTamil = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode == 'ta';
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');

    // Determine category based on current page context (Doctor page vs Lawyer page)
    final isDoctorContext = widget.initialCategory == 'Doctor' || (!isEdit && _selectedCategory == 'Doctor');
    final isLawyerContext = widget.initialCategory == 'Lawyer' || (!isEdit && _selectedCategory == 'Lawyer');

    String defaultCategory = 'Doctor';
    if (isDoctorContext) {
      defaultCategory = 'Doctor';
    } else if (isLawyerContext) {
      defaultCategory = 'Lawyer';
    } else if (_selectedCategory != 'ALL') {
      defaultCategory = _selectedCategory;
    }
    String category = item?['category'] ?? defaultCategory;
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
    final formKey = GlobalKey<FormState>();
    final scrollCtrl = ScrollController();
    bool autoValidate = false;
    bool showScrollTop = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDoc = category == 'Doctor';
          final dialogTitle = isEdit
              ? (isTamil ? 'சுயவிவரத்தைத் திருத்துக' : 'Edit Professional Profile')
              : (isDoc
                  ? (isTamil ? 'புதிய மருத்துவர் விவரப் பதிவு' : 'Add Doctor Profile')
                  : (isTamil ? 'புதிய வழக்கறிஞர் விவரப் பதிவு' : 'Add Lawyer Profile'));

          return Dialog(
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
                              isEdit
                                  ? Icons.edit_note
                                  : (isDoc ? Icons.medical_services_rounded : Icons.gavel_rounded),
                              color: primaryMaroon,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              dialogTitle,
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
                            tooltip: isTamil ? 'மூடுக' : 'Close',
                          ),
                        ],
                      ),
                    ),

                    // 2. Scrollable Form with Right-Side Padding away from scrollbar
                    Flexible(
                      child: Stack(
                        children: [
                          NotificationListener<ScrollNotification>(
                            onNotification: (scrollNotif) {
                              final shouldShow = scrollNotif.metrics.pixels > 60;
                              if (shouldShow != showScrollTop) {
                                setDialogState(() => showScrollTop = shouldShow);
                              }
                              return false;
                            },
                            child: Scrollbar(
                              controller: scrollCtrl,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: scrollCtrl,
                                padding: const EdgeInsets.fromLTRB(24, 20, 28, 20),
                                child: Form(
                            key: formKey,
                            autovalidateMode: autoValidate
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: nameCtrl,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\u0B80-\u0BFF\s\.]")),
                                  ],
                                  validator: (val) {
                                    final text = val?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return isTamil ? 'பெயரை உள்ளிடவும்' : 'Please enter full name';
                                    }
                                    if (text.length < 3) {
                                      return isTamil ? 'குறைந்தது 3 எழுத்துக்கள் தேவை' : 'Minimum 3 characters required';
                                    }
                                    if (!RegExp(r'^[a-zA-Z\u0B80-\u0BFF\s\.]+$').hasMatch(text)) {
                                      return isTamil
                                          ? 'எண்கள் மற்றும் சிறப்பு எழுத்துக்கள் அனுமதிக்கப்படவில்லை'
                                          : 'Numbers and special characters are not allowed';
                                    }
                                    if (!RegExp(r'[a-zA-Z\u0B80-\u0BFF]').hasMatch(text)) {
                                      return isTamil ? 'சரியான பெயரை உள்ளிடவும்' : 'Please enter a valid name';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    label: Text.rich(
                                      TextSpan(
                                        text: isTamil ? 'முழுப் பெயர் (பட்டத்துடன்) ' : 'Full Name with Title ',
                                        children: const [
                                          TextSpan(
                                            text: '*',
                                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    hintText: isDoc
                                        ? (isTamil ? 'எ.கா: Dr. நவீன் பொன்னுசாமி' : 'e.g. Dr. Navin Ponnusamy')
                                        : (isTamil ? 'எ.கா: Adv. பி. சந்திரசேகரன்' : 'e.g. Adv. P. Chandrasekaran'),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: specCtrl,
                                        decoration: InputDecoration(
                                          labelText: isDoc
                                              ? (isTamil ? 'சிறப்பு மருத்துவத் துறை' : 'Specialization')
                                              : (isTamil ? 'சட்டப் பயிற்சித் துறை' : 'Legal Practice Area'),
                                          hintText: isDoc
                                              ? (isTamil
                                                  ? 'எ.கா: அவசர சிகிச்சை / பொது மருத்துவம்'
                                                  : 'e.g. Emergency Medicine / Cardiology')
                                              : (isTamil
                                                  ? 'எ.கா: சிவில் சட்டம் / குற்றவியல் சட்டம்'
                                                  : 'e.g. Civil Law / Corporate Law'),
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
                                      width: 175,
                                      child: TextFormField(
                                        controller: expCtrl,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(2),
                                        ],
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return null;
                                          final n = int.tryParse(val.trim());
                                          if (n == null) {
                                            return isTamil ? 'எண்களை உள்ளிடவும்' : 'Digits only';
                                          }
                                          if (n > 75) {
                                            return isTamil ? '0 - 75 வரை மட்டும்' : '0 - 75 years only';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          labelText: isTamil ? 'அனுபவம் (ஆண்டுகள்)' : 'Exp. (Years)',
                                          hintText: isTamil ? 'எ.கா: 15' : 'e.g. 15',
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
                                TextFormField(
                                  controller: qualCtrl,
                                  validator: (val) {
                                    final text = val?.trim() ?? '';
                                    if (text.isEmpty) {
                                      return isTamil ? 'கல்வித் தகுதியை உள்ளிடவும்' : 'Please enter education & qualifications';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    label: Text.rich(
                                      TextSpan(
                                        text: isTamil ? 'கல்வித் தகுதிகள் ' : 'Education & Qualifications ',
                                        children: const [
                                          TextSpan(
                                            text: '*',
                                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    hintText: isDoc
                                        ? (isTamil ? 'எ.கா: MBBS, MD, MS' : 'e.g. MBBS, MD, MS')
                                        : (isTamil ? 'எ.கா: B.A., B.L. / LL.B., LL.M.' : 'e.g. B.A., B.L. / LL.B., LL.M.'),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: workplaceCtrl,
                                  decoration: InputDecoration(
                                    labelText: isDoc
                                        ? (isTamil ? 'பணிபுரியும் மருத்துவமனை / கிளினிக்' : 'Current Hospital / Clinic Workplace')
                                        : (isTamil ? 'பணிபுரியும் அலுவலகம் / நீதிமன்றம்' : 'Current Chambers / Court / Law Firm'),
                                    hintText: isDoc
                                        ? (isTamil
                                            ? 'எ.கா: கொங்குநாடு மருத்துவமனை, கோயம்புத்தூர்'
                                            : 'e.g. Kongunadu Hospital, Coimbatore')
                                        : (isTamil
                                            ? 'எ.கா: மாவட்ட நீதிமன்றம், ஈரோடு / சென்னை உயர் நீதிமன்றம்'
                                            : 'e.g. District Court, Erode / Madras High Court'),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: nativeCtrl,
                                        decoration: InputDecoration(
                                          labelText: isTamil ? 'சொந்த ஊர் (Native Place)' : 'Native Place',
                                          hintText: isTamil ? 'எ.கா: அவல்பூந்துறை / ஓடக்கல்பாளையம்' : 'e.g. Avalpoondurai / Odakkalpalayam',
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
                                      child: TextFormField(
                                        controller: birthCtrl,
                                        decoration: InputDecoration(
                                          labelText: isTamil ? 'பிறந்த இடம்' : 'Birth Place',
                                          hintText: isTamil ? 'எ.கா: கோயம்புத்தூர் / ஈரோடு' : 'e.g. Coimbatore / Erode',
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: locCtrl,
                                        decoration: InputDecoration(
                                          labelText: isTamil ? 'தற்போதைய வசிப்பிடம் / நகரம்' : 'Current Residence / City',
                                          hintText: isTamil ? 'எ.கா: சென்னை / கோயம்புத்தூர்' : 'e.g. Chennai / Coimbatore',
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
                                      child: TextFormField(
                                        controller: phoneCtrl,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                        validator: (val) {
                                          final text = val?.trim() ?? '';
                                          if (text.isEmpty) {
                                            return isTamil ? 'கைபேசி எண்ணை உள்ளிடவும்' : 'Please enter phone number';
                                          }
                                          if (text.length != 10) {
                                            return isTamil ? '10 இலக்க எண் தேவை' : '10 digits required';
                                          }
                                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(text)) {
                                            return isTamil ? 'சரியான கைபேசி எண் (6-9)' : 'Valid 10-digit mobile number';
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          label: Text.rich(
                                            TextSpan(
                                              text: isTamil ? 'தொலைபேசி எண் ' : 'Phone Number ',
                                              children: const [
                                                TextSpan(
                                                  text: '*',
                                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          hintText: 'e.g. 9842990800',
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
                                TextFormField(
                                  controller: emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return null;
                                    final text = val.trim();
                                    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                    if (!emailRegex.hasMatch(text)) {
                                      return isTamil ? 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்' : 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: isTamil ? 'மின்னஞ்சல் முகவரி' : 'Email Address',
                                    hintText: isDoc ? 'e.g. doctor@example.com' : 'e.g. advocate@example.com',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: primaryMaroon, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: bioCtrl,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: isTamil ? 'சுயவிவரக் குறிப்பு & சாதனைகள்' : 'Bio & Career Summary',
                                    hintText: isTamil
                                        ? 'சுருக்கமான சுயவிவரக் குறிப்பு மற்றும் சாதனைகள்...'
                                        : 'Brief profile notes and accomplishments...',
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
                          ),
                          if (showScrollTop)
                            Positioned(
                              right: 20,
                              bottom: 16,
                              child: Material(
                                color: primaryMaroon,
                                shape: const CircleBorder(),
                                elevation: 4,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () {
                                    if (scrollCtrl.hasClients) {
                                      scrollCtrl.animateTo(
                                        0,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Tooltip(
                                      message: isTamil ? 'மேலே செல்க' : 'Scroll to top',
                                      child: const Icon(
                                        Icons.arrow_upward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                          child: Text(
                            isTamil ? 'ரத்து செய்க' : 'Cancel',
                            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
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
                            if (!formKey.currentState!.validate()) {
                              setDialogState(() => autoValidate = true);
                              if (scrollCtrl.hasClients) {
                                scrollCtrl.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                );
                              }
                              return;
                            }

                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              if (scrollCtrl.hasClients) {
                                scrollCtrl.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                );
                              }
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
                                    title: isTamil ? 'வெற்றி' : 'Success',
                                    message: isEdit
                                        ? (isTamil
                                            ? 'சுயவிவரம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!'
                                            : 'Profile updated successfully!')
                                        : (isTamil
                                            ? 'விவரங்கள் வெற்றிகரமாக சேர்க்கப்பட்டன!'
                                            : 'Professional added successfully!'),
                                    type: DialogType.success,
                                  );
                                }
                                _fetchProfessionals();
                              } else {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isTamil
                                            ? 'பிழை: சேமிக்க முடியவில்லை'
                                            : 'Error: ${res.body}',
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('Error saving professional: $e');
                            }
                          },
                          child: Text(
                            isEdit
                                ? (isTamil ? 'சேமிக்க' : 'Save Changes')
                                : (isDoc
                                    ? (isTamil ? 'மருத்துவர் சேர்க்க' : 'Add Doctor')
                                    : (isTamil ? 'வழக்கறிஞர் சேர்க்க' : 'Add Lawyer')),
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
        );
      },
    ),
  ).whenComplete(() => scrollCtrl.dispose());
}

  void _openProfilePage(Map<String, dynamic> item) {
    final isDoctor = item['category'] == 'Doctor';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final screenHeight = MediaQuery.of(ctx).size.height;
        final isMobile = screenWidth < 700;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : (screenWidth > 950 ? (screenWidth - 850) / 2 : 24),
            vertical: isMobile ? 16 : 24,
          ),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * (isMobile ? 0.95 : 0.88),
              maxWidth: 850,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isDoctor
                  ? DoctorProfilePage(
                      doctor: item,
                      canManage: _canManage,
                      onBack: () => Navigator.pop(ctx),
                      onEdit: () {
                        Navigator.pop(ctx);
                        _showAddEditDialog(item: item);
                      },
                    )
                  : LawyerProfilePage(
                      lawyer: item,
                      canManage: _canManage,
                      onBack: () => Navigator.pop(ctx),
                      onEdit: () {
                        Navigator.pop(ctx);
                        _showAddEditDialog(item: item);
                      },
                    ),
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) _fetchProfessionals();
    });
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
    final isDoctorMode = _selectedCategory == 'Doctor';
    final isLawyerMode = _selectedCategory == 'Lawyer';

    final badgeText = isMobile
        ? (isDoctorMode
            ? (isTamil ? 'மருத்துவர்கள் வலையமைப்பு' : 'Doctors Network')
            : (isLawyerMode
                ? (isTamil ? 'வழக்கறிஞர்கள் வலையமைப்பு' : 'Lawyers Network')
                : (isTamil ? 'வல்லுநர்கள் வலையமைப்பு' : 'Professionals Network')))
        : (isDoctorMode
            ? (isTamil ? 'உயிர் காக்கும் கரங்கள் • மருத்துவர்கள் வலையமைப்பு' : 'Lifesaving Hands • Doctors Network')
            : (isLawyerMode
                ? (isTamil ? 'நீதியின் குரல் • வழக்கறிஞர்கள் வலையமைப்பு' : 'Voice of Justice • Lawyers Network')
                : (isTamil ? 'சமூக அறிஞர்கள் & வல்லுநர்கள்' : 'Community Professionals Network')));

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      constraints: isMobile ? BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 64) : null,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: logoGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDoctorMode
                ? Icons.health_and_safety_rounded
                : (isLawyerMode ? Icons.balance_rounded : Icons.workspace_premium),
            color: logoGold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Color(0xFFFEF3C7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final titleWidget = Text(
      isDoctorMode
          ? (isTamil ? 'உயிர் காக்கும் கரங்கள்' : 'Lifesaving Hands')
          : (isLawyerMode
              ? (isTamil ? 'நீதியின் குரல்' : 'Voice of Justice')
              : (isTamil ? 'மருத்துவர்கள் மற்றும் வழக்கறிஞர்கள் பட்டியல்' : 'Doctors & Lawyers Directory')),
      style: TextStyle(
        fontSize: isMobile ? 22 : 26,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
    );

    final subtitleWidget = Text(
      isDoctorMode
          ? (isTamil
              ? 'நமது காடைக்குல சமூகத்தைச் சேர்ந்த மருத்துவர்களின் விவரங்கள், பணிபுரியும் மருத்துவமனை மற்றும் தொடர்பு பட்டியல்.'
              : 'Honoring and connecting our community’s medical doctors and healthcare professionals.')
          : (isLawyerMode
              ? (isTamil
                  ? 'நமது காடைக்குல சமூகத்தைச் சேர்ந்த வழக்கறிஞர்களின் விவரங்கள், பயிற்சித் துறை மற்றும் தொடர்பு பட்டியல்.'
                  : 'Honoring and connecting our community’s advocates and legal practitioners.')
              : (isTamil
                  ? 'நமது காடைக்குல சமூகத்தைச் சேர்ந்த மருத்துவர்கள் மற்றும் வழக்கறிஞர்களின் விவரங்கள் மற்றும் தொடர்பு பட்டியல்.'
                  : 'A dedicated directory honoring and connecting our community’s medical doctors and legal practitioners.')),
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
        isDoctorMode
            ? (isTamil ? 'புதிய மருத்துவர் பதிவு' : 'Add Doctor')
            : (isLawyerMode
                ? (isTamil ? 'புதிய வழக்கறிஞர் பதிவு' : 'Add Lawyer')
                : (isTamil ? 'புதிய பதிவு' : 'Add Professional')),
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
              if (isDoctorMode) ...[
                _buildStatChip(
                  label: isTamil ? 'மொத்த மருத்துவர்கள்' : 'Total Doctors',
                  count: doctors,
                  icon: Icons.medical_services,
                  color: logoGold,
                ),
                _buildStatChip(
                  label: isTamil ? 'முதுநிலை மருத்துவர்கள்' : 'Senior Doctors (10+ Yrs)',
                  count: _professionals.where((p) => (p['experience_years'] ?? 0) >= 10).length,
                  icon: Icons.verified_user,
                  color: logoGold,
                ),
              ] else if (isLawyerMode) ...[
                _buildStatChip(
                  label: isTamil ? 'மொத்த வழக்கறிஞர்கள்' : 'Total Advocates',
                  count: lawyers,
                  icon: Icons.gavel,
                  color: logoGold,
                ),
                _buildStatChip(
                  label: isTamil ? 'முதுநிலை வழக்கறிஞர்கள்' : 'Senior Advocates (10+ Yrs)',
                  count: _professionals.where((p) => (p['experience_years'] ?? 0) >= 10).length,
                  icon: Icons.balance,
                  color: logoGold,
                ),
              ] else ...[
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
                  color: logoGold,
                ),
                _buildStatChip(
                  label: isTamil ? 'வழக்கறிஞர்கள்' : 'Lawyers / Advocates',
                  count: lawyers,
                  icon: Icons.gavel,
                  color: logoGold,
                ),
              ],
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
              if (widget.initialCategory == 'ALL') ...[
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
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryMaroon.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryMaroon.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCategory == 'Doctor' ? Icons.medical_services : Icons.gavel,
                        size: 16,
                        color: primaryMaroon,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCategory == 'Doctor'
                            ? (isTamil ? 'மருத்துவர்கள் பட்டியல்' : 'Doctors Directory')
                            : (isTamil ? 'வழக்கறிஞர்கள் பட்டியல்' : 'Lawyers Directory'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryMaroon,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isNarrow) const SizedBox(height: 12) else const Spacer(),
              ],
              // Search Field
              SizedBox(
                width: isNarrow ? double.infinity : 320,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _selectedCategory == 'Doctor'
                        ? (isTamil ? 'மருத்துவர் பெயர், சிறப்புத் துறை, ஊர்...' : 'Search doctor, specialty, native...')
                        : (_selectedCategory == 'Lawyer'
                            ? (isTamil ? 'வழக்கறிஞர் பெயர், துறை, நீதிமன்றம், ஊர்...' : 'Search lawyer, practice, native...')
                            : (isTamil ? 'பெயர், ஊர், சிறப்பு துறை தேட...' : 'Search name, native, specialization...')),
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
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 850) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 550) {
          crossAxisCount = 2;
        }

        if (crossAxisCount == 1) {
          return Column(
            children: _professionals.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 260,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryMaroon.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: primaryMaroon.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  isDoctor ? 'Doctor' : 'Lawyer',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: primaryMaroon,
                  ),
                ),
              ),
              if (experience != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: lightGold,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: logoGold.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '$experience+ Yrs Exp',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: darkSidebarBrown,
                    ),
                  ),
                ),
              if (item['current_location'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F4),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    item['current_location'].toString(),
                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF57534E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Workplace
          if (item['workplace'] != null) ...[
            _buildCardInfoRow(
              icon: Icons.business,
              text: item['workplace'],
              maxLines: 1,
            ),
            const SizedBox(height: 4),
          ],

          // Native Place
          if (item['native_place'] != null) ...[
            _buildCardInfoRow(
              icon: Icons.home_filled,
              text: '${isTamil ? "சொந்த ஊர்: " : "Native: "}${item["native_place"]}',
              maxLines: 1,
            ),
            const SizedBox(height: 4),
          ],

          // Qualifications
          if (item['qualifications'] != null) ...[
            _buildCardInfoRow(
              icon: Icons.school,
              text: item['qualifications'],
              maxLines: 1,
            ),
            const SizedBox(height: 4),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E5E4)),
        boxShadow: [
          BoxShadow(
            color: darkSidebarBrown.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: headerBorder)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: logoGold, width: 1.2),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: primaryMaroon,
                    child: Icon(
                      isDoctor ? Icons.medical_services_rounded : Icons.gavel_rounded,
                      color: logoGold,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: darkSidebarBrown,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.verified, size: 14, color: logoGold),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item['specialization'] ??
                            (isDoctor ? 'Doctor / Physician' : 'Advocate / Legal Practitioner'),
                        style: const TextStyle(
                          fontSize: 11,
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
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF78716C)),
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
                            Icon(Icons.edit, size: 16, color: primaryMaroon),
                            SizedBox(width: 8),
                            Text('Edit Profile', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF5F5F4))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryMaroon,
                  side: BorderSide(color: primaryMaroon.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => _openProfilePage(item),
                child: Text(
                  isTamil ? 'விவரங்கள்' : 'View Profile',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: const Color(0xFFA8A29E)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isBold ? darkSidebarBrown : const Color(0xFF44403C),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              height: 1.25,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
