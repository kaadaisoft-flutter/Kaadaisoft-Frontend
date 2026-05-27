import 'package:flutter/material.dart';
import 'dart:html' as html;
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
          _assignedMembers = assignedData;
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

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                  columns: const [
                    DataColumn(label: Text('SNo', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Event Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tax Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Paid Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Balance Amount', style: TextStyle(fontWeight: FontWeight.bold))),
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
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(row['BalanceAmount']?.toString() ?? '0'),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFF1976D2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                row['status'],
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(row['PaymentDate'] ?? '-')),
                    ]);
                  }).toList(),
                ),
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
                  Icon(Icons.person, color: Color(0xFF1976D2), size: 28),
                  SizedBox(width: 12),
                  Text('Coordinator Details:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final url = '${ApiConfig.baseUrl}/api/download-id-card/${widget.numericId}';
                  html.window.open(url, '_blank');
                },
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Download ID Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
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
              Icon(Icons.group, color: Color(0xFF1976D2), size: 24),
              SizedBox(width: 12),
              Text('Family Members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18))),
            ],
          ),
          const SizedBox(height: 16),
          _buildFamilyTable(),
          const SizedBox(height: 48),

          // Assigned Members Section
          Row(
            children: [
              const Icon(Icons.location_city, color: Color(0xFF1976D2), size: 24),
              const SizedBox(width: 12),
              Text('Total Members: ${_assignedMembers.length}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18))),
            ],
          ),
          const SizedBox(height: 16),
          _buildAssignedMembersTable(),
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
          Expanded(
            child: Column(
              children: [
                _detailItem('Name:', _userData!['Name'] ?? 'N/A', isBlue: true, isBold: true),
                const SizedBox(height: 24),
                _detailItem('Family Membership ID:', _userData!['Familymembershipid'] ?? 'N/A', isPill: true),
                const SizedBox(height: 24),
                _detailItem('Phone Number:', _userData!['Phonenumber']?.toString() ?? 'N/A'),
                const SizedBox(height: 24),
                _addressItem('Address:', _userData!),
                const SizedBox(height: 24),
                _detailItem('Assigned Villages:', _userData!['AssignedVillages'] ?? 'None', isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value, {bool isBlue = false, bool isBold = false, bool isPill = false}) {
    return Row(
      children: [
        SizedBox(width: 200, child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54))),
        isPill
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(20)),
                child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: isBlue ? const Color(0xFF1976D2) : Colors.black87,
                ),
              ),
      ],
    );
  }

  Widget _addressItem(String label, Map<String, dynamic> data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 200, child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54))),
        Expanded(
          child: Column(
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
        ),
      ],
    );
  }

  Widget _addressLine(IconData icon, String text) {
    if (text.trim().isEmpty || text == 'null' || text == ', ') return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1976D2), size: 18),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      ],
    );
  }

  Widget _roundIcon(IconData icon, String tooltip, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.5))),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF1976D2), size: 20),
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

  Widget _buildFamilyTable() {
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
          headingRowHeight: 50,
          headingRowColor: MaterialStateProperty.all(const Color(0xFF2D1B18)),
          columns: const [
            DataColumn(label: Text('S.NO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('RELATIONSHIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('GENDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('AGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
          rows: _familyMembers.asMap().entries.map((entry) {
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
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Text(m['Familymembershipid'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              )),
              DataCell(Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                child: Text(m['MemberRole'] ?? 'Member', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(m['Gender'] == 'Male' ? Icons.male : Icons.female, size: 16, color: Colors.blue),
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
          headingRowHeight: 50,
          headingRowColor: MaterialStateProperty.all(const Color(0xFF2D1B18)),
          columns: const [
            DataColumn(label: Text('S.NO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('MEMBER DETAILS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
                  Text(m['Familymembershipid'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                ],
              )),
              DataCell(Text(m['Phonenumber']?.toString() ?? 'N/A')),
              DataCell(Text('${m['Village'] ?? ''}, ${m['Panchayat'] ?? ''}')),
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
