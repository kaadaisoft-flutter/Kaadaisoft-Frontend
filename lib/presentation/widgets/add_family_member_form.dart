import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show FilteringTextInputFormatter, rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart' as fp_pkg;
import 'package:cross_file/cross_file.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'custom_dialog.dart';
import '../../utils/api_config.dart';

class AddFamilyMemberForm extends StatefulWidget {
  final dynamic parentId;
  final Map<String, dynamic> parentData;

  const AddFamilyMemberForm({super.key, required this.parentId, required this.parentData});

  @override
  State<AddFamilyMemberForm> createState() => _AddFamilyMemberFormState();
}

class _AddFamilyMemberFormState extends State<AddFamilyMemberForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  
  // Design Colors
  static const Color primaryBrown = Color(0xFF2D1B18);
  static const Color mediumBrown = Color(0xFF3E2723);
  static const Color accentGold = Color(0xFFC5A028);
  static const Color glassWhite = Color(0xA6FFFFFF);
  static const Color borderColor = Color(0xFFE0E0E0);

  // Controllers
  final ScrollController _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aadharController = TextEditingController();
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

  bool _whatsappSameAsPhone = false;
  bool _showMandatoryErrors = false;
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
  
  List<dynamic> _allCountriesData = [];
  List<String> _countryNames = [];
  List<String> _stateNames = [];
  List<String> _cityNames = [];

  // Options
  final List<String> _relationships = ['Grand Father','Grand Mother','Father','Mother','Husband','Wife','Son','Daughter','Son-in-law','Daughter-in-law','Brother','Sister','Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _educations = ['SSLC', 'HSC', 'Diploma', 'ITI', 'B.A', 'B.Sc', 'B.Com', 'BBA', 'BCA', 'B.E', 'B.Tech', 'MBBS', 'BDS', 'B.Pharm', 'B.Ed', 'LLB', 'B.Arch', 'M.A', 'M.Sc', 'M.Com', 'MBA', 'MCA', 'M.E', 'M.Tech', 'MD', 'MS', 'MDS', 'M.Pharm', 'M.Ed', 'LLM', 'M.Phil', 'Ph.D', 'Others'];
  final List<String> _professions = ['Doctor', 'Lawyer', 'Police', 'Teacher / Lecturer', 'Engineer', 'Government Employee', 'Private Employee', 'Student', 'Farmer', 'Textile Mill Worker', 'Garment Factory Worker', 'Tailor', 'Pattern Master', 'Textile Machinery Technician', 'Loom Operator', 'Truck Driver', 'Dairy Farmer', 'Poultry Farmer', 'Animal Husbandry', 'Pump Technician', 'Electrical Technician', 'Grocery Shop Staff', 'IT / Software Employee', 'Home Maker', 'Retired', 'Others'];

  // Documents
  XFile? _memberImage;
  XFile? _aadharFront;
  XFile? _aadharBack;
  XFile? _communityCert;

  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _focusNodes['Relationship'] = FocusNode();
    _focusNodes['Name'] = FocusNode();
    _focusNodes['Phone Number'] = FocusNode();
    _focusNodes['Aadhar Number'] = FocusNode();
    
    _fetchDistricts();
    _loadGeoData();
    // Initialize other focus nodes as needed...
    
    // Pre-fill address from parent
    _prefillFromParent();
  }

  void _prefillFromParent() {
    final p = widget.parentData;
    _valuvuController.text = p['Valuvu'] ?? '';
    _thottamController.text = p['Thottam'] ?? '';
    
    _selectedDistrict = p['District'];
    _selectedTaluk = p['Taluk'];
    _selectedPanchayat = p['Panchayat'];
    _selectedVillage = p['Village'];
    _streetController.text = p['Street'] ?? '';
    _doorNoController.text = p['Doornumber'] ?? '';
    _pinCodeController.text = p['Pincode']?.toString() ?? '';

    // We don't pre-fill current address as per user request
    _selectedCurrentAddressType = null;
  }

  Future<void> _loadGeoData() async {
    try {
      final String response = await rootBundle.loadString('assets/countries_states_cities.json');
      final data = json.decode(response);
      setState(() {
        _allCountriesData = data;
        _countryNames = _allCountriesData.map((c) => c['name'].toString()).toList();
      });
    } catch (_) {}
  }

  void _updateStates(String countryName) {
    final country = _allCountriesData.firstWhere((c) => c['name'] == countryName, orElse: () => null);
    setState(() {
      _stateNames = country != null ? (country['states'] as List).map((s) => s['name'].toString()).toList() : [];
      _selectedCurrState = null;
      _cityNames = [];
      _selectedCurrCity = null;
    });
  }

  void _updateCities(String countryName, String stateName) {
    final country = _allCountriesData.firstWhere((c) => c['name'] == countryName, orElse: () => null);
    if (country != null) {
      final state = (country['states'] as List).firstWhere((s) => s['name'] == stateName, orElse: () => null);
      setState(() {
        _cityNames = state != null ? (state['cities'] as List).map((c) => c['name'].toString()).toList() : [];
        _selectedCurrCity = null;
      });
    }
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
      _currDoorNoController.text = _doorNoController.text;
      _currPinCodeController.text = _pinCodeController.text;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aadharController.dispose();
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
      child: Container(
        width: 1000,
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
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(Icons.person_outline, 'Family Member Details'),
                      const SizedBox(height: 16),
                      
                      _buildResponsiveRow(isMobile, [
                        _buildDropdownField('Relationship *', _relationships, isMobile, value: _selectedRelationship, onChanged: (v) {
                          setState(() {
                            _selectedRelationship = v;
                            if (['Wife', 'Daughter', 'Mother', 'Grand Mother', 'Daughter-in-law', 'Sister'].contains(v)) {
                              _selectedGender = 'Female';
                            } else if (['Husband', 'Son', 'Father', 'Grand Father', 'Son-in-law', 'Brother'].contains(v)) {
                              _selectedGender = 'Male';
                            }
                          });
                        }),
                        _buildInputField('Name *', _nameController, isMobile),
                        _buildInputField('Phone Number *', _phoneController, isMobile, keyboardType: TextInputType.phone, maxLength: 10),
                      ]),
                      
                      _buildResponsiveRow(isMobile, [
                        _buildInputField('Aadhar Number *', _aadharController, isMobile, keyboardType: TextInputType.number, maxLength: 12),
                        _buildDatePickerField('Date Of Birth *', _dobController, isMobile),
                        _buildGenderSelector(isMobile),
                      ]),

                      _buildResponsiveRow(isMobile, [
                        _buildDropdownField('Blood Group *', _bloodGroups, isMobile, value: _selectedBloodGroup, onChanged: (v) => setState(() => _selectedBloodGroup = v)),
                        _buildEmailField(isMobile),
                        _buildWhatsAppField(isMobile),
                      ]),

                      _buildResponsiveRow(isMobile, [
                        _buildRadioField('Married *', ['Yes', 'No'], isMobile, value: _selectedMarried, onChanged: (v) => setState(() => _selectedMarried = v)),
                        _buildInputField('Valuvu *', _valuvuController, isMobile),
                        _buildInputField('Thottam *', _thottamController, isMobile),
                      ]),

                      _buildResponsiveRow(isMobile, [
                        _buildInputField('Kulam *', TextEditingController(text: 'Poondurai Kaadai'), isMobile, readOnly: true),
                        if (!isMobile) const Spacer(),
                        if (!isMobile) const Spacer(),
                      ]),

                      const SizedBox(height: 32),
                      _buildSectionTitle(Icons.work_outline, 'Education & Career Details'),
                      const SizedBox(height: 16),
                      _buildResponsiveRow(isMobile, [
                        _buildDropdownField('Education *', _educations, isMobile, value: _selectedEducation, onChanged: (v) => setState(() => _selectedEducation = v)),
                        _buildDropdownField('Profession *', _professions, isMobile, value: _selectedProfession, onChanged: (v) => setState(() => _selectedProfession = v)),
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
                         _buildInputField('Street Name *', _streetController, isMobile),
                         _buildInputField('Door Number *', _doorNoController, isMobile),
                      ]),
                      _buildResponsiveRow(isMobile, [
                         _buildInputField('Pin Code *', _pinCodeController, isMobile, keyboardType: TextInputType.number, maxLength: 6),
                         if (!isMobile) const Spacer(),
                         if (!isMobile) const Spacer(),
                      ]),

                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: _buildSectionTitle(Icons.home_outlined, 'Current Address')),
                          if (_selectedCurrentAddressType == 'Tamil Nadu')
                            TextButton.icon(
                              onPressed: _copyNativeToCurrent,
                              icon: const Icon(Icons.copy_all, size: 16, color: Color(0xFFC5A028)),
                              label: const Text('Same as Native', style: TextStyle(color: Color(0xFFC5A028), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
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
                          _buildInputField('Street Name *', _currStreetController, isMobile),
                          _buildInputField('Door Number *', _currDoorNoController, isMobile),
                        ]),
                        _buildResponsiveRow(isMobile, [
                          _buildInputField('Pin Code *', _currPinCodeController, isMobile, keyboardType: TextInputType.number, maxLength: 6),
                          if (!isMobile) const Spacer(),
                          if (!isMobile) const Spacer(),
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
                        _buildFileUploadField('Aadhar Front image *', 'aadhar_front'),
                        _buildFileUploadField('Aadhar Back image *', 'aadhar_back'),
                        _buildFileUploadField('Community Certificate *', 'community_cert'),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Expanded(child: Text('Add Family Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBrown))),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: accentGold, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Icon(icon, color: primaryBrown, size: 20),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBrown)),
    ]);
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) return Column(children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList());
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: c))).toList(),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool isMobile, {TextInputType? keyboardType, bool readOnly = false, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          maxLength: maxLength,
          validator: (v) => (label.contains('*') && (v == null || v.isEmpty)) ? 'Required' : null,
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

  Widget _buildDropdownField(String label, List<String> options, bool isMobile, {String? value, ValueChanged<String?>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownSearch<String>(
          items: (filter, loadProps) => options,
          selectedItem: value,
          onSelected: onChanged,
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              fillColor: Colors.white, filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
            if (picked != null) {
              setState(() => controller.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}");
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
        const Text('Gender *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        Row(
          children: [
            Radio<String>(value: 'Male', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v), activeColor: primaryBrown),
            const Text('Male'),
            Radio<String>(value: 'Female', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v), activeColor: primaryBrown),
            const Text('Female'),
            Radio<String>(value: 'Other', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v), activeColor: primaryBrown),
            const Text('Other'),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isMobile) {
    return _buildInputField('Email', _emailController, isMobile, keyboardType: TextInputType.emailAddress);
  }

  Widget _buildWhatsAppField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('WhatsApp Number *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            Row(children: [
              Checkbox(value: _whatsappSameAsPhone, onChanged: (v) => setState(() {
                _whatsappSameAsPhone = v!;
                if (v) _whatsappController.text = _phoneController.text;
              })),
              const Text('Same as Phone', style: TextStyle(fontSize: 10)),
            ]),
          ],
        ),
        TextFormField(
          controller: _whatsappController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: InputDecoration(
            fillColor: Colors.white, filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
            counterText: "",
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea(String label, TextEditingController controller, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
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
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        Row(
          children: options.map((o) => Row(
            children: [
              Radio<String>(value: o, groupValue: value, onChanged: onChanged, activeColor: primaryBrown),
              Text(o),
              const SizedBox(width: 8),
            ],
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildFileUploadField(String label, String type) {
    XFile? file;
    if (type == 'member_image') file = _memberImage;
    if (type == 'aadhar_front') file = _aadharFront;
    if (type == 'aadhar_back') file = _aadharBack;
    if (type == 'community_cert') file = _communityCert;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await fp_pkg.FilePicker.pickFiles(type: fp_pkg.FileType.image, withData: kIsWeb);
            if (result != null) {
              setState(() {
                final xfile = kIsWeb ? XFile.fromData(result.files.single.bytes!, name: result.files.single.name) : XFile(result.files.single.path!);
                if (type == 'member_image') _memberImage = xfile;
                if (type == 'aadhar_front') _aadharFront = xfile;
                if (type == 'aadhar_back') _aadharBack = xfile;
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
              Expanded(child: Text(file?.name ?? 'Choose file...', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
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
        const Expanded(child: Text('I confirm that the above details are correct.', style: TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (_isSaving || !_isAgreed) ? null : _submit,
        style: ElevatedButton.styleFrom(backgroundColor: mediumBrown, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('ADD FAMILY MEMBER', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_memberImage == null || _aadharFront == null || _aadharBack == null || _communityCert == null) {
      showStatusDialog(context, title: 'Missing Documents', message: 'Please upload all required documents.', type: DialogType.warning);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.register));
      
      // We use the register endpoint but set the relationship and family ID
      request.fields['name'] = _nameController.text;
      request.fields['phone'] = _phoneController.text;
      request.fields['aadhar'] = _aadharController.text;
      request.fields['dob'] = _dobController.text.contains('-') ? _dobController.text.split('-').reversed.join('-') : _dobController.text;
      request.fields['gender'] = _selectedGender ?? '';
      request.fields['blood_group'] = _selectedBloodGroup ?? '';
      request.fields['email'] = _emailController.text;
      request.fields['whatsapp'] = _whatsappController.text;
      request.fields['married'] = _selectedMarried ?? '';
      request.fields['valuvu'] = _valuvuController.text;
      request.fields['thottam'] = _thottamController.text;
      request.fields['education'] = _selectedEducation ?? '';
      request.fields['profession'] = _selectedProfession ?? '';
      request.fields['relationship'] = _selectedRelationship ?? '';
      request.fields['family_id'] = widget.parentData['Familymembershipid'] ?? ''; // Link to family
      
      // Copy parent address
      request.fields['district'] = _selectedDistrict ?? '';
      request.fields['taluk'] = _selectedTaluk ?? '';
      request.fields['panchayat'] = _selectedPanchayat ?? '';
      request.fields['village'] = _selectedVillage ?? '';
      request.fields['street'] = _streetController.text;
      request.fields['door_no'] = _doorNoController.text;
      request.fields['pincode'] = _pinCodeController.text;

      // Current Address
      request.fields['cur_address_type'] = _selectedCurrentAddressType ?? '';
      request.fields['cur_district'] = _selectedCurrDistrict ?? '';
      request.fields['cur_taluk'] = _selectedCurrTaluk ?? '';
      request.fields['cur_panchayat'] = _selectedCurrPanchayat ?? '';
      request.fields['cur_village'] = _selectedCurrVillage ?? '';
      request.fields['cur_street'] = _currStreetController.text;
      request.fields['cur_door_no'] = _currDoorNoController.text;
      request.fields['cur_pincode'] = _currPinCodeController.text;
      request.fields['cur_state'] = _selectedCurrState ?? '';
      request.fields['nri_country'] = _selectedCountry ?? '';
      request.fields['nri_state'] = _selectedCurrState ?? '';
      request.fields['nri_city'] = _selectedCurrCity ?? '';
      request.fields['nri_zip'] = _currPinCodeController.text;
      request.fields['nri_full_address'] = _currFullAddressController.text;

      // Add files
      Future<http.MultipartFile> toMultipart(XFile file, String field) async {
        if (kIsWeb) return http.MultipartFile.fromBytes(field, await file.readAsBytes(), filename: file.name);
        return http.MultipartFile.fromPath(field, file.path);
      }

      request.files.add(await toMultipart(_memberImage!, 'member_image'));
      request.files.add(await toMultipart(_aadharFront!, 'aadhar_front'));
      request.files.add(await toMultipart(_aadharBack!, 'aadhar_back'));
      request.files.add(await toMultipart(_communityCert!, 'community_cert'));

      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        if (mounted) {
           showStatusDialog(context, title: 'Success', message: 'Family member added successfully.', type: DialogType.success).then((_) => Navigator.pop(context));
        }
      } else {
         throw Exception('Failed to add member');
      }
    } catch (e) {
      if (mounted) showStatusDialog(context, title: 'Error', message: e.toString(), type: DialogType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
