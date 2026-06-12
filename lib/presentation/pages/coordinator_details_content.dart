import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';
import 'update_details_content.dart';

class CoordinatorDetailsContent extends StatefulWidget {
  final String numericId;
  final String familyId;
  final VoidCallback onBack;

  const CoordinatorDetailsContent({
    super.key, 
    required this.numericId, 
    required this.familyId,
    required this.onBack,
  });

  @override
  State<CoordinatorDetailsContent> createState() => _CoordinatorDetailsContentState();
}

class _CoordinatorDetailsContentState extends State<CoordinatorDetailsContent> {
  Map<String, dynamic>? _userData;
  List<dynamic> _familyMembers = [];
  List<dynamic> _assignedMembers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Basic Details
      final userRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/user-details/${widget.numericId}'));
      
      // 2. Fetch Family Members
      final familyRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/family-members/${widget.numericId}'));
      
      // 3. Fetch Assigned Village Members
      final assignedRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/coordinator-assigned-members/${widget.familyId}'));
      
      // 4. Fetch Villages for "Assigned Villages" display
      final villagesRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/coordinator-villages/${widget.familyId}'));

      if (userRes.statusCode == 200 && familyRes.statusCode == 200 && assignedRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body)['data'];
        final familyData = jsonDecode(familyRes.body)['data'];
        final assignedData = jsonDecode(assignedRes.body)['data'];
        final villagesData = jsonDecode(villagesRes.body)['data'] as List;
        
        String villageNames = villagesData.map((v) => v['village_name']).join(', ');

        setState(() {
          _userData = userData;
          _userData!['AssignedVillages'] = villageNames.isEmpty ? 'None' : villageNames;
          _familyMembers = familyData;
          _assignedMembers = assignedData.where((m) => m['MemberRole'] == 'Head').toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  void _showEventParticipationDialog() async {
    final ScrollController horizontalScrollController = ScrollController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Event Participation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ],
        ),
        content: SizedBox(
          width: 900,
          child: FutureBuilder<http.Response>(
            future: http.get(Uri.parse('${ApiConfig.baseUrl}/api/event-participation/${widget.numericId}')),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: LoadingSpinner(message: 'Fetching participation records...'));
              }
              if (snapshot.hasError || snapshot.data?.statusCode != 200) {
                return const SizedBox(height: 100, child: Center(child: Text('Failed to load participation data')));
              }
              
              final data = jsonDecode(snapshot.data!.body)['data'] as List;
              if (data.isEmpty) {
                return const SizedBox(height: 100, child: Center(child: Text('No event participation found.')));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return Scrollbar(
                    controller: horizontalScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          border: TableBorder(verticalInside: BorderSide(color: Colors.grey.shade300, width: 1)),
                          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                          columns: const [
                            DataColumn(label: Text('SNo', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Event Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Tax Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Paid Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Balance Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Payment Date', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: data.asMap().entries.map((entry) {
                            final i = entry.key;
                            final row = entry.value;
                            final bool isPaid = row['status'] == 'PAID';
                            
                            return DataRow(cells: [
                              DataCell(Text('${i + 1}')),
                              DataCell(Text(row['EventName'] ?? '-')),
                              DataCell(Text(row['TaxAmount']?.toString() ?? '0')),
                              DataCell(Text(row['PaidAmount']?.toString() ?? '0')),
                              DataCell(Text(row['BalanceAmount']?.toString() ?? '0')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFF5D1712),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    row['status'] ?? 'UNKNOWN',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              DataCell(Text(row['PaymentDate'] ?? '-')),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                }
              );
            },
          ),
        ),
      ),
    );
  }

