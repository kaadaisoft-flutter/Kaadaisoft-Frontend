import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/loading_spinner.dart';
import '../../utils/api_config.dart';

class UpdateRequestsContent extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  final Function(int)? onCountUpdated;
  const UpdateRequestsContent({super.key, this.onBackToDashboard, this.onCountUpdated});

  @override
  State<UpdateRequestsContent> createState() => _UpdateRequestsContentState();
}

class _UpdateRequestsContentState extends State<UpdateRequestsContent> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/update-requests'));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _requests = result['data'];
            _isLoading = false;
          });
          if (widget.onCountUpdated != null) {
            widget.onCountUpdated!(_requests.length);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching update requests: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pagination logic
    int totalPages = (_requests.length / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _requests.length) endIndex = _requests.length;

    List<dynamic> currentPageData = _requests.isNotEmpty 
        ? _requests.sublist(startIndex, endIndex) 
        : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb & Title
          Row(
            children: [
              InkWell(
                onTap: widget.onBackToDashboard,
                child: Text('Dashboard', style: TextStyle(color: Colors.blue.shade700, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const Text(' / Member Update Requests', style: TextStyle(color: Colors.black45, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Table Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 1000,
                            child: Column(
                              children: [
                                // Header
                                Container(
                                  color: const Color(0xFF172030),
                                  height: 48,
                                  child: Row(
                                    children: [
                                      _buildHeaderCell('S.NO', 60),
                                      _buildHeaderCell('MEMBER NAME', 180),
                                      _buildHeaderCell('MEMBER ID', 140),
                                      _buildHeaderCell('DISTRICT', 130),
                                      _buildHeaderCell('TALUK', 130),
                                      _buildHeaderCell('PANCHAYAT', 130),
                                      _buildHeaderCell('VILLAGE', 130),
                                      _buildHeaderCell('REQUEST', 100, hasDivider: false),
                                    ],
                                  ),
                                ),
                                // Body
                                _isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(48.0),
                                        child: Center(child: LoadingSpinner(message: 'Loading requests...')),
                                      )
                                    : _requests.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.all(48.0),
                                            child: Center(child: Text('No pending update requests.', style: TextStyle(color: Colors.black54))),
                                          )
                                        : ListView.separated(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: currentPageData.length,
                                            separatorBuilder: (_, __) => const Divider(height: 1),
                                            itemBuilder: (context, index) {
                                              final req = currentPageData[index];
                                              return _buildDataRow(index, req, startIndex);
                                            },
                                          ),
                              ],
                            ),
                          ),
                        ),
                    ),
                  ],
                ),
              ),
            ),
          // Pagination
          if (!_isLoading && _requests.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Showing page $_currentPage of $totalPages', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                        color: Colors.blue,
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, double width, {bool hasDivider = true}) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        border: hasDivider ? const Border(right: BorderSide(color: Colors.white24, width: 1)) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataRow(int index, dynamic req, int startIndex) {
    return Container(
      height: 46,
      color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _buildDataCell((startIndex + index + 1).toString(), 60),
          _buildDataCell(req['Name'] ?? '-', 180, isBold: true),
          _buildDataCell(req['Familymembershipid'] ?? '-', 140, isBlue: true),
          _buildDataCell(req['District'] ?? '-', 130),
          _buildDataCell(req['Taluk'] ?? '-', 130),
          _buildDataCell(req['Panchayat'] ?? '-', 130),
          _buildDataCell(req['Village'] ?? '-', 130),
          _buildDataCell('', 100, hasDivider: false, child: ElevatedButton(
            onPressed: () {
              // Action for viewing request
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('VIEW'),
          )),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {bool isBlue = false, bool isBold = false, bool hasDivider = true, Widget? child}) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        border: hasDivider ? Border(right: BorderSide(color: Colors.grey.shade200, width: 1)) : null,
      ),
      alignment: Alignment.center,
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
    );
  }
}
