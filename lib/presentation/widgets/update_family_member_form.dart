import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show FilteringTextInputFormatter, rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart' as fp_pkg;
import 'package:cross_file/cross_file.dart';
import 'custom_dropdown_search.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'custom_phone_field.dart';
import 'custom_dialog.dart';
import '../../utils/api_config.dart';
import '../../services/geo_data_service.dart';
import 'add_family_member_form.dart';

class UpdateFamilyMemberForm extends StatefulWidget {
  final Map<String, dynamic> memberData;
  final int submitterRole;
  final VoidCallback onUpdate;

  const UpdateFamilyMemberForm({super.key, required this.memberData, required this.submitterRole, required this.onUpdate});

  @override
  State<UpdateFamilyMemberForm> createState() => _UpdateFamilyMemberFormState();
}

class _UpdateFamilyMemberFormState extends State<UpdateFamilyMemberForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  
  // Design Colors
  static const Color primaryBrown = const Color(0xFF2D1B18);
  static const Color mediumBrown = const Color(0xFF3E2723);
  static const Color accentGold = const Color(0xFFC5A028);
  static const Color glassWhite = Color(0xA6FFFFFF);
  static const Color borderColor = const Color(0xFFE0E0E0);

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _dobController = TextEditingController();
  final _valuvuController = TextEditingController();
  final _thottamController = TextEditingController();
  final _professionController = TextEditingController();
  
  // Husband Details
  final _husbandNameController = TextEditingController();
  final _husbandDobController = TextEditingController();
  final _husbandMobileController = TextEditingController();
  
  // Address Controllers
  final _streetController = TextEditingController();
  final _pinCodeController = TextEditingController();
  
  final _currStreetController = TextEditingController();
  final _currPinCodeController = TextEditingController();
  final _currFullAddressController = TextEditingController();

  // State Variables
  bool _phoneExists = false;
  String _initialPhone = '';
  final _phoneFieldKey = GlobalKey<FormFieldState>();
  
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
  String _selectedAliveStatus = 'Alive';
  String? _selectedHusbandKulam;

  XFile? _memberImage;
  XFile? _communityCert;

  bool _isAgreed = false;
  bool _whatsappSameAsPhone = false;

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
  final List<String> _relationships = ['Head','Grand Father','Grand Mother','Father','Mother','Husband','Wife','Son','Daughter','Son-in-law','Daughter-in-law','Brother','Sister','Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _educations = ['SSLC', 'HSC', 'Diploma', 'ITI', 'B.A', 'B.Sc', 'B.Com', 'BBA', 'BCA', 'B.E', 'B.Tech', 'MBBS', 'BDS', 'B.Pharm', 'B.Ed', 'LLB', 'B.Arch', 'M.A', 'M.Sc', 'M.Com', 'MBA', 'MCA', 'M.E', 'M.Tech', 'MD', 'MS', 'MDS', 'M.Pharm', 'M.Ed', 'LLM', 'M.Phil', 'Ph.D', 'Others'];
  final List<String> _professions = ['Doctor', 'Lawyer', 'Police', 'Teacher / Lecturer', 'Engineer', 'Government Employee', 'Private Employee', 'Student', 'Farmer – Agriculture', 'Textile Mill Worker (Spinning / Weaving)', 'Garment Factory Worker', 'Tailor / Apparel Stitching', 'Garment Pattern Master / Designer', 'Textile Machinery Technician / Mechanic', 'Textile Machinery Sales & Service', 'Powerloom / Auto‑Loom Operator', 'Knitting Machine Operator', 'Truck / Lorry Driver', 'Truck / Lorry Owner‑cum‑Driver', 'Logistics / Transport Staff', 'Fleet Manager', 'Dairy Farmer', 'Poultry Farmer', 'Goat / Sheep Rearing', 'Pump / Motor Technician', 'Pump / Motor Manufacturing Worker', 'Motor Rewinding Technician', 'Machinist / Turner', 'Welder / Fabricator', 'Steel / Aluminium Foundry Worker', 'Mixer‑Grinder Assembly / Service Technician', 'Plastic / Net / Packaging Unit Worker', 'Windmill Maintenance Technician', 'Electrical Line / Maintenance Technician', 'Grocery Shop Staff', 'Medical Shop / Pharmacy Staff', 'Retail Shop / Sales Staff', 'Office Admin / Computer Operator', 'Accountant / Finance Staff', 'Bank / NBFC Staff', 'Hospital Nurse / Lab Tech / Pharmacist', 'Medical Representative', 'IT / Software Employee', 'Home Maker', 'Retired', 'Others'];
  final List<String> _kulams = ['Poondurai Kaadai', 'Aanthuvan Kulam', 'Azhagu Kulam', 'Aathe Kulam', 'Aanthai Kulam', 'Aadar Kulam', 'Aavan Kulam', 'Eenjan Kulam', 'Ozukkar Kulam', 'Oothaalar Kulam', 'Kannakkan Kulam', 'Kannan Kulam', 'Kannaanthai Kulam', 'Kaadai Kulam', 'Kaari Kulam', 'Keeran Kulam', 'Kuzhlaayan Kulam', 'Koorai Kulam', 'Koovendhar Kulam', 'Saathanthai Kulam', 'Sellan Kulam', 'Semban Kulam', 'Sengkannan Kulam', 'Sembuthan Kulam', 'Senkunnier Kulam', 'Sevvaayar Kulam', 'Cheran Kulam', 'Chedan Kulam', 'Dananjayan Kulam', 'Thazhinji Kulam', 'Thooran Kulam', 'Devendran Kulam', 'Thoodar Kulam', 'Neerunniyar Kulam', 'Pavazhalar Kulam', 'Panayan Kulam', 'Pathuman Kulam', 'Payiran Kulam', 'Panagkaadar Kulam', 'Pathariar Kulam', 'Pandiyan Kulam', 'Pillar Kulam', 'Poosan Kulam', 'Poochanthai Kulam', 'Periyan Kulam', 'Perunkudiyaan Kulam', 'Porulaanthai Kulam', 'Ponnar Kulam', 'Maniyan Kulam', 'Mayilar Kulam', 'Maadar Kulam', 'Mutthan Kulam', 'Muzhukathan Kulam', 'Medhi Kulam', 'Vannakkan Kulam', 'Villiyar Kulam', 'Vilayan Kulam', 'Vizhiyar Kulam', 'Venduvan Kulam', 'Vennag Kulam', 'Vellampar Kulam', 'Others'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    _initialPhone = widget.memberData['Phonenumber']?.toString().trim() ?? '';
    
    _phoneController.addListener(() {
      final currentPhone = _phoneController.text.trim();
      
      if (currentPhone.length == 10 && currentPhone != _initialPhone) {
        _checkExistence(currentPhone);
      } else {
        if (_phoneExists) setState(() => _phoneExists = false);
      }
    });
  }

  Future<void> _checkExistence(String phone) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.checkExistence),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'exclude_id': widget.memberData['Id'],
          'family_id': widget.memberData['Existfamilyid'] ?? widget.memberData['Familymembershipid'],
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

  void _loadInitialData() async {
    final d = widget.memberData;
    _nameController.text = d['Name'] ?? '';
    _phoneController.text = d['Phonenumber']?.toString() ?? '';
    _emailController.text = d['Email'] ?? '';
    _whatsappController.text = d['Whatsappnumber']?.toString() ?? '';
    _dobController.text = d['Dob'] ?? '';
    _valuvuController.text = d['Valuvu'] ?? '';
    _thottamController.text = d['Thottam'] ?? '';
    _husbandNameController.text = d['husband_name'] ?? '';
    _husbandDobController.text = d['husband_dob'] ?? '';
    _husbandMobileController.text = d['husband_mobile'] ?? '';
    final hk = (d['husband_kulam']?.toString() ?? '').trim();
    _selectedHusbandKulam = _kulams.contains(hk) ? hk : null;
    _selectedAliveStatus = (d['is_dead'] == 0 || d['is_dead'] == '0' || d['is_dead'] == null) ? 'Alive' : 'Dead';
    
    final rawRole = (d['MemberRole']?.toString() ?? '').trim();
    // Normalize common variations
    String normalizedRole = rawRole;
    if (rawRole.toLowerCase() == 'grandfather') normalizedRole = 'Grand Father';
    if (rawRole.toLowerCase() == 'grandmother') normalizedRole = 'Grand Mother';
    
    // Case-insensitive search in _relationships
    String? found = _relationships.cast<String?>().firstWhere(
      (r) => r!.toLowerCase() == normalizedRole.toLowerCase(),
      orElse: () => null,
    );
    
    _selectedRelationship = found ?? (_relationships.contains(normalizedRole) ? normalizedRole : null);
    _selectedGender = d['Gender'];
    _selectedBloodGroup = d['Bloodgroup'];
    _selectedMarried = d['Married'];
    _selectedEducation = d['Education'];
    _selectedProfession = d['Profession'];
    
    // Native Address
    _selectedDistrict = (d['District']?.toString().trim().isEmpty ?? true) ? null : d['District'];
    _selectedTaluk = (d['Taluk']?.toString().trim().isEmpty ?? true) ? null : d['Taluk'];
    _selectedPanchayat = (d['Panchayat']?.toString().trim().isEmpty ?? true) ? null : d['Panchayat'];
    _selectedVillage = (d['Village']?.toString().trim().isEmpty ?? true) ? null : d['Village'];
    final street = d['Street'] ?? '';
    final doorNo = d['Doornumber']?.toString() ?? '';
    _streetController.text = doorNo.isNotEmpty ? "$doorNo, $street" : street;
    _pinCodeController.text = d['Pincode']?.toString() ?? '';
    
    // Current Address
    _selectedCurrentAddressType = d['Curaddresstype'] == 'TamilNadu' ? 'Tamil Nadu' : (d['Curaddresstype'] == 'OtherState' ? 'Other State' : (d['Curaddresstype'] == 'NRI' ? 'NRI' : null));
    _selectedCurrState = (d['Curstate']?.toString().trim().isEmpty ?? true) ? null : d['Curstate'];
    _selectedCurrDistrict = (d['Curdistrict']?.toString().trim().isEmpty ?? true) ? null : d['Curdistrict'];
    _selectedCurrTaluk = (d['Curtaluk']?.toString().trim().isEmpty ?? true) ? null : d['Curtaluk'];
    _selectedCurrPanchayat = (d['Curpanchayat']?.toString().trim().isEmpty ?? true) ? null : d['Curpanchayat'];
    _selectedCurrVillage = (d['Curvillage']?.toString().trim().isEmpty ?? true) ? null : d['Curvillage'];
    final curStreet = d['Curstreet'] ?? '';
    final curDoorNo = d['Curdoorno']?.toString() ?? '';
    _currStreetController.text = curDoorNo.isNotEmpty ? "$curDoorNo, $curStreet" : curStreet;
    _currPinCodeController.text = d['Curpincode']?.toString() ?? '';
    _selectedCountry = d['Curnricountry'];
    _selectedCurrCity = d['Curnricity'];
    _currFullAddressController.text = d['Curnrifulladdress'] ?? '';

    await _loadGeoData();
    await _fetchDistricts();
    if (_selectedDistrict != null) await _fetchTaluks(_selectedDistrict!);
    if (_selectedTaluk != null) await _fetchPanchayats(_selectedTaluk!);
    if (_selectedPanchayat != null) await _fetchVillages(_selectedPanchayat!);
    
    if (_selectedCurrentAddressType == 'Tamil Nadu') {
      await _fetchCurrDistricts();
      if (_selectedCurrDistrict != null) await _fetchCurrTaluks(_selectedCurrDistrict!);
      if (_selectedCurrTaluk != null) await _fetchCurrPanchayats(_selectedCurrTaluk!);
      if (_selectedCurrPanchayat != null) await _fetchCurrVillages(_selectedCurrPanchayat!);
    } else if (_selectedCurrentAddressType == 'Other State') {
      _updateStates('India');
      if (_selectedCurrState != null) _updateCities('India', _selectedCurrState!);
    } else if (_selectedCurrentAddressType == 'NRI') {
      if (_selectedCountry != null) {
        _updateStates(_selectedCountry!);
        if (_selectedCurrState != null) _updateCities(_selectedCountry!, _selectedCurrState!);
      }
    }
    
    setState(() {});

    final controllers = [
      _nameController, _phoneController, _emailController, _whatsappController,
      _dobController, _valuvuController, _thottamController, _professionController,
      _husbandNameController, _husbandDobController, _husbandMobileController,
      _streetController, _pinCodeController, _currStreetController, _currPinCodeController,
      _currFullAddressController
    ];
    for (var c in controllers) {
      c.addListener(_markChanged);
    }
  }

  bool _hasChanges = false;
  void _markChanged() {
    if (mounted && !_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _loadGeoData() async {
    if (!_geoService.isLoaded) {
      await _geoService.loadData();
    }
    setState(() {
      _countryNames = _geoService.countryNames;
    });
  }

  void _checkMarriedAgeValidation(String? marriedVal) async {
    bool wasNotMarried = _selectedMarried != 'Yes';
    
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

    if (marriedVal == 'Yes' && wasNotMarried) {
      // Auto open Add Spouse dialog
      bool isMale = _selectedGender == 'Male';
      String preSelectedRole = isMale ? 'Wife' : 'Husband';
      
      final familyId = widget.memberData['Existfamilyid'] ?? widget.memberData['Familymembershipid'];
      
      // Temporarily mark the parent data as married so AddFamilyMemberForm allows 'Wife' or 'Husband'
      final modifiedParentData = Map<String, dynamic>.from(widget.memberData);
      modifiedParentData['Married'] = 'Yes';
      
      final result = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AddFamilyMemberForm(
          parentId: familyId,
          parentData: modifiedParentData, // Pass modified context for the spouse
          submitterRole: widget.submitterRole,
          preSelectedRelationship: preSelectedRole,
        ),
      );
      
      if (result != true) {
        setState(() => _selectedMarried = 'No');
      }
    }
  }

  void _updateStates(String countryName) {
    setState(() {
      _stateNames = _geoService.getStates(countryName);
    });
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
        if (mounted) setState(() => _districts = List<String>.from(d['data']));
      }
    } catch (_) {}
  }

  Future<void> _fetchTaluks(String district) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        if (mounted) setState(() => _taluks = List<String>.from(d['data']));
      }
    } catch (_) {}
  }

  Future<void> _fetchPanchayats(String taluk) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        if (mounted) setState(() => _panchayats = List<String>.from(d['data']));
      }
    } catch (_) {}
  }

  Future<void> _fetchVillages(String panchayat) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        if (mounted) setState(() => _villages = List<String>.from(d['data']));
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrDistricts() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        if (mounted) setState(() => _currDistricts = List<String>.from(d['data']));
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrTaluks(String district) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        if (mounted) setState(() => _currTaluks = List<String>.from(d['data']));
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrPanchayats(String taluk) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        if (mounted) setState(() => _currPanchayats = List<String>.from(d['data']));
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrVillages(String panchayat) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        if (mounted) setState(() => _currVillages = List<String>.from(d['data']));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 24),
      child: Container(
        width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 1000,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(Icons.person_outline, 'Update Family Member'),
                      const SizedBox(height: 16),
                      _buildResponsiveRow(isMobile, [
                        _buildDropdownField('Relationship *', _relationships, _selectedRelationship, (v) => setState(() => _selectedRelationship = v)),
                        _buildInputField('Name *', _nameController, maxLength: 254),
                        _buildIntlPhoneField('Phone Number *', _phoneController, 
                          fieldKey: _phoneFieldKey,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (_phoneExists) return 'Phone number already registered';
                            return null;
                          }
                        ),
                      ]),
                      _buildResponsiveRow(isMobile, [
                        _buildDatePickerField('Date Of Birth *', _dobController),
                        _buildGenderSelector(),
                        _buildDropdownField('Blood Group *', _bloodGroups, _selectedBloodGroup, (v) => setState(() => _selectedBloodGroup = v)),
                      ]),
                      _buildResponsiveRow(isMobile, [
                        _buildInputField('Email', _emailController, maxLength: 254),
                        _buildWhatsAppField(),
                        _buildRadioField('Married *', ['Yes', 'No'], _selectedMarried, _checkMarriedAgeValidation),
                      ]),
                      _buildResponsiveRow(isMobile, [
                        _buildRadioField('Alive Status', ['Alive', 'Dead'], _selectedAliveStatus, (v) => setState(() => _selectedAliveStatus = v!)),
                        _buildInputField('Valuvu', _valuvuController, maxLength: 254),
                        _buildInputField('Thottam', _thottamController, maxLength: 254),
                      ]),
                      _buildResponsiveRow(isMobile, [
                        _buildInputField('Kulam *', TextEditingController(text: 'Poondurai Kaadai'), readOnly: true),
                        if (!isMobile) const Spacer(),
                        if (!isMobile) const Spacer(),
                      ]),
                      if (_selectedRelationship == 'Daughter' && _selectedMarried == 'Yes') ...[
                        const SizedBox(height: 16),
                        _buildResponsiveRow(isMobile, [
                          _buildInputField('Husband Name *', _husbandNameController, maxLength: 254),
                          _buildDatePickerField('Husband Date Of Birth *', _husbandDobController),
                        ]),
                        _buildResponsiveRow(isMobile, [
                          _buildIntlPhoneField('Husband Phone *', _husbandMobileController, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                          _buildDropdownField('Husband Kulam *', _kulams, _selectedHusbandKulam, (v) => setState(() => _selectedHusbandKulam = v)),
                        ]),
                      ],
                      const SizedBox(height: 32),
                      _buildSectionTitle(Icons.work_outline, 'Education & Career'),
                      const SizedBox(height: 16),
                      _buildResponsiveRow(isMobile, [
                        _buildDropdownField('Education *', _educations, _selectedEducation, (v) => setState(() => _selectedEducation = v)),
                        _buildDropdownField('Profession *', _professions, _selectedProfession, (v) => setState(() => _selectedProfession = v)),
                        if (!isMobile) const Spacer(),
                      ]),
                      const SizedBox(height: 32),
                      _buildSectionTitle(Icons.location_on_outlined, 'Native Address'),
                      const SizedBox(height: 16),
                      _buildResponsiveRow(isMobile, [
                        _buildDropdownField('District *', _districts, _selectedDistrict, (v) { setState(() { _selectedDistrict = v; _selectedTaluk = null; }); if (v != null) _fetchTaluks(v); }),
                        _buildDropdownField('Taluk *', _taluks, _selectedTaluk, (v) { setState(() { _selectedTaluk = v; _selectedPanchayat = null; }); if (v != null) _fetchPanchayats(v); }),
                        _buildDropdownField('Panchayat *', _panchayats, _selectedPanchayat, (v) { setState(() { _selectedPanchayat = v; _selectedVillage = null; }); if (v != null) _fetchVillages(v); }),
                      ]),
                      _buildResponsiveRow(isMobile, [
                        _buildDropdownField('Village Name *', _villages, _selectedVillage, (v) => setState(() => _selectedVillage = v)),
                        _buildInputField('Door No & Street Name *', _streetController, maxLength: 254),
                        _buildInputField('Pin Code *', _pinCodeController, keyboardType: TextInputType.number, maxLength: 6),
                      ]),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: _buildSectionTitle(Icons.home_outlined, 'Current Address')),
                          if (_selectedCurrentAddressType == 'Tamil Nadu')
                            TextButton.icon(
                              onPressed: _copyNativeToCurrent,
                              icon: const Icon(Icons.copy_all, size: 16, color: accentGold),
                              label: const Text('Same as Native', style: TextStyle(color: accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildRadioField('Current Address Type *', ['Tamil Nadu', 'Other State', 'NRI'], _selectedCurrentAddressType, (v) {
                        setState(() {
                          _selectedCurrentAddressType = v;
                          if (v == 'Tamil Nadu') _fetchCurrDistricts();
                          else if (v == 'Other State') _updateStates('India');
                        });
                      }),
                      const SizedBox(height: 16),
                      if (_selectedCurrentAddressType == 'Tamil Nadu') ...[
                        _buildResponsiveRow(isMobile, [
                          _buildDropdownField('District *', _currDistricts, _selectedCurrDistrict, (v) { setState(() { _selectedCurrDistrict = v; _selectedCurrTaluk = null; }); if (v != null) _fetchCurrTaluks(v); }),
                          _buildDropdownField('Taluk *', _currTaluks, _selectedCurrTaluk, (v) { setState(() { _selectedCurrTaluk = v; _selectedCurrPanchayat = null; }); if (v != null) _fetchCurrPanchayats(v); }),
                          _buildDropdownField('Panchayat *', _currPanchayats, _selectedCurrPanchayat, (v) { setState(() { _selectedCurrPanchayat = v; _selectedCurrVillage = null; }); if (v != null) _fetchCurrVillages(v); }),
                        ]),
                        _buildResponsiveRow(isMobile, [
                          _buildDropdownField('Village Name *', _currVillages, _selectedCurrVillage, (v) => setState(() => _selectedCurrVillage = v)),
                          _buildInputField('Door No & Street Name *', _currStreetController, maxLength: 254),
                          _buildInputField('Pin Code *', _currPinCodeController, keyboardType: TextInputType.number, maxLength: 6),
                        ]),
                      ] else if (_selectedCurrentAddressType == 'Other State') ...[
                        _buildResponsiveRow(isMobile, [
                          _buildDropdownField('State *', _stateNames, _selectedCurrState, (v) { setState(() => _selectedCurrState = v); if (v != null) _updateCities('India', v); }),
                          _buildDropdownField('City *', _cityNames, _selectedCurrCity, (v) => setState(() => _selectedCurrCity = v)),
                          _buildInputField('Zip/Postal Code *', _currPinCodeController),
                        ]),
                        _buildTextArea('Full Address *', _currFullAddressController),
                      ] else if (_selectedCurrentAddressType == 'NRI') ...[
                        _buildResponsiveRow(isMobile, [
                          _buildDropdownField('Country *', _countryNames, _selectedCountry, (v) { setState(() => _selectedCountry = v); if (v != null) _updateStates(v); }),
                          _buildDropdownField('State *', _stateNames, _selectedCurrState, (v) { setState(() => _selectedCurrState = v); if (v != null && _selectedCountry != null) _updateCities(_selectedCountry!, v); }),
                          _buildDropdownField('City *', _cityNames, _selectedCurrCity, (v) => setState(() => _selectedCurrCity = v)),
                        ]),
                        _buildResponsiveRow(isMobile, [
                          _buildInputField('Zip/Postal Code *', _currPinCodeController),
                          if (!isMobile) const Spacer(), if (!isMobile) const Spacer(),
                        ]),
                        _buildTextArea('Full Address *', _currFullAddressController),
                      ],
                      const SizedBox(height: 32),
                      _buildSectionTitle(Icons.description_outlined, 'Documents'),
                      const SizedBox(height: 16),
                      _buildResponsiveRow(isMobile, [
                        _buildFileUploadField('Passport size photo *', 'member_image'),
                        _buildFileUploadField('Community Certificate', 'community_cert'),
                        if (!isMobile) const Spacer(), if (!isMobile) const Spacer(),
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
    );
  }

  void _copyNativeToCurrent() {
    setState(() {
      _selectedCurrDistrict = _selectedDistrict;
      _selectedCurrTaluk = _selectedTaluk;
      _selectedCurrPanchayat = _selectedPanchayat;
      _selectedCurrVillage = _selectedVillage;
      _currStreetController.text = _streetController.text;
      _currPinCodeController.text = _pinCodeController.text;
      
      if (_selectedCurrDistrict != null) _fetchCurrTaluks(_selectedCurrDistrict!);
      if (_selectedCurrTaluk != null) _fetchCurrPanchayats(_selectedCurrTaluk!);
      if (_selectedCurrPanchayat != null) _fetchCurrVillages(_selectedCurrPanchayat!);
    });
  }

  Widget _buildHeader() {
    final memberId = widget.memberData['Familymembershipid'] ?? '';
    final titleText = memberId.isNotEmpty ? 'Update Family Member  ($memberId)' : 'Update Family Member';
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Expanded(child: Text(titleText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBrown))),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
      ]),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: accentGold, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Icon(icon, color: primaryBrown, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBrown))),
    ]);
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) return Column(children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList());
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: c))).toList()),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {TextInputType? keyboardType, bool readOnly = false, int? maxLength, Key? fieldKey, String? Function(String?)? validator, AutovalidateMode? autovalidateMode}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    ]);
  }

  Widget _buildIntlPhoneField(String label, TextEditingController controller, {Key? fieldKey, String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label, fontSize: 14),
      const SizedBox(height: 8),
      CustomPhoneField(
        fieldKey: fieldKey,
        label: '',
        controller: controller,
        validator: (v) => validator?.call(controller.text),
      ),
    ]);
  }

  Widget _buildWhatsAppField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildLabelText('WhatsApp', fontSize: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _whatsappSameAsPhone,
                    activeColor: mediumBrown,
                    onChanged: (v) => setState(() {
                      _whatsappSameAsPhone = v!;
                      if (v) {
                        _whatsappController.text = _phoneController.text;
                        _markChanged();
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Same as Phone', style: TextStyle(fontSize: 11, color: Colors.black87)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        CustomPhoneField(
          label: '',
          controller: _whatsappController,
          validator: (v) => null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String? value, ValueChanged<String?> onChanged) {
    String? matchedValue = value;
    if (value != null && value.isNotEmpty) {
      final valTrimmed = value.trim().toLowerCase();
      try {
        matchedValue = options.firstWhere((item) => item.trim().toLowerCase() == valTrimmed);
      } catch (_) {
        matchedValue = value;
      }
    }
    return CustomDropdownSearch(
      label: label,
      dropdownItems: options,
      value: matchedValue,
      onChanged: (v) {
        _markChanged();
        onChanged(v);
      },
      requiredMark: label.contains('*'),
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label, fontSize: 14),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          DateTime initial = DateTime.now();
          if (controller.text.isNotEmpty) {
            try {
              initial = DateTime.parse(controller.text);
            } catch (_) {
              // If format is different, fallback to today
            }
          }
          final date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(1900), lastDate: DateTime.now());
          if (date != null) {
            setState(() {
              controller.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              _markChanged();
            });
            if (controller == _dobController && _selectedMarried == 'Yes') _checkMarriedAgeValidation('Yes');
          }
        },
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        decoration: InputDecoration(
          fillColor: Colors.white, filled: true,
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
        ),
      ),
    ]);
  }

  Widget _buildGenderSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText('Gender *', fontSize: 14),
      Wrap(children: [
        Radio<String>(value: 'Male', groupValue: _selectedGender, onChanged: (v) { _markChanged(); setState(() => _selectedGender = v); }),
        const Text('Male'),
        Radio<String>(value: 'Female', groupValue: _selectedGender, onChanged: (v) { _markChanged(); setState(() => _selectedGender = v); }),
        const Text('Female'),
      ]),
    ]);
  }

  Widget _buildRadioField(String label, List<String> options, String? value, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label, fontSize: 14),
      Wrap(children: options.map((o) => Row(mainAxisSize: MainAxisSize.min, children: [
        Radio<String>(value: o, groupValue: value, onChanged: (v) {
          _markChanged();
          onChanged(v);
        }),
        Text(o),
        const SizedBox(width: 8),
      ])).toList()),
    ]);
  }

  Widget _buildTextArea(String label, TextEditingController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label, fontSize: 14),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        maxLines: 3,
        validator: (v) => (label.contains('*') && (v == null || v.isEmpty)) ? 'Required' : null,
        decoration: InputDecoration(
          fillColor: Colors.white, filled: true,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
        ),
      ),
    ]);
  }

  Widget _buildFileUploadField(String label, String type) {
    XFile? file;
    String? existingUrl;
    if (type == 'member_image') {
      file = _memberImage;
      existingUrl = widget.memberData['member_image'];
    }
    if (type == 'community_cert') {
      file = _communityCert;
      existingUrl = widget.memberData['community_cert'];
    }

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
                _markChanged();
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
              Expanded(
                child: Text(
                  file?.name ?? (existingUrl != null && existingUrl.isNotEmpty ? 'Existing file: ${existingUrl.split('/').last}' : 'Choose file...'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis
                )
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAgreement() {
    return Row(children: [
      Checkbox(value: _isAgreed, onChanged: (v) => setState(() => _isAgreed = v!)),
      Expanded(child: Text('I confirm that the updated details are correct.', style: TextStyle(fontSize: 13, color: _hasChanges ? Colors.black : Colors.grey))),
    ]);
  }

  Widget _buildSubmitButton() {
    return Center(
      child: SizedBox(
        width: 250, height: 50,
        child: ElevatedButton(
          onPressed: (_isSaving || !_isAgreed || !_hasChanges) ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: mediumBrown, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('UPDATE FAMILY MEMBER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _phoneExists) return;
    
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
    
    setState(() => _isSaving = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.updateMember));
      
      request.fields['user_id'] = widget.memberData['Id'].toString();
      request.fields['role'] = widget.submitterRole.toString();
      request.fields['name'] = _nameController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['whatsapp'] = _whatsappController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['dob'] = _dobController.text.trim();
      request.fields['gender'] = _selectedGender ?? '';
      request.fields['blood_group'] = _selectedBloodGroup ?? '';
      request.fields['married'] = _selectedMarried ?? '';
      request.fields['valuvu'] = _valuvuController.text.trim();
      request.fields['thottam'] = _thottamController.text.trim();
      request.fields['kulam'] = 'Poondurai Kaadai';
      request.fields['exist_family_id'] = widget.memberData['Existfamilyid']?.toString() ?? '';
      request.fields['education'] = _selectedEducation ?? '';
      request.fields['profession'] = _selectedProfession ?? '';
      request.fields['relationship'] = _selectedRelationship ?? '';
      
      if (_selectedRelationship == 'Daughter' && _selectedMarried == 'Yes') {
        request.fields['husband_name'] = _husbandNameController.text;
        request.fields['husband_dob'] = _husbandDobController.text;
        request.fields['husband_mobile'] = _husbandMobileController.text;
        request.fields['husband_kulam'] = _selectedHusbandKulam ?? '';
      }
      
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
      request.fields['pincode'] = _pinCodeController.text.trim();

      request.fields['cur_address_type'] = _selectedCurrentAddressType == 'Tamil Nadu' ? 'TamilNadu' : (_selectedCurrentAddressType == 'Other State' ? 'OtherState' : 'NRI');
      bool isNRI = _selectedCurrentAddressType == 'NRI';
      request.fields['cur_state'] = isNRI ? '' : (_selectedCurrState ?? '');
      request.fields['cur_district'] = isNRI ? '' : (_selectedCurrDistrict ?? '');
      request.fields['cur_taluk'] = isNRI ? '' : (_selectedCurrTaluk ?? '');
      request.fields['cur_panchayat'] = isNRI ? '' : (_selectedCurrPanchayat ?? '');
      request.fields['cur_village'] = isNRI ? '' : (_selectedCurrVillage ?? '');
      
      // Split current street by comma
      String fullCurStreet = _currStreetController.text.trim();
      String curDoorNo = '';
      String curStreetName = fullCurStreet;
      if (fullCurStreet.contains(',')) {
        int commaIndex = fullCurStreet.indexOf(',');
        curDoorNo = fullCurStreet.substring(0, commaIndex).trim();
        curStreetName = fullCurStreet.substring(commaIndex + 1).trim();
      }
      request.fields['cur_street'] = isNRI ? '' : curStreetName;
      request.fields['cur_door_no'] = isNRI ? '' : curDoorNo;
      request.fields['cur_pincode'] = isNRI ? '' : _currPinCodeController.text.trim();
      
      request.fields['nri_country'] = isNRI ? (_selectedCountry ?? '') : '';
      request.fields['nri_state'] = isNRI ? (_selectedCurrState ?? '') : '';
      request.fields['nri_city'] = isNRI ? (_selectedCurrCity ?? '') : '';
      request.fields['nri_zip'] = isNRI ? _currPinCodeController.text.trim() : '';
      request.fields['nri_full_address'] = isNRI ? _currFullAddressController.text.trim() : '';

      // Files
      Future<void> addFile(String field, XFile? file) async {
        if (file == null) return;
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(field, await file.readAsBytes(), filename: file.name));
        } else {
          request.files.add(await http.MultipartFile.fromPath(field, file.path));
        }
      }

      await addFile('member_image', _memberImage);
      await addFile('community_cert', _communityCert);

      final res = await http.Response.fromStream(await request.send());
      
      if (!mounted) return;

      if (res.statusCode == 200) {
        String successMsg = widget.submitterRole != 3 
            ? 'Details updated and verified successfully.' 
            : 'Details updated successfully and sent for approval.';
        showStatusDialog(context, title: 'Success', message: successMsg, type: DialogType.success).then((_) {
          widget.onUpdate();
          Navigator.pop(context);
        });
      } else {
        String errorMsg = 'Update failed';
        try {
          final errorData = jsonDecode(res.body);
          errorMsg = errorData['detail'] ?? 'Update failed';
        } catch (_) {}

        if (errorMsg.contains('Phone number')) {
          setState(() {
            _phoneExists = true;
          });
          _phoneFieldKey.currentState?.validate();
        }
        if (mounted) showStatusDialog(context, title: 'Error', message: errorMsg, type: DialogType.error);
      }
    } catch (e) {
      if (mounted) showStatusDialog(context, title: 'Error', message: e.toString(), type: DialogType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  Widget _buildLabelText(String label, {double fontSize = 14}) {
    if (label.contains('*')) {
      final parts = label.split('*');
      return Text.rich(
        TextSpan(
          text: parts[0],
          children: [
            const TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            if (parts.length > 1) TextSpan(text: parts.sublist(1).join('*')),
          ],
        ),
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black87),
      );
    }
    return Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.black87));
  }
}