  void _showImageViewer(String? imageName, String title) {
    if (imageName == null || imageName.isEmpty) {
      showStatusDialog(
        context,
        title: 'Information',
        message: 'No $title uploaded',
        type: DialogType.warning,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '${ApiConfig.baseUrl}/assets/uploads/$imageName',
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Failed to load $title', style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateDetailsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 1000,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: UpdateDetailsContent(
            userId: widget.numericId,
            userRole: 1, // Manager/Admin role
            userData: _userData!,
            onBack: () {
              Navigator.pop(context);
              _fetchFullDetails();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingSpinner(message: 'Loading coordinator profile...');
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_userData == null) return const Center(child: Text('No data found'));

    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: const Color(0xFF5D1712), size: 28),
                  SizedBox(width: 12),
                  Text('Coordinator Details:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF2D1B18))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final url = '${ApiConfig.baseUrl}/api/download-id-card/${widget.numericId}';
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Download ID Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D1712),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Profile Section
          _buildProfileSection(isMobile),
          const SizedBox(height: 48),

          // Family Members Section
          const Row(
            children: [
              Icon(Icons.group, color: const Color(0xFF5D1712), size: 24),
              SizedBox(width: 12),
              Text('Family Members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2D1B18))),
            ],
          ),
          const SizedBox(height: 16),
          _buildFamilyTable(),
          const SizedBox(height: 48),


        ],
      ),
    );
  }

  Widget _buildProfileSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar & Quick Actions
          Column(
            children: [
              GestureDetector(
                onTap: () => _showImageViewer(_userData?['Memberimage'], 'Profile Photo'),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      image: _userData?['Memberimage'] != null
                          ? DecorationImage(
                              image: NetworkImage('${ApiConfig.baseUrl}/assets/uploads/${_userData!['Memberimage']}'),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _userData?['Memberimage'] == null
                        ? Icon(Icons.person, size: 80, color: Colors.grey.shade400)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _roundIcon(Icons.contact_page_outlined, 'Community Certificate', onTap: () => _showImageViewer(_userData?['Communitycertificateimage'], 'Community Certificate')),
                ],
              ),
              const SizedBox(height: 16),
              _actionButton('Event Participation', Icons.event_available, const Color(0xFFE8F5E9), Colors.green, onTap: _showEventParticipationDialog),
              const SizedBox(height: 12),
              _actionButton('Update Details', Icons.edit_note, const Color(0xFFFFF3E0), Colors.orange, onTap: _showUpdateDetailsDialog),
            ],
          ),
          const SizedBox(width: 60),
          // Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                _detailItem('Name:', _userData!['Name'] ?? 'N/A', isBlue: true, isBold: true),
                const SizedBox(height: 24),
                _detailItem('Family Membership ID:', _userData!['Familymembershipid'] ?? 'N/A', isPill: true),
                const SizedBox(height: 24),
                _detailItem('Phone Number:', _userData!['Phonenumber']?.toString() ?? 'N/A'),
                const SizedBox(height: 24),
                _addressItem('Address:', _userData!),
              ],
            ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value, {bool isBlue = false, bool isBold = false, bool isPill = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 200, child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54))),
        isPill
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF5D1712), borderRadius: BorderRadius.circular(20)),
                child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isBlue ? const Color(0xFF5D1712) : Colors.black87,
                ),
              ),
      ],
    );
  }

  Widget _addressItem(String label, Map<String, dynamic> data) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 200, child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              _addressLine(Icons.home_outlined, '${data['Street'] ?? ''}'),
              const SizedBox(height: 6),
              _addressLine(Icons.location_on_outlined, '${data['Village'] ?? ''}, ${data['Taluk'] ?? ''}'),
              const SizedBox(height: 6),
              _addressLine(Icons.push_pin_outlined, '${data['District'] ?? ''} - ${data['Pincode'] ?? ''}'),
              const SizedBox(height: 6),
              _addressLine(Icons.map_outlined, data['State'] ?? 'Tamil Nadu'),
            ],
          ),
      ],
    );
  }

  Widget _addressLine(IconData icon, String text) {
    if (text.trim().isEmpty || text == 'null' || text == ', ') return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF5D1712), size: 18),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      ],
    );
  }

  Widget _roundIcon(IconData icon, String tooltip, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF5D1712).withOpacity(0.5))),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF5D1712), size: 20),
        onPressed: onTap ?? () {},
        tooltip: tooltip,
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color bgColor, Color textColor, {VoidCallback? onTap}) {
    return SizedBox(
      width: 220,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: textColor, size: 18),
        label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          side: BorderSide(color: textColor.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
  String _getDisplayRole(dynamic member) {
    String role = member['MemberRole']?.toString() ?? 'Unknown';
    String memberFmId = member['Familymembershipid']?.toString() ?? '';
    String memberExId = member['Existfamilyid']?.toString() ?? '';
    String gender = member['Gender']?.toString().toLowerCase() ?? '';
    
    String currentFmId = _userData?['Familymembershipid']?.toString() ?? '';
    String currentExistId = _userData?['Existfamilyid']?.toString() ?? '';
    
    bool amISubHead = currentFmId.isNotEmpty && currentExistId.isNotEmpty;
    
    if (amISubHead) {
      if (memberFmId == currentExistId && memberFmId.isNotEmpty) {
        if (role == 'Head') return gender == 'female' ? 'Mother' : 'Father';
      }
      if (memberExId == currentExistId && memberExId.isNotEmpty) {
        if (memberFmId == currentFmId && currentFmId.isNotEmpty) {
          return 'Head';
        }
        if (role == 'Head') return gender == 'female' ? 'Sister' : 'Brother';
        if (role == 'Wife' || role == 'Husband') return gender == 'male' ? 'Father' : 'Mother';
        if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Sister' : 'Brother';
        if (['Brother', 'Sister'].contains(role)) return gender == 'female' ? 'Aunt' : 'Uncle';
        if (['Father', 'Mother'].contains(role)) return gender == 'female' ? 'Grand Mother' : 'Grand Father';
        if (['Grand Father', 'Grand Mother'].contains(role)) return gender == 'female' ? 'Great Grand Mother' : 'Great Grand Father';
      }
      
      if (memberExId.isNotEmpty && memberExId != currentExistId && memberExId != currentFmId) {
        if (role == 'Wife') return 'Sister-in-law';
        if (role == 'Husband') return 'Brother-in-law';
        if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Niece' : 'Nephew';
      }
    } else {
      String topLevelId = currentFmId.isNotEmpty ? currentFmId : currentExistId;
      bool isFmSubHead = role == 'Head' && memberExId.isNotEmpty;
      if (isFmSubHead && memberExId == topLevelId) {
        return gender == 'female' ? 'Daughter' : 'Son';
      }
      
      bool belongsToSubHead = memberExId.isNotEmpty && memberExId != topLevelId;
      if (belongsToSubHead) {
        if (role == 'Wife') return 'Daughter-in-law';
        if (role == 'Husband') return 'Son-in-law';
        if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Grand Daughter' : 'Grand Son';
      }
    }
    
    return role;
  }

  Widget _buildFamilyTable() {
    String currentFmId = _userData?['Familymembershipid']?.toString() ?? '';
    String currentExistId = _userData?['Existfamilyid']?.toString() ?? '';
    bool amITopHeadFamily = currentExistId.isEmpty;
    bool amISubHead = _userData?['MemberRole'] == 'Head' && currentExistId.isNotEmpty;

    final tableMembers = _familyMembers.where((fm) {
      bool isMarried = fm['Married']?.toString().toLowerCase() == 'yes';
      bool isChild = ['Son', 'Daughter', 'Son-in-law', 'Daughter-in-law'].contains(fm['MemberRole']);
      
      if (amISubHead) {
        if (fm['Familymembershipid']?.toString() == currentFmId && currentFmId.isNotEmpty) return true;
        if (fm['Existfamilyid']?.toString() == currentFmId && currentFmId.isNotEmpty) return true;
        return false;
      } else {
        String topLevelId = amITopHeadFamily ? currentFmId : currentExistId;
        if (fm['Familymembershipid']?.toString() == topLevelId && topLevelId.isNotEmpty) return true;
        if (fm['Existfamilyid']?.toString() == topLevelId && topLevelId.isNotEmpty) {
          bool isFmSubHead = fm['MemberRole'] == 'Head' && (fm['Existfamilyid']?.toString() ?? '').isNotEmpty;
          if (isFmSubHead) return false;
          if (isMarried && isChild) return false;
          return true;
        }
        return false;
      }
    }).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          border: TableBorder(verticalInside: BorderSide(color: Colors.grey.shade300, width: 1)),
          headingRowHeight: 50,
          headingRowColor: MaterialStateProperty.all(const Color(0xFF2D1B18)),
          columns: const [
            DataColumn(label: Text('S.NO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('RELATIONSHIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('GENDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('AGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
          rows: tableMembers.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return DataRow(cells: [
              DataCell(Text('${i + 1}')),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['Name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFDECEB), borderRadius: BorderRadius.circular(4)),
                    child: Text(m['Familymembershipid'] ?? '', style: const TextStyle(fontSize: 10, color: const Color(0xFF5D1712), fontWeight: FontWeight.bold)),
                  ),
                ],
              )),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                child: Text(_getDisplayRole(m), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m['Gender'] == 'Male' ? Icons.male : Icons.female, size: 16, color: const Color(0xFF5D1712)),
                  const SizedBox(width: 4),
                  Text(m['Gender'] ?? 'N/A'),
                ],
              )),
              DataCell(Text(_calculateAge(m['Dob']))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAssignedMembersTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          border: TableBorder(verticalInside: BorderSide(color: Colors.grey.shade300, width: 1)),
          headingRowHeight: 50,
          headingRowColor: MaterialStateProperty.all(const Color(0xFF2D1B18)),
          columns: const [
            DataColumn(label: Text('S.NO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('GENDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('MOBILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('LOCATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
          rows: _assignedMembers.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return DataRow(cells: [
              DataCell(Text('${i + 1}')),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['Name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(m['Familymembershipid'] ?? '', style: const TextStyle(fontSize: 11, color: const Color(0xFF5D1712))),
                ],
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m['Gender'] == 'Male' ? Icons.male : Icons.female, size: 16, color: const Color(0xFF5D1712)),
                  const SizedBox(width: 4),
                  Text(m['Gender'] ?? 'N/A'),
                ],
              )),
              DataCell(Text(m['Phonenumber']?.toString() ?? 'N/A')),
              DataCell(Text(m['Village'] ?? '-')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  String _calculateAge(dynamic dobStr) {
    if (dobStr == null || dobStr.toString().isEmpty) return 'N/A';
    try {
      DateTime dob = DateTime.parse(dobStr.toString());
      DateTime now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
      return age.toString();
    } catch (_) {
      return 'N/A';
    }
  }
}
