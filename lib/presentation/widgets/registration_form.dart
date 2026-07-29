import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle, FilteringTextInputFormatter;
import 'package:http/http.dart' as http;
import 'package:kaadaisoft/presentation/pages/terms_and_conditions_page.dart';
import 'package:kaadaisoft/presentation/pages/privacy_policy_page.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart' as fp_pkg;
import 'package:cross_file/cross_file.dart';
import 'custom_dropdown_search.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'custom_dialog.dart';
import 'custom_phone_field.dart';
import '../../utils/api_config.dart';
import '../../services/geo_data_service.dart';
import '../../l10n/app_localizations.dart';

class RegistrationForm extends StatefulWidget {
  final int? submitterRole;
  const RegistrationForm({super.key, this.submitterRole});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Design Colors
  static const Color primaryBrown = const Color(0xFF2D1B18);
  static const Color mediumBrown = const Color(0xFF3E2723);
  static const Color accentGold = const Color(0xFFC5A028);
  static const Color glassWhite = Color(0xA6FFFFFF);
  static const Color borderColor = const Color(0xFFE0E0E0);

  // Controllers and FocusNodes
  final ScrollController _scrollController = ScrollController();
  final Map<String, FocusNode> _focusNodes = {
    'Name': FocusNode(),
    'Phone Number': FocusNode(),
    'Date Of Birth': FocusNode(),
    'Blood Group': FocusNode(),
    'Email': FocusNode(),
    'WhatsApp Number': FocusNode(),
    'Married': FocusNode(),
    'Valuvu': FocusNode(),
    'Thottam': FocusNode(),
    'Education': FocusNode(),
    'Profession': FocusNode(),
    'Gender': FocusNode(),
    'Address Type': FocusNode(),
    'District': FocusNode(),
    'Taluk': FocusNode(),
    'Panchayat': FocusNode(),
    'Village Name': FocusNode(),
    'Street Name': FocusNode(),
    'Door Number': FocusNode(),
    'Pin Code': FocusNode(),
    'Curr District': FocusNode(),
    'Curr Taluk': FocusNode(),
    'Curr Panchayat': FocusNode(),
    'Curr Village': FocusNode(),
    'Curr Street': FocusNode(),
    'Curr Door': FocusNode(),
    'Curr Pin': FocusNode(),
    'Curr State': FocusNode(),
    'Curr City': FocusNode(),
    'Curr Zip': FocusNode(),
    'Curr Country': FocusNode(),
    'Curr Full Address': FocusNode(),
    'Documents': FocusNode(),
    'Agreement': FocusNode(),
  };

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
  
  // Manual Entry Controllers for "Others"
  final _manualDistrictController = TextEditingController();
  final _manualTalukController = TextEditingController();
  final _manualPanchayatController = TextEditingController();
  final _manualVillageController = TextEditingController();
  
  final _manualCurrDistrictController = TextEditingController();
  final _manualCurrTalukController = TextEditingController();
  final _manualCurrPanchayatController = TextEditingController();
  final _manualCurrVillageController = TextEditingController();
  
  // Selection States
  String _phoneCountryCode = 'IN';
  String _phoneCountryDialCode = '+91';
  String _whatsappCountryCode = 'IN';
  String _whatsappCountryDialCode = '+91';
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedMarried;
  String? _selectedEducation;
  String? _selectedProfession;
  String? _selectedCurrentAddressType;
  String? _selectedDistrict;
  String? _selectedTaluk;
  String? _selectedPanchayat;
  String? _selectedVillage;
  String? _selectedCountry;
  String? _selectedCurrDistrict;
  String? _selectedCurrTaluk;
  String? _selectedCurrPanchayat;
  String? _selectedCurrVillage;
  String? _selectedCurrState;
  String? _selectedCurrCity;
  bool _whatsappSameAsPhone = false;
  bool _isAgreed = false;

  // File Uploads
  XFile? _memberImage;
  XFile? _communityCert;

  // Real Database Data for Hierarchical Dropdowns
  List<String> _districts = [];
  List<String> _taluks = [];
  List<String> _panchayats = [];
  List<String> _villages = [];

  List<String> _currDistricts = [];
  List<String> _currTaluks = [];
  List<String> _currPanchayats = [];
  List<String> _currVillages = [];
  
  // JSON Data for Other State & NRI
  List<String> _countryNames = [];
  List<String> _stateNames = [];
  List<String> _cityNames = [];

  final GeoDataService _geoService = GeoDataService();
  
  final GlobalKey<FormFieldState> _phoneFieldKey = GlobalKey<FormFieldState>();

  bool _isLoadingGeoData = false;
  
  bool _isLoadingDistricts = false;
  bool _isLoadingTaluks = false;
  bool _isLoadingPanchayats = false;
  bool _isLoadingVillages = false;
  bool _phoneExists = false;
  bool _showMandatoryErrors = false;


  @override
  void initState() {
    super.initState();
    _fetchDistricts();
    _loadGeoData();
    
    // Add listeners for existence check
    _phoneController.addListener(() {
      if (_phoneController.text.length == 10) {
        _checkExistence(phone: _phoneController.text);
      } else {
        if (_phoneExists) setState(() => _phoneExists = false);
      }
    });
  }

