import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/loading_spinner.dart';
import '../../utils/api_config.dart';

class ReceivedApplicationsContent extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  const ReceivedApplicationsContent({super.key, this.onBackToDashboard});

  @override
  State<ReceivedApplicationsContent> createState() => _ReceivedApplicationsContentState();
}

class _ReceivedApplicationsContentState extends State<ReceivedApplicationsContent> {
  List<dynamic> _applications = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchApplications() async {
    try {
      // Endpoint for received applications (placeholder for now)
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/received-applications'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _applications = data['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        
        if (_isLoading) {
          return const LoadingSpinner(message: 'Loading applications...');
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: widget.onBackToDashboard,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      ' / Member Update Requests',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF172030),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Table Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Scrollable table area
                    Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 1100,
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF172030),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                child: const Row(
                                  children: [
                                    SizedBox(width: 50, child: Text('S.NO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                    SizedBox(width: 140, child: Text('MEMBER NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                    SizedBox(width: 120, child: Text('MEMBER ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                    SizedBox(width: 110, child: Text('DISTRICT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                    SizedBox(width: 110, child: Text('TALUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                    SizedBox(width: 130, child: Text('PANCHAYAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                    SizedBox(width: 110, child: Text('VILLAGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                    SizedBox(width: 150, child: Text('REQUEST TYPE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                  ],
                                ),
                              ),
                              // Table Body Rows
                              _applications.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(48),
                                      child: Center(
                                        child: Text(
                                          'No pending update requests.',
                                          style: TextStyle(color: Colors.black45, fontSize: 15),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      itemCount: _applications.length,
                                      itemBuilder: (context, index) {
                                        return _buildTableRow(index + 1, _applications[index]);
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Pagination Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPageButton(Icons.chevron_left, false),
                          const SizedBox(width: 8),
                          _buildPageNumber('1', true),
                          const SizedBox(width: 8),
                          _buildPageButton(Icons.chevron_right, false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTableRow(int sno, dynamic app) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(sno.toString(), style: const TextStyle(color: Colors.black87))),
          SizedBox(width: 140, child: Text(app['Name']?.toString() ?? '', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis))),
          SizedBox(width: 120, child: Text(app['Phonenumber']?.toString() ?? '', style: const TextStyle(color: Colors.black54))),
          SizedBox(width: 140, child: Text(app['Aadhar']?.toString() ?? '', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))),
          SizedBox(width: 100, child: _buildBadge(app['State']?.toString() ?? 'Tamil Nadu', Colors.cyan)),
          SizedBox(width: 110, child: _buildBadge(app['District']?.toString() ?? '', Colors.grey.shade200, textColor: Colors.black87)),
          SizedBox(width: 110, child: Text(app['Taluk']?.toString() ?? '', style: const TextStyle(color: Colors.black54, overflow: TextOverflow.ellipsis))),
          SizedBox(width: 140, child: Text(app['Panchayat']?.toString() ?? '', style: const TextStyle(color: Colors.black54, overflow: TextOverflow.ellipsis))),
          SizedBox(width: 110, child: Text(app['Village']?.toString() ?? '', style: const TextStyle(color: Colors.black54, overflow: TextOverflow.ellipsis))),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPageNumber(String num, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          num,
          style: TextStyle(color: isActive ? Colors.white : Colors.black54, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPageButton(IconData icon, bool isEnabled) {
    return Icon(icon, color: isEnabled ? Colors.black87 : Colors.black26);
  }
}
