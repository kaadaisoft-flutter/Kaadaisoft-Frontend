import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:typed_data';
import '../../utils/download_helper.dart' as dl;
import 'package:http/http.dart' as http;
import '../../l10n/app_localizations.dart';
import '../../utils/api_config.dart';
import 'custom_dropdown_search.dart';
import 'custom_dialog.dart';

class BulkUploadDialog extends StatefulWidget {
  final List<int> years;

  const BulkUploadDialog({Key? key, required this.years}) : super(key: key);

  @override
  State<BulkUploadDialog> createState() => _BulkUploadDialogState();
}

class _BulkUploadDialogState extends State<BulkUploadDialog> {
  int? _selectedYear;
  int? _selectedEventId;
  List<dynamic> _events = [];
  bool _isLoadingEvents = false;
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _fetchEvents(int year) async {
    setState(() {
      _isLoadingEvents = true;
      _events = [];
      _selectedEventId = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.eventsByYear}/$year'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _events = data['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
    } finally {
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final file = result.files.first;
      if (file.size > 2 * 1024 * 1024) {
        if (mounted) {
          showStatusDialog(
            context,
            title: 'Error',
            message: 'File size should be below 2MB',
            type: DialogType.error,
          );
        }
        return;
      }
      setState(() {
        _selectedFile = file;
      });
    }
  }

  Future<void> _uploadPayments() async {
    if (_selectedEventId == null || _selectedFile == null) {
      showStatusDialog(
        context,
        title: 'Error',
        message: 'Please select an event and a CSV file',
        type: DialogType.error,
      );
      return;
    }
    
    setState(() {
      _isUploading = true;
    });
    
    // Simulate API call for now. Adjust when backend endpoint is ready.
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isUploading = false;
    });
    
    if (mounted) {
      showStatusDialog(
        context,
        title: 'Success',
        message: 'Bulk payment upload completed successfully!',
        type: DialogType.success,
        onOk: () {
          if (mounted) Navigator.of(context).pop(true);
        },
      );
    }
  }

  void _downloadSampleExcel() {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    List<CellValue> headers = [
      TextCellValue('Familymembershipid'),
      TextCellValue('EventName'),
      TextCellValue('EventId'),
      TextCellValue('paymentdate'),
      TextCellValue('paidamount'),
      TextCellValue('membername'),
      TextCellValue('mobile'),
      TextCellValue('membertaluk'),
      TextCellValue('paymenttype'),
      TextCellValue('transactionid'),
      TextCellValue('bankname'),
    ];
    sheetObject.appendRow(headers);

    List<CellValue> row1 = [
      TextCellValue('NMK00001'),
      TextCellValue('Sample Event 2025'),
      TextCellValue('12'),
      TextCellValue('2025-05-20'),
      TextCellValue('500'),
      TextCellValue('John Doe'),
      TextCellValue('9876543210'),
      TextCellValue('Erode'),
      TextCellValue('cash'),
      TextCellValue(''),
      TextCellValue(''),
    ];
    sheetObject.appendRow(row1);

    List<CellValue> row2 = [
      TextCellValue('NMK00002'),
      TextCellValue('Sample Event 2025'),
      TextCellValue('12'),
      TextCellValue('2025-05-21'),
      TextCellValue('1000'),
      TextCellValue('Jane Smith'),
      TextCellValue('9123456789'),
      TextCellValue('Coimbatore'),
      TextCellValue('online'),
      TextCellValue('TXN123456'),
      TextCellValue('SBI'),
    ];
    sheetObject.appendRow(row2);

    var fileBytes = excel.encode();
    if (fileBytes != null) {
      dl.downloadBytes(Uint8List.fromList(fileBytes), 'sample_bulk_payment_format.xlsx');
      
      if (mounted) {
        showStatusDialog(
          context,
          title: 'Success',
          message: 'Sample Excel format downloaded.',
          type: DialogType.success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? double.infinity : 650,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF198754),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.bulkPaymentUploadTitle ?? 'Bulk Payment Upload',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            
            // Body
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdowns
                  if (isMobile) ...[
                    _buildYearDropdown(),
                    const SizedBox(height: 16),
                    _buildEventDropdown(),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildYearDropdown()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildEventDropdown()),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Upload CSV label
                  const Text(
                    'Upload CSV:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  
                  // Upload Area
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: Colors.green.shade200, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_upload, color: Color(0xFF198754), size: 48),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _isUploading ? null : _pickFile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE2E8F0),
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: const Text('Choose File'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedFile?.name ?? 'No file chosen',
                                style: const TextStyle(color: Colors.black54, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'CSV Priority: Familymembershipid,EventName,EventId,paymentdate,paidamount,...',
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Note: File Size should be below 2MB.',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _downloadSampleExcel,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.table_chart, color: Colors.blue, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Download Sample Excel Format',
                                style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black54,
                          side: const BorderSide(color: Colors.black26),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isUploading ? null : _uploadPayments,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF198754),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: _isUploading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Upload Payments', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)?.eventYearLabel ?? 'Event Year',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Text(':', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 8),
        CustomDropdownSearch(
          label: '',
          hint: AppLocalizations.of(context)?.chooseYearHint ?? 'Choose Year',
          dropdownMap: { for (var y in widget.years) y.toString(): y.toString() },
          value: _selectedYear?.toString(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedYear = int.parse(val);
                _fetchEvents(_selectedYear!);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildEventDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Event (Backup)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Text(':', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 8),
        _isLoadingEvents 
            ? const SizedBox(
                height: 48, 
                child: Center(child: CircularProgressIndicator(strokeWidth: 2))
              )
            : CustomDropdownSearch(
                label: '',
                hint: AppLocalizations.of(context)?.chooseEventHint ?? 'Choose Event',
                dropdownMap: { for (var e in _events) e['Id'].toString(): e['EventName'].toString() },
                value: _selectedEventId?.toString(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedEventId = int.parse(val));
                  }
                },
              ),
      ],
    );
  }
}
