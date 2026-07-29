import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show FilteringTextInputFormatter, rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl_phone_field/countries.dart';
import 'package:file_picker/file_picker.dart' as fp_pkg;
import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'custom_dropdown_search.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'custom_phone_field.dart';
import 'custom_dialog.dart';
import '../../utils/api_config.dart';
import '../../services/geo_data_service.dart';

class AddFamilyMemberForm extends StatefulWidget {
  final dynamic parentId;
  final Map<String, dynamic> parentData;
  final int submitterRole;
  final String? preSelectedRelationship;

  const AddFamilyMemberForm({
    super.key, 
    required this.parentId, 
    required this.parentData, 
    required this.submitterRole,
    this.preSelectedRelationship,
  });

  @override
  State<AddFamilyMemberForm> createState() => _AddFamilyMemberFormState();
}

class _AddFamilyMemberFormState extends State<AddFamilyMemberForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  
  // Design Colors
  static const Color primaryBrown = const Color(0xFF2D1B18);
  static const Color mediumBrown = const Color(0xFF3E2723);
  static const Color accentGold = const Color(0xFFC5A028);
  static const Color glassWhite = Color(0xA6FFFFFF);
  static const Color borderColor = const Color(0xFFE0E0E0);

  // Controllers
  final ScrollController _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _dobController = TextEditingController();
  final _valuvuController = TextEditingController();
  final _thottamController = TextEditingController();
  final _educationController = TextEditingController();
  final _professionController = TextEditingController();
  
  // Address Controllers
  final _streetController = TextEditingController();
  final _doorNoController = TextEditingController();
  final _pinCodeController = TextEditingController();
  
  final _currStreetController = TextEditingController();
  final _currDoorNoController = TextEditingController();
  final _currPinCodeController = TextEditingController();
  final _currCityController = TextEditingController();
  final _currZipController = TextEditingController();
  final _currStateController = TextEditingController();
  final _currFullAddressController = TextEditingController();

  // Husband Details for Married Daughter
  final _otherRelationshipController = TextEditingController();
  final _husbandNameController = TextEditingController();
  final _husbandDobController = TextEditingController();
  final _husbandMobileController = TextEditingController();

  // State Variables
  String? _selectedRelationship;
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedMarried;
  String? _selectedEducation;
  String? _selectedProfession;
  String? _selectedDistrict;
  String? _selectedTaluk;
  String? _selectedPanchayat;
  String? _selectedVillage;
  String? _selectedCurrentAddressType;
  String? _selectedCurrState;
  String? _selectedCurrDistrict;
  String? _selectedCurrTaluk;
  String? _selectedCurrPanchayat;
  String? _selectedCurrVillage;
  String? _selectedCountry;
  String? _selectedCurrCity;
  String? _selectedHusbandKulam;

  final List<String> _kulams = ['Poondurai Kaadai', 'Aanthuvan Kulam', 'Azhagu Kulam', 'Aathe Kulam', 'Aanthai Kulam', 'Aadar Kulam', 'Aavan Kulam', 'Eenjan Kulam', 'Ozukkar Kulam', 'Oothaalar Kulam', 'Kannakkan Kulam', 'Kannan Kulam', 'Kannaanthai Kulam', 'Kaadai Kulam', 'Kaari Kulam', 'Keeran Kulam', 'Kuzhlaayan Kulam', 'Koorai Kulam', 'Koovendhar Kulam', 'Saathanthai Kulam', 'Sellan Kulam', 'Semban Kulam', 'Sengkannan Kulam', 'Sembuthan Kulam', 'Senkunnier Kulam', 'Sevvaayar Kulam', 'Cheran Kulam', 'Chedan Kulam', 'Dananjayan Kulam', 'Thazhinji Kulam', 'Thooran Kulam', 'Devendran Kulam', 'Thoodar Kulam', 'Neerunniyar Kulam', 'Pavazhalar Kulam', 'Panayan Kulam', 'Pathuman Kulam', 'Payiran Kulam', 'Panagkaadar Kulam', 'Pathariar Kulam', 'Pandiyan Kulam', 'Pillar Kulam', 'Poosan Kulam', 'Poochanthai Kulam', 'Periyan Kulam', 'Perunkudiyaan Kulam', 'Porulaanthai Kulam', 'Ponnar Kulam', 'Maniyan Kulam', 'Mayilar Kulam', 'Maadar Kulam', 'Mutthan Kulam', 'Muzhukathan Kulam', 'Medhi Kulam', 'Vannakkan Kulam', 'Villiyar Kulam', 'Vilayan Kulam', 'Vizhiyar Kulam', 'Venduvan Kulam', 'Vennag Kulam', 'Vellampar Kulam', 'Others'];

  bool _whatsappSameAsPhone = false;
  String _phoneCountryCode = 'IN';
  String _whatsappCountryCode = 'IN';
  bool _showMandatoryErrors = false;
  bool _isAgreed = false;
  bool _phoneExists = false;
  final _phoneFieldKey = GlobalKey<FormFieldState>();

  // Address Data
  List<String> _districts = [];
  List<String> _taluks = [];
  List<String> _panchayats = [];
  List<String> _villages = [];
  
  List<String> _currDistricts = [];
  List<String> _currTaluks = [];
  List<String> _currPanchayats = [];
  List<String> _currVillages = [];
  
  List<String> _countryNames = [];
  List<String> _stateNames = [];
  List<String> _cityNames = [];

  final GeoDataService _geoService = GeoDataService();

  // Options
  final List<String> _relationships = ['Grand Father','Grand Mother','Father','Mother','Husband','Wife','Son','Daughter','Son-in-law','Daughter-in-law','Brother','Sister','Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _educations = ['SSLC', 'HSC', 'Diploma', 'ITI', 'B.A', 'B.Sc', 'B.Com', 'BBA', 'BCA', 'B.E', 'B.Tech', 'MBBS', 'BDS', 'B.Pharm', 'B.Ed', 'LLB', 'B.Arch', 'M.A', 'M.Sc', 'M.Com', 'MBA', 'MCA', 'M.E', 'M.Tech', 'MD', 'MS', 'MDS', 'M.Pharm', 'M.Ed', 'LLM', 'M.Phil', 'Ph.D', 'Others'];
  final List<String> _professions = ['Doctor', 'Lawyer', 'Police', 'Teacher / Lecturer', 'Engineer', 'Government Employee', 'Private Employee', 'Student', 'Farmer', 'Textile Mill Worker', 'Garment Factory Worker', 'Tailor', 'Pattern Master', 'Textile Machinery Technician', 'Loom Operator', 'Truck Driver', 'Dairy Farmer', 'Poultry Farmer', 'Animal Husbandry', 'Pump Technician', 'Electrical Technician', 'Grocery Shop Staff', 'IT / Software Employee', 'Home Maker', 'Retired', 'Others'];

  // Documents
  XFile? _memberImage;
  XFile? _communityCert;

  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _focusNodes['Relationship'] = FocusNode();
    _focusNodes['Name'] = FocusNode();
    _focusNodes['Phone Number'] = FocusNode();
    
    _phoneController.addListener(() {
      if (_phoneController.text.length == 10) {
        _checkExistence(_phoneController.text);
      } else {
        if (_phoneExists) setState(() => _phoneExists = false);
      }
    });

    if (widget.preSelectedRelationship != null && _relationships.contains(widget.preSelectedRelationship)) {
      _selectedRelationship = widget.preSelectedRelationship;
      final v = _selectedRelationship;
      if (['Wife', 'Daughter', 'Mother', 'Grand Mother', 'Daughter-in-law', 'Sister'].contains(v)) {
        _selectedGender = 'Female';
      } else if (['Husband', 'Son', 'Father', 'Grand Father', 'Son-in-law', 'Brother'].contains(v)) {
        _selectedGender = 'Male';
      }
      
      if (v == 'Wife' || v == 'Husband' || v == 'Father' || v == 'Mother' || v == 'Grand Father' || v == 'Grand Mother' || v == 'Daughter-in-law' || v == 'Son-in-law') {
        _selectedMarried = 'Yes';
      }
    }

    _fetchDistricts();
    _loadGeoData();
    // Pre-fill address from parent
    _prefillFromParent();
  }

  Future<void> _checkExistence(String phone) async {
    final familyId = widget.parentData['Familymembershipid'] ?? 
                     widget.parentData['familymembershipid'] ?? 
                     widget.parentData['Existfamilyid'] ?? 
                     widget.parentData['existfamilyid'] ?? '';

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.checkExistence),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'family_id': familyId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _phoneExists = data['phone_exists'] ?? false;
          _phoneFieldKey.currentState?.validate();
        });
      }
    } catch (e) {
      debugPrint('Error checking existence: $e');
    }
  }

  void _prefillFromParent() {
    final p = widget.parentData;
    _valuvuController.text = p['Valuvu'] ?? '';
    _thottamController.text = p['Thottam'] ?? '';
    
    _selectedDistrict = (p['District']?.toString().trim().isEmpty ?? true) ? null : p['District'];
    _selectedTaluk = (p['Taluk']?.toString().trim().isEmpty ?? true) ? null : p['Taluk'];
    _selectedPanchayat = (p['Panchayat']?.toString().trim().isEmpty ?? true) ? null : p['Panchayat'];
    _selectedVillage = (p['Village']?.toString().trim().isEmpty ?? true) ? null : p['Village'];
    final street = p['Street'] ?? '';
    final doorNo = p['Doornumber'] ?? '';
    _streetController.text = doorNo.isNotEmpty ? "$doorNo, $street" : street;
    _pinCodeController.text = p['Pincode']?.toString() ?? '';

    _selectedCurrentAddressType = null;
  }

  Future<void> _loadGeoData() async {
    if (!_geoService.isLoaded) {
      await _geoService.loadData();
    }
    setState(() {
      _countryNames = _geoService.countryNames;
    });
  }

  void _updateStates(String countryName) {
    setState(() {
      _stateNames = _geoService.getStates(countryName);
    });
  }

  void _checkMarriedAgeValidation(String? marriedVal) {
    if (marriedVal == 'Yes' && _dobController.text.isNotEmpty) {
      try {
        DateTime? dob;
        final parts = _dobController.text.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            dob = DateTime.parse(_dobController.text);
          } else if (parts[2].length == 4) {
            dob = DateTime.parse("${parts[2]}-${parts[1]}-${parts[0]}");
          }
        }
        if (dob != null) {
          int age = DateTime.now().year - dob.year;
          if (DateTime.now().month < dob.month || (DateTime.now().month == dob.month && DateTime.now().day < dob.day)) age--;
          if (age < 18) {
            showStatusDialog(context, title: 'Validation Error', message: 'Person must be at least 18 years old to be marked as married.', type: DialogType.error);
            setState(() => _selectedMarried = 'No');
            return;
          }
        }
      } catch (_) {}
    }
    setState(() => _selectedMarried = marriedVal);
  }

  void _updateCities(String countryName, String stateName) {
    setState(() {
      _cityNames = _geoService.getCities(countryName, stateName);
    });
  }

  Future<void> _fetchDistricts() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        setState(() { 
          _districts = List<String>.from(d['data']);
          if (_selectedDistrict != null) _fetchTaluks(_selectedDistrict!);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchTaluks(String district) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        setState(() { 
          _taluks = List<String>.from(d['data']);
          if (_selectedTaluk != null) _fetchPanchayats(_selectedTaluk!);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPanchayats(String taluk) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        setState(() { 
          _panchayats = List<String>.from(d['data']);
          if (_selectedPanchayat != null) _fetchVillages(_selectedPanchayat!);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchVillages(String panchayat) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        setState(() { _villages = List<String>.from(d['data']); });
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrDistricts() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        setState(() { _currDistricts = List<String>.from(d['data']); });
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrTaluks(String district) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        setState(() { _currTaluks = List<String>.from(d['data']); });
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrPanchayats(String taluk) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        setState(() { _currPanchayats = List<String>.from(d['data']); });
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrVillages(String panchayat) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        setState(() { _currVillages = List<String>.from(d['data']); });
      }
    } catch (_) {}
  }

  void _copyNativeToCurrent() {
    setState(() {
      _selectedCurrentAddressType = 'Tamil Nadu';
      _selectedCurrDistrict = _selectedDistrict;
      _currDistricts = List.from(_districts);
      
      _selectedCurrTaluk = _selectedTaluk;
      _currTaluks = List.from(_taluks);

      _selectedCurrPanchayat = _selectedPanchayat;
      _currPanchayats = List.from(_panchayats);

      _selectedCurrVillage = _selectedVillage;
      _currVillages = List.from(_villages);

      _currStreetController.text = _streetController.text;
      _currPinCodeController.text = _pinCodeController.text;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _dobController.dispose();
    _valuvuController.dispose();
    _thottamController.dispose();
    _educationController.dispose();
    _professionController.dispose();
    _streetController.dispose();
    _doorNoController.dispose();
    _pinCodeController.dispose();
    _currStreetController.dispose();
    _currDoorNoController.dispose();
    _currPinCodeController.dispose();
    _currCityController.dispose();
    _currZipController.dispose();
    _currStateController.dispose();
    _currFullAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: isMobile ? 10 : 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const Divider(height: 1),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(Icons.person_outline, 'Family Member Details'),
                        const SizedBox(height: 16),
                        
                        _buildResponsiveRow(isMobile, [
                          _buildDropdownField('Relationship *', _relationships, isMobile, value: _selectedRelationship, 
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final isMarried = (widget.parentData['Married']?.toString().toLowerCase() == 'yes') || 
                                                (widget.parentData['married']?.toString().toLowerCase() == 'yes');
                              if ((v == 'Wife' || v == 'Husband') && !isMarried) {
                                return 'Select a different relationship';
                              }
                              return null;
                            },
                            onChanged: (v) {
                              final isMarried = (widget.parentData['Married']?.toString().toLowerCase() == 'yes') || 
                                                (widget.parentData['married']?.toString().toLowerCase() == 'yes');
                              if ((v == 'Wife' || v == 'Husband') && !isMarried) {
                                showStatusDialog(
                                  context,
                                  title: 'Validation Error',
                                  message: 'Family Head is not married. You cannot add a $v.',
                                  type: DialogType.error,
                                  autoDismiss: false,
                                );
                              }
                              setState(() {
                                _selectedRelationship = v;
                                if (['Wife', 'Daughter', 'Mother', 'Grand Mother', 'Daughter-in-law', 'Sister'].contains(v)) {
                                  _selectedGender = 'Female';
                                } else if (['Husband', 'Son', 'Father', 'Grand Father', 'Son-in-law', 'Brother'].contains(v)) {
                                  _selectedGender = 'Male';
                                }
                                
                                if (v == 'Wife' || v == 'Husband' || v == 'Father' || v == 'Mother' || v == 'Grand Father' || v == 'Grand Mother' || v == 'Daughter-in-law' || v == 'Son-in-law') {
                                  _selectedMarried = 'Yes';
                                }
                              });
                            }
                          ),
                          _buildInputField('Name *', _nameController, isMobile, maxLength: 254),
                          _buildIntlPhoneField('Phone Number *', _phoneController, isMobile, 
                            fieldKey: _phoneFieldKey,
                            validator: (v) {
                              final val = _phoneController.text;
                              if (val.isEmpty) return 'Required';
                              if (_phoneExists) return 'Phone number already registered';
                              return null;
                            }
                          ),
                        ]),
                        
                        if (_selectedRelationship == 'Other') ...[
                            _buildResponsiveRow(isMobile, [
                              _buildInputField('Other Relationship *', _otherRelationshipController, isMobile, maxLength: 50, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                              if (!isMobile) const SizedBox(),
                              if (!isMobile) const SizedBox(),
                            ]),
                          ],

                        _buildResponsiveRow(isMobile, [
                          _buildDatePickerField('Date Of Birth *', _dobController, isMobile),
                          _buildGenderSelector(isMobile),
                          _buildDropdownField('Blood Group *', _bloodGroups, isMobile, value: _selectedBloodGroup, onChanged: (v) => setState(() => _selectedBloodGroup = v)),
                        ]),

                        _buildResponsiveRow(isMobile, [
                          _buildEmailField(isMobile),
                          _buildWhatsAppField(isMobile),
                          _buildRadioField('Married *', ['Yes', 'No'], isMobile, value: _selectedMarried, onChanged: _checkMarriedAgeValidation),
                        ]),

                        _buildResponsiveRow(isMobile, [
                          _buildInputField('Valuvu', _valuvuController, isMobile, maxLength: 254),
                          _buildInputField('Thottam', _thottamController, isMobile, maxLength: 254),
                          _buildInputField('Kulam *', TextEditingController(text: 'Poondurai Kaadai'), isMobile, readOnly: true),
                        ]),

                        if (_selectedRelationship == 'Daughter' && _selectedMarried == 'Yes') ...[
                          const SizedBox(height: 16),
                          _buildResponsiveRow(isMobile, [
                            _buildInputField('Husband Name *', _husbandNameController, isMobile, maxLength: 254),
                            _buildDatePickerField('Husband Date Of Birth *', _husbandDobController, isMobile),
                          ]),
                          _buildResponsiveRow(isMobile, [
                            _buildIntlPhoneField('Husband Phone *', _husbandMobileController, isMobile, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                            _buildDropdownField('Husband Kulam *', _kulams, isMobile, value: _selectedHusbandKulam, onChanged: (v) => setState(() => _selectedHusbandKulam = v)),
                          ]),
                        ],

                        const SizedBox(height: 32),
                        _buildSectionTitle(Icons.work_outline, 'Education & Career Details'),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(isMobile, [
                          _buildDropdownField('Education', _educations, isMobile, value: _selectedEducation, onChanged: (v) => setState(() => _selectedEducation = v)),
                          _buildDropdownField('Profession', _professions, isMobile, value: _selectedProfession, onChanged: (v) => setState(() => _selectedProfession = v)),
                          if (!isMobile) const Spacer(),
                        ]),

                        const SizedBox(height: 32),
                        _buildSectionTitle(Icons.location_on_outlined, 'Native Address (Prefilled from Family Head)'),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(isMobile, [
                           _buildDropdownField('District *', _districts, isMobile, value: _selectedDistrict, onChanged: (v) {
                             setState(() { _selectedDistrict = v; _selectedTaluk = null; });
                             if (v != null) _fetchTaluks(v);
                           }),
                           _buildDropdownField('Taluk *', _taluks, isMobile, value: _selectedTaluk, onChanged: (v) {
                             setState(() { _selectedTaluk = v; _selectedPanchayat = null; });
                             if (v != null) _fetchPanchayats(v);
                           }),
                           _buildDropdownField('Panchayat *', _panchayats, isMobile, value: _selectedPanchayat, onChanged: (v) {
                             setState(() { _selectedPanchayat = v; _selectedVillage = null; });
                             if (v != null) _fetchVillages(v);
                           }),
                        ]),
                        _buildResponsiveRow(isMobile, [
                           _buildDropdownField('Village Name *', _villages, isMobile, value: _selectedVillage, onChanged: (v) => setState(() => _selectedVillage = v)),
                           _buildInputField('Door No & Street Name *', _streetController, isMobile, maxLength: 254),
                           _buildInputField('Pin Code *', _pinCodeController, isMobile, keyboardType: TextInputType.number, maxLength: 6),
                        ]),

                        const SizedBox(height: 32),
                        _buildSectionTitle(
                          Icons.home_outlined, 
                          'Current Address',
                          trailing: _selectedCurrentAddressType == 'Tamil Nadu'
                            ? TextButton.icon(
                                onPressed: _copyNativeToCurrent,
                                icon: const Icon(Icons.copy_all, size: 16, color: const Color(0xFFC5A028)),
                                label: const Text('Same as Native', style: TextStyle(color: const Color(0xFFC5A028), fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            : null,
                        ),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(isMobile, [
                          _buildRadioField('Current Address Type *', ['Tamil Nadu', 'Other State', 'NRI'], isMobile, 
                            value: _selectedCurrentAddressType, 
                            onChanged: (v) {
                              setState(() {
                                _selectedCurrentAddressType = v;
                                _selectedCurrDistrict = null;
                                _selectedCurrTaluk = null;
                                _selectedCurrPanchayat = null;
                                _selectedCurrVillage = null;
                                _selectedCurrState = null;
                                _selectedCurrCity = null;
                                _selectedCountry = null;
                                
                                _currStreetController.clear();
                                _currDoorNoController.clear();
                                _currPinCodeController.clear();
                                _currFullAddressController.clear();
                              });
                              if (v == 'Tamil Nadu') _fetchCurrDistricts();
                              if (v == 'Other State') _updateStates('India');
                            }),
                        ]),
                        const SizedBox(height: 16),
                        if (_selectedCurrentAddressType == 'Tamil Nadu') ...[
                          _buildResponsiveRow(isMobile, [
                            _buildDropdownField('District *', _currDistricts, isMobile, value: _selectedCurrDistrict, onChanged: (v) {
                              setState(() { _selectedCurrDistrict = v; _selectedCurrTaluk = null; });
                              if (v != null) _fetchCurrTaluks(v);
                            }),
                            _buildDropdownField('Taluk *', _currTaluks, isMobile, value: _selectedCurrTaluk, onChanged: (v) {
                              setState(() { _selectedCurrTaluk = v; _selectedCurrPanchayat = null; });
                              if (v != null) _fetchCurrPanchayats(v);
                            }),
                            _buildDropdownField('Panchayat *', _currPanchayats, isMobile, value: _selectedCurrPanchayat, onChanged: (v) {
                              setState(() { _selectedCurrPanchayat = v; _selectedCurrVillage = null; });
                              if (v != null) _fetchCurrVillages(v);
                            }),
                          ]),
                          _buildResponsiveRow(isMobile, [
                            _buildDropdownField('Village *', _currVillages, isMobile, value: _selectedCurrVillage, onChanged: (v) => setState(() => _selectedCurrVillage = v)),
                            _buildInputField('Door No & Street Name *', _currStreetController, isMobile, maxLength: 254),
                            _buildInputField('Pin Code *', _currPinCodeController, isMobile, keyboardType: TextInputType.number, maxLength: 6),
                          ]),
                        ] else if (_selectedCurrentAddressType == 'Other State') ...[
                          _buildResponsiveRow(isMobile, [
                            _buildDropdownField('State *', _stateNames, isMobile, value: _selectedCurrState, onChanged: (v) {
                              setState(() => _selectedCurrState = v);
                              if (v != null) _updateCities('India', v);
                            }),
                            _buildDropdownField('City *', _cityNames, isMobile, value: _selectedCurrCity, onChanged: (v) => setState(() => _selectedCurrCity = v)),
                            _buildInputField('Zip/Postal Code *', _currPinCodeController, isMobile, keyboardType: TextInputType.number),
                          ]),
                          _buildTextArea('Full Address *', _currFullAddressController, isMobile),
                        ] else if (_selectedCurrentAddressType == 'NRI') ...[
                           _buildResponsiveRow(isMobile, [
                            _buildDropdownField('Country *', _countryNames, isMobile, value: _selectedCountry, onChanged: (v) {
                              setState(() => _selectedCountry = v);
                              if (v != null) _updateStates(v);
                            }),
                            _buildDropdownField('State *', _stateNames, isMobile, value: _selectedCurrState, onChanged: (v) {
                              setState(() => _selectedCurrState = v);
                              if (v != null && _selectedCountry != null) _updateCities(_selectedCountry!, v);
                            }),
                            _buildDropdownField('City *', _cityNames, isMobile, value: _selectedCurrCity, onChanged: (v) => setState(() => _selectedCurrCity = v)),
                          ]),
                          _buildResponsiveRow(isMobile, [
                            _buildInputField('Zip/Postal Code *', _currPinCodeController, isMobile),
                            if (!isMobile) const Spacer(),
                            if (!isMobile) const Spacer(),
                          ]),
                          _buildTextArea('Full Address *', _currFullAddressController, isMobile),
                        ],

                        const SizedBox(height: 32),
                        _buildSectionTitle(Icons.description_outlined, 'Documents'),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(isMobile, [
                          _buildFileUploadField('Passport size photo *', 'member_image'),
                          _buildFileUploadField('Community Certificate', 'community_cert'),
                          if (!isMobile) const Spacer(),
                          if (!isMobile) const Spacer(),
                        ]),

                        const SizedBox(height: 32),
                        _buildAgreement(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: Text(AppLocalizations.of(context)?.addFamilyMember ?? 'Add Family Member', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBrown))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, {Widget? trailing}) {
    String translatedTitle = title;
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      if (title == 'Family Member Details' || title == 'Basic Details') translatedTitle = loc.basicDetails ?? title;
      else if (title == 'Education & Career Details') translatedTitle = loc.educationCareerDetails ?? title;
      else if (title == 'Native Address') translatedTitle = loc.nativeAddress ?? title;
      else if (title == 'Current Address') translatedTitle = loc.currentAddress ?? title;
      else if (title == 'Documents') translatedTitle = loc.documents ?? title;
    }
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: accentGold, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Icon(icon, color: primaryBrown, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          translatedTitle, 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBrown),
        ),
      ),
      if (trailing != null) trailing,
    ]);
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList());
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: c))).toList(),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool isMobile, {TextInputType? keyboardType, bool readOnly = false, int? maxLength, Key? fieldKey, String? Function(String?)? validator, AutovalidateMode? autovalidateMode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label, fontSize: 14),
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          maxLength: maxLength,
          autovalidateMode: autovalidateMode ?? AutovalidateMode.onUserInteraction,
          inputFormatters: (keyboardType == TextInputType.phone || keyboardType == TextInputType.number)
              ? [FilteringTextInputFormatter.digitsOnly]
              : ((label.contains('Name') && !label.contains('Street') && !label.contains('Village')) ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.]'))] : null),
          validator: validator ?? ((v) {
            final val = v ?? '';
            if (label.contains('Name') && !label.contains('Street') && !label.contains('Village')) {
              if (label.contains('*') && val.trim().isEmpty) return 'Required';
              if (val.trim().isNotEmpty && val.trim().length < 3) return 'Name must be at least 3 characters';
              if (val.trim().isNotEmpty && !RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(val.trim())) return 'Only letters, spaces, and dots allowed';
            }
            return (label.contains('*') && val.isEmpty) ? 'Required' : null;
          }),
          decoration: InputDecoration(
            fillColor: Colors.white, filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: mediumBrown)),
            counterText: "",
          ),
        ),
      ],
    );
  }

  Widget _buildIntlPhoneField(String label, TextEditingController controller, bool isMobile, {Key? fieldKey, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label, fontSize: 14),
        const SizedBox(height: 8),
        CustomPhoneField(
          fieldKey: fieldKey,
          label: '',
          controller: controller,
          initialCountryCode: _phoneCountryCode,
          onCountryChanged: (c) {
            setState(() {
              _phoneCountryCode = c.code;
              controller.clear();
              if (_whatsappSameAsPhone) {
                _whatsappCountryCode = c.code;
                _whatsappController.clear();
              }
            });
          },
          validator: (v) => validator?.call(controller.text),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, bool isMobile, {String? value, ValueChanged<String?>? onChanged, String? Function(String?)? validator}) {
    bool hasAsterisk = label.contains('*');
    String baseLabel = label.replaceAll('*', '').trim();
    String translatedLabel = baseLabel;
    
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      if (baseLabel == 'Relationship') translatedLabel = loc.relationshipHeader ?? baseLabel;
      else if (baseLabel == 'Gender') translatedLabel = loc.genderHeader ?? baseLabel;
      else if (baseLabel == 'Blood Group') translatedLabel = loc.bloodGroupLabel ?? baseLabel;
      else if (baseLabel == 'Married') translatedLabel = loc.marriedStatusLabel ?? baseLabel;
      else if (baseLabel == 'Kulam') translatedLabel = loc.kulamLabel ?? baseLabel;
      else if (baseLabel == 'Education') translatedLabel = loc.educationLabel ?? baseLabel;
      else if (baseLabel == 'Profession') translatedLabel = loc.professionLabel ?? baseLabel;
      else if (baseLabel == 'District') translatedLabel = loc.districtHeader ?? baseLabel;
      else if (baseLabel == 'Taluk') translatedLabel = loc.talukHeader ?? baseLabel;
      else if (baseLabel == 'Panchayat') translatedLabel = loc.panchayatHeader ?? baseLabel;
      else if (baseLabel == 'Village') translatedLabel = loc.villageUpperHeader ?? baseLabel;
      else if (baseLabel == 'State') translatedLabel = loc.stateLabel ?? baseLabel;
      else if (baseLabel == 'Country') translatedLabel = loc.countryLabel ?? baseLabel;
      else if (baseLabel == 'City') translatedLabel = loc.cityVillageLabel ?? baseLabel;
    }

    String finalLabel = hasAsterisk ? '$translatedLabel *' : translatedLabel;

    return CustomDropdownSearch(
      label: finalLabel,
      dropdownItems: options,
      value: value,
      onChanged: onChanged,
      requiredMark: label.contains('*'),
      validator: validator ?? ((v) => (label.contains('*') && (v == null || v.isEmpty)) ? 'Required' : null),
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label, fontSize: 14),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
            if (picked != null) {
              setState(() => controller.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}");
              if (controller == _dobController && _selectedMarried == 'Yes') _checkMarriedAgeValidation('Yes');
            }
          },
          decoration: InputDecoration(
            fillColor: Colors.white, filled: true,
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText('Gender *', fontSize: 14),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Radio<String>(value: 'Male', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v), activeColor: primaryBrown, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: const VisualDensity(horizontal: -4, vertical: -4)),
                ),
                const SizedBox(width: 6),
                const Text('Male'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Radio<String>(value: 'Female', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v), activeColor: primaryBrown, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: const VisualDensity(horizontal: -4, vertical: -4)),
                ),
                const SizedBox(width: 6),
                const Text('Female'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Radio<String>(value: 'Other', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v), activeColor: primaryBrown, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: const VisualDensity(horizontal: -4, vertical: -4)),
                ),
                const SizedBox(width: 6),
                const Text('Other'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isMobile) {
    return _buildInputField('Email', _emailController, isMobile, keyboardType: TextInputType.emailAddress, maxLength: 254);
  }

  Widget _buildWhatsAppField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildLabelText('WhatsApp Number *', fontSize: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(value: _whatsappSameAsPhone, onChanged: (v) => setState(() {
                    _whatsappSameAsPhone = v!;
                    if (v) {
                      _whatsappController.text = _phoneController.text;
                      _whatsappCountryCode = _phoneCountryCode;
                    }
                  }), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: const VisualDensity(horizontal: -4, vertical: -4)),
                ),
                const SizedBox(width: 6),
                Text(AppLocalizations.of(context)?.sameAsPhone ?? 'Same as Phone', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
        CustomPhoneField(
          label: '',
          controller: _whatsappController,
          initialCountryCode: _whatsappCountryCode,
          onCountryChanged: (c) {
            setState(() {
              _whatsappCountryCode = c.code;
              _whatsappController.clear();
            });
          },
          validator: (value) {
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextArea(String label, TextEditingController controller, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label, fontSize: 14),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            fillColor: Colors.white, filled: true,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioField(String label, List<String> options, bool isMobile, {String? value, ValueChanged<String?>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label, fontSize: 14),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: options.map((o) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Radio<String>(value: o, groupValue: value, onChanged: onChanged, activeColor: primaryBrown, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: const VisualDensity(horizontal: -4, vertical: -4)),
              ),
              const SizedBox(width: 6),
              Builder(
                builder: (context) {
                  String display = o;
                  final loc = AppLocalizations.of(context);
                  if (loc != null) {
                    if (o == 'Male') display = loc.maleLabel ?? o;
                    else if (o == 'Female') display = loc.femaleLabel ?? o;
                    else if (o == 'Other') display = loc.otherLabel ?? o;
                    else if (o == 'Yes') display = loc.yesLabel ?? o;
                    else if (o == 'No') display = loc.noLabel ?? o;
                    else if (o == 'Alive') display = loc.aliveLabel ?? o;
                    else if (o == 'Dead') display = loc.deadLabel ?? o;
                    else if (o == 'Tamil Nadu') display = loc.tamilNaduLabel ?? o;
                    else if (o == 'Other State') display = loc.otherStateLabel ?? o;
                    else if (o == 'NRI') display = loc.nriLabel ?? o;
                  }
                  return Text(display);
                }
              ),
            ],
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildFileUploadField(String label, String type) {
    XFile? file;
    if (type == 'member_image') file = _memberImage;
    if (type == 'community_cert') file = _communityCert;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label, fontSize: 12),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await fp_pkg.FilePicker.pickFiles(type: fp_pkg.FileType.image, withData: kIsWeb);
            if (result != null) {
              setState(() {
                final xfile = kIsWeb ? XFile.fromData(result.files.single.bytes!, name: result.files.single.name) : XFile(result.files.single.path!);
                if (type == 'member_image') _memberImage = xfile;
                if (type == 'community_cert') _communityCert = xfile;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(10), color: Colors.white),
            child: Row(children: [
              Icon(Icons.upload_file, size: 18, color: mediumBrown),
              const SizedBox(width: 8),
              Expanded(child: Text(file?.name ?? AppLocalizations.of(context)?.chooseFile ?? 'Choose file...', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAgreement() {
    return Row(
      children: [
        Checkbox(value: _isAgreed, onChanged: (v) => setState(() => _isAgreed = v!)),
        Expanded(child: Text(AppLocalizations.of(context)?.confirmDetailsCorrect ?? 'I confirm that the above details are correct.', style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: (_isSaving || !_isAgreed) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: mediumBrown, 
            foregroundColor: Colors.white, 
            padding: const EdgeInsets.symmetric(horizontal: 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          child: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : Text(AppLocalizations.of(context)?.addFamilyMember?.toUpperCase() ?? 'ADD FAMILY MEMBER', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _phoneExists) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }
    
    if (_selectedMarried == 'Yes' && _dobController.text.isNotEmpty) {
      try {
        DateTime? dob;
        final parts = _dobController.text.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            dob = DateTime.parse(_dobController.text);
          } else if (parts[2].length == 4) {
            dob = DateTime.parse("${parts[2]}-${parts[1]}-${parts[0]}");
          }
        }
        if (dob != null) {
          int age = DateTime.now().year - dob.year;
          if (DateTime.now().month < dob.month || (DateTime.now().month == dob.month && DateTime.now().day < dob.day)) {
            age--;
          }
          if (age < 18) {
            showStatusDialog(context, title: 'Validation Error', message: 'Person must be at least 18 years old to be marked as married.', type: DialogType.error);
            return;
          }
        }
      } catch (e) {
        // Ignore parse error
      }
    }

    if (_memberImage == null) {
      showStatusDialog(context, title: 'Missing Documents', message: 'Please upload all required documents.', type: DialogType.warning);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.register));
      
      request.fields['name'] = _nameController.text;
      request.fields['phone'] = _phoneController.text;
      request.fields['whatsapp'] = _whatsappController.text;
      
      final phoneCountry = countries.firstWhere((c) => c.code == _phoneCountryCode, orElse: () => countries.firstWhere((c) => c.code == 'IN'));
      request.fields['mobile_country_code'] = '+${phoneCountry.dialCode}';
      
      final whatsappCountry = countries.firstWhere((c) => c.code == _whatsappCountryCode, orElse: () => countries.firstWhere((c) => c.code == 'IN'));
      request.fields['whatsapp_country_code'] = '+${whatsappCountry.dialCode}';

      request.fields['dob'] = _dobController.text.contains('-') ? _dobController.text.split('-').reversed.join('-') : _dobController.text;
      request.fields['gender'] = _selectedGender ?? '';
      request.fields['blood_group'] = _selectedBloodGroup ?? '';
      request.fields['email'] = _emailController.text;
      request.fields['married'] = _selectedMarried ?? '';
      request.fields['valuvu'] = _valuvuController.text;
      request.fields['thottam'] = _thottamController.text;
      request.fields['education'] = _selectedEducation == 'Others' ? _educationController.text : (_selectedEducation ?? '');
      request.fields['profession'] = _selectedProfession == 'Others' ? _professionController.text : (_selectedProfession ?? '');
      request.fields['relationship'] = _selectedRelationship == 'Other' ? _otherRelationshipController.text : (_selectedRelationship ?? '');
      request.fields['family_id'] = widget.parentData['Familymembershipid'] ?? '';
      
      if (_selectedRelationship == 'Daughter' && _selectedMarried == 'Yes') {
        request.fields['husband_name'] = _husbandNameController.text;
        request.fields['husband_dob'] = _husbandDobController.text;
        request.fields['husband_mobile'] = _husbandMobileController.text;
        request.fields['husband_kulam'] = _selectedHusbandKulam ?? '';
      }
      
      request.fields['state_id'] = '31';
      request.fields['state'] = 'Tamil Nadu';
      request.fields['district'] = _selectedDistrict ?? '';
      request.fields['taluk'] = _selectedTaluk ?? '';
      request.fields['panchayat'] = _selectedPanchayat ?? '';
      request.fields['village'] = _selectedVillage ?? '';
      // Split native street by comma
      String fullStreet = _streetController.text.trim();
      String doorNo = '';
      String streetName = fullStreet;
      if (fullStreet.contains(',')) {
        int commaIndex = fullStreet.indexOf(',');
        doorNo = fullStreet.substring(0, commaIndex).trim();
        streetName = fullStreet.substring(commaIndex + 1).trim();
      }
      request.fields['street'] = streetName;
      request.fields['door_no'] = doorNo;
      request.fields['pincode'] = _pinCodeController.text;

      request.fields['cur_address_type'] = _selectedCurrentAddressType == 'Tamil Nadu' ? 'TamilNadu' : (_selectedCurrentAddressType == 'Other State' ? 'OtherState' : 'NRI');
      request.fields['cur_state'] = _selectedCurrState ?? '';
      request.fields['cur_district'] = _selectedCurrDistrict ?? '';
      request.fields['cur_taluk'] = _selectedCurrTaluk ?? '';
      request.fields['cur_panchayat'] = _selectedCurrPanchayat ?? '';
      request.fields['cur_village'] = _selectedCurrVillage ?? '';
      
      // Split current street by comma
      String fullCurStreet = _currStreetController.text.trim();
      String curDoorNo = '';
      String curStreetName = fullCurStreet;
      if (fullCurStreet.contains(',')) {
        int commaIndex = fullCurStreet.indexOf(',');
        curDoorNo = fullCurStreet.substring(0, commaIndex).trim();
        curStreetName = fullCurStreet.substring(commaIndex + 1).trim();
      }
      request.fields['cur_street'] = curStreetName;
      request.fields['cur_door_no'] = curDoorNo;
      request.fields['cur_pincode'] = _currPinCodeController.text;
      request.fields['cur_state'] = _selectedCurrentAddressType == 'Tamil Nadu' ? 'Tamil Nadu' : (_selectedCurrState ?? '');
      request.fields['nri_country'] = _selectedCountry ?? '';
      request.fields['nri_state'] = _selectedCurrState ?? '';
      request.fields['nri_city'] = _selectedCurrCity ?? '';
      request.fields['nri_zip'] = _currPinCodeController.text;
      request.fields['nri_full_address'] = _currFullAddressController.text;
      request.fields['submitter_role'] = widget.submitterRole.toString();

      Future<http.MultipartFile> toMultipart(XFile file, String field) async {
        if (kIsWeb) return http.MultipartFile.fromBytes(field, await file.readAsBytes(), filename: file.name);
        return http.MultipartFile.fromPath(field, file.path);
      }

      request.files.add(await toMultipart(_memberImage!, 'member_image'));
      if (_communityCert != null) {
        request.files.add(await toMultipart(_communityCert!, 'community_cert'));
      }

      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        if (mounted) {
           String successMsg = widget.submitterRole != 3 
              ? 'Family member added and verified successfully.' 
              : 'Family member added successfully and sent for approval.';
           showStatusDialog(context, title: 'Success', message: successMsg, type: DialogType.success).then((_) {
             if (mounted) Navigator.pop(context, true);
           });
        }
      } else {
         String errorMsg = 'Failed to add member';
         try {
           final errorData = jsonDecode(response.body);
           errorMsg = errorData['detail'] ?? errorMsg;
         } catch (_) {}
         
         if (errorMsg.contains('Phone number')) {
           setState(() => _phoneExists = true);
           _phoneFieldKey.currentState?.validate();
         } else {
           if (mounted) showStatusDialog(context, title: 'Error', message: errorMsg, type: DialogType.error);
         }
      }
    } catch (e) {
      if (mounted) {
        // Remove 'Exception: ' prefix if present
        String msg = e.toString().replaceFirst('Exception: ', '');
        showStatusDialog(context, title: 'Error', message: msg, type: DialogType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  Widget _buildLabelText(String label, {double fontSize = 14}) {
    bool hasAsterisk = label.contains('*');
    String baseLabel = label.replaceAll('*', '').trim();
    String translatedLabel = baseLabel;
    
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      if (baseLabel == 'Relationship' || baseLabel == 'Husband Relationship') translatedLabel = loc.relationshipHeader ?? baseLabel;
      else if (baseLabel == 'Name' || baseLabel == 'Husband Name') translatedLabel = loc.nameHeader ?? baseLabel;
      else if (baseLabel == 'Phone Number' || baseLabel == 'Husband Phone') translatedLabel = loc.phoneNumberLabel ?? baseLabel;
      else if (baseLabel == 'Date Of Birth' || baseLabel == 'Husband Date Of Birth') translatedLabel = loc.dateOfBirthLabel ?? baseLabel;
      else if (baseLabel == 'Gender') translatedLabel = loc.genderHeader ?? baseLabel;
      else if (baseLabel == 'Blood Group') translatedLabel = loc.bloodGroupLabel ?? baseLabel;
      else if (baseLabel == 'Email') translatedLabel = loc.emailLabel ?? baseLabel;
      else if (baseLabel == 'WhatsApp Number') translatedLabel = loc.whatsappNumberLabel ?? baseLabel;
      else if (baseLabel == 'Married') translatedLabel = loc.marriedStatusLabel ?? baseLabel;
      else if (baseLabel == 'Alive Status') translatedLabel = loc.aliveStatusLabel ?? baseLabel;
      else if (baseLabel == 'Valuvu') translatedLabel = loc.valuvuLabel ?? baseLabel;
      else if (baseLabel == 'Thottam') translatedLabel = loc.thottamLabel ?? baseLabel;
      else if (baseLabel == 'Kulam' || baseLabel == 'Husband Kulam') translatedLabel = loc.kulamLabel ?? baseLabel;
      else if (baseLabel == 'Education') translatedLabel = loc.educationLabel ?? baseLabel;
      else if (baseLabel == 'Profession') translatedLabel = loc.professionLabel ?? baseLabel;
      else if (baseLabel == 'District') translatedLabel = loc.districtHeader ?? baseLabel;
      else if (baseLabel == 'Taluk') translatedLabel = loc.talukHeader ?? baseLabel;
      else if (baseLabel == 'Panchayat') translatedLabel = loc.panchayatHeader ?? baseLabel;
      else if (baseLabel == 'Village') translatedLabel = loc.villageUpperHeader ?? baseLabel;
      else if (baseLabel == 'Door No & Street Name') translatedLabel = loc.streetNameLabel ?? baseLabel;
      else if (baseLabel == 'Pin Code' || baseLabel == 'Zip / Postal Code' || baseLabel == 'Zip/Postal Code') translatedLabel = loc.pincodeLabel ?? baseLabel;
      else if (baseLabel == 'Current Address Type') translatedLabel = loc.currentAddressTypeLabel ?? baseLabel;
      else if (baseLabel == 'State') translatedLabel = loc.stateLabel ?? baseLabel;
      else if (baseLabel == 'Country') translatedLabel = loc.countryLabel ?? baseLabel;
      else if (baseLabel == 'City') translatedLabel = loc.cityVillageLabel ?? baseLabel;
      else if (baseLabel == 'Full Address') translatedLabel = loc.fullAddressLabel ?? baseLabel;
      else if (baseLabel == 'Passport size photo' || baseLabel == 'Passport Photo') translatedLabel = loc.passportPhotoLabel ?? baseLabel;
      else if (baseLabel == 'Community Certificate') translatedLabel = loc.communityCertificateLabel ?? baseLabel;
    }

    if (hasAsterisk) {
      return Text.rich(
        TextSpan(
          text: '$translatedLabel ',
          children: const [
            TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black87),
      );
    }
    return Text(translatedLabel, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black87));
  }
}

