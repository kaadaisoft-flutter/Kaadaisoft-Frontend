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
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: const Text('Are you sure you want to approve this payment request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

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
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: const Text('Are you sure you want to reject this payment request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

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
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 2020, // Total width of all columns
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFF2D1B18),
                        height: 48,
                        child: Row(
                          children: [
                            _buildHeaderCell(AppLocalizations.of(context)?.memberIdHeader ?? 'MEMBER ID', 140),
                            _buildHeaderCell(AppLocalizations.of(context)?.nameHeader?.toUpperCase() ?? 'NAME', 180),
                            _buildHeaderCell(AppLocalizations.of(context)?.eventLabel?.toUpperCase() ?? 'EVENT', 180),
                            _buildHeaderCell(AppLocalizations.of(context)?.totalAmountHeader?.toUpperCase() ?? 'TOTAL AMOUNT', 120),
                            _buildHeaderCell(AppLocalizations.of(context)?.paidAmountHeader?.toUpperCase() ?? 'PAID AMOUNT', 120),
                            _buildHeaderCell('BALANCE AMOUNT', 140),
                            _buildHeaderCell(AppLocalizations.of(context)?.methodHeader?.toUpperCase() ?? 'METHOD', 120),
                            _buildHeaderCell('TRANSACTION ID', 180),
                            _buildHeaderCell(AppLocalizations.of(context)?.dateHeader?.toUpperCase() ?? 'DATE', 120),
                            _buildHeaderCell('STATUS', 120),
                            _buildHeaderCell('RECEIVER NAME', 180),
                            _buildHeaderCell('COLLECTED BY', 180),
                            _buildHeaderCell(AppLocalizations.of(context)?.actionsHeader?.toUpperCase() ?? 'ACTIONS', 180, hasDivider: false),
                          ],
                        ),
                      ),
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(48.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _requests.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(48.0),
                                  child: Center(child: Text(AppLocalizations.of(context)?.noPendingPaymentRequests ?? 'No pending payment requests.', style: const TextStyle(color: Colors.black54))),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _requests.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final req = _requests[index];
                                    return _buildFullDataRow(index, req);
                                  },
                                ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildFullDataRow(int index, dynamic req) {
    return Container(
      height: 46,
      color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _buildDataCell(req['Familymembershipid']?.toString() ?? '-', 140, isBlue: true),
          _buildDataCell(req['membername'] ?? req['Membername'] ?? '-', 180, isBold: true),
          _buildDataCell(req['EventName'] ?? req['eventname'] ?? '-', 180),
          _buildDataCell('₹${req['TaxAmount'] ?? req['Taxamount'] ?? req['taxamount'] ?? 0}', 120),
          _buildDataCell('₹${req['paidamount'] ?? 0}', 120),
          _buildDataCell('₹${req['balanceamount'] ?? req['dues'] ?? 0}', 140),
          _buildDataCell(req['paymenttype'] ?? '-', 120),
          _buildDataCell(req['transactionid'] ?? req['checkqueno'] ?? req['upitransactionid'] ?? '-', 180),
          _buildDataCell(req['paymentdate'] ?? req['receiptdate'] ?? '-', 120),
          _buildDataCell(req['status'] ?? 'Pending', 120),
          _buildDataCell(req['receivedby'] ?? '-', 180),
          _buildDataCell(req['name'] ?? '-', 180),
          _buildDataCell('', 180, hasDivider: false, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _viewReceipt(req['receipt_image_path']),
                icon: const Icon(Icons.image, size: 18),
                color: Colors.blue,
                tooltip: 'View Receipt',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              IconButton(
                onPressed: () => _approveRequest(req['Id']),
                icon: const Icon(Icons.check_circle, size: 18),
                color: Colors.green,
                tooltip: 'Approve',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              IconButton(
                onPressed: () => _rejectRequest(req['Id']),
                icon: const Icon(Icons.cancel, size: 18),
                color: Colors.red,
                tooltip: 'Reject',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ],
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
          color: isBlue ? const Color(0xFF5D1712) : Colors.black87,
          fontWeight: isBlue || isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
