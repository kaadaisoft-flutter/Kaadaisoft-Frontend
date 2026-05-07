import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/loading_spinner.dart';
import '../../utils/api_config.dart';

class MembersContent extends StatefulWidget {
  final dynamic userId;
  final int? role;
  const MembersContent({super.key, this.userId, this.role});

  @override
  State<MembersContent> createState() => _MembersContentState();
}

class _MembersContentState extends State<MembersContent> {
  List<dynamic> _members = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    try {
      final url = '${ApiConfig.members}?user_id=${widget.userId}&role=${widget.role}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _members = data['data'];
          _isLoading = false;
          _currentPage = 1; // Reset to first page
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load members';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Make sure the backend is running.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pagination logic
    int totalPages = (_members.length / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _members.length) endIndex = _members.length;

    List<dynamic> currentPageMembers = _members.isNotEmpty 
        ? _members.sublist(startIndex, endIndex) 
        : [];

    if (_isLoading) {
      return const LoadingSpinner(message: 'Fetching members...');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Action Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Total Members: ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E283C),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _isLoading ? '' : _members.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isNarrow) _buildActionButtons(),
                    ],
                  ),
                  if (isNarrow) ...[
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Members Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1100,
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            color: const Color(0xFF172030),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                _buildHeaderCell('S.NO', 50),
                                _buildHeaderCell('FAMILY ID', 120),
                                _buildHeaderCell('NAME', 140),
                                _buildHeaderCell('ROLE', 80),
                                _buildHeaderCell('MOBILE', 120),
                                _buildHeaderCell('DISTRICT', 110),
                                _buildHeaderCell('TALUK', 110),
                                _buildHeaderCell('PANCHAYAT', 130),
                                _buildHeaderCell('VILLAGE', 130),
                                _buildHeaderCell('ACTIONS', 110),
                              ],
                            ),
                          ),
                          // Table Rows
                          _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(child: LoadingSpinner(message: 'Loading members...')),
                                )
                              : _members.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(32),
                                      child: Center(child: Text('No members found.', style: TextStyle(color: Colors.black54))),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: currentPageMembers.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final member = currentPageMembers[index];
                                        return _buildTableRow(
                                          (startIndex + index + 1).toString(),
                                          member['Familymembershipid'] ?? 'N/A',
                                          member['Name'] ?? '-',
                                          member['Role']?.toString() ?? '3',
                                          member['Phonenumber']?.toString() ?? '-',
                                          member['District'] ?? '-',
                                          member['Taluk'] ?? '-',
                                          member['Panchayat'] ?? '-',
                                          member['Village'] ?? '-',
                                        );
                                      },
                                    ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Pagination
                if (!_isLoading && _members.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.black12)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                              color: Colors.blue,
                              splashRadius: 20,
                            ),
                            ...List.generate(totalPages, (i) {
                              final page = i + 1;
                              final isActive = page == _currentPage;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: InkWell(
                                  onTap: () => setState(() => _currentPage = page),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFF1E283C) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: isActive ? null : Border.all(color: Colors.black12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('$page', style: TextStyle(color: isActive ? Colors.white : Colors.black54, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                                  ),
                                ),
                              );
                            }),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                              color: Colors.blue,
                              splashRadius: 20,
                            ),
                          ],
                        ),
                        Text('Showing page $_currentPage of $totalPages', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                      ],
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

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildOutlinedButton('Upload Bulk Data', Icons.file_upload_outlined, Colors.cyan),
        _buildOutlinedButton('Filter', Icons.filter_alt_outlined, Colors.blue),
        _buildOutlinedButton('Download', Icons.download_outlined, Colors.amber),
        _buildSolidButton('Assign', Icons.person_add_alt_1, Colors.blue.shade700),
        _buildSolidButton('Add', Icons.add, Colors.blue.shade600),
      ],
    );
  }

  Widget _buildOutlinedButton(String label, IconData icon, Color color) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: color, size: 18),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildSolidButton(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 0,
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTableRow(String sno, String id, String name, String role, String mobile, String district, String taluk, String panchayat, String village) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildDataCell(sno, 50),
          _buildDataCell(id, 120, isBlue: true),
          _buildDataCell(name, 140, isBold: true),
          _buildDataCell('', 80, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: role == '2' ? Colors.orange.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: role == '2' ? Colors.orange.shade200 : Colors.blue.shade200),
            ),
            child: Text(
              role == '2' ? 'COORDINATOR' : 'MEMBER',
              style: TextStyle(color: role == '2' ? Colors.orange.shade700 : Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          )),
          _buildDataCell(mobile, 120),
          _buildDataCell(district, 110),
          _buildDataCell(taluk, 110),
          _buildDataCell(panchayat.isEmpty ? '-' : panchayat, 130),
          _buildDataCell(village, 130),
          _buildDataCell('', 110, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionIcon(Icons.edit_outlined, Colors.blue),
              const SizedBox(width: 8),
              _actionIcon(Icons.visibility_outlined, Colors.green),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {bool isBlue = false, bool isBold = false, Widget? child}) {
    return Container(
      width: width,
      height: 34,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Center(
        child: child ?? Text(
          text,
          style: TextStyle(
            color: isBlue ? Colors.blue : Colors.black87,
            fontWeight: isBlue || isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}
