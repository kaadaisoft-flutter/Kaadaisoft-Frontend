import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../widgets/custom_dialog.dart';
import '../../l10n/app_localizations.dart';

class PaymentRequestsContent extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const PaymentRequestsContent({super.key, this.onBackToDashboard});

  @override
  State<PaymentRequestsContent> createState() => _PaymentRequestsContentState();
}

class _PaymentRequestsContentState extends State<PaymentRequestsContent> {
  bool _isLoading = true;
  List<dynamic> _requests = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(ApiConfig.getPaymentRequests));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _requests = data['data'];
          });
        }
      } else {
        debugPrint('Failed to load payment requests: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching payment requests: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _approveRequest(int id) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.approvePaymentRequest(id)));
      if (response.statusCode == 200) {
        if (mounted) {
          showStatusDialog(
            context,
            title: 'Success',
            message: 'Payment Request Approved',
            type: DialogType.success,
          );
        }
        _fetchRequests();
      }
    } catch (e) {
      debugPrint('Error approving: $e');
    }
  }

  Future<void> _rejectRequest(int id) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.rejectPaymentRequest(id)));
      if (response.statusCode == 200) {
        if (mounted) {
          showStatusDialog(
            context,
            title: 'Success',
            message: 'Payment Request Rejected',
            type: DialogType.success,
          );
        }
        _fetchRequests();
      }
    } catch (e) {
      debugPrint('Error rejecting: $e');
    }
  }

  void _viewReceipt(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No receipt image available.')),
      );
      return;
    }
    
    // Convert backend local path to URL
    String imageUrl = imagePath.replaceAll('\\', '/');
    if (!imageUrl.startsWith('/')) {
      imageUrl = '/$imageUrl';
    }
    imageUrl = '${ApiConfig.baseUrl}/assets$imageUrl';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Could not load image.'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.onBackToDashboard != null) ...[
              InkWell(
                onTap: widget.onBackToDashboard,
                child: Text(AppLocalizations.of(context)?.dashboard ?? 'Dashboard', style: const TextStyle(color: Color(0xFF5D1712), fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('/', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
            ],
            Text(
              AppLocalizations.of(context)?.paymentRequests ?? 'Payment Requests',
              style: const TextStyle(
                color: Color(0xFF5D1712),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
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
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fixed Columns
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                              ),
                            ),
                            child: DataTable(
                              border: const TableBorder(
                                verticalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                                horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                              ),
                              headingRowColor: MaterialStateProperty.all(const Color(0xFF2D1B18)),
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 60,
                              headingRowHeight: 56,
                              columns: [
                                DataColumn(label: Text(AppLocalizations.of(context)?.memberIdHeader ?? 'Member ID', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text(AppLocalizations.of(context)?.nameHeader ?? 'Name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              ],
                              rows: _requests.map((req) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(req['Familymembershipid']?.toString() ?? '')),
                                    DataCell(Text(req['membername'] ?? req['Membername'] ?? '')),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          // Scrollable Columns
                          Expanded(
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  border: const TableBorder(
                                    verticalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                                    horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                                  ),
                                  headingRowColor: MaterialStateProperty.all(const Color(0xFF2D1B18)),
                                  dataRowMinHeight: 60,
                                  dataRowMaxHeight: 60,
                                  headingRowHeight: 56,
                                  columns: [
                                    DataColumn(label: Text(AppLocalizations.of(context)?.eventLabel ?? 'Event', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text(AppLocalizations.of(context)?.totalAmountHeader ?? 'Total Amount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text(AppLocalizations.of(context)?.paidAmountHeader ?? 'Paid Amount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Due', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text(AppLocalizations.of(context)?.methodHeader ?? 'Method', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text(AppLocalizations.of(context)?.dateHeader ?? 'Date', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text(AppLocalizations.of(context)?.actionsHeader ?? 'Actions', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  ],
                                  rows: _requests.map((req) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(req['EventName'] ?? req['eventname'] ?? '')),
                                        DataCell(Text('₹${req['TaxAmount'] ?? req['Taxamount'] ?? req['taxamount'] ?? 0}')),
                                        DataCell(Text('₹${req['paidamount'] ?? 0}')),
                                        DataCell(Text(req['dues']?.toString() ?? '')),
                                        DataCell(Text(req['paymenttype'] ?? '')),
                                        DataCell(Text(req['paymentdate'] ?? '')),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.image, color: Colors.blue),
                                                tooltip: 'View Receipt',
                                                onPressed: () => _viewReceipt(req['receipt_image_path']),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                                tooltip: 'Approve',
                                                onPressed: () => _approveRequest(req['Id']),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.cancel, color: Colors.red),
                                                tooltip: 'Reject',
                                                onPressed: () => _rejectRequest(req['Id']),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_requests.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)?.noPendingPaymentRequests ?? 'No pending payment requests.',
                              style: const TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
      ],
    );
  }
}
