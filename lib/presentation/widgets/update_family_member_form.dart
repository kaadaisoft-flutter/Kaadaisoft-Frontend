import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show FilteringTextInputFormatter, rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart' as fp_pkg;
import 'package:cross_file/cross_file.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'custom_phone_field.dart';
import 'custom_dialog.dart';
import '../../utils/api_config.dart';
import '../../services/geo_data_service.dart';

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

  XFile? _memberImage;
  XFile? _communityCert;

  bool _isAgreed = false;

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
    _selectedDistrict = d['District'];
    _selectedTaluk = d['Taluk'];
    _selectedPanchayat = d['Panchayat'];
    _selectedVillage = d['Village'];
    final street = d['Street'] ?? '';
    final doorNo = d['Doornumber']?.toString() ?? '';
    _streetController.text = doorNo.isNotEmpty ? "$doorNo, $street" : street;
    _pinCodeController.text = d['Pincode']?.toString() ?? '';
    
    // Current Address
    _selectedCurrentAddressType = d['Curaddresstype'] == 'TamilNadu' ? 'Tamil Nadu' : (d['Curaddresstype'] == 'OtherState' ? 'Other State' : (d['Curaddresstype'] == 'NRI' ? 'NRI' : null));
    _selectedCurrState = d['Curstate'];
    _selectedCurrDistrict = d['Curdistrict'];
    _selectedCurrTaluk = d['Curtaluk'];
    _selectedCurrPanchayat = d['Curpanchayat'];
    _selectedCurrVillage = d['Curvillage'];
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
        _districts = List<String>.from(d['data']);
      }
    } catch (_) {}
  }

  Future<void> _fetchTaluks(String district) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        _taluks = List<String>.from(d['data']);
      }
    } catch (_) {}
  }

  Future<void> _fetchPanchayats(String taluk) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        _panchayats = List<String>.from(d['data']);
      }
    } catch (_) {}
  }

  Future<void> _fetchVillages(String panchayat) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        _villages = List<String>.from(d['data']);
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrDistricts() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        _currDistricts = List<String>.from(d['data']);
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrTaluks(String district) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        _currTaluks = List<String>.from(d['data']);
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrPanchayats(String taluk) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        _currPanchayats = List<String>.from(d['data']);
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrVillages(String panchayat) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        _currVillages = List<String>.from(d['data']);
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
                            final phone = v.trim();
                            if (_phoneExists && phone != _initialPhone) return 'Phone number already registered';
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
                        _buildIntlPhoneField('WhatsApp', _whatsappController),
                        _buildRadioField('Married *', ['Yes', 'No'], _selectedMarried, (v) => setState(() => _selectedMarried = v)),
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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildSectionTitle(Icons.home_outlined, 'Current Address'),
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

  Widget _buildDropdownField(String label, List<String> options, String? value, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label, fontSize: 14),
      const SizedBox(height: 8),
      DropdownSearch<String>(
        items: (f, p) => options,
        selectedItem: options.contains(value) ? value : null,
        onSelected: onChanged,
        decoratorProps: DropDownDecoratorProps(
          baseStyle: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            fillColor: Colors.white, filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
          ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: true,
          menuProps: MenuProps(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search...",
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    ]);
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
            controller.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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
        Radio<String>(value: 'Male', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v)),
        const Text('Male'),
        Radio<String>(value: 'Female', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v)),
        const Text('Female'),
      ]),
    ]);
  }

  Widget _buildRadioField(String label, List<String> options, String? value, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label, fontSize: 14),
      Wrap(children: options.map((o) => Row(mainAxisSize: MainAxisSize.min, children: [
        Radio<String>(value: o, groupValue: value, onChanged: onChanged),
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
      const Expanded(child: Text('I confirm that the updated details are correct.', style: TextStyle(fontSize: 13))),
    ]);
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: (_isSaving || !_isAgreed) ? null : _submit,
        style: ElevatedButton.styleFrom(backgroundColor: mediumBrown, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('UPDATE FAMILY MEMBER', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _phoneExists) return;
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
      
      request.fields['district'] = _selectedDistrict ?? '';
      request.fields['taluk'] = _selectedTaluk ?? '';
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
      request.fields['cur_pincode'] = _currPinCodeController.text.trim();
      request.fields['nri_country'] = _selectedCountry ?? '';
      request.fields['nri_state'] = _selectedCurrState ?? '';
      request.fields['nri_city'] = _selectedCurrCity ?? '';
      request.fields['nri_zip'] = _currPinCodeController.text.trim();
      request.fields['nri_full_address'] = _currFullAddressController.text.trim();

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
      if (res.statusCode == 200) {
        if (mounted) {
          showStatusDialog(context, title: 'Success', message: 'Details updated successfully and sent for approval.', type: DialogType.success).then((_) {
            widget.onUpdate();
            Navigator.pop(context);
          });
        }
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
        } else {
          if (mounted) showStatusDialog(context, title: 'Error', message: errorMsg, type: DialogType.error);
        }
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
