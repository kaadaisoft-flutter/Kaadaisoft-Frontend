import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart' as fp_pkg;
import 'package:cross_file/cross_file.dart';
import '../widgets/custom_dropdown_search.dart';
import '../widgets/custom_phone_field.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';

class UpdateDetailsContent extends StatefulWidget {
  final dynamic userId;
  final int userRole;
  final Map<String, dynamic> userData;
  final VoidCallback onBack;
  final String? title;
  const UpdateDetailsContent({super.key, required this.userId, required this.userRole, required this.userData, required this.onBack, this.title});

  @override
  State<UpdateDetailsContent> createState() => _UpdateDetailsContentState();
}

class _UpdateDetailsContentState extends State<UpdateDetailsContent> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _whatsappSameAsPhone = false;

  // Controllers
  TextEditingController _nameCtrl = TextEditingController();
  TextEditingController _phoneCtrl = TextEditingController();
  TextEditingController _whatsappCtrl = TextEditingController();
  TextEditingController _emailCtrl = TextEditingController();
  TextEditingController _dobCtrl = TextEditingController();
  TextEditingController _valuvuCtrl = TextEditingController();
  TextEditingController _thottamCtrl = TextEditingController();
  TextEditingController _streetCtrl = TextEditingController();
  TextEditingController _doorNoCtrl = TextEditingController();
  TextEditingController _pincodeCtrl = TextEditingController();
  TextEditingController _professionCtrl = TextEditingController();

  
  // Current Address Controllers
  TextEditingController _curStreetCtrl = TextEditingController();
  TextEditingController _curDoorNoCtrl = TextEditingController();
  TextEditingController _curPincodeCtrl = TextEditingController();
  TextEditingController _curTalukCtrl = TextEditingController();
  TextEditingController _curPanchayatCtrl = TextEditingController();
  TextEditingController _curVillageCtrl = TextEditingController();
  TextEditingController _nriZipCtrl = TextEditingController();
  TextEditingController _nriFullAddressCtrl = TextEditingController();
  TextEditingController _nriCountryCtrl = TextEditingController();
  TextEditingController _nriStateCtrl = TextEditingController();
  TextEditingController _nriCityCtrl = TextEditingController();


  String? _relationship;
  String? _gender;
  String? _bloodGroup;
  String? _married;
  String? _aliveStatus;
  String? _kulam;
  String? _district;
  String? _taluk;
  String? _panchayat;
  String? _village;
  
  // Current Address State
  String? _curAddressType; // TamilNadu, OtherState, NRI
  String? _curState;
  String? _curDistrict;
  String? _nriCountry;
  String? _nriState;
  String? _nriCity;

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

  // Documents
  dynamic _memberImage;
  dynamic _communityCert;
  
  bool _isConfirmed = false;
  
  String? _education;
  String? _profession;

  static const Color _darkBrown = const Color(0xFF322E2E);
  static const Color _gold = const Color(0xFFC5A028);

  final List<String> _relationships = ['Head','Grand Father','Grand Mother','Father','Mother','Husband','Wife','Son','Daughter','Son-in-law','Daughter-in-law','Brother','Sister','Other'];
  final List<String> _bloodGroups = ['A+','A-','B+','B-','O+','O-','AB+','AB-'];
  final List<String> _kulams = ['Poondurai Kaadai', 'Aanthuvan Kulam', 'Azhagu Kulam', 'Aathe Kulam', 'Aanthai Kulam', 'Aadar Kulam', 'Aavan Kulam', 'Eenjan Kulam', 'Ozukkar Kulam', 'Oothaalar Kulam', 'Kannakkan Kulam', 'Kannan Kulam', 'Kannaanthai Kulam', 'Kaadai Kulam', 'Kaari Kulam', 'Keeran Kulam', 'Kuzhlaayan Kulam', 'Koorai Kulam', 'Koovendhar Kulam', 'Saathanthai Kulam', 'Sellan Kulam', 'Semban Kulam', 'Sengkannan Kulam', 'Sembuthan Kulam', 'Senkunnier Kulam', 'Sevvaayar Kulam', 'Cheran Kulam', 'Chedan Kulam', 'Dananjayan Kulam', 'Thazhinji Kulam', 'Thooran Kulam', 'Devendran Kulam', 'Thoodar Kulam', 'Neerunniyar Kulam', 'Pavazhalar Kulam', 'Panayan Kulam', 'Pathuman Kulam', 'Payiran Kulam', 'Panagkaadar Kulam', 'Pathariar Kulam', 'Pandiyan Kulam', 'Pillar Kulam', 'Poosan Kulam', 'Poochanthai Kulam', 'Periyan Kulam', 'Perunkudiyaan Kulam', 'Porulaanthai Kulam', 'Ponnar Kulam', 'Maniyan Kulam', 'Mayilar Kulam', 'Maadar Kulam', 'Mutthan Kulam', 'Muzhukathan Kulam', 'Medhi Kulam', 'Vannakkan Kulam', 'Villiyar Kulam', 'Vilayan Kulam', 'Vizhiyar Kulam', 'Venduvan Kulam', 'Vennag Kulam', 'Vellampar Kulam', 'Others'];
  final List<String> _educations = ['SSLC', 'HSC', 'Diploma', 'ITI', 'B.A', 'B.Sc', 'B.Com', 'BBA', 'BCA', 'B.E', 'B.Tech', 'MBBS', 'BDS', 'B.Pharm', 'B.Ed', 'LLB', 'B.Arch', 'M.A', 'M.Sc', 'M.Com', 'MBA', 'MCA', 'M.E', 'M.Tech', 'MD', 'MS', 'MDS', 'M.Pharm', 'M.Ed', 'LLM', 'M.Phil', 'Ph.D', 'Others'];
  final List<String> _professions = ['Doctor', 'Lawyer', 'Police', 'Teacher / Lecturer', 'Engineer', 'Government Employee', 'Private Employee', 'Student', 'Farmer – Agriculture', 'Textile Mill Worker (Spinning / Weaving)', 'Garment Factory Worker', 'Tailor / Apparel Stitching', 'Garment Pattern Master / Designer', 'Textile Machinery Technician / Mechanic', 'Textile Machinery Sales & Service', 'Powerloom / Auto‑Loom Operator', 'Knitting Machine Operator', 'Truck / Lorry Driver', 'Truck / Lorry Owner‑cum‑Driver', 'Logistics / Transport Staff', 'Fleet Manager', 'Dairy Farmer', 'Poultry Farmer', 'Goat / Sheep Rearing', 'Pump / Motor Technician', 'Pump / Motor Manufacturing Worker', 'Motor Rewinding Technician', 'Machinist / Turner', 'Welder / Fabricator', 'Steel / Aluminium Foundry Worker', 'Mixer‑Grinder Assembly / Service Technician', 'Plastic / Net / Packaging Unit Worker', 'Windmill Maintenance Technician', 'Electrical Line / Maintenance Technician', 'Grocery Shop Staff', 'Medical Shop / Pharmacy Staff', 'Retail Shop / Sales Staff', 'Office Admin / Computer Operator', 'Accountant / Finance Staff', 'Bank / NBFC Staff', 'Hospital Nurse / Lab Tech / Pharmacist', 'Medical Representative', 'IT / Software Employee', 'Home Maker', 'Retired', 'Others'];

  @override
  void initState() {
    super.initState();
    _loadGeoData();
    final d = widget.userData;
    _nameCtrl = TextEditingController(text: d['Name'] ?? '');
    _phoneCtrl = TextEditingController(text: d['Phonenumber']?.toString() ?? '');
    _whatsappCtrl = TextEditingController(text: d['Whatsappnumber']?.toString() ?? '');
    if (_whatsappCtrl.text.isNotEmpty && _whatsappCtrl.text == _phoneCtrl.text) {
      _whatsappSameAsPhone = true;
    }
    _emailCtrl = TextEditingController(text: d['Email'] ?? '');
    _dobCtrl = TextEditingController(text: d['Dob'] ?? '');
    _valuvuCtrl = TextEditingController(text: d['Valuvu'] ?? '');
    _thottamCtrl = TextEditingController(text: d['Thottam'] ?? '');
    final street = d['Street'] ?? '';
    final doorNo = d['Doornumber'] ?? '';
    _streetCtrl = TextEditingController(text: doorNo.isNotEmpty ? "$doorNo, $street" : street);
    _pincodeCtrl = TextEditingController(text: d['Pincode']?.toString() ?? '');
    _professionCtrl = TextEditingController(text: d['Profession'] ?? '');


    // Current Address
    final curStreet = d['Curstreet'] ?? '';
    final curDoorNo = d['Curdoorno'] ?? '';
    _curStreetCtrl = TextEditingController(text: curDoorNo.isNotEmpty ? "$curDoorNo, $curStreet" : curStreet);
    _curPincodeCtrl = TextEditingController(text: d['Curpincode']?.toString() ?? '');
    _curTalukCtrl = TextEditingController(text: d['Curtaluk'] ?? '');
    _curPanchayatCtrl = TextEditingController(text: d['Curpanchayat'] ?? '');
    _curVillageCtrl = TextEditingController(text: d['Curvillage'] ?? '');
    _nriZipCtrl = TextEditingController(text: d['Curnrizip']?.toString() ?? '');
    _nriFullAddressCtrl = TextEditingController(text: d['Curnrifulladdress'] ?? '');
    _nriCountryCtrl = TextEditingController(text: d['Curnricountry'] ?? '');
    _nriStateCtrl = TextEditingController(text: d['Curnristate'] ?? '');
    _nriCityCtrl = TextEditingController(text: d['Curnricity'] ?? '');


    _relationship = d['MemberRole'];
    _gender = d['Gender'];
    _bloodGroup = d['Bloodgroup'];
    _married = d['Married'];
    _aliveStatus = (d['is_dead'] == 0 || d['is_dead'] == '0' || d['is_dead'] == null) ? 'Alive' : 'Dead';
    _kulam = d['Kulam'] ?? 'Poondurai Kaadai';
    _district = d['District'];
    _taluk = d['Taluk'];
    _panchayat = d['Panchayat'];
    _village = d['Village'];

    _education = d['Education'];
    _profession = d['Profession'];
    _curAddressType = d['Curaddresstype'];
    _curState = d['Curstate'];
    _curDistrict = d['Curdistrict'];
    _nriCountry = d['Curnricountry'];
    _nriState = d['Curnristate'];
    _nriCity = d['Curnricity'];

    _fetchDistricts();
    if (_curAddressType == 'TamilNadu') {
       _fetchCurrDistricts();
       if (d['Curdistrict'] != null) {
          _fetchCurrTaluks(d['Curdistrict']);
          if (d['Curtaluk'] != null) {
             _fetchCurrPanchayats(d['Curtaluk']);
             if (d['Curpanchayat'] != null) {
                _fetchCurrVillages(d['Curpanchayat']);
             }
          }
       }
    }
    if (_curAddressType == 'OtherState' || _curAddressType == 'NRI') {
       // Wait for geo data to load before updating states/cities?
       // Actually _loadGeoData is async. 
    }
  }

  Future<void> _loadGeoData() async {
    try {
      final String response = await rootBundle.loadString('assets/countries_states_cities.json');
      final data = json.decode(response);
      setState(() {
        _allCountriesData = data;
        _countryNames = _allCountriesData.map((c) => c['name'].toString()).toList();
        
        // If NRI or Other State, populate states/cities
        if (_curAddressType == 'OtherState' && _curState != null) {
           _updateStates('India', resetSelection: false);
           if (_curDistrict != null) _updateCities('India', _curState!, resetSelection: false);
        } else if (_curAddressType == 'NRI' && _nriCountry != null) {
           _updateStates(_nriCountry!, resetSelection: false);
           if (_nriState != null) _updateCities(_nriCountry!, _nriState!, resetSelection: false);
        }
      });
    } catch (_) {}
  }

  void _updateStates(String countryName, {bool resetSelection = true}) {
    final country = _allCountriesData.firstWhere((c) => c['name'] == countryName, orElse: () => null);
    setState(() {
      _stateNames = country != null ? (country['states'] as List).map((s) => s['name'].toString()).toList() : [];
      if (resetSelection) {
        _curState = null;
        _nriState = null;
        _cityNames = [];
        _curDistrict = null;
        _nriCity = null;
      }
    });
  }

  void _updateCities(String countryName, String stateName, {bool resetSelection = true}) {
    final country = _allCountriesData.firstWhere((c) => c['name'] == countryName, orElse: () => null);
    if (country != null) {
      final state = (country['states'] as List).firstWhere((s) => s['name'] == stateName, orElse: () => null);
      setState(() {
        _cityNames = state != null ? (state['cities'] as List).map((c) => c['name'].toString()).toList() : [];
        if (resetSelection) {
          _curDistrict = null;
          _nriCity = null;
        }
      });
    }
  }

  @override
  void dispose() {
    final ctrls = [
      _nameCtrl, _phoneCtrl, _whatsappCtrl, _emailCtrl, _dobCtrl, 
      _valuvuCtrl, _thottamCtrl, _streetCtrl, 
      _doorNoCtrl, _pincodeCtrl, _professionCtrl, 
      _curStreetCtrl, _curDoorNoCtrl, _curPincodeCtrl, 
      _curTalukCtrl, _curPanchayatCtrl, _curVillageCtrl, _nriZipCtrl, 
      _nriFullAddressCtrl, _nriCountryCtrl, _nriStateCtrl, _nriCityCtrl
    ];
    for (final c in ctrls) { c.dispose(); }
    super.dispose();
  }

  Future<void> _fetchDistricts() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _districts = List<String>.from(data['data']));
        if (_district != null) _fetchTaluks(_district!);
      }
    } catch (_) {}
  }

  Future<void> _fetchTaluks(String district) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _taluks = List<String>.from(data['data']));
        if (_taluk != null) _fetchPanchayats(_taluk!);
      }
    } catch (_) {}
  }

  Future<void> _fetchPanchayats(String taluk) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _panchayats = List<String>.from(data['data']));
        if (_panchayat != null) _fetchVillages(_panchayat!);
      }
    } catch (_) {}
  }

  Future<void> _fetchVillages(String panchayat) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _villages = List<String>.from(data['data']));
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrDistricts() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/districts'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _currDistricts = List<String>.from(data['data']));
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrTaluks(String district) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/taluks/$district'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _currTaluks = List<String>.from(data['data']));
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrPanchayats(String taluk) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/panchayats/$taluk'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _currPanchayats = List<String>.from(data['data']));
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrVillages(String panchayat) async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/villages/$panchayat'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _currVillages = List<String>.from(data['data']));
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.updateMember));
      
      // Basic Fields
      request.fields['user_id'] = widget.userId.toString();
      request.fields['role'] = widget.userRole.toString();
      request.fields['name'] = _nameCtrl.text.trim();
      request.fields['phone'] = _phoneCtrl.text.trim();
      request.fields['whatsapp'] = _whatsappCtrl.text.trim();
      request.fields['email'] = _emailCtrl.text.trim();
      request.fields['dob'] = _dobCtrl.text.trim();
      request.fields['gender'] = _gender ?? '';
      request.fields['blood_group'] = _bloodGroup ?? '';
      request.fields['married'] = _married ?? '';
      request.fields['alive_status'] = _aliveStatus ?? 'Alive';
      request.fields['relationship'] = _relationship ?? '';
      request.fields['valuvu'] = _valuvuCtrl.text.trim();
      request.fields['thottam'] = _thottamCtrl.text.trim();
      request.fields['kulam'] = _kulam ?? '';
      
      // Career
      request.fields['education'] = _education ?? '';
      request.fields['profession'] = _profession ?? '';
      request.fields['business'] = '';
      request.fields['business_website'] = '';

      
      // Native Address
      String fullStreet = _streetCtrl.text.trim();
      String doorNo = '';
      String streetName = fullStreet;
      if (fullStreet.contains(',')) {
        int commaIndex = fullStreet.indexOf(',');
        doorNo = fullStreet.substring(0, commaIndex).trim();
        streetName = fullStreet.substring(commaIndex + 1).trim();
      }
      request.fields['district'] = _district ?? '';
      request.fields['taluk'] = _taluk ?? '';
      request.fields['panchayat'] = _panchayat ?? '';
      request.fields['village'] = _village ?? '';
      request.fields['street'] = streetName;
      request.fields['door_no'] = doorNo;
      request.fields['pincode'] = _pincodeCtrl.text.trim();
      
      // Current Address
      String fullCurStreet = _curStreetCtrl.text.trim();
      String curDoorNo = '';
      String curStreetName = fullCurStreet;
      if (fullCurStreet.contains(',')) {
        int commaIndex = fullCurStreet.indexOf(',');
        curDoorNo = fullCurStreet.substring(0, commaIndex).trim();
        curStreetName = fullCurStreet.substring(commaIndex + 1).trim();
      }
      request.fields['cur_address_type'] = _curAddressType ?? '';
      
      if (_curAddressType == 'TamilNadu') {
        request.fields['cur_state'] = '';
        request.fields['cur_district'] = _curDistrict ?? '';
        request.fields['cur_taluk'] = _curTalukCtrl.text.trim();
        request.fields['cur_panchayat'] = _curPanchayatCtrl.text.trim();
        request.fields['cur_village'] = _curVillageCtrl.text.trim();
        request.fields['cur_street'] = curStreetName;
        request.fields['cur_door_no'] = curDoorNo;
        request.fields['cur_pincode'] = _curPincodeCtrl.text.trim();
        request.fields['nri_country'] = '';
        request.fields['nri_state'] = '';
        request.fields['nri_city'] = '';
        request.fields['nri_zip'] = '';
        request.fields['nri_full_address'] = '';
      } else if (_curAddressType == 'OtherState') {
        request.fields['cur_state'] = _curState ?? '';
        request.fields['cur_district'] = _curDistrict ?? '';
        request.fields['cur_taluk'] = '';
        request.fields['cur_panchayat'] = '';
        request.fields['cur_village'] = '';
        request.fields['cur_street'] = curStreetName;
        request.fields['cur_door_no'] = curDoorNo;
        request.fields['cur_pincode'] = _curPincodeCtrl.text.trim();
        request.fields['nri_country'] = '';
        request.fields['nri_state'] = '';
        request.fields['nri_city'] = '';
        request.fields['nri_zip'] = '';
        request.fields['nri_full_address'] = '';
      } else if (_curAddressType == 'NRI') {
        request.fields['cur_state'] = '';
        request.fields['cur_district'] = '';
        request.fields['cur_taluk'] = '';
        request.fields['cur_panchayat'] = '';
        request.fields['cur_village'] = '';
        request.fields['cur_street'] = '';
        request.fields['cur_door_no'] = '';
        request.fields['cur_pincode'] = '';
        request.fields['nri_country'] = _nriCountryCtrl.text.trim();
        request.fields['nri_state'] = _nriStateCtrl.text.trim();
        request.fields['nri_city'] = _nriCityCtrl.text.trim();
        request.fields['nri_zip'] = _nriZipCtrl.text.trim();
        request.fields['nri_full_address'] = _nriFullAddressCtrl.text.trim();
      } else {
        request.fields['cur_state'] = _curState ?? '';
        request.fields['cur_district'] = _curDistrict ?? '';
        request.fields['cur_taluk'] = _curTalukCtrl.text.trim();
        request.fields['cur_panchayat'] = _curPanchayatCtrl.text.trim();
        request.fields['cur_village'] = _curVillageCtrl.text.trim();
        request.fields['cur_street'] = curStreetName;
        request.fields['cur_door_no'] = curDoorNo;
        request.fields['cur_pincode'] = _curPincodeCtrl.text.trim();
        request.fields['nri_country'] = _nriCountryCtrl.text.trim();
        request.fields['nri_state'] = _nriStateCtrl.text.trim();
        request.fields['nri_city'] = _nriCityCtrl.text.trim();
        request.fields['nri_zip'] = _nriZipCtrl.text.trim();
        request.fields['nri_full_address'] = _nriFullAddressCtrl.text.trim();
      }

      // Files helper for Web/Mobile
      Future<void> addFile(String field, dynamic file) async {
        if (file is XFile) {
          if (kIsWeb) {
            request.files.add(http.MultipartFile.fromBytes(field, await file.readAsBytes(), filename: file.name));
          } else {
            request.files.add(await http.MultipartFile.fromPath(field, file.path));
          }
        }
      }

      await addFile('member_image', _memberImage);
      await addFile('member_image', _memberImage);
      await addFile('community_cert', _communityCert);

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      if (mounted) {
        if (res.statusCode == 200) {
          String successMsg = widget.userRole != 3 
              ? 'Details updated and verified successfully.' 
              : 'Details updated successfully and sent for approval.';
          showStatusDialog(
            context,
            title: 'Success',
            message: successMsg,
            type: DialogType.success,
            onOk: widget.onBack,
          );
        } else {
          final err = jsonDecode(res.body)['detail'] ?? 'Update failed';
          showStatusDialog(
            context,
            title: 'Error',
            message: err,
            type: DialogType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showStatusDialog(
          context,
          title: 'Connection Error',
          message: 'Unable to communicate with the server.',
          type: DialogType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.account_circle, color: _darkBrown, size: 28),
                      const SizedBox(width: 12),
                      Text(widget.title ?? 'Update My Details: ', style: const TextStyle(color: _darkBrown, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(widget.userData['Familymembershipid'] ?? '', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: _darkBrown, size: 20),
                    onPressed: widget.onBack,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Basic Details', Icons.person_outline),
                  _buildBasicSection(isMobile),
                  const SizedBox(height: 24),
                  _sectionTitle('Education & Career Details', Icons.work_outline),
                  _buildEducationSection(isMobile),
                  const SizedBox(height: 24),
                  _sectionTitle('Native Address', Icons.home_outlined),
                  _buildAddressSection(isMobile),
                  const SizedBox(height: 24),
                  _sectionTitle('Current Address', Icons.location_on_outlined),
                  _buildCurrentAddressSection(isMobile),
                  const SizedBox(height: 24),
                  _sectionTitle('Documents', Icons.description_outlined),
                  _buildDocumentsSection(isMobile),
                  const SizedBox(height: 32),

                  // Confirmation Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _isConfirmed,
                        onChanged: (v) => setState(() => _isConfirmed = v!),
                        activeColor: _darkBrown,
                      ),
                      const Expanded(
                        child: Text('I confirm that the above details are correct.', 
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _darkBrown)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Center(
                    child: SizedBox(
                      width: 250,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving || !_isConfirmed ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkBrown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isSaving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text('UPDATE DETAILS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Icon(icon, size: 20, color: _darkBrown),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkBrown))),
      ]),
    );
  }

  Widget _buildBasicSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        // Row 1: Relationship, Name, Phone
        _row(isMobile, [
          _dropField('Relationship *', _relationships, _relationship, (v) => setState(() => _relationship = v)),
          _textField('Name *', _nameCtrl, required: true),
          _intlPhoneField('Phone Number *', _phoneCtrl, required: true),
        ]),
        const SizedBox(height: 24),
        // Row 2: DOB, Gender, Blood Group
        _row(isMobile, [
          _dateField('Date Of Birth *', _dobCtrl),
          _radioField('Gender *', ['Male', 'Female', 'Other'], _gender, (v) => setState(() => _gender = v)),
          _dropField('Blood Group *', _bloodGroups, _bloodGroup, (v) => setState(() => _bloodGroup = v)),
        ]),
        const SizedBox(height: 24),
        // Row 3: Blood Group, Email, Whatsapp
        _row(isMobile, [
          _textField('Email', _emailCtrl, inputType: TextInputType.emailAddress),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('WhatsApp Number *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown)),
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
                            if (v) _whatsappCtrl.text = _phoneCtrl.text;
                          }),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Same as Phone', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              CustomPhoneField(
                label: '',
                controller: _whatsappCtrl,
                validator: (v) {
                  return null;
                },
              ),
            ],
          ),
          _radioField('Married *', ['Yes', 'No'], _married, (v) => setState(() => _married = v)),
        ]),
        const SizedBox(height: 24),
        // Row 4: Married, Alive, Valuvu
        _row(isMobile, [
          _radioField('Alive Status', ['Alive', 'Dead'], _aliveStatus ?? 'Alive', (v) => setState(() => _aliveStatus = v)),
          _textField('Valuvu', _valuvuCtrl),
          _textField('Thottam', _thottamCtrl),
        ]),
        const SizedBox(height: 24),
        // Row 5: Thottam, Kulam, Exist Family ID
        _row(isMobile, [
          _dropField('Kulam *', _kulams, _kulam, (v) => setState(() => _kulam = v)),
          if (!isMobile) const Expanded(child: SizedBox()),
          if (!isMobile) const Expanded(child: SizedBox()),
        ]),
      ]),
    );
  }

  Widget _buildEducationSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        _row(isMobile, [
          _dropField('Education *', _educations, _education, (v) => setState(() => _education = v)),
          _dropField('Profession *', _professions, _profession, (v) => setState(() => _profession = v)),
        ]),

      ]),
    );
  }

  Widget _buildCurrentAddressSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        isMobile 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _radioField('Current Address Type *', ['Tamil Nadu', 'Other State', 'NRI'], _curAddressType == 'TamilNadu' ? 'Tamil Nadu' : (_curAddressType == 'OtherState' ? 'Other State' : (_curAddressType == 'NRI' ? 'NRI' : null)), (v) {
                  setState(() {
                    if (v == 'Tamil Nadu') {
                       _curAddressType = 'TamilNadu';
                       _fetchCurrDistricts();
                    } else if (v == 'Other State') {
                       _curAddressType = 'OtherState';
                       _updateStates('India');
                    } else if (v == 'NRI') {
                       _curAddressType = 'NRI';
                    }
                    _curDistrict = null;
                    _curTalukCtrl.clear();
                    _curPanchayatCtrl.clear();
                    _curVillageCtrl.clear();
                    _curState = null;
                    _nriCountry = null;
                    _nriState = null;
                    _nriCity = null;
                  });
                }),
                if (_curAddressType == 'TamilNadu') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _curDistrict = _district;
                          _curTalukCtrl.text = _taluk ?? '';
                          _curPanchayatCtrl.text = _panchayat ?? '';
                          _curVillageCtrl.text = _village ?? '';
                          _curStreetCtrl.text = _streetCtrl.text;
                          _curPincodeCtrl.text = _pincodeCtrl.text;
                        });
                        if (_district != null) {
                          await _fetchCurrTaluks(_district!);
                          if (_taluk != null) {
                            await _fetchCurrPanchayats(_taluk!);
                            if (_panchayat != null) await _fetchCurrVillages(_panchayat!);
                          }
                        }
                      },
                      icon: const Icon(Icons.copy, size: 16, color: _darkBrown),
                      label: const Text('Same as Native', style: TextStyle(color: _darkBrown, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _radioField('Current Address Type *', ['Tamil Nadu', 'Other State', 'NRI'], _curAddressType == 'TamilNadu' ? 'Tamil Nadu' : (_curAddressType == 'OtherState' ? 'Other State' : (_curAddressType == 'NRI' ? 'NRI' : null)), (v) {
                  setState(() {
                    if (v == 'Tamil Nadu') {
                       _curAddressType = 'TamilNadu';
                       _fetchCurrDistricts();
                    } else if (v == 'Other State') {
                       _curAddressType = 'OtherState';
                       _updateStates('India');
                    } else if (v == 'NRI') {
                       _curAddressType = 'NRI';
                    }
                    _curDistrict = null;
                    _curTalukCtrl.clear();
                    _curPanchayatCtrl.clear();
                    _curVillageCtrl.clear();
                    _curState = null;
                    _nriCountry = null;
                    _nriState = null;
                    _nriCity = null;
                  });
                }),
                if (_curAddressType == 'TamilNadu')
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _curDistrict = _district;
                          _curTalukCtrl.text = _taluk ?? '';
                          _curPanchayatCtrl.text = _panchayat ?? '';
                          _curVillageCtrl.text = _village ?? '';
                          _curStreetCtrl.text = _streetCtrl.text;
                          _curPincodeCtrl.text = _pincodeCtrl.text;
                        });
                        if (_district != null) {
                          await _fetchCurrTaluks(_district!);
                          if (_taluk != null) {
                            await _fetchCurrPanchayats(_taluk!);
                            if (_panchayat != null) await _fetchCurrVillages(_panchayat!);
                          }
                        }
                      },
                      icon: const Icon(Icons.copy, size: 16, color: _darkBrown),
                      label: const Text('Same as Native', style: TextStyle(color: _darkBrown, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
              ],
            ),
        const SizedBox(height: 24),
        
        if (_curAddressType == 'TamilNadu') ...[
           _row(isMobile, [
            _dropField('District *', _currDistricts, _curDistrict, (v) { setState(() { _curDistrict = v; _curTalukCtrl.clear(); _curPanchayatCtrl.clear(); _curVillageCtrl.clear(); _currTaluks = []; _currPanchayats = []; _currVillages = []; }); if (v != null) _fetchCurrTaluks(v); }),
            _dropField('Taluk *', _currTaluks, _curTalukCtrl.text, (v) { setState(() { _curTalukCtrl.text = v ?? ''; _curPanchayatCtrl.clear(); _curVillageCtrl.clear(); _currPanchayats = []; _currVillages = []; }); if (v != null) _fetchCurrPanchayats(v); }),
            _dropField('Panchayat *', _currPanchayats, _curPanchayatCtrl.text, (v) { setState(() { _curPanchayatCtrl.text = v ?? ''; _curVillageCtrl.clear(); _currVillages = []; }); if (v != null) _fetchCurrVillages(v); }),
          ]),
          const SizedBox(height: 24),
          _row(isMobile, [
            _dropField('Village *', _currVillages, _curVillageCtrl.text, (v) => setState(() => _curVillageCtrl.text = v ?? '')),
            _textField('Door No & Street Name *', _curStreetCtrl, required: true),
            _textField('Pin Code *', _curPincodeCtrl, inputType: TextInputType.number, required: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]),
          ]),
        ] else if (_curAddressType == 'OtherState') ...[
          _row(isMobile, [
            _dropField('State *', _stateNames, _curState, (v) {
              setState(() => _curState = v);
              if (v != null) _updateCities('India', v);
            }),
            _dropField('City *', _cityNames, _curDistrict, (v) => setState(() => _curDistrict = v)),
            _textField('Zip / Postal Code *', _curPincodeCtrl, required: true),
          ]),
          const SizedBox(height: 24),
          _textField('Door No & Street Name *', _curStreetCtrl, required: true),
          const SizedBox(height: 24),
          _textField('Full Address *', _nriFullAddressCtrl, required: true, maxLines: 3),
        ] else if (_curAddressType == 'NRI') ...[
          _row(isMobile, [
            _dropField('Country *', _countryNames, _nriCountry, (v) {
              setState(() => _nriCountry = v);
              if (v != null) _updateStates(v);
            }),
            _dropField('State *', _stateNames, _nriState, (v) {
              setState(() => _nriState = v);
              if (v != null && _nriCountry != null) _updateCities(_nriCountry!, v);
            }),
            _dropField('City *', _cityNames, _nriCity, (v) => setState(() => _nriCity = v)),
          ]),
          const SizedBox(height: 24),
          _row(isMobile, [
            _textField('Zip / Postal Code *', _nriZipCtrl, required: true),
            _textField('Door No & Street Name *', _curStreetCtrl, required: true),
          ]),
          const SizedBox(height: 24),
          _textField('Full Address *', _nriFullAddressCtrl, required: true, maxLines: 3),
        ],
      ]),
    );
  }

  Widget _buildDocumentsSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        _row(isMobile, [
          _fileUploadField('Passport Photo', _memberImage, (file) => setState(() => _memberImage = file)),
          _fileUploadField('Community Certificate', _communityCert, (file) => setState(() => _communityCert = file)),
        ]),
      ]),
    );
  }

  Widget _fileUploadField(String label, dynamic file, ValueChanged<dynamic> onPicked) {
    String fileName = 'Choose file...';
    if (file != null) {
       if (file is String) {
         fileName = file.split('/').last;
       } else if (file is XFile) {
         fileName = file.name;
       }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label),
      const SizedBox(height: 8),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _pickFile(onPicked),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.upload_file, size: 18, color: _gold),
                const SizedBox(width: 8),
                Expanded(child: Text(fileName, style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  Future<void> _pickFile(ValueChanged<dynamic> onPicked) async {
    try {
      final result = await fp_pkg.FilePicker.pickFiles(
        type: fp_pkg.FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true, // Crucial for Web
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        if (kIsWeb) {
          if (file.bytes != null) {
            onPicked(XFile.fromData(file.bytes!, name: file.name));
          }
        } else {
          if (file.path != null) {
            onPicked(XFile(file.path!, name: file.name));
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Widget _buildAddressSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        _row(isMobile, [
          _dropField('District *', _districts, _district, (v) { setState(() { _district = v; _taluk = null; _panchayat = null; _village = null; _taluks = []; _panchayats = []; _villages = []; }); if (v != null) _fetchTaluks(v); }),
          _dropField('Taluk *', _taluks, _taluk, (v) { setState(() { _taluk = v; _panchayat = null; _village = null; _panchayats = []; _villages = []; }); if (v != null) _fetchPanchayats(v); }),
          _dropField('Panchayat *', _panchayats, _panchayat, (v) { setState(() { _panchayat = v; _village = null; _villages = []; }); if (v != null) _fetchVillages(v); }),
        ]),
        _row(isMobile, [
          _dropField('Village *', _villages, _village, (v) => setState(() => _village = v)),
          _textField('Door No & Street Name *', _streetCtrl),
          _textField('Pin Code *', _pincodeCtrl, inputType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]),
        ]),
      ]),
    );
  }

  Widget _row(bool isMobile, List<Widget> children) {
    if (isMobile) {
      return Column(children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w is Expanded ? w.child : w)).toList());
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.asMap().entries.map((entry) {
        final i = entry.key;
        final w = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < children.length - 1 ? 16 : 0),
            child: w is Expanded ? w.child : w,
          ),
        );
      }).toList(),
    );
  }

  Widget _textField(String label, TextEditingController ctrl, {TextInputType? inputType, bool required = false, List<TextInputFormatter>? inputFormatters, Widget? suffix, int maxLines = 1, int? maxLength}) {
    List<TextInputFormatter>? formatters = inputFormatters;
    if (label.contains('Name') && !label.contains('Street') && !label.contains('Village')) {
      formatters = (formatters?.toList() ?? [])..add(FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.]')));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        keyboardType: inputType,
        inputFormatters: formatters,
        maxLines: maxLines,
        maxLength: maxLength ?? 254,
        decoration: InputDecoration(
          counterText: "",
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _darkBrown)),
          filled: true, fillColor: Colors.white,
          isDense: true,
          suffixIcon: suffix,
        ),
        validator: (v) {
          final val = v ?? '';
          if (label.contains('Name') && !label.contains('Street') && !label.contains('Village')) {
            if (required && val.trim().isEmpty) return 'Required';
            if (val.trim().isNotEmpty && val.trim().length < 3) return 'Name must be at least 3 characters';
            if (val.trim().isNotEmpty && !RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(val.trim())) return 'Only letters, spaces, and dots allowed';
          }
          if (required && val.isEmpty) return 'Required';
          return null;
        },
      ),
    ]);
  }

  Widget _intlPhoneField(String label, TextEditingController ctrl, {bool required = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label),
      const SizedBox(height: 8),
      CustomPhoneField(
        label: '',
        controller: ctrl,
        validator: (v) {
          final val = ctrl.text;
          if (required && val.isEmpty) return 'Required';
          return null;
        },
      ),
    ]);
  }

  Widget _dropField(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    String? matchedValue = value;
    if (value != null && value.isNotEmpty) {
      final valTrimmed = value.trim().toLowerCase();
      try {
        matchedValue = items.firstWhere((item) => item.trim().toLowerCase() == valTrimmed);
      } catch (_) {
        matchedValue = value;
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label),
      const SizedBox(height: 8),
      CustomDropdownSearch(
        label: '',
        dropdownItems: items,
        value: matchedValue,
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _dateField(String label, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        readOnly: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _darkBrown)),
          filled: true, fillColor: Colors.white, isDense: true,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: _darkBrown),
        ),
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
          if (picked != null) ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
        },
      ),
    ]);
  }

  Widget _radioField(String label, List<String> options, String? value, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabelText(label),
      const SizedBox(height: 8),
      Wrap(
        children: options.map((o) => Row(mainAxisSize: MainAxisSize.min, children: [
          Radio<String>(value: o, groupValue: value, onChanged: onChanged, activeColor: _darkBrown, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          Text(o, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _darkBrown)),
          const SizedBox(width: 8),
        ])).toList(),
      ),
    ]);
  }
  Widget _buildLabelText(String label) {
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
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown),
      );
    }
    return Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown));
  }
}
