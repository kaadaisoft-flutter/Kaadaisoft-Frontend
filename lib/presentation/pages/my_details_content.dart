import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../l10n/app_localizations.dart';
import '../widgets/loading_spinner.dart';
import '../../utils/api_config.dart';
import 'update_details_content.dart';
import '../widgets/add_family_member_form.dart';
import '../widgets/update_family_member_form.dart';
import '../../utils/notification_helper.dart';
import '../widgets/custom_dialog.dart';


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
  final Map<String, bool> _expandedFamilies = {};
  bool _isLoading = true;
  String? _error;
  bool _isTreeView = false;
  final ScrollController _treeScrollController = ScrollController();
  Map<String, dynamic>? _myCoordinator;
  bool _isLoadingCoordinator = true;

  @override
  void dispose() {
    _treeScrollController.dispose();
    super.dispose();
  }

  void _showEventParticipationDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)?.eventParticipation ?? 'Event Participation', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ],
        ),
        content: Container(
          width: 900,
          child: FutureBuilder<http.Response>(
            future: http.get(Uri.parse('${ApiConfig.baseUrl}/api/event-participation/${widget.userId}')),
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
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          border: TableBorder(verticalInside: BorderSide(color: Colors.grey.shade300, width: 1)),
                          headingRowColor: MaterialStateProperty.all(const Color(0xFF5D1712)),
                          columns: const [
                            DataColumn(label: Text('SNo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('Event Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('Tax Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('Paid Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('Balance Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('Payment Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
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
          _fetchMyCoordinator();
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

  Future<void> _fetchMyCoordinator() async {
    if (widget.userRole != 3) {
      if (mounted) setState(() => _isLoadingCoordinator = false);
      return;
    }
    
    try {
        final fid = _userData?['Familymembershipid'];
        if (fid != null && fid.toString().isNotEmpty) {
          final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/member-coordinator-by-fid/$fid'));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (mounted) {
              setState(() {
                _myCoordinator = data['coordinator'];
                _isLoadingCoordinator = false;
              });
            }
          } else {
             if (mounted) setState(() => _isLoadingCoordinator = false);
          }
        } else {
           if (mounted) setState(() => _isLoadingCoordinator = false);
        }
    } catch (e) {
      print('Error fetching coordinator details: $e');
      if (mounted) setState(() => _isLoadingCoordinator = false);
    }
  }

  Widget _buildMyCoordinatorCard() {
    if (widget.userRole != 3) return const SizedBox.shrink();

    if (_isLoadingCoordinator) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myCoordinator == null) {
      return const Center(
        child: Text('No coordinator assigned yet.', style: TextStyle(color: Colors.black54)),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black38),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_pin, color: Color(0xFF5D1712), size: 28),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)?.coordinatorDetails ?? 'My Coordinator Details',
                style: TextStyle(
                  color: Color(0xFF5D1712),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _buildCoordinatorInfo(AppLocalizations.of(context)?.nameHeader ?? 'Name', _myCoordinator!['Name']?.toString() ?? 'N/A'),
              _buildCoordinatorInfo(AppLocalizations.of(context)?.mobileLabel ?? 'Mobile', _myCoordinator!['Phonenumber']?.toString() ?? 'N/A'),
              _buildCoordinatorInfo(AppLocalizations.of(context)?.villageLabel ?? 'Village', _myCoordinator!['Village']?.toString() ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatorInfo(String label, String value) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFF2D1B18),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        
        if (_isLoading) {
          return const LoadingSpinner(message: 'Loading your details...');
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_pin, color: const Color(0xFFE65100), size: isMobile ? 24 : 32),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)?.myDetails ?? 'My Details', 
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 28, 
                              fontWeight: FontWeight.bold, 
                              color: const Color(0xFF2D1B18),
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                    _buildMyCoordinatorCard(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(isMobile),
                    const SizedBox(width: 60),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailsCard(isMobile),
                          _buildMyCoordinatorCard(),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 60),

              // Family Members Section
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group, color: Color(0xFFE65100), size: 28),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)?.familyMembersList ?? 'Family Members', 
                        style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF2D1B18))
                      ),
                    ],
                  ),
                  // Toggle Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButton(AppLocalizations.of(context)?.tableView ?? 'Table', Icons.table_chart, !_isTreeView, () => setState(() => _isTreeView = false)),
                        _buildToggleButton(AppLocalizations.of(context)?.treeView ?? 'Tree', Icons.account_tree, _isTreeView, () => setState(() => _isTreeView = true)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _isTreeView ? _buildFamilyTree(isMobile) : _buildFamilyTable(isMobile),
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
          _ImageLoadState(builder: (context, profileImageFailed, setImgState) {
            final hasProfileImage = _userData?['Memberimage'] != null && _userData!['Memberimage'].toString().isNotEmpty;
            return Tooltip(
              message: !hasProfileImage || profileImageFailed ? 'Profile Image Not Found' : '',
              waitDuration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: (hasProfileImage && !profileImageFailed)
                    ? () => _showImageDialog('Profile Picture', _userData!['Memberimage'])
                    : null,
                child: MouseRegion(
                cursor: (hasProfileImage && !profileImageFailed) ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: (hasProfileImage && !profileImageFailed) ? Colors.white : Colors.grey[200],
                    shape: BoxShape.circle,
                    border: Border.all(color: (hasProfileImage && !profileImageFailed) ? Colors.black38 : Colors.grey[400]!),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipOval(
                    child: hasProfileImage && !profileImageFailed
                        ? Image.network(
                            '${ApiConfig.baseUrl}/assets/uploads/${_userData!['Memberimage']}',
                            fit: BoxFit.cover,
                            width: 200,
                            height: 200,
                            errorBuilder: (context, error, stackTrace) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setImgState();
                              });
                              return Icon(Icons.person, size: 100, color: Colors.grey[400]);
                            },
                          )
                        : Icon(Icons.person, size: 100, color: Colors.grey[400]),
                  ),
                ),
              ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoundIcon(Icons.contact_page, 'Certificate', _userData?['Communitycertificate']),
            ],
          ),
          const SizedBox(height: 32),
          _buildActionButton(AppLocalizations.of(context)?.eventParticipation ?? 'Event Participation', Icons.event_available, const Color(0xFFE8F5E9), const Color(0xFF2E7D32), onTap: _showEventParticipationDialog),
          const SizedBox(height: 12),
          _buildActionButton(AppLocalizations.of(context)?.updateDetails ?? 'Update Details', Icons.person_outline, const Color(0xFFFFF8E1), const Color(0xFFF57C00), onTap: () {
            if (_userData != null) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 24),
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
          _buildActionButton(AppLocalizations.of(context)?.addFamilyMember ?? 'Add Family Member', Icons.person_add_alt_1, const Color(0xFFF5E6E6), const Color(0xFF5D1712), onTap: () {
            if (_userData != null) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AddFamilyMemberForm(
                  parentId: widget.userId,
                  parentData: _userData!,
                  submitterRole: widget.userRole,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black38),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDetailRow(AppLocalizations.of(context)?.nameLabel ?? 'Name:', (_userData?['Name'] ?? 'N/A').toString(), isBold: true, isBlue: true, isMobile: isMobile)),
              if (_userData?['has_pending_update'] == true)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_top, color: Colors.orange, size: 14),
                      SizedBox(width: 4),
                      Text('Waiting for update approval', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          _buildDetailRow(AppLocalizations.of(context)?.familyMembershipId ?? 'Family Membership ID:', (_userData?['Familymembershipid'] ?? 'N/A').toString(), isPill: true, isMobile: isMobile),
          const SizedBox(height: 16),
          _buildDetailRow(AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number:', (_userData?['Phonenumber'] ?? 'N/A').toString(), isMobile: isMobile),
          const SizedBox(height: 16),
          _buildAddressRow(AppLocalizations.of(context)?.address ?? 'Address:', _userData, isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D1B18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyTree(bool isMobile) {
    if (_familyMembers.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: Text('No family members found.', style: TextStyle(color: Colors.grey))),
      );
    }

    bool isSubHead(dynamic m) {
      if (m['MemberRole'] == 'Head' && (m['Existfamilyid']?.toString().trim() ?? '').isNotEmpty) return true;
      if (['Daughter', 'Sister'].contains(m['MemberRole'])) {
          bool hasHusband = m['husband_name'] != null && m['husband_name'].toString().trim().isNotEmpty;
          if (hasHusband) return true;
      }
      if (['Son', 'Brother', 'Uncle'].contains(m['MemberRole']) && m['Married']?.toString().toLowerCase() == 'yes') {
          return true;
      }
      return false;
    }
    
    String currentFmId = _userData?['Familymembershipid']?.toString() ?? '';
    String currentExistId = _userData?['Existfamilyid']?.toString() ?? '';
    String topLevelId = '';
    for (var fm in _familyMembers) {
      if ((fm['Existfamilyid']?.toString().trim() ?? '').isEmpty && fm['MemberRole'] == 'Head') {
        topLevelId = fm['Familymembershipid']?.toString() ?? '';
        break;
      }
    }
    if (topLevelId.isEmpty) {
        topLevelId = currentFmId.isNotEmpty ? currentFmId : currentExistId;
    }
    
    Set<String> subHeadFmIds = _familyMembers
        .where((m) => isSubHead(m) && !['Daughter', 'Sister', 'Niece', 'Grand Daughter', 'Great Grand Daughter'].contains(m['MemberRole']))
        .map((m) => m['Familymembershipid']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
        
    bool isSubSpouse(dynamic m) {
      if (!['Wife', 'Husband'].contains(m['MemberRole'])) return false;
      String existId = m['Existfamilyid']?.toString().trim() ?? '';
      return subHeadFmIds.contains(existId);
    }

    final grandparents = _familyMembers.where((m) => m['MemberRole'] == 'Grand Father' || m['MemberRole'] == 'Grand Mother').toList();
    final parents = _familyMembers.where((m) => m['MemberRole'] == 'Father' || m['MemberRole'] == 'Mother').toList();
    final headAndSpouse = _familyMembers.where((m) => ['Head', 'Wife', 'Husband'].contains(m['MemberRole']) && !isSubHead(m) && !isSubSpouse(m)).toList();
    final siblings = _familyMembers.where((m) => ['Brother', 'Sister'].contains(m['MemberRole'])).toList();
    
    final grandchildren = _familyMembers.where((m) {
      String existId = m['Existfamilyid']?.toString().trim() ?? '';
      return subHeadFmIds.contains(existId) && !['Head', 'Wife', 'Husband'].contains(m['MemberRole']);
    }).toList();

    final children = _familyMembers.where((m) {
      String existId = m['Existfamilyid']?.toString().trim() ?? '';
      
      if (existId == topLevelId && topLevelId.isNotEmpty) {
          if (['Head', 'Wife', 'Husband'].contains(m['MemberRole']) && !isSubHead(m) && !isSubSpouse(m)) {
              return false; // Belong to headAndSpouse
          }
          if (['Father', 'Mother', 'Grand Father', 'Grand Mother', 'Brother', 'Sister'].contains(m['MemberRole'])) {
              return false; // Already categorized in parents/grandparents/siblings
          }
          return true; // Immediate children of topLevelId
      }
      
      if (topLevelId.isEmpty) {
          if (isSubHead(m) || isSubSpouse(m)) return true;
          if (['Son', 'Daughter', 'Son-in-law', 'Daughter-in-law'].contains(m['MemberRole'])) return true;
      }
      
      return false;
    }).toList();
    
    final others = _familyMembers.where((m) => !grandparents.contains(m) && !parents.contains(m) && !headAndSpouse.contains(m) && !siblings.contains(m) && !children.contains(m) && !grandchildren.contains(m)).toList();

    Widget buildVerticalLine() {
      return Container(
        width: 2,
        height: 40,
        color: const Color(0xFF2D1B18).withOpacity(0.3),
        margin: const EdgeInsets.symmetric(vertical: 8),
      );
    }

    Widget buildTreeRow(List<dynamic> members, String role, {bool isRoot = false}) {
      if (members.isEmpty) return const SizedBox.shrink();
      
      List<Widget> groupedWidgets = [];
      Set<String> processedIds = {};
      
      Map<String, int> roleTotalCounts = {};
      Map<String, int> roleCurrentCounts = {};
      for (var m in members) {
        if (isSubHead(m)) {
          String displayRole = _getDisplayRole(m);
          roleTotalCounts[displayRole] = (roleTotalCounts[displayRole] ?? 0) + 1;
        }
      }
      
      for (var m in members) {
        String mId = m['Id']?.toString() ?? '';
        if (mId.isNotEmpty && processedIds.contains(mId)) continue;
        
        bool isAnyHead = m['MemberRole'] == 'Head';
        bool isFather = m['MemberRole'] == 'Father';
        bool isGrandFather = m['MemberRole'] == 'Grand Father';
        
        bool isWife = m['MemberRole'] == 'Wife' || m['MemberRole'] == 'Husband';
        bool isMother = m['MemberRole'] == 'Mother';
        bool isGrandMother = m['MemberRole'] == 'Grand Mother';
        
        if (isWife) {
           String mExId = m['Existfamilyid']?.toString() ?? '';
           bool hasPartner = members.any((s) => s['MemberRole'] == 'Head' && s['Familymembershipid']?.toString() == mExId);
           if (hasPartner) continue;
        } else if (isMother) {
           String mExId = m['Existfamilyid']?.toString() ?? '';
           bool hasPartner = members.any((s) => s['MemberRole'] == 'Father' && s['Existfamilyid']?.toString() == mExId);
           if (hasPartner) continue;
        } else if (isGrandMother) {
           String mExId = m['Existfamilyid']?.toString() ?? '';
           bool hasPartner = members.any((s) => s['MemberRole'] == 'Grand Father' && s['Existfamilyid']?.toString() == mExId);
           if (hasPartner) continue;
        }
        
        List<dynamic> spouse = [];
        
        if (isAnyHead) {
          String mFmId = m['Familymembershipid']?.toString() ?? '';
          spouse = _familyMembers.where((s) => ['Wife', 'Husband'].contains(s['MemberRole']) && s['Existfamilyid']?.toString() == mFmId).toList();
        } else if (isFather) {
          String mExId = m['Existfamilyid']?.toString() ?? '';
          spouse = members.where((s) => s['MemberRole'] == 'Mother' && s['Existfamilyid']?.toString() == mExId).toList();
        } else if (isGrandFather) {
          String mExId = m['Existfamilyid']?.toString() ?? '';
          spouse = members.where((s) => s['MemberRole'] == 'Grand Mother' && s['Existfamilyid']?.toString() == mExId).toList();
        } else if (isSubHead(m)) {
          bool isFemaleSubHead = ['Daughter', 'Sister', 'Niece', 'Grand Daughter', 'Great Grand Daughter'].contains(m['MemberRole']);
          if (!isFemaleSubHead) {
            String mFmId = m['Familymembershipid']?.toString() ?? '';
            if (mFmId.isNotEmpty) {
              spouse = _familyMembers.where((s) => 
                ['Wife', 'Husband', 'Son-in-law', 'Daughter-in-law'].contains(s['MemberRole']) && 
                s['Existfamilyid']?.toString() == mFmId && 
                s['Id'] != m['Id']
              ).toList();
            }
          }
        }
        
          if (spouse.isNotEmpty) {
          List<Widget> spouseWidgets = [];
          for (var s in spouse) {
              spouseWidgets.add(SizedBox(
                width: 50,
                child: Center(
                  child: Text('↔', style: TextStyle(fontSize: 32, color: Colors.grey.shade500, fontWeight: FontWeight.w300)),
                ),
              ));
            spouseWidgets.add(_buildTreeNodeCard(s));
            processedIds.add(s['Id']?.toString() ?? '');
          }
          
          Widget nodeWidget = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTreeNodeCard(m),
              ...spouseWidgets,
            ],
          );
          
          if (isSubHead(m)) {
             String mFmId = m['Familymembershipid']?.toString() ?? '';
             var myKids = grandchildren.where((c) => c['Existfamilyid']?.toString().trim() == mFmId && c['Id']?.toString() != m['Id']?.toString()).toList();
             
             if (myKids.isNotEmpty) {
                 String uniqueBoxId = m['Familymembershipid']?.toString() ?? m['Id']?.toString() ?? '';
                 Widget originalNodeWidget = nodeWidget;
                 nodeWidget = StatefulBuilder(
                   key: ValueKey('tree_node_state_$uniqueBoxId'),
                   builder: (context, setBoxState) {
                     bool isExpanded = _expandedFamilies[uniqueBoxId] ?? false;
                     return Column(
                       children: [
                         originalNodeWidget,
                         const SizedBox(height: 8),
                         InkWell(
                           onTap: () {
                             setBoxState(() {
                               _expandedFamilies[uniqueBoxId] = !isExpanded;
                             });
                           },
                           borderRadius: BorderRadius.circular(20),
                           child: Container(
                             padding: const EdgeInsets.all(4),
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               color: Colors.white,
                               border: Border.all(color: Colors.grey.shade300),
                               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                             ),
                             child: Icon(isExpanded ? Icons.remove : Icons.add, size: 18, color: const Color(0xFFE65100)),
                           ),
                         ),
                         if (isExpanded) ...[
                           buildVerticalLine(),
                           buildTreeRow(myKids, 'SubKids'),
                         ],
                       ],
                     );
                   },
                 );
             }
          }
          
          groupedWidgets.add(nodeWidget);
        } else {
          Widget nodeWidget = _buildTreeNodeCard(m);
          
          if ((m['MemberRole'] == 'Daughter' || m['MemberRole'] == 'Sister') && m['husband_name'] != null && m['husband_name'].toString().trim().isNotEmpty) {
             String mDisplayRole = _getDisplayRole(m);
             String syntheticRole = 'Husband';
             if (mDisplayRole == 'Daughter') syntheticRole = 'Son-in-law';
             else if (mDisplayRole == 'Sister') syntheticRole = 'Brother-in-law';
             else if (mDisplayRole == 'Aunt') syntheticRole = 'Uncle';
             else if (mDisplayRole == 'Great Aunt') syntheticRole = 'Great Uncle';
             else if (mDisplayRole == 'Great Great Aunt') syntheticRole = 'Great Great Uncle';
             else if (mDisplayRole == 'Grand Daughter') syntheticRole = 'Grand Son-in-law';
             else if (mDisplayRole == 'Great Grand Daughter') syntheticRole = 'Great Grand Son-in-law';
             else if (mDisplayRole == 'Niece') syntheticRole = 'Nephew-in-law';
             else if (mDisplayRole == 'Grand Niece') syntheticRole = 'Grand Nephew-in-law';
             else if (mDisplayRole == 'Great Grand Niece') syntheticRole = 'Great Grand Nephew-in-law';
             
             Map<String, dynamic> synthHusband = {
                'Id': 'synth_${m['Id']}',
                'Name': m['husband_name'],
                'MemberRole': syntheticRole,
                'Gender': 'Male',
                'Dob': m['husband_dob'],
                'isSynthetic': true,
             };
             
             Widget husbandNode = _buildTreeNodeCard(synthHusband);
             nodeWidget = Row(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.center,
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 nodeWidget,
                 SizedBox(
                   width: 50,
                   child: Center(
                     child: Text('↔', style: TextStyle(fontSize: 32, color: Colors.grey.shade500, fontWeight: FontWeight.w300)),
                   ),
                 ),
                 husbandNode,
               ],
             );
          }
          
          if (isSubHead(m)) {
             String mFmId = m['Familymembershipid']?.toString() ?? '';
             var myKids = grandchildren.where((c) => c['Existfamilyid']?.toString().trim() == mFmId && c['Id']?.toString() != m['Id']?.toString()).toList();
             
             if (myKids.isNotEmpty) {
                 String uniqueBoxId = m['Familymembershipid']?.toString() ?? m['Id']?.toString() ?? '';
                 Widget originalNodeWidget = nodeWidget;
                 nodeWidget = StatefulBuilder(
                   key: ValueKey('tree_node_state_$uniqueBoxId'),
                   builder: (context, setBoxState) {
                     bool isExpanded = _expandedFamilies[uniqueBoxId] ?? false;
                     return Column(
                       children: [
                         originalNodeWidget,
                         const SizedBox(height: 8),
                         InkWell(
                           onTap: () {
                             setBoxState(() {
                               _expandedFamilies[uniqueBoxId] = !isExpanded;
                             });
                           },
                           borderRadius: BorderRadius.circular(20),
                           child: Container(
                             padding: const EdgeInsets.all(4),
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               color: Colors.white,
                               border: Border.all(color: Colors.grey.shade300),
                               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                             ),
                             child: Icon(isExpanded ? Icons.remove : Icons.add, size: 18, color: const Color(0xFFE65100)),
                           ),
                         ),
                         if (isExpanded) ...[
                           buildVerticalLine(),
                           buildTreeRow(myKids, 'SubKids'),
                         ],
                       ],
                     );
                   },
                 );
             }
          }
          
          groupedWidgets.add(nodeWidget);
        }
        processedIds.add(mId);
      }
      
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: groupedWidgets.asMap().entries.map<Widget>((entry) {
                int index = entry.key;
                Widget w = entry.value;
                bool isFirst = index == 0;
                bool isLast = index == groupedWidgets.length - 1;
                bool isOnly = groupedWidgets.length == 1;

                return IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isRoot)
                        SizedBox(
                          height: 20,
                          child: isOnly
                              ? Center(
                                  child: Container(
                                    width: 1,
                                    color: const Color(0xFF2D1B18).withOpacity(0.3),
                                  ),
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: isFirst ? Colors.transparent : const Color(0xFF2D1B18).withOpacity(0.3),
                                              width: 1,
                                            ),
                                            right: BorderSide(
                                              color: const Color(0xFF2D1B18).withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: isLast ? Colors.transparent : const Color(0xFF2D1B18).withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: w,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      );
    }


    List<Widget> treeWidgets = [];
    bool rootFound = false;
    
    if (grandparents.isNotEmpty) {
      treeWidgets.add(buildTreeRow(grandparents, 'Grandparents', isRoot: !rootFound));
      rootFound = true;
      treeWidgets.add(buildVerticalLine());
    }
    if (parents.isNotEmpty) {
      treeWidgets.add(buildTreeRow(parents, 'Parents', isRoot: !rootFound));
      rootFound = true;
      treeWidgets.add(buildVerticalLine());
    }
    
    List<dynamic> middleLayer = [...headAndSpouse, ...siblings];
    if (middleLayer.isNotEmpty) {
      treeWidgets.add(buildTreeRow(middleLayer, 'Head & Siblings', isRoot: !rootFound));
      rootFound = true;
      if (children.isNotEmpty) treeWidgets.add(buildVerticalLine());
    }
    
    if (children.isNotEmpty) {
      treeWidgets.add(buildTreeRow(children, 'Children', isRoot: !rootFound));
      rootFound = true;
    }
    
    // Grandchildren are now rendered recursively under their respective Sub-Head parents
    
    // Remove spouses of Sub-Heads from others so they aren't rendered twice
    others.removeWhere((o) {
      if (!['Wife', 'Husband', 'Son-in-law', 'Daughter-in-law'].contains(o['MemberRole'])) return false;
      String oExId = o['Existfamilyid']?.toString() ?? '';
      return _familyMembers.any((fm) => fm['Familymembershipid']?.toString() == oExId && isSubHead(fm) && fm['Id'] != o['Id']);
    });
    
    if (others.isNotEmpty) {
      if (treeWidgets.isNotEmpty) {
        treeWidgets.add(const SizedBox(height: 24));
        treeWidgets.add(const Divider());
        treeWidgets.add(const SizedBox(height: 24));
      }
      treeWidgets.add(buildTreeRow(others, 'Others'));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _treeScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _treeScrollController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: treeWidgets,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
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
    String myRole = _userData?['MemberRole']?.toString() ?? '';
    
    String topLevelId = '';
    for (var fm in _familyMembers) {
      if ((fm['Existfamilyid']?.toString().trim() ?? '').isEmpty && fm['MemberRole'] == 'Head') {
        topLevelId = fm['Familymembershipid']?.toString() ?? '';
        break;
      }
    }
    if (topLevelId.isEmpty) {
        topLevelId = currentFmId.isNotEmpty ? currentFmId : currentExistId;
    }
    
    // Check if this member is MY spouse (they share my exist/fm id, and I am married)
    bool amIMarried = _userData?['Married']?.toString().toLowerCase() == 'yes';
    if (amIMarried && ['Wife', 'Husband'].contains(role)) {
       // Since the database links spouses via Existfamilyid matching the husband's Familymembershipid
       if (memberExId == currentFmId && currentFmId.isNotEmpty) {
           // To avoid colliding with parents' spouses, check if they were added specifically as our spouse
           String myGender = _userData?['Gender']?.toString().toLowerCase() ?? 'male';
           if (myGender == 'male' && role == 'Wife') return 'Wife';
           if (myGender == 'female' && role == 'Husband') return 'Husband';
       }
    }
    
    // Override for Grand Son logged in viewing Father/Mother
    if (myRole == 'Grand Son' || myRole == 'Grand Daughter') {
        if (role == 'Son' && (memberExId == currentExistId || memberFmId == currentExistId)) {
            return gender == 'female' ? 'Mother' : 'Father'; // The son of the head is our father
        }
        if (role == 'Wife' && (memberExId == currentExistId || memberFmId == currentExistId)) {
            // Is it our wife or mother? We already checked 'Wife' above, so if it falls through, it might be Mother
            return 'Mother';
        }
    }
    
    // Override for Son/Daughter logged in viewing their parents
    if (myRole == 'Son' || myRole == 'Daughter') {
        if (memberFmId == currentExistId && currentExistId.isNotEmpty) {
            return gender == 'female' ? 'Mother' : 'Father'; // The member with our ExistID is our direct parent
        }
        if (memberExId == currentExistId && currentExistId.isNotEmpty && memberFmId != currentExistId) {
            if (role == 'Wife') return 'Mother'; // The wife of our parent is our mother
        }
    }

    // Override for Head viewing their parents when parents are marked as Son/Wife instead of Head
    if (myRole == 'Head' && currentExistId.isNotEmpty) {
        if (memberFmId == currentExistId && memberFmId.isNotEmpty) {
            // The member whose FMID matches our ExistID is our direct parent
            if (role == 'Son' || role == 'Head') return gender == 'female' ? 'Mother' : 'Father';
        }
        if (memberExId == currentExistId && memberExId.isNotEmpty && memberFmId != currentExistId) {
            // Other members sharing the parent's exist ID
            if (role == 'Wife') return 'Mother';
            if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Sister' : 'Brother';
        }
    }

    // --- Special case: logged-in user is a Wife or Husband ---
    // Their existfamilyid points to their SPOUSE's FmId, not a parent family.
    bool amIWifeOrHusband = (myRole == 'Wife' || myRole == 'Husband') && currentExistId.isNotEmpty;
    
    if (amIWifeOrHusband) {
      String spouseFmId = currentExistId;
      
      if (memberFmId == currentFmId) {
        return myRole;
      }
      if (memberFmId == spouseFmId) {
        return gender == 'female' ? 'Wife' : 'Husband';
      }
      
      int depthFm = -1;
      int depthEx = -1;
      String curr = spouseFmId;
      
      for (int i = 0; i < 6; i++) {
        if (curr == memberFmId && depthFm == -1) {
          depthFm = i;
        }
        if (memberExId.isNotEmpty && curr == memberExId && depthEx == -1) {
          depthEx = i;
        }
        
        String parentEx = '';
        var matches = _familyMembers.where((fm) => fm['Familymembershipid']?.toString() == curr);
        if (matches.isNotEmpty) {
          parentEx = matches.first['Existfamilyid']?.toString() ?? '';
        }
        if (parentEx.isEmpty) break;
        curr = parentEx;
      }
      
      if (depthFm == 1) {
        return gender == 'female' ? 'Mother-in-law' : 'Father-in-law';
      }
      if (depthEx == 1) {
        if (role == 'Head') return gender == 'female' ? 'Sister-in-law' : 'Brother-in-law';
        if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Sister-in-law' : 'Brother-in-law';
        if (role == 'Wife') return 'Mother-in-law';
        if (role == 'Husband') return 'Father-in-law';
      }
      
      if (depthFm == 2) {
        return gender == 'female' ? 'Grand Mother-in-law' : 'Grand Father-in-law';
      }
      if (depthEx == 2) {
        if (role == 'Head') return gender == 'female' ? 'Aunt-in-law' : 'Uncle-in-law';
        if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Aunt-in-law' : 'Uncle-in-law';
        if (role == 'Wife') return 'Grand Mother-in-law';
        if (role == 'Husband') return 'Grand Father-in-law';
      }
      
      if (depthFm == 3) {
        return gender == 'female' ? 'Great Grand Mother-in-law' : 'Great Grand Father-in-law';
      }
      if (depthEx == 3) {
        if (role == 'Wife') return 'Great Grand Mother-in-law';
        if (role == 'Husband') return 'Great Grand Father-in-law';
      }
      
      if (memberExId == spouseFmId) {
        if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Daughter' : 'Son';
        if (role == 'Head') return gender == 'female' ? 'Daughter' : 'Son';
      }
      
      return role;
    }
    
    bool amISubHead = currentFmId.isNotEmpty && currentExistId.isNotEmpty;
    
    if (amISubHead) {
      if (memberFmId == currentExistId && memberFmId.isNotEmpty) {
        if (role == 'Head') return gender == 'female' ? 'Mother' : 'Father';
      }
      if (memberExId == currentExistId && memberExId.isNotEmpty) {
        if (memberFmId == currentFmId && currentFmId.isNotEmpty) {
          return 'Head';
        }
        if (role == 'Head') return gender == 'female' ? 'Sister' : 'Brother'; // Sibling Sub-Head
        if (role == 'Wife' || role == 'Husband') return gender == 'male' ? 'Father' : 'Mother';
        if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Sister' : 'Brother';
        if (['Brother', 'Sister'].contains(role)) return gender == 'female' ? 'Aunt' : 'Uncle';
        if (['Father', 'Mother'].contains(role)) return gender == 'female' ? 'Grand Mother' : 'Grand Father';
        if (['Grand Father', 'Grand Mother'].contains(role)) return gender == 'female' ? 'Great Grand Mother' : 'Great Grand Father';
      }
      // Dynamic Ancestor Tracing (UP the tree)
      int depthUp = 0;
      int depthUpEx = 0;
      String currUp = currentExistId;
      int d = 1;
      for (int i = 0; i < 10; i++) {
        if (currUp.isEmpty) break;
        if (memberFmId.isNotEmpty && currUp == memberFmId) depthUp = d;
        if (memberExId.isNotEmpty && currUp == memberExId) depthUpEx = d;
        if (depthUp > 0 && depthUpEx > 0) break;
        
        var matches = _familyMembers.where((fm) => fm['Familymembershipid']?.toString() == currUp);
        if (matches.isEmpty) break;
        currUp = matches.first['Existfamilyid']?.toString() ?? '';
        d++;
      }

      // If they are a direct ancestor
      if (depthUp > 0) {
        if (depthUp == 2) return gender == 'female' ? 'Grand Mother' : 'Grand Father';
        if (depthUp == 3) return gender == 'female' ? 'Great Grand Mother' : 'Great Grand Father';
        if (depthUp == 4) return gender == 'female' ? 'Great Great Grand Mother' : 'Great Great Grand Father';
        if (depthUp >= 5) return gender == 'female' ? 'Great Great Great Grand Mother' : 'Great Great Great Grand Father';
      }
      
      // If they share an Exist ID with a direct ancestor (Spouses or Siblings of ancestors)
      if (depthUpEx > 0 && depthUp == 0) {
        if (depthUpEx == 2) {
          if (role == 'Wife') return 'Grand Mother';
          if (role == 'Husband') return 'Grand Father';
          if (['Son', 'Daughter', 'Head'].contains(role)) return gender == 'female' ? 'Aunt' : 'Uncle';
        }
        if (depthUpEx == 3) {
          if (role == 'Wife') return 'Great Grand Mother';
          if (role == 'Husband') return 'Great Grand Father';
          if (['Son', 'Daughter', 'Head'].contains(role)) return gender == 'female' ? 'Great Aunt' : 'Great Uncle';
        }
        if (depthUpEx == 4) {
          if (role == 'Wife') return 'Great Great Grand Mother';
          if (role == 'Husband') return 'Great Great Grand Father';
          if (['Son', 'Daughter', 'Head'].contains(role)) return gender == 'female' ? 'Great Great Aunt' : 'Great Great Uncle';
        }
        if (depthUpEx >= 5) {
          if (role == 'Wife') return 'Great Great Great Grand Mother';
          if (role == 'Husband') return 'Great Great Great Grand Father';
        }
      }
      
      // Extended family tracing
      if (memberExId.isNotEmpty && memberExId != currentExistId && memberExId != currentFmId && memberExId != topLevelId) {
        int depthFromCurrent = -1;
        int depthFromParent = -1;
        
        String curr = memberExId;
        int d = 1;
        for (int i = 0; i < 5; i++) {
          var matches = _familyMembers.where((fm) => fm['Familymembershipid']?.toString() == curr);
          if (matches.isEmpty) break;
          String pExId = matches.first['Existfamilyid']?.toString() ?? '';
          if (pExId.isEmpty) break;
          d++;
          if (pExId == currentFmId) { depthFromCurrent = d; break; }
          if (pExId == currentExistId) { depthFromParent = d; break; }
          curr = pExId;
        }

        if (depthFromCurrent == 2) {
          if (role == 'Wife') return 'Daughter-in-law';
          if (role == 'Husband') return 'Son-in-law';
          if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Grand Daughter' : 'Grand Son';
          if (role == 'Head') return gender == 'female' ? 'Grand Daughter' : 'Grand Son';
        } else if (depthFromCurrent == 3) {
          if (role == 'Wife') return 'Grand Daughter-in-law';
          if (role == 'Husband') return 'Grand Son-in-law';
          if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Great Grand Daughter' : 'Great Grand Son';
          if (role == 'Head') return gender == 'female' ? 'Great Grand Daughter' : 'Great Grand Son';
        } else if (depthFromCurrent >= 4) {
          if (role == 'Wife') return 'Great Grand Daughter-in-law';
          if (role == 'Husband') return 'Great Grand Son-in-law';
          if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Great Great Grand Daughter' : 'Great Great Grand Son';
        } else if (depthFromParent == 2) {
          if (role == 'Wife') return 'Sister-in-law';
          if (role == 'Husband') return 'Brother-in-law';
          if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Niece' : 'Nephew';
          if (role == 'Head') return gender == 'female' ? 'Niece' : 'Nephew';
        } else if (depthFromParent == 3) {
          if (role == 'Wife') return 'Niece-in-law';
          if (role == 'Husband') return 'Nephew-in-law';
          if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Grand Niece' : 'Grand Nephew';
          if (role == 'Head') return gender == 'female' ? 'Grand Niece' : 'Grand Nephew';
        } else if (depthFromParent >= 4) {
          if (role == 'Wife') return 'Grand Niece-in-law';
          if (role == 'Husband') return 'Grand Nephew-in-law';
          if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Great Grand Niece' : 'Great Grand Nephew';
          if (role == 'Head') return gender == 'female' ? 'Great Grand Niece' : 'Great Grand Nephew';
        } else if (depthFromCurrent == -1 && depthFromParent == -1 && myRole == 'Head') {
          // Fallback: If a member is fetched but completely disconnected (due to missing intermediate nodes),
          // and we are Head, they are almost certainly the parents that the backend tried to fetch.
          if (role == 'Son' || role == 'Head') return gender == 'female' ? 'Mother' : 'Father';
          if (role == 'Wife') return 'Mother';
          return role; // Keep their role if we don't know
        } else {
          // The member's existfamilyid may be pointing to a subhead's own FmId (e.g. Keerthi → Rohan's FmId)
          // Check if the member is a Wife/Husband whose existfamilyid is a cousin's FmId
          if ((role == 'Wife' || role == 'Husband') && memberExId.isNotEmpty) {
            // Find the spouse (the subhead) and get their display role
            String spouseDisplayRole = '';
            for (var fm in _familyMembers) {
              if (fm['Familymembershipid']?.toString() == memberExId) {
                spouseDisplayRole = _getDisplayRole(fm);
                break;
              }
            }
            // Map spouse display role to correct relationship term
            const Map<String, String> wifeOfMap = {
              'Uncle': 'Aunt',
              'Brother': 'Sister-in-law',
              'Cousin': "Cousin's Wife",
              'Nephew': 'Niece-in-law',
              'Son': 'Daughter-in-law',
              'Grand Son': 'Grand Daughter-in-law',
              'Great Grand Son': 'Great Grand Daughter-in-law',
            };
            const Map<String, String> husbandOfMap = {
              'Aunt': 'Uncle',
              'Sister': 'Brother-in-law',
              'Cousin': "Cousin's Husband",
              'Niece': 'Nephew-in-law',
              'Daughter': 'Son-in-law',
              'Grand Daughter': 'Grand Son-in-law',
              'Great Grand Daughter': 'Great Grand Son-in-law',
            };
            if (role == 'Wife' && wifeOfMap.containsKey(spouseDisplayRole)) {
              return wifeOfMap[spouseDisplayRole]!;
            }
            if (role == 'Husband' && husbandOfMap.containsKey(spouseDisplayRole)) {
              return husbandOfMap[spouseDisplayRole]!;
            }
            // Generic fallback
            if (spouseDisplayRole.isNotEmpty && spouseDisplayRole != role) {
              return gender == 'female' ? "$spouseDisplayRole's Wife" : "$spouseDisplayRole's Husband";
            }
          }
          if (role == 'Wife') return 'Aunt';
          if (role == 'Husband') return 'Uncle';
          if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Cousin' : 'Cousin';
          if (role == 'Head') return gender == 'female' ? 'Aunt' : 'Uncle';
        }
      }
    } else {
      bool isFmSubHead = role == 'Head' && memberExId.isNotEmpty;
      if (isFmSubHead && memberExId == topLevelId) {
        return gender == 'female' ? 'Daughter' : 'Son';
      }
      
      bool belongsToSubHead = memberExId.isNotEmpty && memberExId != topLevelId;
      if (belongsToSubHead) {
        int depth = 1;
        String currentExId = memberExId;
        for (int i = 0; i < 5; i++) {
          var matches = _familyMembers.where((fm) => fm['Familymembershipid']?.toString() == currentExId);
          if (matches.isEmpty) break;
          var parent = matches.first;
          String pExId = parent['Existfamilyid']?.toString() ?? '';
          if (pExId.isEmpty) break;
          depth++;
          if (pExId == topLevelId) break;
          currentExId = pExId;
        }
        
        if (depth == 2) {
            if (role == 'Wife') return 'Daughter-in-law';
            if (role == 'Husband') return 'Son-in-law';
            if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Grand Daughter' : 'Grand Son';
        } else if (depth == 3) {
            if (role == 'Wife') return 'Grand Daughter-in-law';
            if (role == 'Husband') return 'Grand Son-in-law';
            if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Great Grand Daughter' : 'Great Grand Son';
        } else if (depth >= 4) {
            if (role == 'Wife') return 'Great Grand Daughter-in-law';
            if (role == 'Husband') return 'Great Grand Son-in-law';
            if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Great Great Grand Daughter' : 'Great Great Grand Son';
        } else {
            if (role == 'Wife') return 'Daughter-in-law';
            if (role == 'Husband') return 'Son-in-law';
            if (['Son', 'Daughter'].contains(role)) return gender == 'female' ? 'Grand Daughter' : 'Grand Son';
        }
      }
    }
    
    return role;
  }

  Widget _buildTreeNodeCard(dynamic member) {
    IconData icon = Icons.person;
    Color iconBgColor = Colors.grey.shade200;
    Color iconColor = Colors.grey.shade700;

    final gender = member['Gender']?.toString().toLowerCase() ?? '';
    if (gender == 'male') {
      icon = Icons.man;
      iconBgColor = Colors.blue.shade50;
      iconColor = Colors.blue.shade700;
    } else if (gender == 'female') {
      icon = Icons.woman;
      iconBgColor = Colors.pink.shade50;
      iconColor = Colors.pink.shade700;
    }

    final isDead = member['is_dead']?.toString().toLowerCase() == 'dead' || member['is_dead']?.toString() == '1';
    if (isDead) {
      iconBgColor = Colors.grey.shade300;
      iconColor = Colors.grey.shade600;
    }

    final displayRole = _getDisplayRole(member);
    final isHead = displayRole == 'Head';
    final hasImage = member['Memberimage'] != null && member['Memberimage'].toString().isNotEmpty;

    String ageStr = 'N/A';
    if (member['Dob'] != null && member['Dob'].toString().trim().isNotEmpty) {
      try {
        DateTime? dob;
        String dobStr = member['Dob'].toString().trim().replaceAll('/', '-');
        final parts = dobStr.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            dob = DateTime.parse(dobStr);
          } else if (parts[2].length == 4) {
            dob = DateTime.parse("${parts[2]}-${parts[1]}-${parts[0]}");
          }
        } else {
          dob = DateTime.parse(dobStr);
        }

        if (dob != null) {
          DateTime now = DateTime.now();
          int age = now.year - dob.year;
          if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
            age--;
          }
          ageStr = age.toString();
        }
      } catch (e) {
        ageStr = 'N/A';
      }
    }

    String mFmId = member['Familymembershipid']?.toString() ?? '';
    String mExId = member['Existfamilyid']?.toString() ?? '';
    String currentFmId = _userData?['Familymembershipid']?.toString() ?? '';
    
    bool canEdit = false;
    if (currentFmId.isNotEmpty) {
      if (mFmId == currentFmId) {
        canEdit = true;
      } else if (mExId == currentFmId) {
        bool isMemberSubHead = member['MemberRole']?.toString().trim() == 'Head' && mExId.isNotEmpty;
        if (!isMemberSubHead) {
          canEdit = true;
        }
      }
      
      // Block editing if the member is a married male descendant (they form a separate sub-family).
      if (canEdit && member['Id'] != _userData?['Id']) {
        String role = member['MemberRole']?.toString().trim() ?? '';
        bool isMarried = member['Married']?.toString().trim() == 'Yes';
        
        // Married daughters do not become heads, so they remain editable.
        List<String> allowedMarriedRoles = [
          'Head', 'Wife', 'Husband', 
          'Daughter', 'Son-in-law', 
          'Grand Daughter', 'Grand Son-in-law',
          'Great Grand Daughter', 'Great Grand Son-in-law'
        ];
        
        if (isMarried && !allowedMarriedRoles.contains(role)) {
          canEdit = false;
        }
      }
    }

    bool isNewMemberPending = member['Approvedstatus'] == 'Pending';

    bool isHovered = false;

    return StatefulBuilder(
      key: ValueKey('tree_node_card_${member['Id']}_${member['isSynthetic']}'),
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (canEdit && !isNewMemberPending && member['isSynthetic'] != true) ? (_) => setState(() => isHovered = true) : null,
          onExit: (canEdit && !isNewMemberPending && member['isSynthetic'] != true) ? (_) => setState(() => isHovered = false) : null,
          cursor: (canEdit && !isNewMemberPending && member['isSynthetic'] != true) ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: member['isSynthetic'] == true ? null : () {
              if (isNewMemberPending) {
                showStatusDialog(context, title: 'Action Denied', message: 'This member is awaiting approval and cannot be edited yet.', type: DialogType.error);
                return;
              }
              if (canEdit) {
                showDialog(
                  context: context,
                  builder: (context) => UpdateFamilyMemberForm(
                    memberData: member,
                    submitterRole: widget.userRole,
                    onUpdate: _fetchDetails,
                  ),
                );
              } else {
                showStatusDialog(context, title: 'Action Denied', message: 'You do not have permission to edit this member. They belong to a separate family unit.', type: DialogType.error);
              }
            },
            child: AnimatedScale(
              scale: isHovered ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: isDead ? Colors.grey.shade100 : (isHead ? Colors.orange.shade50 : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDead ? Colors.grey.shade400 : (isHead ? const Color(0xFFE65100) : const Color(0xFFE2E8F0)),
                    width: isHead ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isHovered ? 0.15 : 0.04),
                      blurRadius: isHovered ? 15 : 8,
                      offset: Offset(0, isHovered ? 8 : 4),
                    ),
                  ],
                ),
      child: Column(
        children: [
          _ImageLoadState(
            key: ValueKey('tree_node_img_${member['Id']}_${member['isSynthetic']}'),
            builder: (context, imageLoadFailed, setImgState) {
              return Tooltip(
                message: !hasImage || imageLoadFailed ? 'Image Not Found' : '',
                waitDuration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: (hasImage && !imageLoadFailed) ? () => _showFullScreenImage('${ApiConfig.baseUrl}/assets/uploads/${member['Memberimage']}') : null,
                  child: MouseRegion(
                    cursor: (hasImage && !imageLoadFailed) ? SystemMouseCursors.click : SystemMouseCursors.basic,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage && !imageLoadFailed
                          ? (isDead ? ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0,      0,      0,      1, 0,
                              ]),
                              child: Image.network(
                                '${ApiConfig.baseUrl}/assets/uploads/${member['Memberimage']}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    setImgState();
                                  });
                                  return Icon(icon, color: iconColor, size: 28);
                                },
                              ),
                            ) : Image.network(
                              '${ApiConfig.baseUrl}/assets/uploads/${member['Memberimage']}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  setImgState();
                                });
                                return Icon(icon, color: iconColor, size: 28);
                              },
                            ))
                          : Icon(icon, color: iconColor, size: 28),
                    ),
                  ),
                ),
              );
            }
          ),
          const SizedBox(height: 8),
          Text(
            (isDead ? 'Late. ' : '') + (member['Name'] ?? 'Unknown'),
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 13, 
              color: isDead ? Colors.grey.shade600 : const Color(0xFF1E293B)
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDead ? Colors.grey.shade300 : (isHead ? const Color(0xFFFFF3E0) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              displayRole,
              style: TextStyle(
                fontSize: 12, 
                fontWeight: isHead ? FontWeight.bold : FontWeight.w600,
                color: isDead ? Colors.grey.shade700 : (isHead ? const Color(0xFFE65100) : Colors.grey.shade600),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (member['Approvedstatus'] == 'Pending' || member['pending_status'] == 'Pending') ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange)),
              child: Text(member['Approvedstatus'] == 'Pending' ? 'Awaiting Approval' : 'Waiting for update approval', style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Age: $ageStr',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    ),
    ),
    ),
    );
    },
    );
  }

  Widget _buildFamilyTable(bool isMobile) {
    String currentFmId = _userData?['Familymembershipid']?.toString() ?? '';
    String currentExistId = _userData?['Existfamilyid']?.toString() ?? '';
    bool amITopHeadFamily = currentExistId.isEmpty;
    bool amISubHead = currentFmId.isNotEmpty && currentExistId.isNotEmpty;

    final tableMembers = _familyMembers.where((fm) {
      if (fm['Id']?.toString() == _userData?['Id']?.toString()) return true;
      
      bool isMarried = fm['Married']?.toString().toLowerCase() == 'yes';
      bool isChild = ['Son', 'Daughter', 'Son-in-law', 'Daughter-in-law'].contains(fm['MemberRole']);
      
      if (amISubHead) {
        if (fm['Familymembershipid']?.toString() == currentFmId && currentFmId.isNotEmpty) return true;
        if (fm['Existfamilyid']?.toString() == currentFmId && currentFmId.isNotEmpty) {
          bool isFmSubHead = fm['MemberRole'] == 'Head' && (fm['Existfamilyid']?.toString() ?? '').isNotEmpty;
          if (isFmSubHead) return false;
          if (isMarried && isChild) return false;
          return true;
        }
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
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowHeight: 50,
                  columnSpacing: 24,
                  border: const TableBorder(verticalInside: BorderSide(color: Colors.black12, width: 1)),
                  headingRowColor: MaterialStateProperty.all(const Color(0xFF2D1B18)),
                  columns: [
                    DataColumn(label: Text(AppLocalizations.of(context)?.sNo ?? 'S.No', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocalizations.of(context)?.nameHeader ?? 'Name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocalizations.of(context)?.relationshipHeader ?? 'Relationship', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocalizations.of(context)?.genderHeader ?? 'Gender', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocalizations.of(context)?.ageHeader ?? 'Age', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(AppLocalizations.of(context)?.actionHeader ?? 'Action', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                  rows: tableMembers.asMap().entries.map<DataRow>((entry) {
                    final index = entry.key;
                    final fm = entry.value;
                    
                    // Calculate Age
                    String ageStr = 'N/A';
                    if (fm['Dob'] != null && fm['Dob'].toString().isNotEmpty) {
                      try {
                        DateTime dob = DateTime.parse(fm['Dob'].toString());
                        DateTime now = DateTime.now();
                        int age = now.year - dob.year;
                        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
                          age--;
                        }
                        ageStr = age.toString();
                      } catch (_) {}
                    }
      
                    bool isDead = fm['is_dead']?.toString().toLowerCase() == 'dead' || fm['is_dead']?.toString() == '1';
                    bool isNewMemberPending = fm['Approvedstatus'] == 'Pending';
                    bool isUpdatePending = fm['pending_status'] == 'Pending';

                    return DataRow(
                      onSelectChanged: isNewMemberPending ? null : (bool? selected) {
                        if (selected != null) {
                          showDialog(
                            context: context,
                            builder: (context) => UpdateFamilyMemberForm(
                              memberData: fm,
                              submitterRole: widget.userRole,
                              onUpdate: _fetchDetails,
                            ),
                          );
                        }
                      },
                      cells: [
                        DataCell(Text((index + 1).toString())),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (isDead ? 'Late. ' : '') + (fm['Name'] ?? 'N/A'),
                                style: TextStyle(
                                  color: isDead ? Colors.grey.shade600 : Colors.black87,
                                  fontWeight: isDead ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                              if (isUpdatePending || isNewMemberPending)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange)),
                                  child: Text(isNewMemberPending ? 'Awaiting Approval' : 'Waiting for update approval', style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                        DataCell(Text(_getDisplayRole(fm))),
                        DataCell(Text(fm['Gender'] ?? 'N/A')),
                        DataCell(Text(ageStr)),
                        DataCell(
                          isNewMemberPending 
                            ? const Text('Awaiting Approval', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))
                            : TextButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => UpdateFamilyMemberForm(
                                      memberData: fm,
                                      submitterRole: widget.userRole,
                                      onUpdate: _fetchDetails,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit, size: 16, color: const Color(0xFF5D1712)),
                                label: Text(AppLocalizations.of(context)?.editAction ?? 'Edit', style: const TextStyle(color: Color(0xFF5D1712))),
                              ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoundIcon(IconData icon, String tooltip, dynamic imgPath) {
    return _ImageLoadState(builder: (context, imageLoadFailed, setIconState) {
      final hasImage = imgPath != null && imgPath.toString().trim().isNotEmpty && imgPath.toString() != 'null';
      final isValidImage = hasImage && !imageLoadFailed;

      return Stack(
        children: [
          if (hasImage && !imageLoadFailed)
            Offstage(
              offstage: true,
              child: Image.network(
                '${ApiConfig.baseUrl}/assets/uploads/$imgPath',
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setIconState();
                  });
                  return const SizedBox();
                },
              ),
            ),
          Tooltip(
            message: !isValidImage ? 'Community Certificate Image Not Found' : tooltip,
            waitDuration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                color: isValidImage ? const Color(0xFF5D1712).withOpacity(0.1) : Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(color: isValidImage ? const Color(0xFF5D1712) : Colors.grey[400]!),
              ),
              child: IconButton(
                icon: Icon(icon, color: isValidImage ? const Color(0xFF5D1712) : Colors.grey, size: 20),
                onPressed: isValidImage ? () => _showImageDialog(tooltip, imgPath) : null,
              ),
            ),
          ),
        ],
      );
    });
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
              automaticallyImplyLeading: false,
              actions: const [
                CloseButton(color: Colors.white),
              ],
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
      width: isMobile ? 120 : 200,
      child: Text(
        label,
        style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600, color: Colors.black54),
      ),
    );

    final valueWidget = isPill
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 6 : 8),
            decoration: BoxDecoration(color: const Color(0xFF5D1712), borderRadius: BorderRadius.circular(20)),
            child: Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14)),
          )
        : Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 15 : 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBlue ? const Color(0xFF5D1712) : Colors.black87,
            ),
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        labelWidget,
        Expanded(child: Align(alignment: Alignment.centerLeft, child: valueWidget)),
      ],
    );
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, color: const Color(0xFF5D1712), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ),
      ],
    );
  }
}

class _ImageLoadState extends StatefulWidget {
  final Widget Function(BuildContext context, bool imageLoadFailed, VoidCallback setFailed) builder;
  final Key? key;
  const _ImageLoadState({this.key, required this.builder}) : super(key: key);

  @override
  State<_ImageLoadState> createState() => _ImageLoadStateState();
}

class _ImageLoadStateState extends State<_ImageLoadState> {
  bool _imageLoadFailed = false;

  void _setFailed() {
    if (mounted) {
      setState(() {
        _imageLoadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _imageLoadFailed, _setFailed);
  }
}
