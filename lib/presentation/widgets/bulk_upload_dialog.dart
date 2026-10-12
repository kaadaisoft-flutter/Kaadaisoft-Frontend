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
  List<int> _years = [];

  @override
  void initState() {
    super.initState();
    _years = List<int>.from(widget.years);
    if (_years.isEmpty) {
      _fetchYears();
    }
  }

  Future<void> _fetchYears() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.eventYears));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fetched = List<int>.from(data['data']);
        if (mounted && fetched.isNotEmpty) {
          setState(() {
            _years = fetched;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching years in dialog: $e');
    }
  }

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
        final rawEvents = List<dynamic>.from(data['data'] ?? []);
        final filteredEvents = rawEvents.where((e) {
          final name = (e['EventName'] ?? e['eventname'] ?? '').toString().trim();
          final reg = RegExp(r'\b(19\d{2}|20\d{2}|21\d{2})\b');
          final match = reg.firstMatch(name) ?? RegExp(r'(\d{4})').firstMatch(name);
          if (match != null) {
            final evYear = int.tryParse(match.group(1)!);
            if (evYear != null && evYear != year) {
              return false;
            }
          }
          return true;
        }).toList();

        setState(() {
          _events = filteredEvents;
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
      final extension = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
      if (extension != 'csv') {
        if (mounted) {
          showStatusDialog(
            context,
            title: 'Unsupported File Format',
            message: 'Only CSV files (.csv) are allowed for bulk payment upload. PDF, XLSX, DOCX, and other file formats are not supported.',
            type: DialogType.error,
          );
        }
        return;
      }
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
        title: 'Validation Error',
        message: 'Please select an event and a CSV file.',
        type: DialogType.error,
      );
      return;
    }

    final extension = _selectedFile!.name.contains('.') ? _selectedFile!.name.split('.').last.toLowerCase() : '';
    if (extension != 'csv') {
      showStatusDialog(
        context,
        title: 'Unsupported File Format',
        message: 'Only CSV files (.csv) are allowed for bulk payment upload. PDF, XLSX, DOCX, and other file formats are not supported.',
        type: DialogType.error,
      );
      return;
    }

    if (_selectedFile!.bytes == null || _selectedFile!.bytes!.isEmpty) {
      showStatusDialog(
        context,
        title: 'Validation Error',
        message: 'The selected CSV file is empty. Please upload a file containing payment rows.',
        type: DialogType.error,
      );
      return;
    }

    // Client-side CSV validation
    try {
      final text = utf8.decode(_selectedFile!.bytes!, allowMalformed: true);
      final lines = const LineSplitter().convert(text).where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        showStatusDialog(
          context,
          title: 'Validation Error',
          message: 'The CSV file is empty. Please upload a file containing payment rows.',
          type: DialogType.error,
        );
        return;
      }

      final headerLine = lines.first;
      final headers = headerLine.split(',').map((h) => h.replaceAll('"', '').replaceAll("'", "").trim().toLowerCase()).toList();

      final hasMemberId = headers.any((h) => ['familymembershipid', 'membershipid', 'familyid', 'family_membership_id', 'memberid'].contains(h.replaceAll('_', '').replaceAll(' ', '')));
      final hasAmount = headers.any((h) => ['paidamount', 'paid_amount', 'amount', 'taxamount'].contains(h.replaceAll('_', '').replaceAll(' ', '')));

      if (!hasMemberId || !hasAmount) {
        final missing = <String>[];
        if (!hasMemberId) missing.add('Familymembershipid');
        if (!hasAmount) missing.add('paidamount');
        showStatusDialog(
          context,
          title: 'Invalid CSV Headers',
          message: 'Missing required header column(s): ${missing.join(', ')}. Please use the expected CSV format.',
          type: DialogType.error,
        );
        return;
      }

      if (lines.length < 2) {
        showStatusDialog(
          context,
          title: 'Validation Error',
          message: 'The CSV file contains headers but no payment data rows. Please add payment rows to upload.',
          type: DialogType.error,
        );
        return;
      }

      int memIdx = headers.indexWhere((h) => ['familymembershipid', 'membershipid', 'familyid', 'family_membership_id', 'memberid'].contains(h.replaceAll('_', '').replaceAll(' ', '')));
      int amtIdx = headers.indexWhere((h) => ['paidamount', 'paid_amount', 'amount', 'taxamount'].contains(h.replaceAll('_', '').replaceAll(' ', '')));

      for (int i = 1; i < lines.length; i++) {
        final cols = lines[i].split(',').map((c) => c.replaceAll('"', '').trim()).toList();
        final memVal = memIdx < cols.length ? cols[memIdx] : '';
        final amtVal = amtIdx < cols.length ? cols[amtIdx] : '';

        if (memVal.isEmpty) {
          showStatusDialog(
            context,
            title: 'Validation Error',
            message: 'CSV Validation Error on Row ${i + 1}: Missing Familymembershipid.',
            type: DialogType.error,
          );
          return;
        }

        final parsedAmt = double.tryParse(amtVal);
        if (amtVal.isEmpty || parsedAmt == null || parsedAmt <= 0) {
          showStatusDialog(
            context,
            title: 'Validation Error',
            message: 'CSV Validation Error on Row ${i + 1}: Invalid paidamount ("$amtVal"). Amount must be a positive number.',
            type: DialogType.error,
          );
          return;
        }
      }
    } catch (e) {
      showStatusDialog(
        context,
        title: 'CSV Format Error',
        message: 'Failed to parse CSV file content. Please verify the file structure.',
        type: DialogType.error,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.bulkUploadPayments));
      request.fields['event_id'] = _selectedEventId.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _selectedFile!.bytes!,
        filename: _selectedFile!.name,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        final msg = resJson['message'] ?? 'Bulk payment upload completed successfully!';
        if (mounted) {
          showStatusDialog(
            context,
            title: 'Success',
            message: msg,
            type: DialogType.success,
            onOk: () {
              if (mounted) Navigator.of(context).pop(true);
            },
          );
        }
      } else {
        final resJson = jsonDecode(response.body);
        final errorMsg = resJson['detail'] ?? resJson['message'] ?? 'Bulk payment upload failed.';
        if (mounted) {
          showStatusDialog(
            context,
            title: 'Validation Error',
            message: errorMsg,
            type: DialogType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showStatusDialog(
          context,
          title: 'Error',
          message: 'Connection error during bulk payment upload: ${e.toString()}',
          type: DialogType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _downloadSampleExcel() {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    List<CellValue> headers = [
      TextCellValue('Familymembershipid'),
      TextCellValue('membername'),
      TextCellValue('mobile'),
      TextCellValue('paidamount'),
      TextCellValue('paymentdate'),
      TextCellValue('paymenttype'),
      TextCellValue('transactionid'),
      TextCellValue('remarks'),
    ];
    sheetObject.appendRow(headers);

    List<CellValue> row1 = [
      TextCellValue('NMK00001'),
      TextCellValue('John Doe'),
      TextCellValue('9876543210'),
      TextCellValue('500'),
      TextCellValue('2026-05-20'),
      TextCellValue('Cash'),
      TextCellValue(''),
      TextCellValue('Annual payment'),
    ];
    sheetObject.appendRow(row1);

    List<CellValue> row2 = [
      TextCellValue('NMK00002'),
      TextCellValue('Jane Smith'),
      TextCellValue('9123456789'),
      TextCellValue('1000'),
      TextCellValue('2026-05-21'),
      TextCellValue('UPI'),
      TextCellValue('TXN12345678'),
      TextCellValue('GPay'),
    ];
    sheetObject.appendRow(row2);

    var fileBytes = excel.encode();
    if (fileBytes != null) {
      dl.downloadBytes(Uint8List.fromList(fileBytes), 'sample_bulk_payment_format.xlsx');
      
      if (mounted) {
        showStatusDialog(
          context,
          title: 'Success',
          message: 'Sample Excel format downloaded successfully.',
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
                          'Expected Columns: Familymembershipid, membername, mobile, paidamount, paymentdate, paymenttype, transactionid, remarks',
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
    final currentYear = DateTime.now().year;
    final yearList = _years.isNotEmpty 
        ? _years 
        : (widget.years.isNotEmpty ? widget.years : [currentYear - 1, currentYear, currentYear + 1]);

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
          dropdownMap: { for (var y in yearList) y.toString(): y.toString() },
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
