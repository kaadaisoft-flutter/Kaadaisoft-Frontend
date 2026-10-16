import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/image_load_state.dart';
import '../../utils/api_config.dart';
import 'update_details_content.dart';
import 'package:intl/intl.dart';

class MemberDetailsContent extends StatefulWidget {
  final String numericId;
  final String familyId;
  final VoidCallback onBack;

  const MemberDetailsContent({
    super.key, 
    required this.numericId, 
    required this.familyId,
    required this.onBack,
  });

  @override
  State<MemberDetailsContent> createState() => _MemberDetailsContentState();
}

class _MemberDetailsContentState extends State<MemberDetailsContent> {
  Map<String, dynamic>? _userData;
  List<dynamic> _familyMembers = [];
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

      if (userRes.statusCode == 200 && familyRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body)['data'];
        final familyData = jsonDecode(familyRes.body)['data'];
        
        setState(() {
          _userData = userData;
          _familyMembers = familyData;
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
    final horizontalScrollController = ScrollController();
    showDialog(
      context: context,
      builder: (context) {
        final isTamil = Localizations.localeOf(context).languageCode == 'ta';
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTamil ? 'விசேஷங்களில் பங்கேற்பு' : 'Event Participation',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2D1B18)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: isTamil ? 'மூடு' : 'Close',
              ),
            ],
          ),
          content: Container(
            width: 900,
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: FutureBuilder<http.Response>(
              future: http.get(Uri.parse('${ApiConfig.baseUrl}/api/event-participation/${widget.numericId}')),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 200,
                    child: LoadingSpinner(
                      message: isTamil ? 'பங்கேற்பு விவரங்கள் பெறப்படுகின்றன...' : 'Fetching participation records...',
                    ),
                  );
                }
                if (snapshot.hasError || snapshot.data?.statusCode != 200) {
                  return SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        isTamil ? 'பங்கேற்பு விவரங்களை ஏற்றுவதில் தோல்வி' : 'Failed to load participation data',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                
                final data = jsonDecode(snapshot.data!.body)['data'] as List;
                if (data.isEmpty) {
                  return SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        isTamil ? 'விசேஷப் பங்கேற்பு விவரங்கள் எதுவும் இல்லை.' : 'No event participation found.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return RawScrollbar(
                      controller: horizontalScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      thickness: 8,
                      radius: const Radius.circular(8),
                      thumbColor: const Color(0xFFC49A3C).withValues(alpha: 0.7),
                      trackColor: Colors.grey.shade200,
                      padding: const EdgeInsets.only(bottom: 2),
                      child: SingleChildScrollView(
                        controller: horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 14),
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              border: TableBorder(verticalInside: BorderSide(color: Colors.grey.shade300, width: 1)),
                              headingRowColor: WidgetStateProperty.all(const Color(0xFF5D1712)),
                              columns: [
                                DataColumn(label: Text(isTamil ? 'வ.எண்' : 'SNo', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text(isTamil ? 'விசேஷத்தின் பெயர்' : 'Event Name', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text(isTamil ? 'கட்டணத் தொகை' : 'Tax Amount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text(isTamil ? 'செலுத்திய தொகை' : 'Paid Amount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text(isTamil ? 'நிலுவைத் தொகை' : 'Balance Amount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text(isTamil ? 'நிலை' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text(isTamil ? 'செலுத்திய தேதி' : 'Payment Date', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                              ],
                              rows: data.asMap().entries.map<DataRow>((entry) {
                                final i = entry.key;
                                final row = entry.value;
                                final statusRaw = (row['status'] ?? '').toString().toUpperCase();
                                final bool isPaid = statusRaw == 'PAID';
                                final bool isPartial = statusRaw == 'PARTIALLY PAID';

                                String statusText = row['status'] ?? 'UNKNOWN';
                                if (isTamil) {
                                  if (isPaid) {
                                    statusText = 'முழுவதும் செலுத்தப்பட்டது';
                                  } else if (isPartial) {
                                    statusText = 'பகுதி செலுத்தப்பட்டது';
                                  } else if (statusRaw == 'UNPAID') {
                                    statusText = 'செலுத்தப்படவில்லை';
                                  } else if (statusRaw == 'PENDING') {
                                    statusText = 'நிலுவை';
                                  }
                                }

                                return DataRow(cells: [
                                  DataCell(Text('${i + 1}')),
                                  DataCell(Text(row['EventName'] ?? '-')),
                                  DataCell(Text('₹${row['TaxAmount']?.toString() ?? '0'}')),
                                  DataCell(Text('₹${row['PaidAmount']?.toString() ?? '0'}')),
                                  DataCell(Text('₹${row['BalanceAmount']?.toString() ?? '0'}')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPaid
                                            ? const Color(0xFF2E7D32)
                                            : (isPartial ? Colors.orange.shade800 : const Color(0xFF5D1712)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        statusText,
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      horizontalScrollController.dispose();
    });
  }

  void _showImageViewer(String? imageName, String title) {
    if (imageName == null || imageName.isEmpty || imageName == 'null') {
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
            title: 'Update Member Details: ',
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
    final bool isTamil = Localizations.localeOf(context).languageCode == 'ta';

    if (_isLoading) {
      return LoadingSpinner(
        message: isTamil ? 'உறுப்பினர் விவரங்கள் ஏற்றப்படுகின்றன...' : 'Loading member profile...',
      );
    }
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_userData == null) {
      return Center(
        child: Text(
          isTamil ? 'விவரங்கள் எதுவும் கிடைக்கவில்லை' : 'No data found',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, color: Color(0xFF5D1712), size: 28),
                    const SizedBox(width: 12),
                    Text(
                      isTamil ? 'உறுப்பினர் விவரங்கள்:' : 'Member Details:',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final url = '${ApiConfig.baseUrl}/api/download-id-card/${widget.numericId}?origin=${Uri.base.origin}';
                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.badge_outlined, size: 18),
                  label: Text(isTamil ? 'அடையாள அட்டையைப் பதிவிறக்குக' : 'Download ID Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D1712),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Profile Section
          _buildProfileSection(isMobile, isTamil),
          const SizedBox(height: 48),

          // Family Members Section
          Row(
            children: [
              const Icon(Icons.group, color: Color(0xFF5D1712), size: 24),
              const SizedBox(width: 12),
              Text(
                isTamil ? 'குடும்ப உறுப்பினர்கள்' : 'Family Members',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFamilyTable(isTamil, isMobile),
        ],
      ),
    );
  }

  Widget _buildProfileSection(bool isMobile, bool isTamil) {
    return Center(
      child: Container(
        width: isMobile ? double.infinity : 800,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: isMobile 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatarAndActions(isTamil),
                  const SizedBox(height: 32),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: _buildDetailsColumn(isTamil),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAvatarAndActions(isTamil),
                  const SizedBox(width: 60),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: _buildDetailsColumn(isTamil),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAvatarAndActions(bool isTamil) {
    return Column(
      children: [
        Builder(
          builder: (context) {
            return ImageLoadState(
              builder: (context, profileImageFailed, setImgState) {
                final bool hasString = _userData?['Memberimage'] != null && _userData!['Memberimage'].toString().isNotEmpty && _userData!['Memberimage'].toString() != 'null';
                final bool isValidImage = hasString && !profileImageFailed;
                
                return Tooltip(
                  message: !isValidImage
                      ? (isTamil ? 'சுயவிவரப் படம் கிடைக்கவில்லை' : 'Profile Image Not Found')
                      : '',
                  waitDuration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: isValidImage
                        ? () => _showImageViewer(_userData?['Memberimage'], isTamil ? 'சுயவிவரப் படம்' : 'Profile Photo')
                        : null,
                    child: MouseRegion(
                      cursor: isValidImage ? SystemMouseCursors.click : SystemMouseCursors.basic,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: isValidImage ? Colors.white : Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(color: isValidImage ? Colors.black38 : Colors.grey[400]!),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ClipOval(
                          child: hasString
                              ? Image.network(
                                  '${ApiConfig.baseUrl}/assets/uploads/${_userData!['Memberimage']}',
                                  fit: BoxFit.cover,
                                  width: 150,
                                  height: 150,
                                  errorBuilder: (context, error, stackTrace) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      setImgState();
                                    });
                                    return Icon(Icons.person, size: 80, color: Colors.grey.shade400);
                                  },
                                )
                              : Icon(Icons.person, size: 80, color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roundIcon(
              Icons.contact_page_outlined, 
              isTamil ? 'சாதிச் சான்றிதழ்' : 'Community Certificate', 
              onTap: () => _showImageViewer(_userData?['Communitycertificateimage'], isTamil ? 'சாதிச் சான்றிதழ்' : 'Community Certificate'),
              disabled: _userData?['Communitycertificateimage'] == null || _userData!['Communitycertificateimage'].toString().isEmpty || _userData!['Communitycertificateimage'].toString() == 'null',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _actionButton(
          isTamil ? 'விசேஷங்களில் பங்கேற்பு' : 'Event Participation',
          Icons.event_available,
          const Color(0xFFE8F5E9),
          Colors.green,
          onTap: _showEventParticipationDialog,
        ),
        const SizedBox(height: 12),
        _actionButton(
          isTamil ? 'விவரங்களைப் புதுப்பிக்கவும்' : 'Update Details',
          Icons.edit_note,
          const Color(0xFFFFF3E0),
          Colors.orange,
          onTap: _showUpdateDetailsDialog,
        ),
      ],
    );
  }

  String _formatDate(String? dateStr, bool isTamil) {
    if (dateStr == null || dateStr.isEmpty) return isTamil ? 'உள்நுழையவில்லை' : 'Never';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildDetailsColumn(bool isTamil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailItem(isTamil ? 'பெயர்:' : 'Name:', _userData!['Name'] ?? 'N/A', isBlue: true, isBold: true),
        const SizedBox(height: 24),
        _detailItem(isTamil ? 'குடும்ப உறுப்பினர் எண்:' : 'Family Membership ID:', _userData!['Familymembershipid'] ?? 'N/A', isPill: true),
        const SizedBox(height: 24),
        _detailItem(isTamil ? 'மொபைல் எண்:' : 'Phone Number:', _userData!['Phonenumber']?.toString() ?? 'N/A'),
        const SizedBox(height: 24),
        _detailItem(isTamil ? 'கடைசி உள்நுழைவு:' : 'Last Login:', _formatDate(_userData!['last_login']?.toString(), isTamil)),
        const SizedBox(height: 24),
        _addressItem(isTamil ? 'முகவரி:' : 'Address:', _userData!),
      ],
    );
  }

  Widget _detailItem(String label, String value, {bool isBlue = false, bool isBold = false, bool isPill = false}) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    
    final labelWidget = SizedBox(
      width: isMobile ? double.infinity : 200,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
      ),
    );

    final valueWidget = isPill
        ? Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF5D1712), borderRadius: BorderRadius.circular(20)),
              child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        : Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBlue ? const Color(0xFF5D1712) : Colors.black87,
            ),
          );

    if (isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [labelWidget, const SizedBox(height: 8), valueWidget]);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [labelWidget, Expanded(child: valueWidget)]);
  }

  Widget _addressItem(String label, Map<String, dynamic> data) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    
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
        _addressLine(Icons.home, '$street'),
        const SizedBox(height: 8),
        _addressLine(Icons.location_on, '$village, $taluk'),
        const SizedBox(height: 8),
        _addressLine(Icons.push_pin, '$district - $pincode'),
        const SizedBox(height: 8),
        _addressLine(Icons.map, state),
      ],
    );

    if (isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [labelWidget, const SizedBox(height: 12), contentWidget]);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [labelWidget, Expanded(child: contentWidget)]);
  }

  Widget _addressLine(IconData icon, String text) {
    if (text.trim().isEmpty || text == 'null' || text == ', ' || text == ' - ') return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.4))),
      ],
    );
  }

  Widget _roundIcon(IconData icon, String tooltip, {VoidCallback? onTap, bool disabled = false}) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: disabled ? Colors.grey.withOpacity(0.5) : const Color(0xFF5D1712).withOpacity(0.5))),
      child: IconButton(
        icon: Icon(icon, color: disabled ? Colors.grey : const Color(0xFF5D1712), size: 20),
        onPressed: disabled ? null : (onTap ?? () {}),
        tooltip: disabled ? '$tooltip Not Found' : tooltip,
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

  String _translateRel(String rel, bool isTamil) {
    if (!isTamil) return rel;
    switch (rel) {
      case 'Head': return 'குடும்பத் தலைவர்';
      case 'Grand Father': return 'தாத்தா';
      case 'Grand Mother': return 'பாட்டி';
      case 'Grand Son': return 'பேரன்';
      case 'Grand Daughter': return 'பேத்தி';
      case 'Father': return 'தந்தை';
      case 'Mother': return 'தாய்';
      case 'Father-in-law': return 'மாமனார்';
      case 'Mother-in-law': return 'மாமியார்';
      case 'Husband': return 'கணவர்';
      case 'Wife': return 'மனைவி';
      case 'Son': return 'மகன்';
      case 'Daughter': return 'மகள்';
      case 'Son-in-law': return 'மருமகன்';
      case 'Daughter-in-law': return 'மருமகள்';
      case 'Brother': return 'சகோதரர்';
      case 'Sister': return 'சகோதரி';
      case 'Brother-in-law': return 'மைத்துனர்';
      case 'Sister-in-law': return 'மைத்துனி';
      case 'Uncle': return 'மாமா / பெரியப்பா / சித்தப்பா';
      case 'Aunt': return 'அத்தை / பெரியம்மா / சித்தி';
      case 'Nephew': return 'மருமகன்';
      case 'Niece': return 'மருமகள்';
      case 'Great Grand Father': return 'கொள்ளுத் தாத்தா';
      case 'Great Grand Mother': return 'கொள்ளுப் பாட்டி';
      case 'Other': return 'மற்றவை';
      default: return rel;
    }
  }

  Widget _buildFamilyTable(bool isTamil, bool isMobile) {
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

    if (tableMembers.isEmpty) {
      return Center(
        child: Container(
          width: isMobile ? double.infinity : 800,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(
              isTamil ? 'குடும்ப உறுப்பினர்கள் யாரும் இல்லை.' : 'No family members found.',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: isMobile ? double.infinity : 800,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 50,
                    columnSpacing: 32,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFF2D1B18)),
                    columns: [
                      DataColumn(label: Text(isTamil ? 'வ.எண்' : 'S.No', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(isTamil ? 'பெயர்' : 'Name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(isTamil ? 'உறவுமுறை' : 'Relationship', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(isTamil ? 'பாலினம்' : 'Gender', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(isTamil ? 'வயது' : 'Age', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ],
                    rows: tableMembers.asMap().entries.map<DataRow>((entry) {
                      final index = entry.key;
                      final fm = entry.value;
                      String gender = fm['Gender']?.toString() ?? 'N/A';
                      if (isTamil) {
                        if (gender.toLowerCase() == 'male') {
                          gender = 'ஆண்';
                        } else if (gender.toLowerCase() == 'female') {
                          gender = 'பெண்';
                        }
                      }
                      
                      return DataRow(
                        cells: [
                          DataCell(Text((index + 1).toString())),
                          DataCell(Text(fm['Name'] ?? 'N/A')),
                          DataCell(Text(_translateRel(_getDisplayRole(fm), isTamil))),
                          DataCell(Text(gender)),
                          DataCell(Text(_calculateAge(fm['Dob']))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _calculateAge(dynamic dobStrRaw) {
    if (dobStrRaw == null || dobStrRaw.toString().trim().isEmpty) return 'N/A';
    try {
      String dobStr = dobStrRaw.toString().trim().replaceAll('/', '-').replaceAll('.', '-');
      if (dobStr.contains('T')) {
        dobStr = dobStr.split('T').first;
      }
      final parts = dobStr.split('-');
      int? year, month, day;
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          year = int.tryParse(parts[0]);
          month = int.tryParse(parts[1]);
          day = int.tryParse(parts[2]);
        } else if (parts[2].length == 4) {
          year = int.tryParse(parts[2]);
          month = int.tryParse(parts[1]);
          day = int.tryParse(parts[0]);
        }
      }
      if (year != null && month != null && day != null) {
        DateTime dob = DateTime(year, month, day);
        DateTime now = DateTime.now();
        int age = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        return age >= 0 ? age.toString() : 'N/A';
      }
      return 'N/A';
    } catch (_) {
      return 'N/A';
    }
  }
}
