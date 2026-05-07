import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart' as fp_pkg;
import 'package:cross_file/cross_file.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';

class UpdateDetailsContent extends StatefulWidget {
  final dynamic userId;
  final int userRole;
  final Map<String, dynamic> userData;
  final VoidCallback onBack;
  const UpdateDetailsContent({super.key, required this.userId, required this.userRole, required this.userData, required this.onBack});

  @override
  State<UpdateDetailsContent> createState() => _UpdateDetailsContentState();
}

class _UpdateDetailsContentState extends State<UpdateDetailsContent> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _valuvuCtrl;
  late TextEditingController _thottamCtrl;
  late TextEditingController _streetCtrl;
  late TextEditingController _doorNoCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _professionCtrl;
  late TextEditingController _businessCtrl;
  late TextEditingController _aadharCtrl;
  
  // Current Address Controllers
  late TextEditingController _curStreetCtrl;
  late TextEditingController _curDoorNoCtrl;
  late TextEditingController _curPincodeCtrl;
  late TextEditingController _curTalukCtrl;
  late TextEditingController _curPanchayatCtrl;
  late TextEditingController _curVillageCtrl;
  late TextEditingController _nriZipCtrl;
  late TextEditingController _nriFullAddressCtrl;
  late TextEditingController _businessWebsiteCtrl;

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

  List<String> _districts = [];
  List<String> _taluks = [];
  List<String> _panchayats = [];
  List<String> _villages = [];

  // Current Address State
  String? _curAddressType; // TamilNadu, OtherState, NRI
  String? _curState;
  String? _curDistrict;
  String? _nriCountry;
  String? _nriState;
  String? _nriCity;

  // Documents
  dynamic _memberImage;
  dynamic _aadharFront;
  dynamic _aadharBack;
  dynamic _communityCert;
  
  bool _isConfirmed = false;
  
  String? _education;
  String? _profession;

  static const Color _darkBrown = Color(0xFF322E2E);
  static const Color _gold = Color(0xFFC5A028);

  final List<String> _relationships = ['Head','Grand Father','Grand Mother','Father','Mother','Husband','Wife','Son','Daughter','Son-in-law','Daughter-in-law','Brother','Sister','Other'];
  final List<String> _bloodGroups = ['A+','A-','B+','B-','O+','O-','AB+','AB-'];
  final List<String> _kulams = ['Poondurai Kaadai','Aanthuvan Kulam','Azhagu Kulam','Aathe Kulam','Kaadai Kulam','Kaari Kulam','Keeran Kulam','Sellan Kulam','Semban Kulam','Pandiyan Kulam','Ponnar Kulam','Maniyan Kulam','Others'];
  final List<String> _educations = ['SSLC', 'HSC', 'Diploma', 'ITI', 'B.A', 'B.Sc', 'B.Com', 'BBA', 'BCA', 'B.E', 'B.Tech', 'MBBS', 'BDS', 'B.Pharm', 'B.Ed', 'LLB', 'B.Arch', 'M.A', 'M.Sc', 'M.Com', 'MBA', 'MCA', 'M.E', 'M.Tech', 'MD', 'MS', 'MDS', 'M.Pharm', 'M.Ed', 'LLM', 'M.Phil', 'Ph.D', 'Others'];
  final List<String> _professions = ['Doctor', 'Lawyer', 'Police', 'Teacher / Lecturer', 'Engineer', 'Government Employee', 'Private Employee', 'Student', 'Farmer – Agriculture', 'Textile Mill Worker (Spinning / Weaving)', 'Garment Factory Worker', 'Tailor / Apparel Stitching', 'Garment Pattern Master / Designer', 'Textile Machinery Technician / Mechanic', 'Textile Machinery Sales & Service', 'Powerloom / Auto‑Loom Operator', 'Knitting Machine Operator', 'Truck / Lorry Driver', 'Truck / Lorry Owner‑cum‑Driver', 'Logistics / Transport Staff', 'Fleet Manager', 'Dairy Farmer', 'Poultry Farmer', 'Goat / Sheep Rearing', 'Pump / Motor Technician', 'Pump / Motor Manufacturing Worker', 'Motor Rewinding Technician', 'Machinist / Turner', 'Welder / Fabricator', 'Steel / Aluminium Foundry Worker', 'Mixer‑Grinder Assembly / Service Technician', 'Plastic / Net / Packaging Unit Worker', 'Windmill Maintenance Technician', 'Electrical Line / Maintenance Technician', 'Grocery Shop Staff', 'Medical Shop / Pharmacy Staff', 'Retail Shop / Sales Staff', 'Office Admin / Computer Operator', 'Accountant / Finance Staff', 'Bank / NBFC Staff', 'Hospital Nurse / Lab Tech / Pharmacist', 'Medical Representative', 'IT / Software Employee', 'Home Maker', 'Retired', 'Others'];

  @override
  void initState() {
    super.initState();
    final d = widget.userData;
    _nameCtrl = TextEditingController(text: d['Name'] ?? '');
    _phoneCtrl = TextEditingController(text: d['Phonenumber']?.toString() ?? '');
    _whatsappCtrl = TextEditingController(text: d['Whatsappnumber']?.toString() ?? '');
    _emailCtrl = TextEditingController(text: d['Email'] ?? '');
    _dobCtrl = TextEditingController(text: d['Dob'] ?? '');
    _valuvuCtrl = TextEditingController(text: d['Valuvu'] ?? '');
    _thottamCtrl = TextEditingController(text: d['Thottam'] ?? '');
    _streetCtrl = TextEditingController(text: d['Street'] ?? '');
    _doorNoCtrl = TextEditingController(text: d['Doornumber'] ?? '');
    _pincodeCtrl = TextEditingController(text: d['Pincode']?.toString() ?? '');
    _professionCtrl = TextEditingController(text: d['Profession'] ?? '');
    _businessCtrl = TextEditingController(text: d['Business'] ?? '');
    _aadharCtrl = TextEditingController(text: d['Aadhar']?.toString() ?? '');

    // Current Address
    _curStreetCtrl = TextEditingController(text: d['Curstreet'] ?? '');
    _curDoorNoCtrl = TextEditingController(text: d['Curdoorno'] ?? '');
    _curPincodeCtrl = TextEditingController(text: d['Curpincode']?.toString() ?? '');
    _curTalukCtrl = TextEditingController(text: d['Curtaluk'] ?? '');
    _curPanchayatCtrl = TextEditingController(text: d['Curpanchayat'] ?? '');
    _curVillageCtrl = TextEditingController(text: d['Curvillage'] ?? '');
    _nriZipCtrl = TextEditingController(text: d['Curnrizip']?.toString() ?? '');
    _nriFullAddressCtrl = TextEditingController(text: d['Curnrifulladdress'] ?? '');
    _businessWebsiteCtrl = TextEditingController(text: d['BusinessWebsite'] ?? '');

    _relationship = d['MemberRole'];
    _gender = d['Gender'];
    _bloodGroup = d['Bloodgroup'];
    _married = d['Married'];
    _aliveStatus = (d['is_dead'] == 0 || d['is_dead'] == '0') ? 'Alive' : 'Dead';
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
  }

  @override
  void dispose() {
    final ctrls = [
      _nameCtrl, _phoneCtrl, _whatsappCtrl, _emailCtrl, _dobCtrl, 
      _valuvuCtrl, _thottamCtrl, _streetCtrl, 
      _doorNoCtrl, _pincodeCtrl, _professionCtrl, _businessCtrl, 
      _aadharCtrl, _curStreetCtrl, _curDoorNoCtrl, _curPincodeCtrl, 
      _curTalukCtrl, _curPanchayatCtrl, _curVillageCtrl, _nriZipCtrl, 
      _nriFullAddressCtrl, _businessWebsiteCtrl
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
      request.fields['aadhar'] = _aadharCtrl.text.trim();
      
      // Career
      request.fields['education'] = _education ?? '';
      request.fields['profession'] = _profession ?? '';
      request.fields['business'] = _businessCtrl.text.trim();
      request.fields['business_website'] = _businessWebsiteCtrl.text.trim();
      
      // Native Address
      request.fields['district'] = _district ?? '';
      request.fields['taluk'] = _taluk ?? '';
      request.fields['panchayat'] = _panchayat ?? '';
      request.fields['village'] = _village ?? '';
      request.fields['street'] = _streetCtrl.text.trim();
      request.fields['door_no'] = _doorNoCtrl.text.trim();
      request.fields['pincode'] = _pincodeCtrl.text.trim();
      
      // Current Address
      request.fields['cur_address_type'] = _curAddressType ?? '';
      request.fields['cur_state'] = _curState ?? '';
      request.fields['cur_district'] = _curDistrict ?? '';
      request.fields['cur_taluk'] = _curTalukCtrl.text.trim();
      request.fields['cur_panchayat'] = _curPanchayatCtrl.text.trim();
      request.fields['cur_village'] = _curVillageCtrl.text.trim();
      request.fields['cur_street'] = _curStreetCtrl.text.trim();
      request.fields['cur_door_no'] = _curDoorNoCtrl.text.trim();
      request.fields['cur_pincode'] = _curPincodeCtrl.text.trim();
      request.fields['nri_country'] = _nriCountry ?? '';
      request.fields['nri_state'] = _nriState ?? '';
      request.fields['nri_city'] = _nriCity ?? '';
      request.fields['nri_zip'] = _nriZipCtrl.text.trim();
      request.fields['nri_full_address'] = _nriFullAddressCtrl.text.trim();

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
      await addFile('aadhar_front', _aadharFront);
      await addFile('aadhar_back', _aadharBack);
      await addFile('community_cert', _communityCert);

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      if (mounted) {
        if (res.statusCode == 200) {
          showStatusDialog(
            context,
            title: 'Success',
            message: 'Details updated successfully!',
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
                      const Text('Update My Details: ', style: TextStyle(color: _darkBrown, fontWeight: FontWeight.bold, fontSize: 18)),
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

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving || !_isConfirmed ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _darkBrown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Text('UPDATE DETAILS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkBrown)),
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
          _dropField('Relationship', _relationships, _relationship, (v) => setState(() => _relationship = v)),
          _textField('Name *', _nameCtrl, required: true),
          _textField('Phone Number *', _phoneCtrl, inputType: TextInputType.phone, required: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            suffix: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)),
        ]),
        const SizedBox(height: 24),
        // Row 2: Aadhar, DOB, Gender
        _row(isMobile, [
          _textField('Aadhar Number *', _aadharCtrl, inputType: TextInputType.number, 
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)]),
          _dateField('Date Of Birth', _dobCtrl),
          _radioField('Gender', ['Male', 'Female', 'Other'], _gender, (v) => setState(() => _gender = v)),
        ]),
        const SizedBox(height: 24),
        // Row 3: Blood Group, Email, Whatsapp
        _row(isMobile, [
          _dropField('Blood Group', _bloodGroups, _bloodGroup, (v) => setState(() => _bloodGroup = v)),
          _textField('Email', _emailCtrl, inputType: TextInputType.emailAddress,
            suffix: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('WhatsApp Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _darkBrown)),
                    filled: true, fillColor: Colors.white, isDense: true,
                  ),
                )),
                const SizedBox(width: 8),
                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _whatsappCtrl.text = _phoneCtrl.text),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Same as Phone', style: TextStyle(color: _darkBrown, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ]),
        const SizedBox(height: 24),
        // Row 4: Married, Alive, Valuvu
        _row(isMobile, [
          _radioField('Married', ['Yes', 'No'], _married, (v) => setState(() => _married = v)),
          _radioField('Alive Status', ['Alive', 'Dead'], _aliveStatus ?? 'Alive', (v) => setState(() => _aliveStatus = v)),
          _textField('Valuvu', _valuvuCtrl),
        ]),
        const SizedBox(height: 24),
        // Row 5: Thottam, Kulam, Exist Family ID
        _row(isMobile, [
          _textField('Thottam', _thottamCtrl),
          _dropField('Kulam', _kulams, _kulam, (v) => setState(() => _kulam = v)),
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
          _dropField('Education', _educations, _education, (v) => setState(() => _education = v)),
          _dropField('Profession', _professions, _profession, (v) => setState(() => _profession = v)),
        ]),
        const SizedBox(height: 24),
        _row(isMobile, [
          _textField('Business Name', _businessCtrl),
          _textField('Business Website', _businessWebsiteCtrl),
        ]),
      ]),
    );
  }

  Widget _buildCurrentAddressSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _radioField('Current Address Type', ['Tamil Nadu', 'Other State', 'NRI'], _curAddressType == 'TamilNadu' ? 'Tamil Nadu' : (_curAddressType == 'OtherState' ? 'Other State' : (_curAddressType == 'NRI' ? 'NRI' : null)), (v) {
          setState(() {
            if (v == 'Tamil Nadu') _curAddressType = 'TamilNadu';
            else if (v == 'Other State') _curAddressType = 'OtherState';
            else if (v == 'NRI') _curAddressType = 'NRI';
          });
        }),
        const SizedBox(height: 24),
        
        if (_curAddressType == 'TamilNadu') ...[
           _row(isMobile, [
            _textField('District', _curDistrict != null ? TextEditingController(text: _curDistrict) : TextEditingController(), required: true),
            _textField('Taluk', _curTalukCtrl, required: true),
            _textField('Panchayat', _curPanchayatCtrl, required: true),
          ]),
          const SizedBox(height: 24),
          _row(isMobile, [
            _textField('Village', _curVillageCtrl, required: true),
            _textField('Street', _curStreetCtrl, required: true),
            _textField('Door No', _curDoorNoCtrl, required: true),
          ]),
          const SizedBox(height: 24),
           _row(isMobile, [
            _textField('Pin Code', _curPincodeCtrl, inputType: TextInputType.number, required: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]),
            const Expanded(child: SizedBox()),
            const Expanded(child: SizedBox()),
          ]),
        ] else if (_curAddressType == 'OtherState' || _curAddressType == 'NRI') ...[
          _row(isMobile, [
            _textField('Country', TextEditingController(text: _nriCountry), required: true),
            _textField('State', TextEditingController(text: _nriState), required: true),
            _textField('City', TextEditingController(text: _nriCity), required: true),
          ]),
          const SizedBox(height: 24),
          _row(isMobile, [
            _textField('Zip / Postal Code', _nriZipCtrl, required: true),
            _textField('Street', _curStreetCtrl, required: true),
            _textField('Door No', _curDoorNoCtrl, required: true),
          ]),
          const SizedBox(height: 24),
          _textField('Full Address', _nriFullAddressCtrl, required: true),
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
          _fileUploadField('Aadhar Front', _aadharFront, (file) => setState(() => _aadharFront = file)),
        ]),
        const SizedBox(height: 24),
        _row(isMobile, [
          _fileUploadField('Aadhar Back', _aadharBack, (file) => setState(() => _aadharBack = file)),
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
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown)),
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
          _dropField('District', _districts, _district, (v) { setState(() { _district = v; _taluk = null; _panchayat = null; _village = null; _taluks = []; _panchayats = []; _villages = []; }); if (v != null) _fetchTaluks(v); }),
          _dropField('Taluk', _taluks, _taluk, (v) { setState(() { _taluk = v; _panchayat = null; _village = null; _panchayats = []; _villages = []; }); if (v != null) _fetchPanchayats(v); }),
          _dropField('Panchayat', _panchayats, _panchayat, (v) { setState(() { _panchayat = v; _village = null; _villages = []; }); if (v != null) _fetchVillages(v); }),
        ]),
        const SizedBox(height: 24),
        _row(isMobile, [
          _dropField('Village', _villages, _village, (v) => setState(() => _village = v)),
          _textField('Street', _streetCtrl),
          _textField('Door No', _doorNoCtrl),
        ]),
        const SizedBox(height: 24),
        _row(isMobile, [
          _textField('Pin Code', _pincodeCtrl, inputType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]),
          const Expanded(child: SizedBox()),
          const Expanded(child: SizedBox()),
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

  Widget _textField(String label, TextEditingController ctrl, {TextInputType? inputType, bool required = false, List<TextInputFormatter>? inputFormatters, Widget? suffix}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _darkBrown)),
          filled: true, fillColor: Colors.white,
          isDense: true,
          suffixIcon: suffix,
        ),
        validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      ),
    ]);
  }

  Widget _dropField(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    final safeValue = items.contains(value) ? value : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _darkBrown)),
          filled: true, fillColor: Colors.white, isDense: true,
        ),
        hint: Text('Select $label', style: const TextStyle(fontSize: 13)),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _dateField(String label, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown)),
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
          final picked = await showDatePicker(context: context, initialDate: DateTime.tryParse(ctrl.text) ?? DateTime(1990), firstDate: DateTime(1900), lastDate: DateTime.now());
          if (picked != null) ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
        },
      ),
    ]);
  }

  Widget _radioField(String label, List<String> options, String? value, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown)),
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
}
