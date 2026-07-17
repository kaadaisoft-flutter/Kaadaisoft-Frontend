import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../utils/api_config.dart';
import 'loading_spinner.dart';
import 'custom_dialog.dart';
import '../../utils/bank_list.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'custom_dropdown_search.dart';
class PaymentForm extends StatefulWidget {
  final Map<String, dynamic> memberData;
  final VoidCallback onPaymentSuccess;
  final int? initialYear;
  final int? initialEventId;

  const PaymentForm({
    super.key,
    required this.memberData,
    required this.onPaymentSuccess,
    this.initialYear,
    this.initialEventId,
  });

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _amountController = TextEditingController();
  final _receiverController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _refNoController = TextEditingController();
  final _chequeNoController = TextEditingController();
  final _upiIdController = TextEditingController();

  // Focus Nodes
  final _eventFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _bankFocus = FocusNode();
  final _otherBankFocus = FocusNode();
  final _upiIdFocus = FocusNode();
  final _refNoFocus = FocusNode();
  final _chequeNoFocus = FocusNode();
  final _receiverFocus = FocusNode();

  // State
  List<int> _years = [];
  List<dynamic> _events = [];
  int? _selectedYear;
  int? _selectedEventId;
  String _paymentMethod = 'Cash';
  bool _isConfirmed = false;
  bool _isLoading = false;
  bool _isSummaryLoading = false;
  bool _autoValidate = false;
  String? _selectedBank;
  bool _showOtherBank = false;
  final _otherBankController = TextEditingController();

  // Summary Data
  int _totalAmount = 0;
  int _alreadyPaid = 0;
  int _balance = 0; // The fixed balance from backend
  int _displayedBalance = 0; // Dynamic balance shown in UI

