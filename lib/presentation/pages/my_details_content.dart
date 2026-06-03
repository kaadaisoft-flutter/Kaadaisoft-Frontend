import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/loading_spinner.dart';
import '../../utils/api_config.dart';
import 'update_details_content.dart';
import '../widgets/add_family_member_form.dart';
import '../widgets/update_family_member_form.dart';
import '../../utils/notification_helper.dart';


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
  bool _isTreeView = false;

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

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
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
                                  color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFF5D1712),
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
                ),
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
                            'My Details', 
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
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final url = '${ApiConfig.baseUrl}/api/download-id-card/${widget.userId}';
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                    icon: Icon(Icons.badge_outlined, size: isMobile ? 16 : 20),
                    label: Text(
                      'Download ID Card',
                      style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D1712),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 10 : 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        'Family Members', 
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
                        _buildToggleButton('Table', Icons.table_chart, !_isTreeView, () => setState(() => _isTreeView = false)),
                        _buildToggleButton('Tree', Icons.account_tree, _isTreeView, () => setState(() => _isTreeView = true)),
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
              _buildRoundIcon(Icons.card_membership, 'Certificate', _userData?['Communitycertificate']),
            ],
          ),
          const SizedBox(height: 32),
          _buildActionButton('Event Participation', Icons.event_available, const Color(0xFFE8F5E9), const Color(0xFF2E7D32), onTap: _showEventParticipationDialog),
          const SizedBox(height: 12),
          _buildActionButton('Update Details', Icons.person_outline, const Color(0xFFFFF8E1), const Color(0xFFF57C00), onTap: () {
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
          _buildActionButton('Add Family Member', Icons.person_add_alt_1, const Color(0xFFE3F2FD), const Color(0xFF5D1712), onTap: () {
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
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDetailRow('Name:', (_userData?['Name'] ?? 'N/A').toString(), isBold: true, isBlue: true, isMobile: isMobile)),
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
                      Text('Update In Progress', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
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
      if (m['MemberRole'] != 'Head') return false;
      return (m['Existfamilyid']?.toString().trim() ?? '').isNotEmpty;
    }
    
    Set<String> subHeadFmIds = _familyMembers
        .where((m) => isSubHead(m))
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
      if (isSubHead(m) || isSubSpouse(m)) return true;
      
      String existId = m['Existfamilyid']?.toString().trim() ?? '';
      if (subHeadFmIds.contains(existId)) return false; // They belong in grandchildren
      
      if (['Son', 'Daughter', 'Son-in-law', 'Daughter-in-law'].contains(m['MemberRole'])) return true;
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

    Widget buildTreeRow(List<dynamic> members, String layerName) {
      if (members.isEmpty) return const SizedBox.shrink();
      
      List<Widget> groupedWidgets = [];
      Set<String> processedIds = {};
      
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
          spouse = members.where((s) => ['Wife', 'Husband'].contains(s['MemberRole']) && s['Existfamilyid']?.toString() == mFmId).toList();
        } else if (isFather) {
          String mExId = m['Existfamilyid']?.toString() ?? '';
          spouse = members.where((s) => s['MemberRole'] == 'Mother' && s['Existfamilyid']?.toString() == mExId).toList();
        } else if (isGrandFather) {
          String mExId = m['Existfamilyid']?.toString() ?? '';
          spouse = members.where((s) => s['MemberRole'] == 'Grand Mother' && s['Existfamilyid']?.toString() == mExId).toList();
        }
        
        if (spouse.isNotEmpty) {
          List<Widget> spouseWidgets = [];
          for (var s in spouse) {
              spouseWidgets.add(Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('↔', style: TextStyle(fontSize: 32, color: Colors.grey.shade500, fontWeight: FontWeight.w300)),
              ));
            spouseWidgets.add(_buildTreeNodeCard(s));
            processedIds.add(s['Id']?.toString() ?? '');
          }
          
          Widget nodeWidget = Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              _buildTreeNodeCard(m),
              ...spouseWidgets,
            ],
          );
          
          if (isSubHead(m)) {
             String mFmId = m['Familymembershipid']?.toString() ?? '';
             var myKids = grandchildren.where((c) => c['Existfamilyid']?.toString().trim() == mFmId).toList();
             if (myKids.isNotEmpty) {
                nodeWidget = Column(
                   children: [
                      nodeWidget,
                      buildVerticalLine(),
                      buildTreeRow(myKids, 'SubKids'),
                   ],
                );
             }
          }
          
          groupedWidgets.add(nodeWidget);
        } else {
          Widget nodeWidget = _buildTreeNodeCard(m);
          
          if (isSubHead(m)) {
             String mFmId = m['Familymembershipid']?.toString() ?? '';
             var myKids = grandchildren.where((c) => c['Existfamilyid']?.toString().trim() == mFmId).toList();
             if (myKids.isNotEmpty) {
                nodeWidget = Column(
                   children: [
                      nodeWidget,
                      buildVerticalLine(),
                      buildTreeRow(myKids, 'SubKids'),
                   ],
                );
             }
          }
          
          groupedWidgets.add(nodeWidget);
        }
        processedIds.add(mId);
      }
      
      return Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 32,
            runSpacing: 32,
            children: groupedWidgets,
          ),
        ],
      );
    }


    List<Widget> treeWidgets = [];
    
    if (grandparents.isNotEmpty) {
      treeWidgets.add(buildTreeRow(grandparents, 'Grandparents'));
      treeWidgets.add(buildVerticalLine());
    }
    if (parents.isNotEmpty) {
      treeWidgets.add(buildTreeRow(parents, 'Parents'));
      treeWidgets.add(buildVerticalLine());
    }
    
    List<dynamic> middleLayer = [...headAndSpouse, ...siblings];
    if (middleLayer.isNotEmpty) {
      treeWidgets.add(buildTreeRow(middleLayer, 'Head & Siblings'));
      if (children.isNotEmpty) treeWidgets.add(buildVerticalLine());
    }
    
    if (children.isNotEmpty) {
      treeWidgets.add(buildTreeRow(children, 'Children'));
    }
    
    // Grandchildren are now rendered recursively under their respective Sub-Head parents
    
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
      child: Column(
        children: treeWidgets,
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

    final displayRole = _getDisplayRole(member);
    final isHead = displayRole == 'Head';
    final hasImage = member['Memberimage'] != null && member['Memberimage'].toString().isNotEmpty;

    String ageStr = 'N/A';
    if (member['Dob'] != null && member['Dob'].toString().isNotEmpty) {
      try {
        DateTime dob = DateTime.parse(member['Dob'].toString());
        DateTime now = DateTime.now();
        int age = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        ageStr = age.toString();
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
        bool isMemberSubHead = member['MemberRole'] == 'Head' && mExId.isNotEmpty;
        if (!isMemberSubHead) {
          canEdit = true;
        }
      }
    }

    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: canEdit ? (_) => setState(() => isHovered = true) : null,
          onExit: canEdit ? (_) => setState(() => isHovered = false) : null,
          cursor: canEdit ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: canEdit ? () {
              showDialog(
                context: context,
                builder: (context) => UpdateFamilyMemberForm(
                  memberData: member,
                  submitterRole: widget.userRole,
                  onUpdate: _fetchDetails,
                ),
              );
            } : () {
              NotificationHelper.showError(context, 'You do not have permission to edit this member. They belong to a separate family unit.');
            },
            child: AnimatedScale(
              scale: isHovered ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHead ? const Color(0xFFE65100) : const Color(0xFFE2E8F0),
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
          GestureDetector(
            onTap: hasImage ? () => _showFullScreenImage('${ApiConfig.baseUrl}/assets/uploads/${member['Memberimage']}') : null,
            child: MouseRegion(
              cursor: hasImage ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: hasImage ? Colors.grey.shade200 : iconBgColor,
                  shape: BoxShape.circle,
                  image: hasImage 
                      ? DecorationImage(
                          image: NetworkImage('${ApiConfig.baseUrl}/assets/uploads/${member['Memberimage']}'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasImage ? Icon(icon, color: iconColor, size: 28) : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            member['Name'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHead ? const Color(0xFFFFF3E0) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              displayRole,
              style: TextStyle(
                fontSize: 12, 
                fontWeight: isHead ? FontWeight.bold : FontWeight.w600,
                color: isHead ? const Color(0xFFE65100) : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
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
                  columns: const [
                    DataColumn(label: Text('S.No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Relationship', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Gender', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Age', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Action', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                  rows: tableMembers.asMap().entries.map((entry) {
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
      
                    return DataRow(
                      onSelectChanged: (bool? selected) {
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
                              Text(fm['Name'] ?? 'N/A'),
                              if (fm['pending_status'] == 'Pending')
                                const Padding(
                                  padding: EdgeInsets.only(left: 6.0),
                                  child: Tooltip(
                                    message: 'Update in progress',
                                    child: Icon(Icons.hourglass_top, color: Colors.orange, size: 14),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        DataCell(Text(_getDisplayRole(fm))),
                        DataCell(Text(fm['Gender'] ?? 'N/A')),
                        DataCell(Text(ageStr)),
                        DataCell(
                          TextButton.icon(
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
                            label: const Text('Edit', style: TextStyle(color: const Color(0xFF5D1712))),
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

  Widget _buildRoundIcon(IconData icon, String tooltip, String? imgPath) {
    final bool hasImage = imgPath != null && imgPath.isNotEmpty;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasImage ? const Color(0xFF5D1712).withOpacity(0.1) : Colors.transparent,
        border: Border.all(color: hasImage ? const Color(0xFF5D1712) : const Color(0xFF5D1712).withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF5D1712), size: 20),
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
            decoration: BoxDecoration(color: const Color(0xFF5D1712), borderRadius: BorderRadius.circular(20)),
            child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
