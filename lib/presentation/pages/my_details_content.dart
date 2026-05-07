import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/loading_spinner.dart';
import '../../utils/api_config.dart';
import 'update_details_content.dart';
import '../widgets/add_family_member_form.dart';

class MyDetailsContent extends StatefulWidget {
  final dynamic userId;
  final int userRole;
  const MyDetailsContent({super.key, required this.userId, required this.userRole});

  @override
  State<MyDetailsContent> createState() => _MyDetailsContentState();
}

class _MyDetailsContentState extends State<MyDetailsContent> {
  Map<String, dynamic>? _userData;
  List<dynamic> _familyMembers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final userRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user-details/${widget.userId}'),
      );
      
      final familyRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/family-members/${widget.userId}'),
      );

      if (userRes.statusCode == 200 && familyRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        final familyData = jsonDecode(familyRes.body);
        
        if (mounted) {
          setState(() {
            _userData = userData['data'];
            _familyMembers = familyData['data'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load details';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection error';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        
        if (_isLoading) {
          return const LoadingSpinner(message: 'Loading your details...');
        }

        if (_error != null) {
          return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Wrap(
                spacing: 12,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, color: Color(0xFFE65100), size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'My Details', 
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24, 
                          fontWeight: FontWeight.bold, 
                          color: const Color(0xFF172030)
                        )
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download, size: 18),
                    label: const Text('Download ID Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Main Profile Section
              if (isMobile)
                Column(
                  children: [
                    _buildProfileCard(isMobile),
                    const SizedBox(height: 32),
                    _buildDetailsCard(isMobile),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(isMobile),
                    const SizedBox(width: 60),
                    Expanded(child: _buildDetailsCard(isMobile)),
                  ],
                ),

              const SizedBox(height: 60),

              // Family Members Section
              const Row(
                children: [
                  Icon(Icons.group, color: Color(0xFFE65100), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Family Members', 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF172030))
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFamilyTable(isMobile),
            ],
          ),
        );
      }
    );
  }

  Widget _buildProfileCard(bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 300,
      child: Column(
        children: [
          GestureDetector(
            onTap: (_userData?['Memberimage'] != null && _userData!['Memberimage'].toString().isNotEmpty)
                ? () => _showImageDialog('Profile Picture', _userData!['Memberimage'])
                : null,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                image: (_userData?['Memberimage'] != null && _userData!['Memberimage'].toString().isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage('${ApiConfig.baseUrl}/assets/uploads/${_userData!['Memberimage']}'),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (_userData?['Memberimage'] == null || _userData!['Memberimage'].toString().isEmpty)
                  ? Icon(Icons.person, size: 100, color: Colors.grey[400])
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoundIcon(Icons.credit_card, 'Aadhar Front', _userData?['Aadharfrontimage']),
              const SizedBox(width: 16),
              _buildRoundIcon(Icons.badge, 'Aadhar Back', _userData?['Aadharbackimage']),
              const SizedBox(width: 16),
              _buildRoundIcon(Icons.card_membership, 'Certificate', _userData?['Communitycertificate']),
            ],
          ),
          const SizedBox(height: 32),
          _buildActionButton('Event Participation', Icons.event_available, const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
          const SizedBox(height: 12),
          _buildActionButton('Update Details', Icons.person_outline, const Color(0xFFFFF8E1), const Color(0xFFF57C00), onTap: () {
            if (_userData != null) {
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
                      userId: widget.userId,
                      userRole: widget.userRole,
                      userData: _userData!,
                      onBack: () { Navigator.pop(context); _fetchDetails(); },
                    ),
                  ),
                ),
              );
            }
          }),
          const SizedBox(height: 12),
          _buildActionButton('Add Family Member', Icons.person_add_alt_1, const Color(0xFFE3F2FD), const Color(0xFF1976D2), onTap: () {
            if (_userData != null) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Container(
                    width: 1000,
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
                    child: AddFamilyMemberForm(
                      parentId: widget.userId,
                      parentData: _userData!,
                    ),
                  ),
                ),
              ).then((_) => _fetchDetails());
            }
          }),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow('Name:', (_userData?['Name'] ?? 'N/A').toString(), isBold: true, isBlue: true, isMobile: isMobile),
          const SizedBox(height: 32),
          _buildDetailRow('Family Membership ID:', (_userData?['Familymembershipid'] ?? 'N/A').toString(), isPill: true, isMobile: isMobile),
          const SizedBox(height: 32),
          _buildDetailRow('Phone Number:', (_userData?['Phonenumber'] ?? 'N/A').toString(), isMobile: isMobile),
          const SizedBox(height: 32),
          _buildAddressRow('Address:', _userData, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildFamilyTable(bool isMobile) {
    if (_familyMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('No family members found.', style: TextStyle(color: Colors.grey))),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFF172030)),
          columns: const [
            DataColumn(label: Text('S.No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Relationship', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Gender', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Action', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
          rows: _familyMembers.asMap().entries.map((entry) {
            final index = entry.key;
            final fm = entry.value;
            return DataRow(
              cells: [
                DataCell(Text((index + 1).toString())),
                DataCell(Text(fm['Name'] ?? 'N/A')),
                DataCell(Text(fm['MemberRole'] ?? 'N/A')),
                DataCell(Text(fm['Gender'] ?? 'N/A')),
                DataCell(
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 16, color: Color(0xFF3B82F6)),
                    label: const Text('Edit', style: TextStyle(color: Color(0xFF3B82F6))),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRoundIcon(IconData icon, String tooltip, String? imgPath) {
    final bool hasImage = imgPath != null && imgPath.isNotEmpty;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasImage ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent,
        border: Border.all(color: hasImage ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        onPressed: hasImage ? () => _showImageDialog(tooltip, imgPath) : () {},
        tooltip: tooltip,
      ),
    );
  }

  void _showImageDialog(String title, String imgName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.black45,
              elevation: 0,
              leading: const CloseButton(color: Colors.white),
            ),
            Flexible(
              child: Container(
                color: Colors.white,
                child: Image.network(
                  '${ApiConfig.baseUrl}/assets/uploads/$imgName',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Image not found'))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color bgColor, Color textColor, {VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: textColor, size: 20),
        label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          side: BorderSide(color: textColor.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool isBlue = false, bool isPill = false, required bool isMobile}) {
    final labelWidget = SizedBox(
      width: isMobile ? double.infinity : 200,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
      ),
    );

    final valueWidget = isPill
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(20)),
            child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        : Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBlue ? const Color(0xFF3B82F6) : Colors.black87,
            ),
          );

    if (isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [labelWidget, const SizedBox(height: 8), valueWidget]);
    }

    return Row(children: [labelWidget, valueWidget]);
  }

  Widget _buildAddressRow(String label, Map<String, dynamic>? data, {required bool isMobile}) {
    if (data == null) return const SizedBox.shrink();
    
    final street = data['Street'] ?? '';
    final village = data['Village'] ?? '';
    final taluk = data['Taluk'] ?? '';
    final district = data['District'] ?? '';
    final state = data['State'] ?? 'Tamil Nadu';
    final pincode = data['Pincode']?.toString() ?? '';

    final labelWidget = SizedBox(
      width: isMobile ? double.infinity : 200,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
      ),
    );

    final contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAddressLine(Icons.home, '$street'),
        const SizedBox(height: 8),
        _buildAddressLine(Icons.location_on, '$village, $taluk'),
        const SizedBox(height: 8),
        _buildAddressLine(Icons.push_pin, '$district - $pincode'),
        const SizedBox(height: 8),
        _buildAddressLine(Icons.map, state),
      ],
    );

    if (isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [labelWidget, const SizedBox(height: 12), contentWidget]);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [labelWidget, Expanded(child: contentWidget)]);
  }

  Widget _buildAddressLine(IconData icon, String text) {
    if (text.trim().isEmpty || text == 'null' || text == ', ') return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 18),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      ],
    );
  }
}
