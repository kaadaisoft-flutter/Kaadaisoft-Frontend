import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';

class EventsContent extends StatefulWidget {
  final int? role;
  final String? globalSearchQuery;
  
  const EventsContent({super.key, this.role = 3, this.globalSearchQuery});

  @override
  State<EventsContent> createState() => _EventsContentState();
}

class _EventsContentState extends State<EventsContent> {
  List<dynamic> _events = [];
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  String _selectedTab = 'Upcoming';

  List<dynamic> get _filteredEvents {
    List<dynamic> filtered = _events;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    filtered = filtered.where((event) {
      DateTime? fromDate;
      DateTime? toDate;
      try {
        if (event['From_date'] != null && event['From_date'].toString().isNotEmpty && event['From_date'] != 'N/A') {
          final p = DateTime.parse(event['From_date'].toString());
          fromDate = DateTime(p.year, p.month, p.day);
        }
      } catch (_) {}
      try {
        if (event['To_date'] != null && event['To_date'].toString().isNotEmpty && event['To_date'] != 'N/A') {
          final p = DateTime.parse(event['To_date'].toString());
          toDate = DateTime(p.year, p.month, p.day);
        }
      } catch (_) {}

      if (_selectedTab == 'Upcoming') {
        return fromDate != null && fromDate.isAfter(today);
      } else if (_selectedTab == 'Current') {
        if (fromDate != null && toDate != null) {
          return (fromDate.isBefore(today) || fromDate.isAtSameMomentAs(today)) &&
                 (toDate.isAfter(today) || toDate.isAtSameMomentAs(today));
        } else if (fromDate != null) {
          return fromDate.isAtSameMomentAs(today);
        }
        return false;
      } else if (_selectedTab == 'Completed') {
        if (toDate != null) {
          return toDate.isBefore(today);
        } else if (fromDate != null) {
          return fromDate.isBefore(today);
        }
        return false;
      }
      return true;
    }).toList();

    if (widget.globalSearchQuery != null && widget.globalSearchQuery!.isNotEmpty) {
      final query = widget.globalSearchQuery!.toLowerCase();
      filtered = filtered.where((event) {
        final name = (event['EventName']?.toString() ?? '').toLowerCase();
        final tax = (event['TaxAmount']?.toString() ?? '').toLowerCase();
        return name.contains(query) || tax.contains(query);
      }).toList();
    }
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/events'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            final List<dynamic> eventsList = List<dynamic>.from(result['data']);
            eventsList.sort((a, b) => (b['Id'] ?? 0).compareTo(a['Id'] ?? 0));
            _events = eventsList;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load events';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection error';
          _isLoading = false;
        });
      }
    }
  }

  void _showUpdateEventDialog(Map<String, dynamic> event) {
    final initialName = event['EventName']?.toString() ?? '';
    final initialTax = event['TaxAmount']?.toString() ?? '0.00';
    final nameController = TextEditingController(text: initialName);
    final taxController = TextEditingController(text: initialTax);
    
    DateTime parseDate(dynamic dateStr) {
      if (dateStr == null || dateStr == 'N/A' || dateStr.toString().isEmpty) return DateTime.now();
      try {
        return DateTime.parse(dateStr.toString());
      } catch (e) {
        try {
          // Try parsing DD-MM-YYYY
          List<String> parts = dateStr.toString().split('-');
          if (parts.length == 3) {
            int d = int.parse(parts[0]);
            int m = int.parse(parts[1]);
            int y = int.parse(parts[2]);
            return DateTime(y, m, d);
          }
        } catch (_) {}
        return DateTime.now();
      }
    }

    DateTime initialFromDate = parseDate(event['From_date']);
    DateTime initialToDate = parseDate(event['To_date']);
    DateTime fromDate = initialFromDate;
    DateTime toDate = initialToDate;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.eventDetails ?? 'Event Details', 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)?.addEventNameUpper ?? 'EVENT NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    onChanged: (value) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Enter event name',
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: const Color(0xFF5D1712), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)?.addEventDurationUpper ?? 'DURATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      bool isSmall = MediaQuery.of(context).size.width < 500;
                      
                      final fromDateWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)?.addEventFrom ?? 'From', style: TextStyle(fontSize: 11, color: Colors.black45)),
                          const SizedBox(height: 4),
                          _buildDatePicker(context, fromDate, (date) {
                            setDialogState(() {
                              fromDate = date;
                              if (!toDate.isAfter(fromDate)) {
                                toDate = fromDate.add(const Duration(days: 1));
                              }
                            });
                          }, minDate: DateTime.now()),
                        ],
                      );
                      
                      final toDateWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)?.addEventTo ?? 'To', style: TextStyle(fontSize: 11, color: Colors.black45)),
                          const SizedBox(height: 4),
                          _buildDatePicker(context, toDate, (date) => setDialogState(() => toDate = date), minDate: fromDate.add(const Duration(days: 1))),
                        ],
                      );

                      if (isSmall) {
                        return Column(
                          children: [
                            fromDateWidget,
                            const SizedBox(height: 12),
                            toDateWidget,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: fromDateWidget),
                          const SizedBox(width: 16),
                          Expanded(child: toDateWidget),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(AppLocalizations.of(context)?.addEventTaxAmountUpper ?? 'TAX AMOUNT (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taxController,
                    onChanged: (value) => setDialogState(() {}),
                    maxLength: 9,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
           inputFormatters: [
             FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
           ],
           onTap: () {
             taxController.selection = TextSelection(
               baseOffset: 0,
               extentOffset: taxController.text.length,
             );
           },
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Enter tax amount',
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: const Color(0xFF5D1712), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSaving ||
                                 (nameController.text == initialName &&
                                  taxController.text == initialTax &&
                                  fromDate == initialFromDate &&
                                  toDate == initialToDate)
                          ? null : () async {
                        if (nameController.text.isEmpty) {
                          showStatusDialog(context, title: 'Error', message: 'Please enter an event name', type: DialogType.error);
                          return;
                        }
                        if (!RegExp(r'_20\d{2}$').hasMatch(nameController.text.trim())) {
                          showStatusDialog(context, title: 'Error', message: 'Event name must end with an underscore and a valid year (e.g. Event_2026)', type: DialogType.error);
                          return;
                        }
                        if (!toDate.isAfter(fromDate)) {
                          showStatusDialog(context, title: 'Error', message: 'To date must be greater than From date', type: DialogType.error);
                          return;
                        }
                        if (taxController.text.isEmpty || double.tryParse(taxController.text) == null || double.parse(taxController.text) <= 0) {
                          showStatusDialog(context, title: 'Error', message: 'Tax amount must be greater than zero', type: DialogType.error);
                          return;
                        }
                        if (double.parse(taxController.text) > 500000000) {
                          showStatusDialog(context, title: 'Error', message: 'Tax amount cannot exceed 50 crores (500000000)', type: DialogType.error);
                          return;
                        }
                        setDialogState(() => isSaving = true);
                        try {
                          final response = await http.post(
                            Uri.parse('${ApiConfig.baseUrl}/api/update-event/${event['Id']}'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'EventName': nameController.text,
                              'From_date': fromDate.toIso8601String().split('T')[0],
                              'To_date': toDate.toIso8601String().split('T')[0],
                              'TaxAmount': taxController.text,
                            }),
                          );

                          if (response.statusCode == 200) {
                            Navigator.pop(context);
                            _fetchEvents();
                            showStatusDialog(context, title: 'Success', message: 'Event updated successfully', type: DialogType.success);
                          }
                        } catch (e) {
                          showStatusDialog(context, title: 'Error', message: 'Failed to update event', type: DialogType.error);
                        } finally {
                          setDialogState(() => isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D1712),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isSaving 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(AppLocalizations.of(context)?.saveChanges ?? 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateBannerDialog(Map<String, dynamic> event) {
    PlatformFile? selectedFile;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Text('Update Event Banner', style: TextStyle(fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[50], border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      const Text('CURRENT EVENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text(event['EventName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF5D1712))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('NEW BANNER IMAGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    try {
                      FilePickerResult? result = await FilePicker.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (result != null) {
                        if (result.files.first.size > 2 * 1024 * 1024) {
                          showStatusDialog(context, title: 'Error', message: 'Image size must be less than 2 MB', type: DialogType.error);
                          return;
                        }
                        String? ext = result.files.first.extension?.toLowerCase();
                        if (ext != 'jpg' && ext != 'png') {
                          showStatusDialog(context, title: 'Error', message: 'Only JPG and PNG formats are supported', type: DialogType.error);
                          return;
                        }
                        setDialogState(() => selectedFile = result.files.first);
                      }
                    } catch (e) {
                      print("File picker error: $e");
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedFile != null ? const Color(0xFF5D1712).withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selectedFile != null ? const Color(0xFF5D1712) : Colors.grey[300]!, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                          size: 20,
                          color: selectedFile != null ? const Color(0xFF5D1712) : Colors.grey[500],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedFile?.name ?? 'Click to choose an image file...',
                            style: TextStyle(
                              color: selectedFile != null ? const Color(0xFF5D1712) : Colors.grey[600],
                              fontSize: 13,
                              fontWeight: selectedFile != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: const Color(0xFF5D1712)),
                    SizedBox(width: 4),
                    Expanded(child: Text('Choose a high-quality JPG or PNG.', style: TextStyle(fontSize: 12, color: const Color(0xFF5D1712)))),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving || selectedFile == null ? null : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/update-event-banner/${event['Id']}'));
                        request.files.add(http.MultipartFile.fromBytes('image', selectedFile!.bytes!, filename: selectedFile!.name));
                        var streamedResponse = await request.send();
                        if (streamedResponse.statusCode == 200) {
                          Navigator.pop(context);
                          _fetchEvents();
                          showStatusDialog(context, title: 'Success', message: 'Banner updated successfully', type: DialogType.success);
                        } else {
                          showStatusDialog(context, title: 'Error', message: 'Failed to update banner', type: DialogType.error);
                        }
                      } catch (e) {
                        showStatusDialog(context, title: 'Error', message: e.toString(), type: DialogType.error);
                      } finally {
                        setDialogState(() => isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D1712), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Update Banner', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 300,
                    height: 300,
                    color: Colors.white,
                    child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDatePicker(BuildContext context, DateTime? selectedDate, Function(DateTime) onDateSelected, {DateTime? minDate}) {
    return InkWell(
      onTap: () async {
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);
        DateTime first = minDate ?? DateTime(2000);
        DateTime initial = selectedDate ?? today;
        if (initial.isBefore(first)) {
          initial = first;
        }

        final date = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: first,
          lastDate: DateTime(2100),
        );
        if (date != null) onDateSelected(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(selectedDate != null 
                ? '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}'
                : 'dd-mm-yyyy',
                style: TextStyle(
                  color: selectedDate != null ? Colors.black87 : Colors.black45,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.calendar_month, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog() {
    final nameController = TextEditingController();
    final taxController = TextEditingController();
    DateTime? fromDate;
    DateTime? toDate;
    PlatformFile? selectedBanner;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.addNewEvent ?? 'Add New Event', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: Container(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)?.addEventNameUpper ?? 'EVENT NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)?.addEventEgName ?? 'e.g. Event_2026',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: const Color(0xFF5D1712)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)?.addEventNoteName ?? 'Note: Year should be at the end of the event name (e.g. Event_2026).',
                          style: TextStyle(fontSize: 11, color: const Color(0xFF5D1712)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Text(AppLocalizations.of(context)?.addEventBannerUpper ?? 'EVENT BANNER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      try {
                        FilePickerResult? result = await FilePicker.pickFiles(
                          type: FileType.image,
                          withData: true,
                        );
                        if (result != null) {
                          if (result.files.first.size > 2 * 1024 * 1024) {
                            showStatusDialog(context, title: 'Error', message: 'Image size must be less than 2 MB', type: DialogType.error);
                            return;
                          }
                          String? ext = result.files.first.extension?.toLowerCase();
                          if (ext != 'jpg' && ext != 'png') {
                            showStatusDialog(context, title: 'Error', message: 'Only JPG and PNG formats are supported', type: DialogType.error);
                            return;
                          }
                          setDialogState(() => selectedBanner = result.files.first);
                        }
                      } catch (e) {
                        debugPrint('File picker error: $e');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(AppLocalizations.of(context)?.addEventChooseFile ?? 'Choose File', style: TextStyle(fontSize: 13, color: Colors.black87)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedBanner?.name ?? AppLocalizations.of(context)?.addEventNoFileChosen ?? 'No file chosen',
                              style: TextStyle(fontSize: 13, color: selectedBanner == null ? Colors.black45 : Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: const Color(0xFF5D1712)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)?.addEventNoteBanner ?? 'Note: Max file size 2MB (JPG, PNG).',
                          style: TextStyle(fontSize: 11, color: const Color(0xFF5D1712)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(AppLocalizations.of(context)?.addEventDurationUpper ?? 'DURATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      bool isSmall = MediaQuery.of(context).size.width < 500;
                      
                      final fromDateWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)?.addEventFrom ?? 'From', style: TextStyle(fontSize: 11, color: Colors.black45)),
                          const SizedBox(height: 4),
                          _buildDatePicker(context, fromDate, (date) {
                            setDialogState(() {
                              fromDate = date;
                              if (toDate != null && !toDate!.isAfter(fromDate!)) {
                                toDate = fromDate!.add(const Duration(days: 1));
                              }
                            });
                          }, minDate: DateTime.now()),
                        ],
                      );
                      
                      final toDateWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)?.addEventTo ?? 'To', style: TextStyle(fontSize: 11, color: Colors.black45)),
                          const SizedBox(height: 4),
                          _buildDatePicker(context, toDate, (date) => setDialogState(() => toDate = date), minDate: fromDate != null ? fromDate!.add(const Duration(days: 1)) : DateTime.now().add(const Duration(days: 1))),
                        ],
                      );

                      if (isSmall) {
                        return Column(
                          children: [
                            fromDateWidget,
                            const SizedBox(height: 12),
                            toDateWidget,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: fromDateWidget),
                          const SizedBox(width: 16),
                          Expanded(child: toDateWidget),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  Text(AppLocalizations.of(context)?.addEventTaxAmountUpper ?? 'TAX AMOUNT (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taxController,
                    maxLength: 9,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onTap: () {
                      taxController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: taxController.text.length,
                      );
                    },
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        if (nameController.text.isEmpty) {
                          showStatusDialog(context, title: 'Error', message: 'Please enter an event name', type: DialogType.error);
                          return;
                        }
                        if (!RegExp(r'_20\d{2}$').hasMatch(nameController.text.trim())) {
                          showStatusDialog(context, title: 'Error', message: 'Event name must end with an underscore and a valid year (e.g. Event_2026)', type: DialogType.error);
                          return;
                        }
                        if (selectedBanner == null) {
                          showStatusDialog(context, title: 'Error', message: 'Please select an event banner', type: DialogType.error);
                          return;
                        }
                        if (fromDate == null || toDate == null) {
                          showStatusDialog(context, title: 'Error', message: 'Please select event duration', type: DialogType.error);
                          return;
                        }
                        if (!toDate!.isAfter(fromDate!)) {
                          showStatusDialog(context, title: 'Error', message: 'To date must be greater than From date', type: DialogType.error);
                          return;
                        }
                        if (taxController.text.isEmpty || double.tryParse(taxController.text) == null || double.parse(taxController.text) <= 0) {
                          showStatusDialog(context, title: 'Error', message: 'Tax amount must be greater than zero', type: DialogType.error);
                          return;
                        }
                        if (double.parse(taxController.text) > 500000000) {
                          showStatusDialog(context, title: 'Error', message: 'Tax amount cannot exceed 50 crores (500000000)', type: DialogType.error);
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/api/add-event'));
                          request.fields['EventName'] = nameController.text;
                          request.fields['From_date'] = fromDate!.toIso8601String().split('T')[0];
                          request.fields['To_date'] = toDate!.toIso8601String().split('T')[0];
                          request.fields['TaxAmount'] = taxController.text;

                          if (selectedBanner != null && selectedBanner!.bytes != null) {
                            request.files.add(http.MultipartFile.fromBytes(
                              'image', 
                              selectedBanner!.bytes!,
                              filename: selectedBanner!.name
                            ));
                          }

                          var streamedResponse = await request.send();
                          var response = await http.Response.fromStream(streamedResponse);

                          if (response.statusCode == 200) {
                            Navigator.pop(context);
                            _fetchEvents();
                            showStatusDialog(context, title: 'Success', message: 'Event created successfully', type: DialogType.success);
                          } else {
                            final error = jsonDecode(response.body)['message'] ?? 'Failed to create event';
                            showStatusDialog(context, title: 'Error', message: error, type: DialogType.error);
                          }
                        } catch (e) {
                          showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);
                        } finally {
                          setDialogState(() => isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D1712),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(AppLocalizations.of(context)?.addEventCreateBtn ?? 'Create Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    
    Widget tabsRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: ['Upcoming', 'Current', 'Completed'].map((tab) {
        final isSelected = _selectedTab == tab;
        Widget tabWidget = GestureDetector(
          onTap: () => setState(() => _selectedTab = tab),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: isMobile ? 4 : 24),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tab == 'Upcoming' ? (AppLocalizations.of(context)?.upcomingTab ?? 'Upcoming') :
                tab == 'Current' ? (AppLocalizations.of(context)?.currentTab ?? 'Current') :
                (AppLocalizations.of(context)?.completedTab ?? 'Completed'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFE53935) : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
          ),
        );
        return isMobile ? Expanded(child: tabWidget) : tabWidget;
      }).toList(),
    );

    return Align(
      alignment: Alignment.center,
      child: Container(
        width: isMobile ? double.infinity : null,
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: tabsRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingSpinner(message: 'Fetching events...');
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)?.eventsManagement ?? 'Events Management', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18))),
                  const SizedBox(height: 16),
                  if (widget.role == 1)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddEventDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(AppLocalizations.of(context)?.addNewEvent ?? 'Add New Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D1B18),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)?.eventsManagement ?? 'Events Management', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18))),
                  if (widget.role == 1)
                    ElevatedButton.icon(
                      onPressed: _showAddEventDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(AppLocalizations.of(context)?.addNewEvent ?? 'Add New Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D1B18),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                ],
              ),
            
            _buildFilterTabs(),
            
            const SizedBox(height: 12),
            if (isMobile)
              Column(
                children: [
                  _events.isEmpty && !_isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No events found', style: TextStyle(color: Colors.black54))),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredEvents.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildEventCard(_filteredEvents[index], index);
                        },
                      ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(_isLoading ? '' : '${AppLocalizations.of(context)?.totalEvents ?? "Total Events:"} ${_filteredEvents.length}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                        const Row(
                          children: [
                            Icon(Icons.chevron_left, color: Colors.black26),
                            SizedBox(width: 16),
                            CircleAvatar(radius: 14, backgroundColor: const Color(0xFF5D1712), child: Text('1', style: TextStyle(color: Colors.white, fontSize: 12))),
                            SizedBox(width: 16),
                            Icon(Icons.chevron_right, color: Colors.black26),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              // Table Container
              Container(
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
                    // Main Area (Header + Body)
                    Column(
                      children: [
                        // Table Header
                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2D1B18),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                child: Row(
                                  children: [
                                    _buildHeaderCell(AppLocalizations.of(context)?.sNo ?? 'S.NO', 60, alignment: Alignment.center),
                                    Expanded(flex: 2, child: _buildHeaderCell(AppLocalizations.of(context)?.eventNameHeader ?? 'EVENT NAME', 150)),
                                    _buildHeaderCell(AppLocalizations.of(context)?.bannerHeader ?? 'BANNER', 120, alignment: Alignment.center),
                                    Expanded(flex: 2, child: _buildHeaderCell(AppLocalizations.of(context)?.durationHeader ?? 'DURATION', 150)),
                                    _buildHeaderCell(AppLocalizations.of(context)?.taxAmount ?? 'TAX AMOUNT', 120, alignment: Alignment.center),
                                    if (widget.role == 1)
                                      _buildHeaderCell('ACTIONS', 120, alignment: Alignment.center),
                                  ],
                                ),
                              ),
                              // Table Body
                              _filteredEvents.isEmpty && !_isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(child: Text('No events found', style: TextStyle(color: Colors.black54))),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: _filteredEvents.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                                    itemBuilder: (context, index) {
                                      final event = _filteredEvents[index];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        child: Row(
                                          children: [
                                            _buildDataCell('${index + 1}', 60, alignment: Alignment.center),
                                            Expanded(flex: 2, child: _buildDataCell(event['EventName'] ?? 'N/A', 150, isBold: true)),
                                            // Banner Column
                                            _buildDataCell('', 120, child: Align(
                                              alignment: Alignment.center,
                                              child: Container(
                                                width: 80,
                                                height: 46,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Stack(
                                                  alignment: Alignment.bottomCenter,
                                                  children: [
                                                    SizedBox.expand(
                                                      child: event['Image'] != null && event['Image'].toString().isNotEmpty && event['Image'].toString() != 'null' && event['Image'].toString() != 'N/A'
                                                        ? InkWell(
                                                            onTap: () => _showFullScreenImage(Uri.encodeFull('${ApiConfig.baseUrl}/assets/uploads/${event['Image']}')),
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(4),
                                                              child: Image.network(
                                                                Uri.encodeFull('${ApiConfig.baseUrl}/assets/uploads/${event['Image']}'),
                                                                fit: BoxFit.cover,
                                                                errorBuilder: (context, error, stackTrace) => GestureDetector(
                                                                  onTap: () {}, // Consume tap to prevent opening dialog
                                                                  child: Tooltip(
                                                                    message: 'image not found',
                                                                    child: Container(
                                                                      color: Colors.grey[100],
                                                                      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                        : Tooltip(
                                                            message: 'image not found',
                                                            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                                          ),
                                                    ),
                                                    if (widget.role == 1)
                                                      InkWell(
                                                        onTap: () => _showUpdateBannerDialog(event),
                                                        child: Container(
                                                          width: double.infinity,
                                                          color: Colors.black.withOpacity(0.7),
                                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                                          child: const Text('CHANGE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            )),
                                            // Duration Column
                                            Expanded(flex: 2, child: _buildDataCell('', 150, child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildDateInfo(AppLocalizations.of(context)?.fromDate ?? 'From:', event['From_date'], alignment: MainAxisAlignment.start),
                                                const SizedBox(height: 4),
                                                _buildDateInfo(AppLocalizations.of(context)?.toDate ?? 'To:', event['To_date'], alignment: MainAxisAlignment.start),
                                              ],
                                            ))),
                                            // Tax Amount Column
                                            _buildDataCell('', 120, child: Align(
                                              alignment: Alignment.center,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF5D1712).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: const Color(0xFF5D1712).withOpacity(0.2)),
                                                ),
                                                child: Text(
                                                  '₹ ${_formatCurrency(event['TaxAmount'])}',
                                                  style: const TextStyle(color: const Color(0xFF5D1712), fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                              ),
                                            )),
                                            // Actions Column
                                            if (widget.role == 1)
                                              _buildDataCell('', 120, child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  _buildIconButton(Icons.edit_outlined, const Color(0xFF5D1712), () => _showUpdateEventDialog(event), tooltip: 'Edit'),
                                                  const SizedBox(width: 8),
                                                  _buildIconButton(Icons.delete_outline, Colors.red, () => _showDeleteConfirmationDialog(event), tooltip: 'Delete'),
                                                ],
                                              )),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                            ],
                          ),
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(_isLoading ? '' : '${AppLocalizations.of(context)?.totalEvents ?? "Total Events:"} ${_filteredEvents.length}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                          const Row(
                            children: [
                              Icon(Icons.chevron_left, color: Colors.black26),
                              SizedBox(width: 16),
                              CircleAvatar(radius: 14, backgroundColor: const Color(0xFF5D1712), child: Text('1', style: TextStyle(color: Colors.white, fontSize: 12))),
                              SizedBox(width: 16),
                              Icon(Icons.chevron_right, color: Colors.black26),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  void _showDeleteConfirmationDialog(dynamic event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline, color: const Color(0xFFD81B60), size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Move to Trash?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF2D1B18)),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to move\n${event['EventName']} to the trash?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF64748B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/api/delete-event/${event['Id']}'));
                    if (response.statusCode == 200) {
                      Navigator.pop(context);
                      _fetchEvents();
                    } else {
                      Navigator.pop(context);
                      showStatusDialog(context, title: 'Error', message: 'Failed to delete event', type: DialogType.error);
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(dynamic amountStr) {
    if (amountStr == null) return '0';
    final amount = double.tryParse(amountStr.toString());
    if (amount == null) return '0';
    if (amount == amount.toInt()) return amount.toInt().toString();
    return amount.toStringAsFixed(2);
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr == 'N/A') return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      return dateStr.toString();
    }
  }

  Widget _buildDateInfo(String label, dynamic date, {MainAxisAlignment alignment = MainAxisAlignment.center}) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _formatDate(date),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(dynamic event, int index) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF3E0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          event['EventName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D1B18),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.role == 1)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconButton(Icons.edit_outlined, const Color(0xFF5D1712), () => _showUpdateEventDialog(event), tooltip: 'Edit'),
                      const SizedBox(width: 8),
                      _buildIconButton(Icons.delete_outline, Colors.red, () => _showDeleteConfirmationDialog(event), tooltip: 'Delete'),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.durationHeader ?? 'DURATION',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildDateInfo(AppLocalizations.of(context)?.fromDate ?? 'From:', event['From_date'], alignment: MainAxisAlignment.start),
                      const SizedBox(height: 2),
                      _buildDateInfo(AppLocalizations.of(context)?.toDate ?? 'To:', event['To_date'], alignment: MainAxisAlignment.start),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)?.taxAmount ?? 'TAX AMOUNT',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D1712).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF5D1712).withOpacity(0.2)),
                        ),
                        child: Text(
                          '₹ ${_formatCurrency(event['TaxAmount'])}',
                          style: const TextStyle(color: Color(0xFF5D1712), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                // Banner Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.bannerHeader ?? 'BANNER',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          SizedBox.expand(
                            child: event['Image'] != null && event['Image'].toString().isNotEmpty && event['Image'].toString() != 'null' && event['Image'].toString() != 'N/A'
                              ? InkWell(
                                  onTap: () => _showFullScreenImage(Uri.encodeFull('${ApiConfig.baseUrl}/assets/uploads/${event['Image']}')),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      Uri.encodeFull('${ApiConfig.baseUrl}/assets/uploads/${event['Image']}'),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => GestureDetector(
                                        onTap: () {},
                                        child: Tooltip(
                                          message: 'image not found',
                                          child: Container(
                                            color: Colors.grey[100],
                                            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Tooltip(
                                  message: 'image not found',
                                  child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                ),
                          ),
                          if (widget.role == 1)
                            InkWell(
                              onTap: () => _showUpdateBannerDialog(event),
                              child: Container(
                                width: double.infinity,
                                color: Colors.black.withOpacity(0.7),
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: const Text('CHANGE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed, {String? tooltip}) {
    Widget iconWidget = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );

    if (tooltip != null) {
      iconWidget = Tooltip(message: tooltip, child: iconWidget);
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: iconWidget,
    );
  }

  Widget _buildHeaderCell(String label, double width, {Alignment alignment = Alignment.centerLeft}) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: alignment,
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {bool isBlue = false, bool isBold = false, Widget? child, Alignment alignment = Alignment.centerLeft}) {
    return SizedBox(
      width: width,
      child: child ?? Align(
        alignment: alignment,
        child: Text(
          text,
          style: TextStyle(
            color: isBlue ? const Color(0xFF5D1712) : Colors.black87,
            fontWeight: isBlue || isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