  // Receipt image
  PlatformFile? _receiptImage;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateDisplayedBalance);
    _fetchYears();
  }

  void _updateDisplayedBalance() {
    final text = _amountController.text;
    if (text.isEmpty) {
      setState(() => _displayedBalance = _balance);
      return;
    }
    
    final payAmount = int.tryParse(text) ?? 0;
    setState(() {
      _displayedBalance = _balance - payAmount;
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateDisplayedBalance);
    _amountController.dispose();
    _receiverController.dispose();
    _bankNameController.dispose();
    _refNoController.dispose();
    _chequeNoController.dispose();
    _upiIdController.dispose();
    _otherBankController.dispose();
    _eventFocus.dispose();
    _amountFocus.dispose();
    _bankFocus.dispose();
    _otherBankFocus.dispose();
    _upiIdFocus.dispose();
    _refNoFocus.dispose();
    _chequeNoFocus.dispose();
    _receiverFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _receiptImage = result.files.first;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _fetchYears() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.eventYears));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _years = List<int>.from(data['data']);
          if (widget.initialYear != null && _years.contains(widget.initialYear)) {
            _selectedYear = widget.initialYear;
            _fetchEvents(_selectedYear!);
          } else {
            _selectedYear = null; 
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching years: $e');
    }
  }

  Future<void> _fetchEvents(int year) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.eventsByYear}/$year'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _events = data['data'] ?? [];
          if (widget.initialEventId != null && _events.any((e) => e['Id'] == widget.initialEventId)) {
            _selectedEventId = widget.initialEventId;
            _fetchSummary(_selectedEventId!);
          } else {
            _selectedEventId = null;
            _totalAmount = 0;
            _alreadyPaid = 0;
            _balance = 0;
            _amountController.clear();
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
    }
  }

  Future<void> _fetchSummary(int eventId) async {
    setState(() => _isSummaryLoading = true);
    try {
      final memberId = widget.memberData['Familymembershipid'];
      final response = await http.get(Uri.parse('${ApiConfig.paymentSummary}/$memberId/$eventId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalAmount = data['total_amount'];
          _alreadyPaid = data['already_paid'];
          _balance = data['balance'];
          _displayedBalance = _balance;
          _amountController.text = "0";
        });
      }
    } catch (e) {
      debugPrint('Error fetching summary: $e');
    } finally {
      setState(() => _isSummaryLoading = false);
    }
  }

  Future<void> _saveReceipt() async {
    setState(() => _autoValidate = true);
    bool isValid = _formKey.currentState!.validate();
    if (!isValid) {
      FocusNode? firstErrorNode;
      if (_selectedEventId == null) {
        firstErrorNode = _eventFocus;
      } else if (_amountController.text.isEmpty || (int.tryParse(_amountController.text) ?? 0) <= 0 || (int.tryParse(_amountController.text) ?? 0) > _balance) {
        firstErrorNode = _amountFocus;
      } else if ((_paymentMethod == 'Bank' || _paymentMethod == 'Cheque') && (_selectedBank == null || _selectedBank!.isEmpty)) {
        firstErrorNode = _bankFocus;
      } else if ((_paymentMethod == 'Bank' || _paymentMethod == 'Cheque') && _showOtherBank && _otherBankController.text.isEmpty) {
        firstErrorNode = _otherBankFocus;
      } else if (_paymentMethod == 'UPI' && _upiIdController.text.isEmpty) {
        firstErrorNode = _upiIdFocus;
      } else if (_paymentMethod == 'Bank' && _refNoController.text.isEmpty) {
        firstErrorNode = _refNoFocus;
      } else if (_paymentMethod == 'Cheque' && _chequeNoController.text.isEmpty) {
        firstErrorNode = _chequeNoFocus;
      } else if (_receiverController.text.isEmpty) {
        firstErrorNode = _receiverFocus;
      }

      if (firstErrorNode != null && firstErrorNode.context != null) {
        Scrollable.ensureVisible(
          firstErrorNode.context!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
        firstErrorNode.requestFocus();
      }
      return;
    }

    if (_paymentMethod == 'UPI' && _receiptImage == null) {
      showStatusDialog(context, title: 'Receipt Required', message: 'Please upload the payment receipt for UPI transactions.', type: DialogType.warning);
      return;
    }

    if (!_isConfirmed) {
      showStatusDialog(context, title: 'Confirmation Required', message: 'Please confirm the details before saving.', type: DialogType.warning);
      return;
    }

    setState(() => _isLoading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.saveReceipt));
      request.fields['member_id'] = widget.memberData['Familymembershipid'].toString();
      request.fields['event_id'] = _selectedEventId.toString();
      request.fields['paid_amount'] = _amountController.text;
      request.fields['payment_method'] = _paymentMethod;
      request.fields['received_by'] = _receiverController.text;
      request.fields['payment_date'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      if (_paymentMethod == 'Bank' || _paymentMethod == 'Cheque') {
          request.fields['bank_name'] = _selectedBank == 'Other Bank' ? _otherBankController.text : _selectedBank!;
      }
      if (_paymentMethod == 'Bank') request.fields['transaction_id'] = _refNoController.text;
      if (_paymentMethod == 'Cheque') request.fields['check_no'] = _chequeNoController.text;
      if (_paymentMethod == 'UPI') request.fields['upi_id'] = _upiIdController.text;

      if (_receiptImage != null) {
        if (_receiptImage!.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes('receipt_image', _receiptImage!.bytes!, filename: _receiptImage!.name));
        } else if (_receiptImage!.path != null) {
          request.files.add(await http.MultipartFile.fromPath('receipt_image', _receiptImage!.path!));
        }
      }

      var streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          showStatusDialog(
            context,
            title: 'Success',
            message: 'Payment receipt saved successfully.',
            type: DialogType.success,
          ).then((_) {
            widget.onPaymentSuccess();
          });
        }
      } else {
        final decoded = jsonDecode(response.body);
        final detail = decoded['detail'];
        final String error = detail is List ? detail.first['msg'].toString() : (detail?.toString() ?? 'Failed to save receipt');
        if (mounted) showStatusDialog(context, title: 'Error', message: error, type: DialogType.error);
      }
    } catch (e) {
      debugPrint('Save Receipt Error: $e');
      if (mounted) showStatusDialog(context, title: 'Connection Error', message: 'Unable to save receipt. \n$e', type: DialogType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showBankSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredBanks = bankList.where((bank) => 
              bank.toLowerCase().contains(searchQuery.toLowerCase())
            ).toList();

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 400,
                height: 500,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance, color: Color(0xFF5D1712)),
                        const SizedBox(width: 12),
                        const Text('Choose bank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D1712))),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search bank...',
                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                        suffixIcon: const Icon(Icons.search, color: Color(0xFF5D1712)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF5D1712), width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() => searchQuery = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredBanks.isEmpty 
                        ? const Center(
                            child: Text('No banks found', style: TextStyle(color: Colors.black54)),
                          )
                        : ListView.separated(
                            itemCount: filteredBanks.length,
                            separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
                            itemBuilder: (context, index) {
                              final bank = filteredBanks[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedBank = bank;
                                      _showOtherBank = bank == 'Other Bank';
                                    });
                                    Navigator.pop(context);
                                  },
                                  hoverColor: const Color(0xFF5D1712).withOpacity(0.05),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                    child: Text(
                                      bank, 
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.receipt_long, color: const Color(0xFF5D1712), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'My Payment Details', 
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22, 
                        fontWeight: FontWeight.bold, 
                        color: const Color(0xFF2D1B18)
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 32),

              if (isMobile) 
                Column(children: [
                  _buildMemberInfoCard(isMobile),
                  const SizedBox(height: 16),
                  _buildEventInfoCard(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                ])
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildMemberInfoCard(isMobile)),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildEventInfoCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildSummaryCard()),
                  ],
                ),

              const SizedBox(height: 24),
              _buildPaymentMethodCard(),
              const SizedBox(height: 24),
              _buildReceiverCard(isMobile),
              const SizedBox(height: 32),
              
              Center(
                child: SizedBox(
                  width: isMobile ? double.infinity : 300,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveReceipt,
                    icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline),
                    label: Text(_isLoading ? 'Saving...' : 'Save Receipt', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D1712),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF5D1712)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5D1712))),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildMemberInfoCard(bool isMobile) {
    final address = "${widget.memberData['Street'] ?? ''}, ${widget.memberData['Village'] ?? ''}, ${widget.memberData['Taluk'] ?? ''}, ${widget.memberData['District'] ?? ''}, Tamil Nadu - ${widget.memberData['Pincode'] ?? ''}";
    
    return _buildCard(
      title: 'My Info',
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Name:', widget.memberData['Name'] ?? 'N/A', isBold: true),
          const SizedBox(height: 12),
          _infoRow('ID:', widget.memberData['Familymembershipid'] ?? 'N/A', color: const Color(0xFF5D1712), isBold: true),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Address:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 14, color: const Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(child: Text(address, style: const TextStyle(fontSize: 12, color: const Color(0xFF2D1B18), height: 1.4))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF64748B))),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? const Color(0xFF2D1B18)), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildEventInfoCard() {
    return _buildCard(
      title: 'Event Info',
      icon: Icons.event_note_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Event Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 6),
          CustomDropdownSearch(
            label: '',
            hint: 'Choose Year',
            dropdownItems: _years.map((y) => y.toString()).toList(),
            value: _selectedYear?.toString(),
            height: 45,
            onChanged: (val) {
              setState(() {
                final intVal = val == null ? null : int.tryParse(val);
                _selectedYear = intVal;
                if (intVal != null) {
                  _fetchEvents(intVal);
                } else {
                  _events = [];
                  _selectedEventId = null;
                  _totalAmount = 0;
                  _alreadyPaid = 0;
                  _balance = 0;
                  _displayedBalance = 0;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          const Text('Event', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 6),
          Focus(
            focusNode: _eventFocus,
            child: CustomDropdownSearch(
              label: '',
              hint: 'Choose Event',
              dropdownMap: {
                for (var e in _events) e['Id'].toString(): e['EventName'].toString(),
              },
              value: _selectedEventId?.toString(),
              height: 45,
              validator: (v) => v == null ? 'Required' : null,
              onChanged: (val) {
                final intVal = val == null ? null : int.tryParse(val);
                setState(() => _selectedEventId = intVal);
                if (intVal != null) _fetchSummary(intVal);
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Pay Amount *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 6),
          TextFormField(
            controller: _amountController,
            focusNode: _amountFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                final val = int.tryParse(newValue.text) ?? 0;
                if (val > _balance) return oldValue;
                return newValue;
              }),
            ],
            decoration: InputDecoration(
              prefixText: '₹ ',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              final amt = int.tryParse(v) ?? 0;
              if (amt <= 0) return 'Must be greater than 0';
              if (amt > _balance) return 'Cannot exceed balance (₹ $_balance)';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: const Color(0xFF64748B)),
                const SizedBox(width: 10),
                Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2D1B18))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _buildCard(
      title: 'Rs Summary',
      icon: Icons.summarize_outlined,
      child: _isSummaryLoading 
        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
        : Column(
            children: [
              _summaryRow('Total Amount', _totalAmount, Colors.black87),
              const Divider(height: 24),
              _summaryRow('Already Paid', _alreadyPaid, Colors.green),
              const Divider(height: 24),
              _summaryRow('Balance Amount', _displayedBalance, Colors.red, isBold: true),
            ],
          ),
    );
  }

  Widget _summaryRow(String label, int amount, Color color, {bool isBold = false}) {
    bool isInvalid = label == 'Balance Amount' && amount < 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isInvalid ? Colors.red.shade50 : const Color(0xFFF8FAFC), 
            borderRadius: BorderRadius.circular(8), 
            border: Border.all(color: isInvalid ? Colors.red.shade300 : const Color(0xFFE2E8F0))
          ),
          child: Text(
            isInvalid ? 'Invalid Amount' : '₹ $amount', 
            style: TextStyle(
              fontSize: 15, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600, 
              color: isInvalid ? Colors.red.shade900 : color
            )
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard() {
    return _buildCard(
      title: 'Payment Method',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _methodRadio('Bank', Icons.account_balance),
              _methodRadio('Cheque', Icons.article_outlined),
              _methodRadio('UPI', Icons.qr_code_scanner),
              _methodRadio('Cash', Icons.money),
            ],
          ),
          if (_paymentMethod != 'Cash') ...[
            const SizedBox(height: 24),
            if (_paymentMethod == 'Bank' || _paymentMethod == 'Cheque') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose Bank *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _showBankSearchDialog,
                    child: IgnorePointer(
                      child: TextFormField(
                        focusNode: _bankFocus,
                        controller: TextEditingController(text: _selectedBank ?? ''),
                        decoration: InputDecoration(
                          hintText: 'Choose bank',
                          hintStyle: const TextStyle(fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                        validator: (v) => (_selectedBank == null || _selectedBank!.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (_showOtherBank) ...[
                const SizedBox(height: 16),
                _textField('Other Bank Name *', _otherBankController, focusNode: _otherBankFocus),
              ],
              const SizedBox(height: 16),
            ],
            
            if (_paymentMethod == 'UPI') ...[
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: "upi://pay?pa=KADAIKULANARPANIMANDRAM@iob&pn=Poondurai%20Kaadaikulam%20Narpanimandram&cu=INR",
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'UPI ID:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'KADAIKULANARPANIMANDRAM@iob',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5D1712)),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _textField('UPI Transaction ID *', _upiIdController, focusNode: _upiIdFocus),
                    ),
                  ],
                ),
              ),
            ],

            if (_paymentMethod == 'Bank' || _paymentMethod == 'Cheque')
              Row(
                children: [
                  if (_paymentMethod == 'Bank')
                    Expanded(child: _textField('Reference ID *', _refNoController, focusNode: _refNoFocus)),
                  if (_paymentMethod == 'Cheque')
                    Expanded(child: _textField('Cheque Number *', _chequeNoController, focusNode: _chequeNoFocus)),
                ],
              ),
          ],
          if (_paymentMethod == 'UPI')
            _buildImagePicker(),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: 'Upload Receipt ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            children: const [
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (_receiptImage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.image, color: Color(0xFF5D1712)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_receiptImage!.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: () => setState(() => _receiptImage = null),
                  tooltip: 'Remove Image',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Color(0xFF64748B), size: 32),
                  const SizedBox(height: 8),
                  const Text('Tap to upload receipt', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _methodRadio(String value, IconData icon) {
    bool isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
            activeColor: const Color(0xFF5D1712),
          ),
          Icon(icon, size: 20, color: isSelected ? const Color(0xFF5D1712) : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? const Color(0xFF2D1B18) : const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller, {FocusNode? focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildReceiverCard(bool isMobile) {
    return _buildCard(
      title: 'Receiver Info',
      icon: Icons.person_add_alt_1_outlined,
      child: isMobile 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Person Received the Money *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              const SizedBox(height: 6),
              TextFormField(
                controller: _receiverController,
                focusNode: _receiverFocus,
                decoration: InputDecoration(
                  hintText: 'Enter name of receiver',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isConfirmed ? Colors.green.withOpacity(0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isConfirmed ? Colors.green.withOpacity(0.3) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isConfirmed,
                      onChanged: (v) => setState(() => _isConfirmed = v!),
                      activeColor: Colors.green,
                    ),
                    const Expanded(child: Text('Confirm Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF059669)))),
                  ],
                ),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Person Received the Money *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _receiverController,
                      decoration: InputDecoration(
                        hintText: 'Enter name of receiver',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isConfirmed ? Colors.green.withOpacity(0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isConfirmed ? Colors.green.withOpacity(0.3) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isConfirmed,
                        onChanged: (v) => setState(() => _isConfirmed = v!),
                        activeColor: Colors.green,
                      ),
                      const Expanded(child: Text('Confirm Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF059669)))),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
