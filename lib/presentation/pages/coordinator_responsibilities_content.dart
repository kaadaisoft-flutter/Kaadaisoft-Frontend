import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/loading_spinner.dart';
import '../../utils/api_config.dart';
import '../widgets/pagination_widget.dart';

class CoordinatorResponsibilitiesContent extends StatefulWidget {
  final String numericId;
  final String familyId;
  final VoidCallback onBack;

  const CoordinatorResponsibilitiesContent({
    super.key, 
    required this.numericId, 
    required this.familyId,
    required this.onBack,
  });

  @override
  State<CoordinatorResponsibilitiesContent> createState() => _CoordinatorResponsibilitiesContentState();
}

class _CoordinatorResponsibilitiesContentState extends State<CoordinatorResponsibilitiesContent> {
  Map<String, dynamic>? _userData;
  List<dynamic> _assignedMembers = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchFullDetails();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchFullDetails() async {
    setState(() => _isLoading = true);
    try {
      // Fetch Assigned Village Members
      final assignedRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/coordinator-assigned-members/${widget.familyId}'));
      // Fetch Villages for "Assigned Villages" display
      final villagesRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/coordinator-villages/${widget.familyId}'));

      if (assignedRes.statusCode == 200 && villagesRes.statusCode == 200) {
        final assignedData = jsonDecode(assignedRes.body)['data'];
        final villagesData = jsonDecode(villagesRes.body)['data'] as List;
        
        String villageNames = villagesData.map((v) => v['village_name']).join(', ');

        setState(() {
          _userData = {'AssignedVillages': villageNames.isEmpty ? 'None' : villageNames};
          _assignedMembers = assignedData.where((m) => m['MemberRole'] == 'Head').toList();
          _currentPage = 1;
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

  @override
  Widget build(BuildContext context) {
    final isTa = Localizations.localeOf(context).languageCode == 'ta';

    if (_isLoading) {
      return LoadingSpinner(
        message: isTa ? 'பொறுப்புகள் ஏற்றப்படுகின்றன...' : 'Loading responsibilities...',
      );
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_userData == null) {
      return Center(
        child: Text(
          isTa ? 'விவரங்கள் எதுவும் கிடைக்கவில்லை' : 'No data found',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final assignedVillages = _userData!['AssignedVillages']?.toString() ?? 'None';
    final displayVillages = (assignedVillages == 'None' || assignedVillages.isEmpty)
        ? (isTa ? 'எதுவுமில்லை' : 'None')
        : assignedVillages;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_ind, color: Color(0xFF5D1712), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    isTa ? 'பொறுப்புகள்' : 'Responsibilities',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onBack,
                tooltip: isTa ? 'மூடு' : 'Close',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              bool isMobile = MediaQuery.of(context).size.width < 800;
              final labelWidget = SizedBox(
                width: isMobile ? double.infinity : 220,
                child: Text(
                  isTa ? 'ஒதுக்கப்பட்ட கிராமங்கள்:' : 'Assigned Villages:',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
              );
              final valueWidget = Text(
                displayVillages,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [labelWidget, const SizedBox(height: 8), valueWidget],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [labelWidget, Expanded(child: valueWidget)],
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Icon(Icons.location_city, color: Color(0xFF5D1712), size: 24),
              const SizedBox(width: 12),
              Text(
                isTa
                    ? 'ஒதுக்கப்பட்ட உறுப்பினர்கள் (${_assignedMembers.length})'
                    : 'Assigned Members (${_assignedMembers.length})',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAssignedMembersTable(isTa),
        ],
      ),
    );
  }

  Widget _buildAssignedMembersTable(bool isTa) {
    if (_assignedMembers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            isTa ? 'ஒதுக்கப்பட்ட உறுப்பினர்கள் எவரும் இல்லை' : 'No assigned members found',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    final int totalItems = _assignedMembers.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 999999);
    final int validCurrentPage = _currentPage > totalPages ? totalPages : _currentPage;
    final int startIndex = (validCurrentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage < totalItems)
        ? (startIndex + _itemsPerPage)
        : totalItems;
    final pageMembers = (startIndex < totalItems)
        ? _assignedMembers.sublist(startIndex, endIndex)
        : <dynamic>[];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return RawScrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  thickness: 8,
                  radius: const Radius.circular(8),
                  thumbColor: const Color(0xFFC49A3C).withValues(alpha: 0.7),
                  trackColor: Colors.grey.shade200,
                  padding: const EdgeInsets.only(bottom: 2),
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        border: TableBorder(verticalInside: BorderSide(color: Colors.grey.shade300, width: 1)),
                        headingRowHeight: 50,
                        headingRowColor: WidgetStateProperty.all(const Color(0xFF5D1712)),
                        columns: [
                          DataColumn(label: Text(isTa ? 'வ.எண்' : 'S.NO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isTa ? 'பெயர்' : 'NAME', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isTa ? 'பாலினம்' : 'GENDER', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isTa ? 'மொபைல் எண்' : 'MOBILE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(isTa ? 'கிராமம்' : 'LOCATION', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ],
                        rows: pageMembers.asMap().entries.map((entry) {
                          final i = entry.key;
                          final m = entry.value;
                          final serialNumber = startIndex + i + 1;
                          final genderRaw = (m['Gender'] ?? '').toString();
                          String genderDisplay = genderRaw;
                          if (isTa) {
                            if (genderRaw.toLowerCase() == 'male') {
                              genderDisplay = 'ஆண்';
                            } else if (genderRaw.toLowerCase() == 'female') {
                              genderDisplay = 'பெண்';
                            }
                          }

                          return DataRow(cells: [
                            DataCell(Text('$serialNumber')),
                            DataCell(Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['Name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(m['Familymembershipid'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF5D1712))),
                              ],
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(genderRaw.toLowerCase() == 'male' ? Icons.male : Icons.female, size: 16, color: const Color(0xFF5D1712)),
                                const SizedBox(width: 4),
                                Text(genderDisplay),
                              ],
                            )),
                            DataCell(Text(m['Phonenumber']?.toString() ?? '-')),
                            DataCell(Text(m['Village'] ?? '-')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isSmall = constraints.maxWidth < 600;
                  final infoText = Text(
                    isTa
                        ? 'காட்டுவது ${startIndex + 1} முதல் $endIndex வரை (மொத்தம் $totalItems)'
                        : 'Showing ${startIndex + 1} to $endIndex of $totalItems entries',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  );

                  if (totalPages <= 1) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: infoText,
                    );
                  }

                  if (isSmall) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        infoText,
                        const SizedBox(height: 8),
                        PaginationWidget(
                          currentPage: validCurrentPage,
                          totalPages: totalPages,
                          onPageChanged: (page) => setState(() => _currentPage = page),
                        ),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      infoText,
                      PaginationWidget(
                        currentPage: validCurrentPage,
                        totalPages: totalPages,
                        onPageChanged: (page) => setState(() => _currentPage = page),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
