import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/loading_spinner.dart';
import '../../utils/api_config.dart';
import '../../utils/notification_helper.dart';

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
                                  color: const Color(0xFF2D1B18),
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
                                color: isActive ? const Color(0xFF2D1B18) : Colors.transparent,
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
          _buildDataCell('', 100, hasDivider: false, child: IconButton(
            onPressed: () {
              _showRequestDetails(req);
            },
            icon: const Icon(Icons.visibility),
            color: Colors.blue,
            tooltip: 'View Details',
          )),
        ],
      ),
    );
  }

  Future<void> _handleApprove(int requestId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.approveUpdateRequest(requestId)),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          NotificationHelper.showSuccess(context, 'Request approved successfully');
          _fetchRequests();
        }
      } else {
        if (mounted) {
          NotificationHelper.showError(context, 'Failed to approve request: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Error approving request: $e');
    }
  }

  Future<void> _handleReject(int requestId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.rejectUpdateRequest(requestId)),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          NotificationHelper.showSuccess(context, 'Request rejected successfully');
          _fetchRequests();
        }
      } else {
        if (mounted) {
          NotificationHelper.showError(context, 'Failed to reject request: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Error rejecting request: $e');
    }
  }

  void _showRequestDetails(dynamic req) {
    showDialog(
      context: context,
      builder: (context) {
        final data = Map<String, dynamic>.from(req);
        
        // Extract updated_data
        final updatedDataRaw = data['updated_data'];
        Map<String, dynamic> updatedDataMap = {};
        if (updatedDataRaw != null) {
          if (updatedDataRaw is String) {
            try {
              updatedDataMap = json.decode(updatedDataRaw);
            } catch (e) {
              debugPrint('Error decoding updated_data: $e');
            }
          } else if (updatedDataRaw is Map) {
            updatedDataMap = Map<String, dynamic>.from(updatedDataRaw);
          }
        }

        // Internal system fields to hide
        final systemFields = [
          'id', 'request_id', 'status', 'familymembershipid', 'existfamilyid',
          'memberrole', 'role', 'approvedstatus', 'isshow', 'created_at',
          'password', 'coordinator_id', 'coordinator_two_id', 'aadharnumber',
          'aadhar_hash', 'assigned_areas_count', 'state_id', 'updated_at'
        ];

        // Remove empty, very large base64 strings, and system fields
        data.removeWhere((k, v) => 
            v == null || 
            v.toString().isEmpty || 
            k.toLowerCase().contains('image') || 
            k.toLowerCase().contains('cert') || 
            k == 'updated_data' ||
            systemFields.contains(k.toLowerCase()) ||
            v.toString().length > 150);
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D1B18),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Update Request Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Member Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 16),
                        ...data.entries.map((e) {
                          final formattedKey = e.key.replaceAll(RegExp(r'(?<=[a-z])[A-Z]'), r' $0').toUpperCase();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    formattedKey,
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13),
                                  ),
                                ),
                                const Text(':', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    e.value.toString(),
                                    style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        
                        if (updatedDataMap.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text('Requested Updates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                          const SizedBox(height: 16),
                          ...updatedDataMap.entries.map((e) {
                            // Skip base64 or very large values
                            if (e.value.toString().length > 150) {
                              return const SizedBox.shrink();
                            }
                            final key = e.key.toLowerCase();
                            final isImageField = key == 'member_image' || key == 'community_cert';
                            final formattedKey = e.key.replaceAll(RegExp(r'(?<=[a-z])[A-Z]'), r' $0').toUpperCase();
                            final labelText = key == 'member_image' ? 'PASSPORT PHOTO' : key == 'community_cert' ? 'COMMUNITY CERTIFICATE' : formattedKey;

                            if (isImageField && e.value.toString().isNotEmpty) {
                              final imageUrl = '${ApiConfig.baseUrl}/assets/uploads/${e.value}';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      labelText,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.orange, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          imageUrl,
                                          height: 160,
                                          fit: BoxFit.contain,
                                          errorBuilder: (ctx, err, st) => Container(
                                            height: 80,
                                            color: Colors.grey.shade100,
                                            child: Center(
                                              child: Text('Image: ${e.value}', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                                            ),
                                          ),
                                          loadingBuilder: (ctx, child, progress) {
                                            if (progress == null) return child;
                                            return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('New image uploaded', style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      formattedKey,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13),
                                    ),
                                  ),
                                  const Text(':', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.value.toString(),
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.green,
                                        decorationThickness: 2.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleApprove(req['request_id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleReject(req['request_id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