  Future<void> _checkExistence({String? phone}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.checkExistence),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Existence check result: $data');
        setState(() {
          if (phone != null) {
            _phoneExists = data['phone_exists'] ?? false;
            _phoneFieldKey.currentState?.validate();
          }
        });
      } else {
        debugPrint('Existence check failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking existence: $e');
    }
  }

  Future<void> _loadGeoData() async {
    setState(() => _isLoadingGeoData = true);
    if (!_geoService.isLoaded) {
      await _geoService.loadData();
    }
    setState(() {
      _countryNames = _geoService.countryNames.where((c) => c.toLowerCase() != 'india').toList();
      _isLoadingGeoData = false;
      if (_selectedCurrentAddressType == 'Other State') {
        _updateStates('India');
      }
    });
  }

  void _updateStates(String countryName) {
    setState(() {
      final states = _geoService.getStates(countryName);
      if (countryName.toLowerCase() == 'india') {
        _stateNames = states.where((s) => s.toLowerCase() != 'tamil nadu').toList();
      } else {
        _stateNames = states;
      }
      _selectedCurrState = null;
      _cityNames = [];
      _selectedCurrCity = null;
    });
  }

  void _updateCities(String countryName, String stateName) {
    setState(() {
      _cityNames = _geoService.getCities(countryName, stateName);
      _selectedCurrCity = null;
    });
  }

  Future<void> _fetchDistricts() async {
    setState(() => _isLoadingDistricts = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _districts = List<String>.from(data['data']);
          if (!_districts.contains('Others')) _districts.add('Others');
          _isLoadingDistricts = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching districts: $e');
      setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _fetchTaluks(String district) async {
    setState(() {
      _isLoadingTaluks = true;
      _taluks = [];
      _selectedTaluk = null;
      _panchayats = [];
      _selectedPanchayat = null;
      _villages = [];
      _selectedVillage = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _taluks = List<String>.from(data['data']);
          if (!_taluks.contains('Others')) _taluks.add('Others');
          _isLoadingTaluks = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching taluks: $e');
      setState(() => _isLoadingTaluks = false);
    }
  }

  Future<void> _fetchPanchayats(String taluk) async {
    setState(() {
      _isLoadingPanchayats = true;
      _panchayats = [];
      _selectedPanchayat = null;
      _villages = [];
      _selectedVillage = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _panchayats = List<String>.from(data['data']);
          if (!_panchayats.contains('Others')) _panchayats.add('Others');
          _isLoadingPanchayats = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching panchayats: $e');
      setState(() => _isLoadingPanchayats = false);
    }
  }

  Future<void> _fetchVillages(String panchayat) async {
    setState(() {
      _isLoadingVillages = true;
      _villages = [];
      _selectedVillage = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _villages = List<String>.from(data['data']);
          if (!_villages.contains('Others')) _villages.add('Others');
          _isLoadingVillages = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching villages: $e');
      setState(() => _isLoadingVillages = false);
    }
  }

  Future<void> _fetchCurrDistricts() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currDistricts = List<String>.from(data['data']);
          if (!_currDistricts.contains('Others')) _currDistricts.add('Others');
        });
      }
    } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _fetchCurrTaluks(String district) async {
    setState(() { 
      _currTaluks = []; _selectedCurrTaluk = null; 
      _currPanchayats = []; _selectedCurrPanchayat = null;
      _currVillages = []; _selectedCurrVillage = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currTaluks = List<String>.from(data['data']);
          if (!_currTaluks.contains('Others')) _currTaluks.add('Others');
        });
      }
    } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _fetchCurrPanchayats(String taluk) async {
    setState(() { 
      _currPanchayats = []; _selectedCurrPanchayat = null; 
      _currVillages = []; _selectedCurrVillage = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currPanchayats = List<String>.from(data['data']);
          if (!_currPanchayats.contains('Others')) _currPanchayats.add('Others');
        });
      }
    } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _fetchCurrVillages(String panchayat) async {
    setState(() { _currVillages = []; _selectedCurrVillage = null; });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currVillages = List<String>.from(data['data']);
          if (!_currVillages.contains('Others')) _currVillages.add('Others');
        });
      }
    } catch (e) { debugPrint('Error: $e'); }
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
      
      // Copy manual entry fields if "Others" was selected
      _manualCurrDistrictController.text = _manualDistrictController.text;
      _manualCurrTalukController.text = _manualTalukController.text;
      _manualCurrPanchayatController.text = _manualPanchayatController.text;
      _manualCurrVillageController.text = _manualVillageController.text;
    });
    
    // Clear validation errors after copying using a post-frame callback
    if (_showMandatoryErrors) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.validate();
      });
    }
  }

  void _handleRegister() {
    setState(() => _showMandatoryErrors = true);
    
    // Check form validation first
    bool isFormValid = _formKey.currentState!.validate();
    
    // Check mandatory documents
    bool documentsValid = true;
    String? missingDoc;
    
    if (_memberImage == null) { documentsValid = false; missingDoc = 'Passport size photo'; }

    if (!isFormValid) {
      String? firstErrorField;
      if (_nameController.text.isEmpty) firstErrorField = 'Name';
      else if (_phoneController.text.length != 10) firstErrorField = 'Phone Number';
      else if (_dobController.text.isEmpty) firstErrorField = 'Date Of Birth';
      else if (_selectedGender == null) firstErrorField = 'Gender';
      else if (_selectedBloodGroup == null) firstErrorField = 'Blood Group';
      else if (_emailController.text.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) firstErrorField = 'Email';
      else if (_whatsappController.text.length != 10) firstErrorField = 'WhatsApp Number';
      else if (_selectedMarried == null) firstErrorField = 'Married';
      else if (_selectedEducation == 'Others' && (_educationController.text.isEmpty || !RegExp(r'[a-zA-Z]').hasMatch(_educationController.text.trim()))) firstErrorField = 'Education';
      else if (_selectedProfession == 'Others' && (_professionController.text.isEmpty || !RegExp(r'[a-zA-Z]').hasMatch(_professionController.text.trim()))) firstErrorField = 'Profession';
      else if (_selectedDistrict == 'Others' && (_manualDistrictController.text.isEmpty || !RegExp(r'[a-zA-Z]').hasMatch(_manualDistrictController.text.trim()))) firstErrorField = 'District';
      else if (_selectedDistrict == null) firstErrorField = 'District';
      else if (_selectedTaluk == 'Others' && (_manualTalukController.text.isEmpty || !RegExp(r'[a-zA-Z]').hasMatch(_manualTalukController.text.trim()))) firstErrorField = 'Taluk';
      else if (_selectedTaluk == null) firstErrorField = 'Taluk';
      else if (_selectedPanchayat == 'Others' && (_manualPanchayatController.text.isEmpty || !RegExp(r'[a-zA-Z]').hasMatch(_manualPanchayatController.text.trim()))) firstErrorField = 'Panchayat';
      else if (_selectedPanchayat == null) firstErrorField = 'Panchayat';
      else if (_selectedVillage == 'Others' && (_manualVillageController.text.isEmpty || !RegExp(r'[a-zA-Z]').hasMatch(_manualVillageController.text.trim()))) firstErrorField = 'Village Name';
      else if (_selectedVillage == null) firstErrorField = 'Village Name';
      else if (_streetController.text.isEmpty) firstErrorField = 'Street Name';
      else if (_pinCodeController.text.length != 6) firstErrorField = 'Pin Code';
      
      // Current Address Validation
      if (firstErrorField == null) {
        if (_selectedCurrentAddressType == null) {
          firstErrorField = 'Address Type';
        } else if (_selectedCurrentAddressType == 'Tamil Nadu') {
          if (_selectedCurrDistrict == null) firstErrorField = 'Curr District';
          else if (_selectedCurrTaluk == null) firstErrorField = 'Curr Taluk';
          else if (_selectedCurrPanchayat == null) firstErrorField = 'Curr Panchayat';
          else if (_selectedCurrVillage == null) firstErrorField = 'Curr Village';
          else if (_currStreetController.text.isEmpty) firstErrorField = 'Curr Street';
          else if (_currPinCodeController.text.length != 6) firstErrorField = 'Curr Pin';
        } else if (_selectedCurrentAddressType == 'Other State') {
          if (_selectedCurrState == null) firstErrorField = 'Curr State';
          else if (_selectedCurrCity == null) firstErrorField = 'Curr City';
          else if (_currZipController.text.isEmpty) firstErrorField = 'Curr Zip';
          else if (_currFullAddressController.text.isEmpty) firstErrorField = 'Curr Full Address';
        } else if (_selectedCurrentAddressType == 'NRI') {
          if (_selectedCountry == null) firstErrorField = 'Curr Country';
          else if (_selectedCurrState == null) firstErrorField = 'Curr State';
          else if (_selectedCurrCity == null) firstErrorField = 'Curr City';
          else if (_currZipController.text.isEmpty) firstErrorField = 'Curr Zip';
          else if (_currFullAddressController.text.isEmpty) firstErrorField = 'Curr Full Address';
        }
      }

      showStatusDialog(
        context,
        title: 'Mandatory Fields',
        message: 'Please fill all the mandatory fields marked with * correctly.',
        type: DialogType.warning,
        onOk: () {
          if (firstErrorField != null) {
            final focusNode = _focusNodes[firstErrorField];
            if (focusNode != null && focusNode.context != null) {
              Future.delayed(const Duration(milliseconds: 100), () {
                Scrollable.ensureVisible(
                  focusNode.context!,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  alignment: 0.5,
                );
                focusNode.requestFocus();
              });
            }
          }
        },
      );
      return;
    }

    if (!documentsValid) {
      showStatusDialog(
        context,
        title: AppLocalizations.of(context)?.missingDocumentTitle ?? 'Missing Document',
        message: 'Please upload your $missingDoc.',
        type: DialogType.warning,
        onOk: () {
          final focusNode = _focusNodes['Documents'];
          if (focusNode != null && focusNode.context != null) {
            Future.delayed(const Duration(milliseconds: 100), () {
              Scrollable.ensureVisible(
                focusNode.context!,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                alignment: 0.5,
              );
            });
          }
        },
      );
      return;
    }

    if (!_isAgreed) {
      showStatusDialog(
        context,
        title: AppLocalizations.of(context)?.agreementRequiredTitle ?? 'Agreement Required',
        message: AppLocalizations.of(context)?.pleaseAgreeToTerms ?? 'Please agree to the Terms and Conditions to proceed.',
        type: DialogType.warning,
      );
      return;
    }

    _submitRegistration();
  }

  Future<void> _submitRegistration() async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.register));
      
      // Add text fields
      request.fields['name'] = _nameController.text.trim();
      request.fields['phone'] = _phoneController.text;
      request.fields['dob'] = _dobController.text.contains('-') ? _dobController.text.split('-').reversed.join('-') : _dobController.text;
      request.fields['gender'] = _selectedGender ?? '';
      request.fields['blood_group'] = _selectedBloodGroup ?? '';
      request.fields['email'] = _emailController.text;
      request.fields['whatsapp'] = _whatsappController.text;
      request.fields['mobile_country_code'] = _phoneCountryDialCode;
      request.fields['whatsapp_country_code'] = _whatsappCountryDialCode;
      request.fields['married'] = _selectedMarried ?? '';
      request.fields['valuvu'] = _valuvuController.text;
      request.fields['thottam'] = _thottamController.text;
      request.fields['education'] = _selectedEducation == 'Others' ? _educationController.text : (_selectedEducation ?? '');
      request.fields['profession'] = _selectedProfession == 'Others' ? _professionController.text : (_selectedProfession ?? '');
      request.fields['state_id'] = '31';
      request.fields['state'] = 'Tamil Nadu';
      request.fields['district'] = _selectedDistrict == 'Others' ? _manualDistrictController.text : (_selectedDistrict ?? '');
      request.fields['taluk'] = _selectedTaluk == 'Others' ? _manualTalukController.text : (_selectedTaluk ?? '');
      request.fields['panchayat'] = _selectedPanchayat == 'Others' ? _manualPanchayatController.text : (_selectedPanchayat ?? '');
      request.fields['village'] = _selectedVillage == 'Others' ? _manualVillageController.text : (_selectedVillage ?? '');
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
      request.fields['cur_address_type'] = _selectedCurrentAddressType ?? '';
      request.fields['cur_state'] = _selectedCurrentAddressType == 'Tamil Nadu' ? 'Tamil Nadu' : (_selectedCurrState ?? '');
      request.fields['cur_district'] = _selectedCurrDistrict == 'Others' ? _manualCurrDistrictController.text : (_selectedCurrDistrict ?? '');
      request.fields['cur_taluk'] = _selectedCurrTaluk == 'Others' ? _manualCurrTalukController.text : (_selectedCurrTaluk ?? '');
      request.fields['cur_panchayat'] = _selectedCurrPanchayat == 'Others' ? _manualCurrPanchayatController.text : (_selectedCurrPanchayat ?? '');
      request.fields['cur_village'] = _selectedCurrVillage == 'Others' ? _manualCurrVillageController.text : (_selectedCurrVillage ?? '');
      
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
      request.fields['nri_country'] = _selectedCountry ?? '';
      request.fields['nri_state'] = _selectedCurrState ?? '';
      request.fields['nri_city'] = _selectedCurrCity ?? '';
      request.fields['nri_zip'] = _currZipController.text;
      request.fields['nri_full_address'] = _currFullAddressController.text;
      request.fields['submitter_role'] = (widget.submitterRole ?? 3).toString();

      // Add files
      if (_memberImage != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'member_image',
            await _memberImage!.readAsBytes(),
            filename: _memberImage!.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('member_image', _memberImage!.path));
        }
      }
      if (_communityCert != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'community_cert',
            await _communityCert!.readAsBytes(),
            filename: _communityCert!.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath('community_cert', _communityCert!.path));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          showStatusDialog(
            context,
            title: 'Success',
            message: data['message'] ?? 'Member registered successfully.',
            type: DialogType.success,
          ).then((_) {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        String errorMsg = 'Failed to submit application. Please try again later.';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['detail'] ?? errorMsg;
          if (errorMsg.contains('value too long for type character varying')) {
            final match = RegExp(r'varying\((\d+)\)').firstMatch(errorMsg);
            if (match != null) {
              errorMsg = 'Maximum ${match.group(1)} characters allowed for one of the text fields.';
            } else {
              errorMsg = 'Input exceeds the maximum allowed characters for a field.';
            }
          }
        } catch (e) {}
        
        if (errorMsg.contains('Phone number')) {
          setState(() {
            _phoneExists = true;
          });
          _phoneFieldKey.currentState?.validate();
        } else {
          if (mounted) {
            showStatusDialog(
              context,
              title: 'Error',
              message: errorMsg,
              type: DialogType.error,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showStatusDialog(
          context,
          title: 'Error',
          message: 'An error occurred: $e',
          type: DialogType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : size.width * 0.1,
        vertical: isMobile ? 10 : 20,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: glassWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.registrationFormTitle ?? 'Poondurai Kaadaikulam.org / Registration Form',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primaryBrown,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  _buildExitButton(),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x1A000000)),
            
            // Scrollable Form
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.indicatesMandatory ?? 'Note: * Indicates Mandatory.',
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 24),
                      
                      // Section: Basic Details
                      _buildSectionTitle(Icons.person_outline, 'Basic Details'),
                      const SizedBox(height: 16),
                      
                      _buildResponsiveRow(isMobile, [
                        _buildInputField('Name *', _nameController, isMobile, focusNode: _focusNodes['Name'], maxLength: 100),
                        _buildIntlPhoneField('Phone Number *', _phoneController, isMobile, focusNode: _focusNodes['Phone Number'], fieldKey: _phoneFieldKey),
                        _buildDatePickerField('Date Of Birth *', _dobController, isMobile, focusNode: _focusNodes['Date Of Birth']),
                      ]),
                      
                      _buildResponsiveRow(isMobile, [
                        _buildGenderSelector(isMobile, focusNode: _focusNodes['Gender']),
                        _buildDropdownField('Blood Group *', ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'], isMobile, value: _selectedBloodGroup, onChanged: (v) => setState(() => _selectedBloodGroup = v), focusNode: _focusNodes['Blood Group']),
                        _buildEmailField(isMobile, focusNode: _focusNodes['Email']),
                      ]),
                      
                      _buildResponsiveRow(isMobile, [
                        _buildWhatsAppField(isMobile, focusNode: _focusNodes['WhatsApp Number']),
                        _buildRadioField('Married *', ['Yes', 'No'], isMobile, 
                          value: _selectedMarried, 
                          focusNode: _focusNodes['Married'],
                          onChanged: (v) => setState(() => _selectedMarried = v)),
                        _buildInputField('Valuvu', _valuvuController, isMobile, focusNode: _focusNodes['Valuvu'], maxLength: 100),
                      ]),
                      
                      _buildResponsiveRow(isMobile, [
                        _buildInputField('Thottam', _thottamController, isMobile, focusNode: _focusNodes['Thottam'], maxLength: 100),
                        _buildInputField('Kulam *', TextEditingController(text: 'Poondurai Kaadai'), isMobile, readOnly: true),
                        if (!isMobile) const SizedBox.shrink(),
                      ]),

                      const SizedBox(height: 32),
                      
                      // Section: Education & Career
                      _buildSectionTitle(Icons.work_outline, 'Education & Career Details'),
                      const SizedBox(height: 16),
                      _buildResponsiveRow(isMobile, [
                        Column(
                          children: [
                            _buildDropdownField('Education', [
                              'SSLC', 'HSC', 'Diploma', 'ITI', 'B.A', 'B.Sc', 'B.Com', 'BBA', 'BCA', 'B.E', 'B.Tech',
                              'MBBS', 'BDS', 'B.Pharm', 'B.Ed', 'LLB', 'B.Arch', 'M.A', 'M.Sc', 'M.Com', 'MBA', 'MCA',
                              'M.E', 'M.Tech', 'MD', 'MS', 'MDS', 'M.Pharm', 'M.Ed', 'LLM', 'M.Phil', 'Ph.D', 'Others'
                            ], isMobile, value: _selectedEducation, onChanged: (v) => setState(() => _selectedEducation = v), focusNode: _focusNodes['Education']),
                            if (_selectedEducation == 'Others')
                              _buildInputField('Enter Education', _educationController, isMobile, maxLength: 254),
                          ],
                        ),
                        Column(
                          children: [
                            _buildDropdownField('Profession', [
                              'Doctor', 'Lawyer', 'Police', 'Teacher / Lecturer', 'Engineer', 'Government Employee',
                              'Private Employee', 'Student', 'Farmer', 'Textile Mill Worker', 'Garment Factory Worker',
                              'Tailor', 'Pattern Master', 'Textile Machinery Technician', 'Loom Operator', 'Truck Driver',
                              'Dairy Farmer', 'Poultry Farmer', 'Animal Husbandry', 'Pump Technician', 'Electrical Technician',
                              'Grocery Shop Staff', 'IT / Software Employee', 'Home Maker', 'Retired', 'Others'
                            ], isMobile, value: _selectedProfession, onChanged: (v) => setState(() => _selectedProfession = v), focusNode: _focusNodes['Profession']),
                            if (_selectedProfession == 'Others')
                              _buildInputField('Enter Profession', _professionController, isMobile, maxLength: 254),
                          ],
                        ),
                        if (!isMobile) const SizedBox.shrink(),
                      ]),

                      const SizedBox(height: 32),
                      
                      // Section: Native Address
                      _buildSectionTitle(Icons.location_on_outlined, 'Native Address *'),
                      const SizedBox(height: 16),
                      _buildResponsiveRow(isMobile, [
                        Column(
                          children: [
                            _buildDropdownField('District *', _districts, isMobile, 
                              value: _selectedDistrict, 
                              focusNode: _focusNodes['District'],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _selectedDistrict = v;
                                    _selectedTaluk = null;
                                    _selectedPanchayat = null;
                                    _selectedVillage = null;
                                  });
                                  if (v != 'Others') _fetchTaluks(v);
                                  else setState(() => _taluks = ['Others']);
                                }
                              }),
                            if (_selectedDistrict == 'Others')
                              _buildInputField('Enter District *', _manualDistrictController, isMobile, maxLength: 254),
                          ],
                        ),
                        Column(
                          children: [
                            _buildDropdownField('Taluk *', _taluks, isMobile, 
                              value: _selectedTaluk, 
                              focusNode: _focusNodes['Taluk'],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _selectedTaluk = v;
                                    _selectedPanchayat = null;
                                    _selectedVillage = null;
                                  });
                                  if (v != 'Others') _fetchPanchayats(v);
                                  else setState(() => _panchayats = ['Others']);
                                }
                              }),
                            if (_selectedTaluk == 'Others')
                              _buildInputField('Enter Taluk *', _manualTalukController, isMobile, maxLength: 254),
                          ],
                        ),
                        Column(
                          children: [
                            _buildDropdownField('Panchayat *', _panchayats, isMobile, 
                              value: _selectedPanchayat, 
                              focusNode: _focusNodes['Panchayat'],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _selectedPanchayat = v;
                                    _selectedVillage = null;
                                  });
                                  if (v != 'Others') _fetchVillages(v);
                                  else setState(() => _villages = ['Others']);
                                }
                              }),
                            if (_selectedPanchayat == 'Others')
                              _buildInputField('Enter Panchayat *', _manualPanchayatController, isMobile, maxLength: 254),
                          ],
                        ),
                        Column(
                          children: [
                            _buildDropdownField('Village Name *', _villages, isMobile, 
                              value: _selectedVillage, 
                              focusNode: _focusNodes['Village Name'],
                              onChanged: (v) => setState(() => _selectedVillage = v)),
                            if (_selectedVillage == 'Others')
                              _buildInputField('Enter Village *', _manualVillageController, isMobile, maxLength: 254),
                          ],
                        ),
                      ]),
                      _buildResponsiveRow(isMobile, [
                        _buildInputField('Door No & Street Name *', _streetController, isMobile, hint: 'e.g. 1/4, Nehru Street', focusNode: _focusNodes['Street Name'], maxLength: 254),
                        _buildInputField('Pin Code *', _pinCodeController, isMobile, keyboardType: TextInputType.number, maxLength: 6, focusNode: _focusNodes['Pin Code']),
                        if (!isMobile) const SizedBox.shrink(),
                      ]),

                      const SizedBox(height: 32),

                      // Section: Current Address
                      _buildSectionTitle(
                        Icons.home_outlined, 
                        'Current Address *',
                        trailing: _selectedCurrentAddressType == 'Tamil Nadu'
                          ? TextButton.icon(
                              onPressed: _copyNativeToCurrent,
                              icon: const Icon(Icons.copy_all, size: 16, color: mediumBrown),
                              label: const Text('Same as Native', style: TextStyle(color: mediumBrown, fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                          : null,
                      ),
                      const SizedBox(height: 16),
                        _buildRadioField('Current Address Type *', ['Tamil Nadu', 'Other State', 'NRI'], isMobile,
                        value: _selectedCurrentAddressType,
                        focusNode: _focusNodes['Address Type'],
                        onChanged: (v) {
                          setState(() {
                            _selectedCurrentAddressType = v;
                            _selectedCurrState = null;
                            _selectedCurrCity = null;
                            _selectedCountry = null;
                            _selectedCurrDistrict = null;
                            _selectedCurrTaluk = null;
                            _selectedCurrPanchayat = null;
                            _selectedCurrVillage = null;
                            _stateNames = [];
                            _cityNames = [];
                            _currTaluks = [];
                            _currPanchayats = [];
                            _currVillages = [];
                            _currZipController.clear();
                            _currPinCodeController.clear();
                            _currFullAddressController.clear();
                            _currStreetController.clear();
                            _manualCurrVillageController.clear();
                          });
                          if (v == 'Tamil Nadu') _fetchCurrDistricts();
                          if (v == 'Other State') _updateStates('India');
                        }),

                      if (_selectedCurrentAddressType == 'Tamil Nadu') ...[
                        const SizedBox(height: 16),
                        _buildResponsiveRow(isMobile, [
                          Column(
                            children: [
                              _buildDropdownField('District *', _currDistricts, isMobile, 
                                value: _selectedCurrDistrict, 
                                focusNode: _focusNodes['Curr District'],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _selectedCurrDistrict = v;
                                      _selectedCurrTaluk = null;
                                      _selectedCurrPanchayat = null;
                                      _selectedCurrVillage = null;
                                    });
                                    if (v != 'Others') _fetchCurrTaluks(v);
                                    else setState(() => _currTaluks = ['Others']);
                                  }
                                }),
                              if (_selectedCurrDistrict == 'Others')
                                _buildInputField('Enter District *', _manualCurrDistrictController, isMobile, maxLength: 254),
                            ],
                          ),
                          Column(
                            children: [
                              _buildDropdownField('Taluk *', _currTaluks, isMobile, 
                                value: _selectedCurrTaluk, 
                                focusNode: _focusNodes['Curr Taluk'],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _selectedCurrTaluk = v;
                                      _selectedCurrPanchayat = null;
                                      _selectedCurrVillage = null;
                                    });
                                    if (v != 'Others') _fetchCurrPanchayats(v);
                                    else setState(() => _currPanchayats = ['Others']);
                                  }
                                }),
                              if (_selectedCurrTaluk == 'Others')
                                _buildInputField('Enter Taluk *', _manualCurrTalukController, isMobile, maxLength: 254),
                            ],
                          ),
                          Column(
                            children: [
                              _buildDropdownField('Panchayat *', _currPanchayats, isMobile, 
                                value: _selectedCurrPanchayat, 
                                focusNode: _focusNodes['Curr Panchayat'],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _selectedCurrPanchayat = v;
                                      _selectedCurrVillage = null;
                                    });
                                    if (v != 'Others') _fetchCurrVillages(v);
                                    else setState(() => _currVillages = ['Others']);
                                  }
                                }),
                              if (_selectedCurrPanchayat == 'Others')
                                _buildInputField('Enter Panchayat *', _manualCurrPanchayatController, isMobile, maxLength: 254),
                            ],
                          ),
                          Column(
                            children: [
                              _buildDropdownField('Village Name *', _currVillages, isMobile, 
                                value: _selectedCurrVillage, 
                                focusNode: _focusNodes['Curr Village'],
                                onChanged: (v) => setState(() => _selectedCurrVillage = v)),
                              if (_selectedCurrVillage == 'Others')
                                _buildInputField('Enter Village *', _manualCurrVillageController, isMobile, maxLength: 254),
                            ],
                          ),
                        ]),
                        _buildResponsiveRow(isMobile, [
                          _buildInputField('Door No & Street Name *', _currStreetController, isMobile, hint: 'e.g. 1/4, Nehru Street', focusNode: _focusNodes['Curr Street'], maxLength: 254),
                          _buildInputField('Pin Code *', _currPinCodeController, isMobile, keyboardType: TextInputType.number, maxLength: 6, focusNode: _focusNodes['Curr Pin']),
                          if (!isMobile) const SizedBox.shrink(),
                          if (!isMobile) const SizedBox.shrink(),
                        ]),
                      ] else if (_selectedCurrentAddressType == 'Other State') ...[
                        const SizedBox(height: 16),
                        _buildResponsiveRow(isMobile, [
                          _buildDropdownField('State / Province / Region *', _stateNames, isMobile,
                            value: _selectedCurrState,
                            focusNode: _focusNodes['Curr State'],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedCurrState = v);
                                _updateCities('India', v);
                              }
                            }),
                          _buildDropdownField('City / Town *', _cityNames, isMobile,
                            value: _selectedCurrCity,
                            focusNode: _focusNodes['Curr City'],
                            onChanged: (v) => setState(() => _selectedCurrCity = v)),
                          _buildInputField('Zip / Postal Code *', _currZipController, isMobile, keyboardType: TextInputType.number, maxLength: 6, focusNode: _focusNodes['Curr Zip']),
                        ]),
                        _buildTextArea('Full Address (House no, street, area) *', _currFullAddressController, isMobile, focusNode: _focusNodes['Curr Full Address']),
                      ] else if (_selectedCurrentAddressType == 'NRI') ...[
                        const SizedBox(height: 16),
                        _buildResponsiveRow(isMobile, [
                          _buildDropdownField('Country *', _countryNames, isMobile,
                            value: _selectedCountry,
                            focusNode: _focusNodes['Curr Country'],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedCountry = v);
                                _updateStates(v);
                              }
                            }),
                          _buildDropdownField('State / Province / Region *', _stateNames, isMobile,
                            value: _selectedCurrState,
                            focusNode: _focusNodes['Curr State'],
                            onChanged: (v) {
                              if (v != null && _selectedCountry != null) {
                                setState(() => _selectedCurrState = v);
                                _updateCities(_selectedCountry!, v);
                              }
                            }),
                          _buildDropdownField('City / Town *', _cityNames, isMobile,
                            value: _selectedCurrCity,
                            focusNode: _focusNodes['Curr City'],
                            onChanged: (v) => setState(() => _selectedCurrCity = v)),
                          _buildInputField('Zip / Postal Code *', _currZipController, isMobile, keyboardType: TextInputType.number, maxLength: 6, focusNode: _focusNodes['Curr Zip']),
                        ]),
                        _buildTextArea('Full Address (House no, street, area) *', _currFullAddressController, isMobile, focusNode: _focusNodes['Curr Full Address']),
                      ],

                      const SizedBox(height: 32),

                      // Section: Documents
                      Focus(
                        focusNode: _focusNodes['Documents'],
                        child: _buildSectionTitle(Icons.description_outlined, 'Documents'),
                      ),
                      const SizedBox(height: 16),
                      _buildResponsiveRow(isMobile, [
                        _buildFileUploadField('Upload Your Passport size photo *', isMobile),
                        _buildFileUploadField('Upload Community Certificate', isMobile),
                        if (!isMobile) const SizedBox.shrink(),
                        if (!isMobile) const SizedBox.shrink(),
                      ]),
                      
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Note: File Size should be below 2MB. (JPG, JPEG, PNG only)',
                          style: TextStyle(color: Colors.grey[600], fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Agreement and Register
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Checkbox(
                            value: _isAgreed,
                            onChanged: (v) => setState(() => _isAgreed = v ?? false),
                            activeColor: mediumBrown,
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => setState(() => _isAgreed = !_isAgreed),
                              child: Text(AppLocalizations.of(context)?.iAgreeToThe ?? 'I agree to the ', style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()));
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(AppLocalizations.of(context)?.termsAndConditionsTitle ?? 'Terms and Conditions', style: const TextStyle(decoration: TextDecoration.underline, fontSize: 13, color: mediumBrown, fontWeight: FontWeight.bold)),
                          ),
                          Text(AppLocalizations.of(context)?.andText ?? ' and ', style: const TextStyle(fontSize: 13)),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()));
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(AppLocalizations.of(context)?.privacyPolicy ?? 'Privacy Policy', style: const TextStyle(decoration: TextDecoration.underline, fontSize: 13, color: mediumBrown, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isAgreed ? _handleRegister : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mediumBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(AppLocalizations.of(context)?.registerBtn ?? 'Register', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Future<void> _handleClose() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Discard Changes?'),
        content: const Text('Are you sure you want to close this form? Any unsaved data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildExitButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleClose,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.close, color: primaryBrown, size: 20),
        ),
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
      else if (title == 'Family Details') translatedTitle = loc.familyDetails ?? title;
      else if (title == 'Documents') translatedTitle = loc.documents ?? title;
      else if (title == 'Terms and Conditions') translatedTitle = loc.termsAndConditionsTitle ?? title;
    }
    return Container(
      padding: const EdgeInsets.only(left: 0, bottom: 8),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accentGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: primaryBrown, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              translatedTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryBrown,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .where((c) => c is! Spacer)
            .map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c))
            .toList(),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((c) {
          if (c is Spacer) return c;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: c,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool isMobile, {String? hint, FocusNode? focusNode, TextInputType? keyboardType, bool readOnly = false, int? maxLength, Key? fieldKey, AutovalidateMode? autovalidateMode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label),
        const SizedBox(height: 6),
        TextFormField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          readOnly: readOnly,
          maxLength: maxLength,
          autovalidateMode: autovalidateMode ?? AutovalidateMode.onUserInteraction,
          inputFormatters: (keyboardType == TextInputType.phone || keyboardType == TextInputType.number)
              ? [FilteringTextInputFormatter.digitsOnly]
              : (((label.contains('Name') || label.contains('Thottam') || label.contains('Valuvu')) && !label.contains('Street') && !label.contains('Village')) ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.]'))] : null),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF333333)),
          validator: (value) {
            final val = value ?? '';
            if (label.contains('Name') && !label.contains('Street') && !label.contains('Village')) {
              if (val.trim().isEmpty && _showMandatoryErrors) return 'Please fill this field';
              if (val.trim().isNotEmpty && val.trim().length < 3) return 'Name must be at least 3 characters';
              if (val.trim().isNotEmpty && !RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(val.trim())) return 'Only letters, spaces, and dots allowed';
            }
            if ((label.contains('Thottam') || label.contains('Valuvu')) && val.trim().isNotEmpty) {
              if (!RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(val.trim())) return 'Only letters, spaces, and dots allowed';
            }
            if ((label.contains('Education') || label.contains('Profession') || label.contains('District') || label.contains('Taluk') || label.contains('Panchayat') || label.contains('Village')) && val.trim().isNotEmpty) {
              if (!RegExp(r'[a-zA-Z]').hasMatch(val.trim())) return 'Must contain at least one letter';
            }
            if (label.contains('Phone')) {
              if (val.isEmpty) return _showMandatoryErrors ? 'Please fill this field' : null;
              if (val.length < 10) return 'Phone number should contain 10 digits.';
              if (_phoneExists) return 'Phone number already exist.';
            }
            if ((label.toLowerCase().contains('pin code') || label.toLowerCase().contains('zip')) && val.isNotEmpty) {
              if (!RegExp(r'^[0-9]+$').hasMatch(val)) return 'Only numbers allowed';
              if (int.tryParse(val) == 0) return 'Invalid PIN code';
            }
            if (label.contains('*') && val.trim().isEmpty && _showMandatoryErrors) {
              return 'Please fill this field';
            }
            if (label.contains('Street Name') && val.trim().isNotEmpty) {
              if (RegExp(r'^[^a-zA-Z0-9]+$').hasMatch(val.trim())) return 'Please enter a valid address';
            }
            if ((label.contains('Manual') || label.contains('Enter')) && val.trim().isNotEmpty) {
              if (RegExp(r'^[^a-zA-Z0-9]+$').hasMatch(val.trim())) return 'Please enter a valid name';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint ?? '',
            counterText: "", // Hide character counter
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            fillColor: Colors.white.withOpacity(0.9),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: mediumBrown, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildIntlPhoneField(String label, TextEditingController controller, bool isMobile, {String? hint, FocusNode? focusNode, Key? fieldKey}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label),
        const SizedBox(height: 6),
        CustomPhoneField(
          fieldKey: fieldKey,
          label: '', // Label is already built above in this method, so pass empty or skip
          controller: controller,
          focusNode: focusNode,
          hint: hint,
          validator: (value) {
            final val = controller.text;
            if (val.isEmpty) return _showMandatoryErrors ? 'Please fill this field' : null;
            if (_phoneExists) return 'Phone number already exist.';
            return null;
          },
          initialCountryCode: _phoneCountryCode,
          onCountryChanged: (c) {
            setState(() {
              _phoneCountryCode = c.code;
              _phoneCountryDialCode = '+${c.dialCode}';
              _phoneController.clear();
              if (_whatsappSameAsPhone) {
                _whatsappCountryCode = c.code;
                _whatsappCountryDialCode = '+${c.dialCode}';
                _whatsappController.clear();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller, bool isMobile, {FocusNode? focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: true,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF333333)),
          validator: (value) {
            if (label.contains('*') && (value == null || value.isEmpty) && _showMandatoryErrors) {
              return 'Please select date';
            }
            if (value != null && value.isNotEmpty) {
              try {
                final parts = value.split('-');
                if (parts.length == 3) {
                  final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  if (!date.isBefore(today)) {
                    return 'Date of Birth must be a past date';
                  }
                }
              } catch (e) {
                // ignore
              }
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'dd-mm-yyyy',
            suffixIcon: const Icon(Icons.calendar_today, size: 18, color: mediumBrown),
            fillColor: Colors.white.withOpacity(0.9),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: mediumBrown, width: 1.5)),
          ),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              setState(() {
                String day = pickedDate.day.toString().padLeft(2, '0');
                String month = pickedDate.month.toString().padLeft(2, '0');
                controller.text = "$day-$month-${pickedDate.year}";
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildGenderSelector(bool isMobile, {FocusNode? focusNode}) {
    return Focus(
      focusNode: focusNode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelText('Gender *'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildRadioOption('Male'),
              _buildRadioOption('Female'),
              _buildRadioOption('Others'),
            ],
          ),
          if (_selectedGender == null && _showMandatoryErrors)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text('Please select an option', style: TextStyle(color: Colors.red[700], fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: label, 
              groupValue: _selectedGender, 
              onChanged: (v) => setState(() => _selectedGender = v),
              activeColor: primaryBrown,
            ),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> options, bool isMobile, {String? value, ValueChanged<String?>? onChanged, FocusNode? focusNode}) {
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
      validator: (val) {
        if (label.contains('*') && (val == null || val.isEmpty) && _showMandatoryErrors) {
          return 'Please select an option';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField(bool isMobile, {FocusNode? focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText('Email'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          focusNode: focusNode,
          validator: (value) {
            final val = value ?? '';
            if (val.isEmpty) return null;
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return 'Invalid email';
            return null;
          },
          maxLength: 100,
          decoration: InputDecoration(
            counterText: "",
            hintText: 'Email address',
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            fillColor: Colors.white.withOpacity(0.9),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: mediumBrown, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsAppField(bool isMobile, {FocusNode? focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildLabelText('WhatsApp Number *'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _whatsappSameAsPhone, 
                    onChanged: (v) => setState(() {
                      _whatsappSameAsPhone = v!;
                      if (_whatsappSameAsPhone) {
                        _whatsappController.text = _phoneController.text;
                        _whatsappCountryCode = _phoneCountryCode;
                        _whatsappCountryDialCode = _phoneCountryDialCode;
                      }
                    }), 
                    activeColor: primaryBrown
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Same as Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 2),
        CustomPhoneField(
          label: '', // Handled above
          controller: _whatsappController,
          focusNode: focusNode,
          initialCountryCode: _whatsappCountryCode,
          onCountryChanged: (c) {
            setState(() {
              _whatsappCountryCode = c.code;
              _whatsappCountryDialCode = '+${c.dialCode}';
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

  Widget _buildRadioField(String label, List<String> options, bool isMobile, {String? value, ValueChanged<String?>? onChanged, FocusNode? focusNode}) {
    return Focus(
      focusNode: focusNode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelText(label),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: options.map((o) => MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onChanged?.call(o),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: o,
                      groupValue: value,
                      onChanged: onChanged,
                      activeColor: primaryBrown,
                    ),
                      Builder(
                        builder: (context) {
                          String display = o;
                          final loc = AppLocalizations.of(context);
                          if (loc != null) {
                            if (o == 'Male') display = loc.maleLabel ?? o;
                            else if (o == 'Female') display = loc.femaleLabel ?? o;
                            else if (o == 'Others' || o == 'Other') display = loc.otherLabel ?? o;
                            else if (o == 'Yes') display = loc.yesLabel ?? o;
                            else if (o == 'No') display = loc.noLabel ?? o;
                            else if (o == 'Alive') display = loc.aliveLabel ?? o;
                            else if (o == 'Dead') display = loc.deadLabel ?? o;
                            else if (o == 'Tamil Nadu') display = loc.tamilNaduLabel ?? o;
                            else if (o == 'Other State') display = loc.otherStateLabel ?? o;
                            else if (o == 'NRI') display = loc.nriLabel ?? o;
                          }
                          return Text(display, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500));
                        }
                      ),
                  ],
                ),
              ),
            )).toList(),
          ),
          if (label.contains('*') && (value == null || value.isEmpty) && _showMandatoryErrors)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text('Please select an option', style: TextStyle(color: Colors.red[700], fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildFileUploadField(String label, bool isMobile) {
    XFile? selectedFile;
    if (label.contains('Passport')) selectedFile = _memberImage;
    else if (label.contains('Community')) selectedFile = _communityCert;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText(label),
        const SizedBox(height: 6),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () async {
              final result = await fp_pkg.FilePicker.pickFiles(
                type: fp_pkg.FileType.custom,
                allowedExtensions: ['jpg', 'jpeg', 'png'],
              );
              if (result != null && (result.files.single.path != null || result.files.single.bytes != null)) {
                final file = result.files.single;
                if (file.size > 2 * 1024 * 1024) {
                  if (mounted) showStatusDialog(context, title: 'Validation Error', message: 'Maximum allowed file size is 2 MB.', type: DialogType.error);
                  return;
                }
                setState(() {
                  final xFile = file.path != null ? XFile(file.path!, name: file.name) : XFile.fromData(file.bytes!, name: file.name);
                  if (label.contains('Passport')) _memberImage = xFile;
                  else if (label.contains('Community')) _communityCert = xFile;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selectedFile != null ? accentGold : borderColor, width: 1.5),
                boxShadow: selectedFile != null ? [
                  BoxShadow(color: accentGold.withOpacity(0.1), blurRadius: 4, spreadRadius: 1)
                ] : null,
              ),
              child: Row(
                children: [
                  Icon(selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined, 
                    size: 20, color: selectedFile != null ? accentGold : Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(child: Text(selectedFile != null ? selectedFile.name : 'Choose file...', 
                    style: TextStyle(
                      color: selectedFile != null ? Colors.black87 : Colors.grey[600], 
                      fontSize: 13, 
                      fontWeight: selectedFile != null ? FontWeight.w500 : FontWeight.normal,
                      overflow: TextOverflow.ellipsis
                    ))),
                ],
              ),
            ),
          ),
        ),
        if (label.contains('*') && selectedFile == null && _showMandatoryErrors)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text('Please select a file', style: TextStyle(color: Colors.red[700], fontSize: 11)),
          ),
      ],
    );
  }

  Widget _buildTextArea(String label, TextEditingController controller, bool isMobile, {FocusNode? focusNode}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelText(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 4,
            decoration: InputDecoration(
              fillColor: Colors.white.withOpacity(0.9),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: mediumBrown, width: 1.5)),
            ),
          ),
        ],
      ),
    );
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
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: const Color(0xFF333333)),
      );
    }
    return Text(translatedLabel, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: const Color(0xFF333333)));
  }
}

