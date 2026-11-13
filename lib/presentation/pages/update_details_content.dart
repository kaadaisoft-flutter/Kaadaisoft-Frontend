import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;

import 'package:file_picker/file_picker.dart' as fp_pkg;

import 'package:cross_file/cross_file.dart';

import 'package:intl_phone_field/countries.dart';

import 'dart:io';

import '../../l10n/app_localizations.dart';

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

  final ScrollController _scrollController = ScrollController();

  bool _isSaving = false;

  bool _whatsappSameAsPhone = false;

  bool _isPrivilege = false;

  String? _privilegeId;
  String? _nextPrivilegeId;



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



  late TextEditingController _otherRelationshipCtrl;

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

  

  String _phoneCountryCode = 'IN';

  String _whatsappCountryCode = 'IN';

  

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

  bool _isProfilePublished = false;

  String? _publishOption; // 'Yes' or 'No'

  final TextEditingController _specializationCtrl = TextEditingController();

  final TextEditingController _qualificationsCtrl = TextEditingController();

  final TextEditingController _workplaceCtrl = TextEditingController();

  final TextEditingController _experienceCtrl = TextEditingController();

  final TextEditingController _bioSummaryCtrl = TextEditingController();

  final TextEditingController _publishCommentsCtrl = TextEditingController();



  String _initialStateHash = '';

  

  String _getFormStateHash() {

    return [
      _isPrivilege.toString(),

      _nameCtrl.text.trim(), _phoneCtrl.text.trim(), _whatsappCtrl.text.trim(),

      _phoneCountryCode, _whatsappCountryCode, _emailCtrl.text.trim(),

      _dobCtrl.text.trim(), _valuvuCtrl.text.trim(), _thottamCtrl.text.trim(),

      _streetCtrl.text.trim(), _pincodeCtrl.text.trim(), _professionCtrl.text.trim(),

      _curStreetCtrl.text.trim(), _curPincodeCtrl.text.trim(), _curTalukCtrl.text.trim(),

      _curPanchayatCtrl.text.trim(), _curVillageCtrl.text.trim(), _nriZipCtrl.text.trim(),

      _nriFullAddressCtrl.text.trim(), _nriCountryCtrl.text.trim(), _nriStateCtrl.text.trim(),

      _nriCityCtrl.text.trim(), _relationship == 'Other' ? _otherRelationshipCtrl.text.trim() : (_relationship ?? ''), _gender ?? '', _bloodGroup ?? '',

      _married ?? '', _aliveStatus ?? '', _kulam ?? '', _district ?? '', _taluk ?? '',

      _panchayat ?? '', _village ?? '', _education ?? '', _profession ?? '', _isProfilePublished.toString(),

      _publishOption ?? '', _specializationCtrl.text.trim(), _qualificationsCtrl.text.trim(), _workplaceCtrl.text.trim(),

      _experienceCtrl.text.trim(), _bioSummaryCtrl.text.trim(), _publishCommentsCtrl.text.trim(),

      _curAddressType ?? '', _curState ?? '', _curDistrict ?? '', _nriCountry ?? '',

      _nriState ?? '', _nriCity ?? '',

      _memberImage is XFile ? 'new_${(_memberImage as XFile).name}' : (_memberImage?.toString() ?? 'no_img'),

      _communityCert is XFile ? 'new_${(_communityCert as XFile).name}' : (_communityCert?.toString() ?? 'no_cert'),

    ].join('|');

  }



  bool _hasChanges() {

    return _initialStateHash.isNotEmpty && _getFormStateHash() != _initialStateHash;

  }



  static const Color _darkBrown = const Color(0xFF322E2E);

  static const Color _gold = const Color(0xFFC5A028);



  final List<String> _relationships = ['Head','Grand Father','Grand Mother','Father','Mother','Husband','Wife','Son','Daughter','Son-in-law','Daughter-in-law','Brother','Sister','Other'];

  final List<String> _bloodGroups = ['A+','A-','B+','B-','O+','O-','AB+','AB-'];

  final List<String> _kulams = ['Poondurai Kaadai', 'Aanthuvan Kulam', 'Azhagu Kulam', 'Aathe Kulam', 'Aanthai Kulam', 'Aadar Kulam', 'Aavan Kulam', 'Eenjan Kulam', 'Ozukkar Kulam', 'Oothaalar Kulam', 'Kannakkan Kulam', 'Kannan Kulam', 'Kannaanthai Kulam', 'Kaadai Kulam', 'Kaari Kulam', 'Keeran Kulam', 'Kuzhlaayan Kulam', 'Koorai Kulam', 'Koovendhar Kulam', 'Saathanthai Kulam', 'Sellan Kulam', 'Semban Kulam', 'Sembuthan Kulam', 'Senkannan Kulam', 'Senkannier Kulam', 'Sevvaayar Kulam', 'Cheran Kulam', 'Chedan Kulam', 'Dananjayan Kulam', 'Thazhinji Kulam', 'Thooran Kulam', 'Devendran Kulam', 'Thoodar Kulam', 'Neerunniyar Kulam', 'Pavazhalar Kulam', 'Panayan Kulam', 'Pathuman Kulam', 'Payiran Kulam', 'Panagkaadar Kulam', 'Pathariar Kulam', 'Pandiyan Kulam', 'Pillar Kulam', 'Poosan Kulam', 'Poochanthai Kulam', 'Periyan Kulam', 'Perunkudiyaan Kulam', 'Porulaanthai Kulam', 'Ponnar Kulam', 'Maniyan Kulam', 'Mayilar Kulam', 'Maadar Kulam', 'Mutthan Kulam', 'Muzhukathan Kulam', 'Medhi Kulam', 'Vannakkan Kulam', 'Villiyar Kulam', 'Vilayan Kulam', 'Vizhiyar Kulam', 'Venduvan Kulam', 'Vennag Kulam', 'Vellampar Kulam', 'Others'];

  final List<String> _educations = ['SSLC', 'HSC', 'Diploma', 'ITI', 'B.A', 'B.Sc', 'B.Com', 'BBA', 'BCA', 'B.E', 'B.Tech', 'MBBS', 'BDS', 'B.Pharm', 'B.Ed', 'LLB', 'B.Arch', 'M.A', 'M.Sc', 'M.Com', 'MBA', 'MCA', 'M.E', 'M.Tech', 'MD', 'MS', 'MDS', 'M.Pharm', 'M.Ed', 'LLM', 'M.Phil', 'Ph.D', 'Others'];

  final List<String> _professions = ['Doctor', 'Lawyer', 'Police', 'Teacher / Lecturer', 'Engineer', 'Government Employee', 'Private Employee', 'Student', 'Farmer – Agriculture', 'Textile Mill Worker (Spinning / Weaving)', 'Garment Factory Worker', 'Tailor / Apparel Stitching', 'Garment Pattern Master / Designer', 'Textile Machinery Technician / Mechanic', 'Textile Machinery Sales & Service', 'Powerloom / Auto‑Loom Operator', 'Knitting Machine Operator', 'Truck / Lorry Driver', 'Truck / Lorry Owner‑cum‑Driver', 'Logistics / Transport Staff', 'Fleet Manager', 'Dairy Farmer', 'Poultry Farmer', 'Goat / Sheep Rearing', 'Pump / Motor Technician', 'Pump / Motor Manufacturing Worker', 'Motor Rewinding Technician', 'Machinist / Turner', 'Welder / Fabricator', 'Steel / Aluminium Foundry Worker', 'Mixer‑Grinder Assembly / Service Technician', 'Plastic / Net / Packaging Unit Worker', 'Windmill Maintenance Technician', 'Electrical Line / Maintenance Technician', 'Grocery Shop Staff', 'Medical Shop / Pharmacy Staff', 'Retail Shop / Sales Staff', 'Office Admin / Computer Operator', 'Accountant / Finance Staff', 'Bank / NBFC Staff', 'Hospital Nurse / Lab Tech / Pharmacist', 'Medical Representative', 'IT / Software Employee', 'Home Maker', 'Retired', 'Others'];



  String? _getProfessionForEducation(String? edu) {

    if (edu == null) return null;

    final e = edu.trim();

    if (['MBBS', 'BDS', 'MD', 'MS', 'MDS'].contains(e)) return 'Doctor';

    if (['LLB', 'LLM'].contains(e)) return 'Lawyer';

    if (['B.Ed', 'M.Ed'].contains(e)) return 'Teacher / Lecturer';

    if (['B.E', 'B.Tech', 'M.E', 'M.Tech', 'B.Arch'].contains(e)) return 'Engineer';

    if (['B.Pharm', 'M.Pharm'].contains(e)) return 'Hospital Nurse / Lab Tech / Pharmacist';

    return null;

  }



  List<String> _getFilteredProfessions(String? education) {

    final edu = education?.trim() ?? '';

    final isMedical = ['MBBS', 'BDS', 'MD', 'MS', 'MDS'].contains(edu);

    final isLaw = ['LLB', 'LLM'].contains(edu);

    

    return _professions.where((p) {

      if (p == 'Doctor' && !isMedical) return false;

      if (p == 'Lawyer' && !isLaw) return false;

      return true;

    }).toList();

  }



  @override

  void initState() {

    super.initState();

    _loadGeoData();

    Map<String, dynamic> d = widget.userData;

    if (d.containsKey('data') && d['data'] is Map<String, dynamic>) {

      d = Map<String, dynamic>.from(d['data']);

    } else if (d.containsKey('user') && d['user'] is Map<String, dynamic>) {

      d = Map<String, dynamic>.from(d['user']);

    } else if (d.containsKey('member') && d['member'] is Map<String, dynamic>) {

      d = Map<String, dynamic>.from(d['member']);

    }

    _isPrivilege = d['is_privilege'] == true || d['is_privilege'] == 1 || d['is_privilege']?.toString().toLowerCase() == 'true';

    _privilegeId = d['privilege_id']?.toString();

    _nameCtrl = TextEditingController(text: d['Name'] ?? '');

    _phoneCtrl = TextEditingController(text: d['Phonenumber']?.toString() ?? '');

    _whatsappCtrl = TextEditingController(text: d['Whatsappnumber']?.toString() ?? '');

    if (_whatsappCtrl.text.isNotEmpty && _whatsappCtrl.text == _phoneCtrl.text) {

      _whatsappSameAsPhone = true;

    }

    _emailCtrl = TextEditingController(text: d['Email'] ?? '');

    

    final mDial = d['mobile_country_code']?.toString();

    if (mDial != null && mDial.isNotEmpty) {

      final cleanDial = mDial.replaceAll('+', '');

      try {

        final c = countries.firstWhere((element) => element.dialCode == cleanDial);

        _phoneCountryCode = c.code;

      } catch (_) {}

    }

    

    final wDial = d['whatsapp_country_code']?.toString();

    if (wDial != null && wDial.isNotEmpty) {

      final cleanDial = wDial.replaceAll('+', '');

      try {

        final c = countries.firstWhere((element) => element.dialCode == cleanDial);

        _whatsappCountryCode = c.code;

      } catch (_) {}

    }



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

    if (_relationship != null && !_relationships.contains(_relationship)) {

      _otherRelationshipCtrl = TextEditingController(text: _relationship);

      _relationship = 'Other';

    } else {

      _otherRelationshipCtrl = TextEditingController();

    }

    String? rawGender = d['Gender']?.toString().trim();

    if (rawGender != null && rawGender.isNotEmpty) {

      if (rawGender.toLowerCase() == 'female') _gender = 'Female';

      else if (rawGender.toLowerCase() == 'male') _gender = 'Male';

      else if (rawGender.toLowerCase() == 'other') _gender = 'Other';

      else _gender = rawGender;

    }



    if (['Wife', 'Daughter', 'Mother', 'Grand Mother', 'Daughter-in-law', 'Sister'].contains(_relationship)) {

      _gender = 'Female';

    } else if (['Husband', 'Son', 'Father', 'Grand Father', 'Son-in-law', 'Brother'].contains(_relationship)) {

      _gender = 'Male';

    }

    _bloodGroup = d['Bloodgroup'];

    final rawMarried = d['Married']?.toString().trim().toLowerCase();

    if (rawMarried == 'yes') {

      _married = 'Yes';

    } else if (rawMarried == 'no') {

      _married = 'No';

    } else {

      _married = null;

    }



    if (['Wife', 'Husband', 'Father', 'Mother', 'Grand Father', 'Grand Mother', 'Daughter-in-law', 'Son-in-law'].contains(_relationship)) {

      _married = 'Yes';

    }

    final rawKulam = (d['Kulam']?.toString() ?? '').trim();

    String normalizedKulam = rawKulam;

    if (normalizedKulam == 'Sengkannan Kulam') normalizedKulam = 'Senkannan Kulam';

    if (normalizedKulam == 'Senkunnier Kulam') normalizedKulam = 'Senkannier Kulam';

    _kulam = _kulams.contains(normalizedKulam) ? normalizedKulam : 'Poondurai Kaadai';

    _district = d['District'];

    _taluk = d['Taluk'];

    _panchayat = d['Panchayat'];

    _village = d['Village'];



    _education = d['Education'];

    _profession = d['Profession'];

    if ((_profession == null || _profession!.isEmpty) && _education != null) {

      _profession = _getProfessionForEducation(_education);

    }

    final rawPub = d['is_profile_published'] ?? d['profile_published'] ?? d['IsProfilePublished'] ?? d['ProfilePublished'];

    _isProfilePublished = (rawPub == true || rawPub == 1 || rawPub == '1' || rawPub.toString().toLowerCase() == 'true');

    _publishOption = _isProfilePublished ? 'Yes' : 'No';

    _publishCommentsCtrl.text = (d['profile_publish_comments'] ?? d['ProfilePublishComments'] ?? '').toString();

    _specializationCtrl.text = (d['specialization'] ?? d['Specialization'] ?? '').toString();

    _workplaceCtrl.text = (d['workplace'] ?? d['Workplace'] ?? '').toString();

    _experienceCtrl.text = (d['experience_years'] ?? d['ExperienceYears'] ?? '').toString();

    _bioSummaryCtrl.text = (d['bio_summary'] ?? d['BioSummary'] ?? '').toString();

    _qualificationsCtrl.text = (d['qualifications'] ?? d['Qualifications'] ?? d['Education'] ?? '').toString();

    _curAddressType = d['Curaddresstype'];

    _curState = d['Curstate'];

    _curDistrict = d['Curdistrict'];

    _nriCountry = d['Curnricountry'];

    _nriState = d['Curnristate'];

    _nriCity = d['Curnricity'];



    final rawImg = d['Memberimage'] ?? d['member_image'] ?? d['memberimage'] ?? d['passport_photo'] ?? d['ProfilePhoto'];

    if (rawImg != null && rawImg.toString().isNotEmpty && rawImg.toString() != 'null' && rawImg.toString() != 'None') {

      _memberImage = rawImg.toString();

    } else {

      _memberImage = null;

    }



    final rawCert = d['Communitycertificate'] ?? d['Communitycertificateimage'] ?? d['community_cert'] ?? d['community_certificate'] ?? d['communitycertificate'];

    if (rawCert != null && rawCert.toString().isNotEmpty && rawCert.toString() != 'null' && rawCert.toString() != 'None') {

      _communityCert = rawCert.toString();

    } else {

      _communityCert = null;

    }



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

    _initialStateHash = _getFormStateHash();

  }



  Future<void> _fetchNextPrivilegeId() async {
    try {
      final res = await http.get(Uri.parse('/api/next-privilege-id'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['next_privilege_id'] != null && mounted) {
          setState(() {
            _nextPrivilegeId = body['next_privilege_id'].toString();
          });
        }
      }
    } catch (_) {}
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

    _scrollController.dispose();

    final ctrls = [

      _nameCtrl, _phoneCtrl, _whatsappCtrl, _emailCtrl, _dobCtrl, 

      _valuvuCtrl, _thottamCtrl, _streetCtrl, 

      _doorNoCtrl, _pincodeCtrl, _professionCtrl, 

      _curStreetCtrl, _curDoorNoCtrl, _curPincodeCtrl, 

      _curTalukCtrl, _curPanchayatCtrl, _curVillageCtrl, _nriZipCtrl, 

      _nriFullAddressCtrl, _nriCountryCtrl, _nriStateCtrl, _nriCityCtrl,

      _otherRelationshipCtrl,

      _specializationCtrl, _qualificationsCtrl, _workplaceCtrl,

      _experienceCtrl, _bioSummaryCtrl, _publishCommentsCtrl,

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

    if (!_formKey.currentState!.validate()) {

      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

      return;

    }

    setState(() => _isSaving = true);

    try {

      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.updateMember));

      

      // Basic Fields

      request.fields['user_id'] = widget.userId.toString();

      request.fields['role'] = widget.userRole.toString();

      request.fields['is_privilege'] = _isPrivilege.toString();

      request.fields['name'] = _nameCtrl.text.trim();

      request.fields['phone'] = _phoneCtrl.text.trim();

      request.fields['whatsapp'] = _whatsappCtrl.text.trim();

      

      final phoneCountry = countries.firstWhere((c) => c.code == _phoneCountryCode, orElse: () => countries.firstWhere((c) => c.code == 'IN'));

      request.fields['mobile_country_code'] = '+${phoneCountry.dialCode}';

      

      final whatsappCountry = countries.firstWhere((c) => c.code == _whatsappCountryCode, orElse: () => countries.firstWhere((c) => c.code == 'IN'));

      request.fields['whatsapp_country_code'] = '+${whatsappCountry.dialCode}';



      request.fields['email'] = _emailCtrl.text.trim();

      request.fields['dob'] = _dobCtrl.text.trim();

      request.fields['gender'] = _gender ?? '';

      request.fields['blood_group'] = _bloodGroup ?? '';

      request.fields['married'] = _married ?? '';

      request.fields['alive_status'] = _aliveStatus ?? 'Alive';

      request.fields['relationship'] = _relationship == 'Other' ? _otherRelationshipCtrl.text.trim() : (_relationship ?? '');

      request.fields['valuvu'] = _valuvuCtrl.text.trim();

      request.fields['thottam'] = _thottamCtrl.text.trim();

      request.fields['kulam'] = _kulam ?? '';

      

      // Career

      request.fields['education'] = _education ?? '';

      request.fields['profession'] = _profession ?? '';

      final bool canPublish = _profession == 'Doctor' || _profession == 'Lawyer';

      final bool isPub = canPublish && _publishOption == 'Yes';

      request.fields['is_profile_published'] = isPub.toString();

      request.fields['profile_publish_comments'] = (!isPub) ? _publishCommentsCtrl.text.trim() : '';

      if (isPub) {

        request.fields['specialization'] = _specializationCtrl.text.trim();

        request.fields['qualifications'] = _qualificationsCtrl.text.trim().isNotEmpty 

            ? _qualificationsCtrl.text.trim() 

            : (_education ?? '');

        request.fields['workplace'] = _workplaceCtrl.text.trim();

        request.fields['experience_years'] = _experienceCtrl.text.trim();

        request.fields['bio_summary'] = _bioSummaryCtrl.text.trim();

      }

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



    return ClipRRect(

      borderRadius: BorderRadius.circular(16),

      child: Container(

        color: Colors.white,

        child: Column(

          children: [

              // Header

              Container(

                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),

                decoration: const BoxDecoration(

                  color: Colors.white,

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

                      Text(widget.title?.contains('Member Details') == true ? (AppLocalizations.of(context)?.updateMemberDetailsTitle ?? 'Update Member Details: ') : (AppLocalizations.of(context)?.updateMyDetailsTitle ?? 'Update My Details: '), style: const TextStyle(color: _darkBrown, fontWeight: FontWeight.bold, fontSize: 18)),

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



          Expanded(

            child: SingleChildScrollView(

              controller: _scrollController,

              physics: const BouncingScrollPhysics(),

              child: Padding(

                padding: const EdgeInsets.all(24),

            child: Form(

              key: _formKey,

              onChanged: () {

                setState(() {});

              },

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  if (widget.userRole == 1) ...[

                    _buildMembershipTypeSection(isMobile),

                    const SizedBox(height: 24),

                  ],

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

                      Expanded(

                        child: Text(AppLocalizations.of(context)?.confirmDetailsCorrect ?? 'I confirm that the above details are correct.', 

                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _darkBrown)),

                      ),

                    ],

                  ),

                  const SizedBox(height: 32),



                  Center(

                    child: SizedBox(

                      width: 250,

                      height: 50,

                      child: ElevatedButton(

                        onPressed: _isSaving || !_isConfirmed || (widget.userRole != 1 && !_hasChanges()) ? null : _submit,

                        style: ElevatedButton.styleFrom(

                          backgroundColor: _darkBrown,

                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                          elevation: 2,

                        ),

                        child: _isSaving 

                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 

                          : Text(AppLocalizations.of(context)?.saveDetailsBtn ?? 'Save Details', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5)),

                      ),

                    ),

                  ),

                ],

              ),

            ),

          ),

        ),

      ),

      ],

      ),

      ),

    );

  }



  Widget _sectionTitle(String title, IconData icon) {
    final bool hasAsterisk = title.contains('*');
    final String cleanTitle = title.replaceAll('*', '').trim();
    String translatedTitle = cleanTitle;
    final loc = AppLocalizations.of(context);
    if (loc != null) {
      if (cleanTitle == 'Basic Details') translatedTitle = loc.basicDetails ?? cleanTitle;
      else if (cleanTitle == 'Education & Career Details') translatedTitle = loc.educationCareerDetails ?? cleanTitle;
      else if (cleanTitle == 'Native Address') translatedTitle = loc.nativeAddress ?? cleanTitle;
      else if (cleanTitle == 'Current Address') translatedTitle = loc.currentAddress ?? cleanTitle;
      else if (cleanTitle == 'Documents') translatedTitle = loc.documents ?? cleanTitle;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Icon(icon, size: 20, color: _darkBrown),
        const SizedBox(width: 8),
        Expanded(
          child: hasAsterisk
              ? Text.rich(
                  TextSpan(
                    text: '$translatedTitle ',
                    children: const [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkBrown),
                )
              : Text(translatedTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkBrown)),
        ),
      ]),
    );
  }

  Widget _buildBasicSection(bool isMobile) {

    return Container(

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),

      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Row 1: Relationship, Name, Phone

        _row(isMobile, [

          Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              _dropField('Relationship *', _relationships, _relationship, (v) {

                setState(() {

                  _relationship = v;

                  if (['Wife', 'Daughter', 'Mother', 'Grand Mother', 'Daughter-in-law', 'Sister'].contains(v)) {

                    _gender = 'Female';

                  } else if (['Husband', 'Son', 'Father', 'Grand Father', 'Son-in-law', 'Brother'].contains(v)) {

                    _gender = 'Male';

                  }

                  if (['Wife', 'Husband', 'Father', 'Mother', 'Grand Father', 'Grand Mother', 'Daughter-in-law', 'Son-in-law'].contains(v)) {

                    _married = 'Yes';

                  }

                });

              }),

              if (_relationship == 'Other') ...[

                const SizedBox(height: 16),

                _textField('Specify Relationship *', _otherRelationshipCtrl, required: true),

              ]

            ],

          ),

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

                            if (v) {

                              _whatsappCtrl.text = _phoneCtrl.text;

                              _whatsappCountryCode = _phoneCountryCode;

                            }

                          }),

                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),

                        ),

                      ),

                      const SizedBox(width: 6),

                      Text(AppLocalizations.of(context)?.sameAsPhone ?? 'Same as Phone', style: const TextStyle(fontSize: 10)),

                    ],

                  ),

                ],

              ),

              CustomPhoneField(

                label: '',

                controller: _whatsappCtrl,

                initialCountryCode: _whatsappCountryCode,

                onCountryChanged: (c) {

                  setState(() {

                    _whatsappCountryCode = c.code;

                    _whatsappCtrl.clear();

                  });

                },

                validator: (v) {

                  return null;

                },

              ),

            ],

          ),

          _radioField('Married *', ['Yes', 'No'], _married, (v) {

            bool isMarriedLocked = ['Wife', 'Husband', 'Father', 'Mother', 'Grand Father', 'Grand Mother', 'Daughter-in-law', 'Son-in-law'].contains(_relationship);

            if (v == 'No' && isMarriedLocked) {

              showStatusDialog(

                context,

                title: 'Married Status Locked',

                message: 'Married status is automatically set to Yes for relationship "$_relationship".',

                type: DialogType.info,

              );

              setState(() => _married = 'Yes');

            } else {

              setState(() => _married = v);

            }

          }),

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

    final bool isEligibleForDirectory = _profession == 'Doctor' || _profession == 'Lawyer';

    final bool isTamil = Localizations.localeOf(context).languageCode == 'ta';



    return Container(

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey.shade200),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          _row(isMobile, [

            _dropField('Education *', _educations, _education, (v) {

              setState(() {

                _education = v;

                final mapped = _getProfessionForEducation(v);

                if (mapped != null) {

                  _profession = mapped;

                  if (_profession != 'Doctor' && _profession != 'Lawyer') {

                    _isProfilePublished = false;

                    _publishOption = 'No';

                  }

                } else {

                  final isMedical = ['MBBS', 'BDS', 'MD', 'MS', 'MDS'].contains(v?.trim());

                  final isLaw = ['LLB', 'LLM'].contains(v?.trim());

                  if (_profession == 'Doctor' && !isMedical) {

                    _profession = null;

                    _isProfilePublished = false;

                    _publishOption = 'No';

                  } else if (_profession == 'Lawyer' && !isLaw) {

                    _profession = null;

                    _isProfilePublished = false;

                    _publishOption = 'No';

                  }

                }

                if (v != null) {

                  if (_qualificationsCtrl.text.trim().isEmpty || _educations.contains(_qualificationsCtrl.text.trim())) {

                    _qualificationsCtrl.text = v;

                  }

                }

              });

            }),

            _dropField('Profession *', _getFilteredProfessions(_education), _profession, (v) {

              setState(() {

                _profession = v;

                if (_profession != 'Doctor' && _profession != 'Lawyer') {

                  _isProfilePublished = false;

                  _publishOption = 'No';

                }

              });

            }),

          ]),

          if (isEligibleForDirectory) ...[

            const SizedBox(height: 20),

            // 1. Directory Publish Dropdown (Yes / No)

            _row(isMobile, [

              _dropField(

                isTamil

                    ? 'சுயவிவரத்தை சமூக அடைவில் வெளியிடவா? *'

                    : 'Publish Profile in Directory? *',

                ['Yes', 'No'],

                _publishOption,

                (v) {

                  setState(() {

                    _publishOption = v;

                    _isProfilePublished = (v == 'Yes');

                  });

                },

              ),

              if (!isMobile) const Expanded(child: SizedBox()),

            ]),

            const SizedBox(height: 16),



            // 2. When YES: Show detailed Doctor / Lawyer form

            if (_publishOption == 'Yes') ...[

              Container(

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(

                  color: const Color(0xFFFEF3C7).withOpacity(0.3),

                  borderRadius: BorderRadius.circular(14),

                  border: Border.all(color: const Color(0xFFC49A3C).withOpacity(0.55), width: 1.2),

                ),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Row(

                      children: [

                        Container(

                          padding: const EdgeInsets.all(8),

                          decoration: BoxDecoration(

                            color: const Color(0xFF5D1712).withOpacity(0.1),

                            borderRadius: BorderRadius.circular(8),

                          ),

                          child: Icon(

                            _profession == 'Doctor' ? Icons.medical_services_outlined : Icons.gavel_outlined,

                            size: 22,

                            color: const Color(0xFF5D1712),

                          ),

                        ),

                        const SizedBox(width: 12),

                        Expanded(

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Text(

                                _profession == 'Doctor'

                                    ? (isTamil

                                        ? 'மருத்துவர் அடைவு விவரங்கள் ("உயிர் காக்கும் கரங்கள்")'

                                        : 'Doctor Directory Profile Details ("Uyir Kaakkum Karangal")')

                                    : (isTamil

                                        ? 'வழக்கறிஞர் அடைவு விவரங்கள் ("நீதியின் குரல்")'

                                        : 'Lawyer Directory Profile Details ("Neethiyin Kural")'),

                                style: const TextStyle(

                                  fontSize: 15,

                                  fontWeight: FontWeight.bold,

                                  color: Color(0xFF5D1712),

                                ),

                              ),

                              const SizedBox(height: 3),

                              Text(

                                isTamil

                                    ? 'கீழே உள்ள விவரங்களை நிரப்பினால் சமூக மக்கள் உங்களை எளிதில் தொடர்புகொள்ள முடியும்.'

                                    : 'Please provide professional details so community members can connect with you.',

                                style: TextStyle(

                                  fontSize: 12,

                                  color: Colors.grey.shade700,

                                ),

                              ),

                            ],

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 20),

                    // Row 1: Specialization & Experience

                    _row(isMobile, [

                      _textField(

                        _profession == 'Doctor'

                            ? (isTamil ? 'சிறப்பு மருத்துவத் துறை (Specialization) *' : 'Medical Specialization *')

                            : (isTamil ? 'சட்டப் பயிற்சித் துறை (Specialization) *' : 'Legal Practice Area *'),

                        _specializationCtrl,

                        required: true,

                        maxLength: 150,

                      ),

                      _textField(

                        isTamil ? 'அனுபவம் (ஆண்டுகள்)' : 'Experience (Years)',

                        _experienceCtrl,

                        inputType: TextInputType.number,

                        inputFormatters: [

                          FilteringTextInputFormatter.digitsOnly,

                          LengthLimitingTextInputFormatter(2),

                        ],

                      ),

                    ]),

                    const SizedBox(height: 18),

                    // Row 2: Qualifications & Current Workplace

                    _row(isMobile, [

                      _textField(

                        isTamil ? 'கல்வித் தகுதிகள் (Qualifications) *' : 'Education & Qualifications *',

                        _qualificationsCtrl,

                        required: true,

                        maxLength: 150,

                      ),

                      _textField(

                        _profession == 'Doctor'

                            ? (isTamil ? 'பணிபுரியும் மருத்துவமனை / கிளினிக்' : 'Current Hospital / Clinic Workplace')

                            : (isTamil ? 'பணிபுரியும் அலுவலகம் / நீதிமன்றம்' : 'Current Chambers / Court / Law Firm'),

                        _workplaceCtrl,

                        maxLength: 200,

                      ),

                    ]),

                    const SizedBox(height: 18),

                    // Row 3: Bio / Summary

                    _textField(

                      isTamil ? 'சுருக்கமான அறிமுகம் / விவரம் (Bio Summary)' : 'Brief Bio / Professional Summary',

                      _bioSummaryCtrl,

                      maxLines: 3,

                      maxLength: 500,

                    ),

                  ],

                ),

              ),

            ],

          ],

        ],

      ),

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

          _fileUploadField(AppLocalizations.of(context)?.passportPhotoLabel ?? 'Passport Photo', _memberImage, (file) => setState(() => _memberImage = file)),

          _fileUploadField(AppLocalizations.of(context)?.communityCertificateLabel ?? 'Community Certificate', _communityCert, (file) => setState(() => _communityCert = file)),

        ]),

      ]),

    );

  }



  Widget _fileUploadField(String label, dynamic file, ValueChanged<dynamic> onPicked) {

    String fileName = AppLocalizations.of(context)?.chooseFile ?? 'Choose file...';

    Widget? previewWidget;



    if (file != null) {

       if (file is String && file.isNotEmpty && file != 'null' && file != 'None') {

         final cleanName = file.split('?').first.split('/').last.split('\\').last;

         final existingPrefix = AppLocalizations.of(context)?.existingFile ?? "Existing file: ";

         fileName = '$existingPrefix$cleanName';

         bool isPdf = cleanName.toLowerCase().endsWith('.pdf');

         if (isPdf) {

           previewWidget = const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30);

         } else {

           final imageUrl = file.startsWith('http') ? file : '${ApiConfig.baseUrl}/assets/uploads/$cleanName';

           previewWidget = ClipRRect(

             borderRadius: BorderRadius.circular(4), 

             child: Image.network(

               imageUrl, 

               width: 40, 

               height: 40, 

               fit: BoxFit.cover, 

               errorBuilder: (c,e,s) => const Icon(Icons.insert_drive_file, size: 28, color: _gold)

             )

           );

         }

       } else if (file is XFile) {

         fileName = file.name;

         bool isPdf = fileName.toLowerCase().endsWith('.pdf');

         if (isPdf) {

           previewWidget = const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30);

         } else {

           if (kIsWeb) {

             previewWidget = ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(file.path, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image, size: 30, color: _gold)));

           } else {

             previewWidget = ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(file.path), width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image, size: 30, color: _gold)));

           }

         }

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

                if (previewWidget != null) ...[

                  previewWidget!,

                  const SizedBox(width: 12),

                ] else ...[

                  const Icon(Icons.upload_file, size: 18, color: _gold),

                  const SizedBox(width: 8),

                ],

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



        final ext = (file.extension ?? file.name.split('.').last).toLowerCase();

        final allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

        if (!allowedExtensions.contains(ext)) {

          if (mounted) {

            showStatusDialog(

              context,

              title: 'Validation Error',

              message: 'Only JPG, JPEG, PNG, and PDF document formats are supported.',

              type: DialogType.error,

            );

          }

          return;

        }



        if (file.size > 5 * 1024 * 1024) {

          if (mounted) {

            showStatusDialog(

              context,

              title: 'Validation Error',

              message: 'File size exceeds the allowed limit of 5 MB.',

              type: DialogType.error,

            );

          }

          return;

        }



        if (kIsWeb) {

          if (file.bytes != null || file.path != null) {

            onPicked(file.path != null ? XFile(file.path!, name: file.name) : XFile.fromData(file.bytes!, name: file.name));

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

      return Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w is Expanded ? w.child : w)).toList()

      );

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

    if ((label.contains('Name') || label.contains('Thottam') || label.contains('Valuvu')) && !label.contains('Street') && !label.contains('Village')) {

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

          if ((label.contains('Thottam') || label.contains('Valuvu')) && val.trim().isNotEmpty) {

            if (!RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(val.trim())) return 'Only letters, spaces, and dots allowed';

          }

          if (label.contains('Street Name') && val.trim().isNotEmpty) {

            if (val.trim().length < 4) return 'Address is too short';

            if (!RegExp(r'[a-zA-Z]').hasMatch(val.trim())) return 'Must contain at least one letter';

            if (RegExp(r'^[^a-zA-Z0-9]+$').hasMatch(val.trim())) return 'Please enter a valid address';

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

        initialCountryCode: _phoneCountryCode,

        onCountryChanged: (c) {

          setState(() {

            _phoneCountryCode = c.code;

            ctrl.clear();

            if (_whatsappSameAsPhone) {

              _whatsappCountryCode = c.code;

              _whatsappCtrl.clear();

            }

          });

        },

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

        spacing: 16,

        runSpacing: 8,

        children: options.map((o) => Row(mainAxisSize: MainAxisSize.min, children: [

          SizedBox(

            width: 24,

            height: 24,

            child: Radio<String>(

              value: o, 

              groupValue: value, 

              onChanged: onChanged, 

              activeColor: _darkBrown, 

              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),

            ),

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

              return Text(display, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _darkBrown));

            }

          ),

        ])).toList(),

      ),

    ]);

  }

  Widget _buildLabelText(String label) {

    bool hasAsterisk = label.contains('*');

    String baseLabel = label.replaceAll('*', '').trim();

    String translatedLabel = baseLabel;

    

    final loc = AppLocalizations.of(context);

    if (loc != null) {

      if (baseLabel == 'Relationship') translatedLabel = loc.relationshipHeader ?? baseLabel;

      else if (baseLabel == 'Name') translatedLabel = loc.nameHeader ?? baseLabel;

      else if (baseLabel == 'Phone Number') translatedLabel = loc.phoneNumberLabel ?? baseLabel;

      else if (baseLabel == 'Date Of Birth') translatedLabel = loc.dateOfBirthLabel ?? baseLabel;

      else if (baseLabel == 'Gender') translatedLabel = loc.genderHeader ?? baseLabel;

      else if (baseLabel == 'Blood Group') translatedLabel = loc.bloodGroupLabel ?? baseLabel;

      else if (baseLabel == 'Email') translatedLabel = loc.emailLabel ?? baseLabel;

      else if (baseLabel == 'WhatsApp Number') translatedLabel = loc.whatsappNumberLabel ?? baseLabel;

      else if (baseLabel == 'Married') translatedLabel = loc.marriedStatusLabel ?? baseLabel;

      else if (baseLabel == 'Alive Status') translatedLabel = loc.aliveStatusLabel ?? baseLabel;

      else if (baseLabel == 'Valuvu') translatedLabel = loc.valuvuLabel ?? baseLabel;

      else if (baseLabel == 'Thottam') translatedLabel = loc.thottamLabel ?? baseLabel;

      else if (baseLabel == 'Kulam') translatedLabel = loc.kulamLabel ?? baseLabel;

      else if (baseLabel == 'Education') translatedLabel = loc.educationLabel ?? baseLabel;

      else if (baseLabel == 'Profession') translatedLabel = loc.professionLabel ?? baseLabel;

      else if (baseLabel == 'District') translatedLabel = loc.districtHeader ?? baseLabel;

      else if (baseLabel == 'Taluk') translatedLabel = loc.talukHeader ?? baseLabel;

      else if (baseLabel == 'Panchayat') translatedLabel = loc.panchayatHeader ?? baseLabel;

      else if (baseLabel == 'Village') translatedLabel = loc.villageUpperHeader ?? baseLabel;

      else if (baseLabel == 'Door No & Street Name') translatedLabel = loc.streetNameLabel ?? baseLabel;

      else if (baseLabel == 'Pin Code' || baseLabel == 'Zip / Postal Code') translatedLabel = loc.pincodeLabel ?? baseLabel;

      else if (baseLabel == 'Current Address Type') translatedLabel = loc.currentAddressTypeLabel ?? baseLabel;

      else if (baseLabel == 'State') translatedLabel = loc.stateLabel ?? baseLabel;

      else if (baseLabel == 'Country') translatedLabel = loc.countryLabel ?? baseLabel;

      else if (baseLabel == 'City') translatedLabel = loc.cityVillageLabel ?? baseLabel;

      else if (baseLabel == 'Full Address') translatedLabel = loc.fullAddressLabel ?? baseLabel;

    }



    if (hasAsterisk) {

      return Text.rich(

        TextSpan(

          text: '$translatedLabel ',

          children: const [

            TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),

          ],

        ),

        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown),

      );

    }

    return Text(translatedLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown));

  }



  Widget _buildMembershipTypeSection(bool isMobile) {

    final isTa = Localizations.localeOf(context).languageCode == 'ta';

        final bool hasAssignedId = _privilegeId != null && _privilegeId!.isNotEmpty;
    final String displayBadgeId = hasAssignedId
        ? _privilegeId!
        : (_nextPrivilegeId != null && _nextPrivilegeId!.isNotEmpty
            ? _nextPrivilegeId!
            : (isTa ? 'அடுத்த சிறப்பு எண்' : 'Next PRV ID'));



    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: _isPrivilege ? const Color(0xFFFFFDF5) : Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(

          color: _isPrivilege ? const Color(0xFFC49A3C) : Colors.grey.shade300,

          width: _isPrivilege ? 1.5 : 1.0,

        ),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.04),

            blurRadius: 8,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(

                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(

                  color: _isPrivilege ? const Color(0xFFFFF8E1) : const Color(0xFF5D1712).withOpacity(0.1),

                  borderRadius: BorderRadius.circular(8),

                ),

                child: Icon(

                  _isPrivilege ? Icons.workspace_premium : Icons.person_outline,

                  size: 22,

                  color: _isPrivilege ? const Color(0xFFC49A3C) : const Color(0xFF5D1712),

                ),

              ),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      isTa ? 'உறுப்பினர் வகை (Membership Type)' : 'Membership Type Selection',

                      style: const TextStyle(

                        fontSize: 15,

                        fontWeight: FontWeight.bold,

                        color: _darkBrown,

                      ),

                    ),

                    Text(

                      isTa

                          ? 'வழக்கமான அல்லது சிறப்பு உறுப்பினர் வகையைத் தேர்ந்தெடுக்கவும்.'

                          : 'Choose whether this member is a Standard or Privileged member.',

                      style: const TextStyle(fontSize: 12, color: Colors.black54),

                    ),

                  ],

                ),

              ),

            ],

          ),

          const SizedBox(height: 16),

          isMobile

              ? Column(

                  children: [

                    _buildStandardMemberOption(isTa),

                    const SizedBox(height: 12),

                    _buildPrivilegeMemberOption(isTa, displayBadgeId, hasAssignedId),

                  ],

                )

              : Row(

                  children: [

                    Expanded(child: _buildStandardMemberOption(isTa)),

                    const SizedBox(width: 12),

                    Expanded(child: _buildPrivilegeMemberOption(isTa, displayBadgeId, hasAssignedId)),

                  ],

                ),

        ],

      ),

    );

  }



  Widget _buildStandardMemberOption(bool isTa) {

    return InkWell(

      onTap: () => setState(() => _isPrivilege = false),

      borderRadius: BorderRadius.circular(10),

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

        decoration: BoxDecoration(

          color: !_isPrivilege ? const Color(0xFF5D1712).withOpacity(0.08) : Colors.grey.shade50,

          borderRadius: BorderRadius.circular(10),

          border: Border.all(

            color: !_isPrivilege ? const Color(0xFF5D1712) : Colors.grey.shade300,

            width: !_isPrivilege ? 1.8 : 1.0,

          ),

        ),

        child: Row(

          children: [

            Icon(

              !_isPrivilege ? Icons.radio_button_checked : Icons.radio_button_off,

              color: !_isPrivilege ? const Color(0xFF5D1712) : Colors.grey,

              size: 20,

            ),

            const SizedBox(width: 10),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    isTa ? 'வழக்கமான உறுப்பினர் (Standard Member)' : 'Standard Member (Non-Privilege)',

                    style: TextStyle(

                      fontWeight: FontWeight.bold,

                      fontSize: 13.5,

                      color: !_isPrivilege ? const Color(0xFF5D1712) : Colors.black87,

                    ),

                  ),

                  Text(

                    isTa ? 'நிரந்தர எண் மட்டுமே (Privilege எண் மறைக்கப்படும்)' : 'Permanent Member ID only (Privileged ID hidden)',

                    style: const TextStyle(fontSize: 11, color: Colors.black54),

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildPrivilegeMemberOption(bool isTa, String displayBadgeId, bool hasAssignedId) {

    return InkWell(

      onTap: () => setState(() => _isPrivilege = true),

      borderRadius: BorderRadius.circular(10),

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

        decoration: BoxDecoration(

          color: _isPrivilege ? const Color(0xFFFFF8E1) : Colors.grey.shade50,

          borderRadius: BorderRadius.circular(10),

          border: Border.all(

            color: _isPrivilege ? const Color(0xFFC49A3C) : Colors.grey.shade300,

            width: _isPrivilege ? 1.8 : 1.0,

          ),

        ),

        child: Row(

          children: [

            Icon(

              _isPrivilege ? Icons.radio_button_checked : Icons.radio_button_off,

              color: _isPrivilege ? const Color(0xFFC49A3C) : Colors.grey,

              size: 20,

            ),

            const SizedBox(width: 10),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(

                    children: [

                      Text(

                        isTa ? 'சிறப்பு உறுப்பினர் (Privilege Member)' : 'Privilege Member',

                        style: TextStyle(

                          fontWeight: FontWeight.bold,

                          fontSize: 13.5,

                          color: _isPrivilege ? const Color(0xFF8D6E18) : Colors.black87,

                        ),

                      ),

                      const SizedBox(width: 6),

                      Container(

                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),

                        decoration: BoxDecoration(

                          color: const Color(0xFFC49A3C),

                          borderRadius: BorderRadius.circular(4),

                        ),

                        child: Text(

                          displayBadgeId,

                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),

                        ),

                      ),

                    ],

                  ),

                  Text(

                    hasAssignedId ? (isTa ? 'நிரந்தர எண் + சிறப்பு எண் ($displayBadgeId)' : 'Dual ID: Permanent + Privilege ID ($displayBadgeId)') : (isTa ? 'நிரந்தர எண் + புதிய சிறப்பு எண் ($displayBadgeId ஒதுக்கப்படும்)' : 'Dual ID: Permanent + Next Privilege ID ($displayBadgeId)'),

                    style: TextStyle(

                      fontSize: 11,

                      color: _isPrivilege ? const Color(0xFF8D6E18) : Colors.black54,

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }



}

