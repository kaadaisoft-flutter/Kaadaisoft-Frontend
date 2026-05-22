import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';

class EventsContent extends StatefulWidget {
  final int? role;
  const EventsContent({super.key, this.role = 3});

  @override
  State<EventsContent> createState() => _EventsContentState();
}

class _EventsContentState extends State<EventsContent> {
  List<dynamic> _events = [];
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

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
    final nameController = TextEditingController(text: event['EventName']?.toString() ?? '');
    final taxController = TextEditingController(text: event['TaxAmount']?.toString() ?? '0.00');
    
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

    DateTime fromDate = parseDate(event['From_date']);
    DateTime toDate = parseDate(event['To_date']);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Update Event Details', 
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EVENT NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter event name',
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('DURATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      bool isSmall = MediaQuery.of(context).size.width < 500;
                      
                      final fromDateWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('From', style: TextStyle(fontSize: 11, color: Colors.black45)),
                          const SizedBox(height: 4),
                          _buildDatePicker(context, fromDate, (date) => setDialogState(() => fromDate = date)),
                        ],
                      );
                      
                      final toDateWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('To', style: TextStyle(fontSize: 11, color: Colors.black45)),
                          const SizedBox(height: 4),
                          _buildDatePicker(context, toDate, (date) => setDialogState(() => toDate = date)),
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
                  const Text('TAX AMOUNT (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter tax amount',
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
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
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isSaving 
                        ? const SizedBox(width: 24, height: 24, child: LoadingSpinner())
                        : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
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
                      Text(event['EventName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                      if (result != null) setDialogState(() => selectedFile = result.files.first);
                    } catch (e) {
                      print("File picker error: $e");
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedFile != null ? Colors.blue.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selectedFile != null ? Colors.blue : Colors.grey[300]!, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                          size: 20,
                          color: selectedFile != null ? Colors.blue : Colors.grey[500],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedFile?.name ?? 'Click to choose an image file...',
                            style: TextStyle(
                              color: selectedFile != null ? Colors.blue[800] : Colors.grey[600],
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
                    Icon(Icons.info_outline, size: 14, color: Colors.blue),
                    SizedBox(width: 4),
                    Expanded(child: Text('Choose a high-quality JPG or PNG.', style: TextStyle(fontSize: 12, color: Colors.blue))),
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
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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


  Widget _buildDatePicker(BuildContext context, DateTime? selectedDate, Function(DateTime) onDateSelected) {

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
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
    final taxController = TextEditingController(text: '0.00');
    DateTime? fromDate;
    DateTime? toDate;
    PlatformFile? selectedBanner;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Add New Event', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                  const Text('EVENT NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Event_2026',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Note: Year should be at the end of the event name (e.g. Event_2026).',
                          style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('EVENT BANNER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      try {
                        FilePickerResult? result = await FilePicker.pickFiles(
                          type: FileType.image,
                          withData: true,
                        );
                        if (result != null) {
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
                            child: const Text('Choose File', style: TextStyle(fontSize: 13, color: Colors.black87)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedBanner?.name ?? 'No file chosen',
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
                      const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Note: Max file size 2MB (JPG, PNG).',
                          style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('DURATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      bool isSmall = MediaQuery.of(context).size.width < 500;
                      
                      final fromDateWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('From', style: TextStyle(fontSize: 11, color: Colors.black45)),
                          const SizedBox(height: 4),
                          _buildDatePicker(context, fromDate, (date) => setDialogState(() => fromDate = date)),
                        ],
                      );
                      
                      final toDateWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('To', style: TextStyle(fontSize: 11, color: Colors.black45)),
                          const SizedBox(height: 4),
                          _buildDatePicker(context, toDate, (date) => setDialogState(() => toDate = date)),
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

                  const Text('TAX AMOUNT (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
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
                        if (fromDate == null || toDate == null) {
                          showStatusDialog(context, title: 'Error', message: 'Please select event duration', type: DialogType.error);
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
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isSaving 
                        ? const SizedBox(width: 20, height: 20, child: LoadingSpinner())
                        : const Text('Create Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  const Text('Events Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF172030))),
                  const SizedBox(height: 16),
                  if (widget.role == 1)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddEventDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add New Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF172030),
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
                  const Text('Events Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF172030))),
                  if (widget.role == 1)
                    ElevatedButton.icon(
                      onPressed: _showAddEventDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add New Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF172030),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                ],
              ),
            
            const SizedBox(height: 12),
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
                  // Main Scrollable Area (Header + Body)
                  Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: widget.role == 1 ? 960 : 810,
                        child: Column(
                          children: [
                            // Table Header
                            Container(
                              color: const Color(0xFF172030),
                              height: 48,
                              child: Row(
                                children: [
                                  _buildHeaderCell('S.NO', 60),
                                  _buildHeaderCell('EVENT NAME', 250),
                                  _buildHeaderCell('BANNER', 150),
                                  _buildHeaderCell('DURATION', 200),
                                  _buildHeaderCell('TAX AMOUNT', 150, hasDivider: widget.role == 1),
                                  if (widget.role == 1)
                                    _buildHeaderCell('ACTIONS', 150, hasDivider: false),
                                ],
                              ),
                            ),
                            // Table Body
                            _events.isEmpty && !_isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(child: Text('No events found', style: TextStyle(color: Colors.black54))),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: _events.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                                  itemBuilder: (context, index) {
                                    final event = _events[index];
                                    return Container(
                                      height: 60,
                                      color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
                                      child: Row(
                                        children: [
                                          _buildDataCell('${index + 1}', 60),
                                          _buildDataCell(event['EventName'] ?? 'N/A', 250, isBold: true),
                                          // Banner Column
                                          _buildDataCell('', 150, child: Center(
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
                                                    child: event['Image'] != null 
                                                      ? InkWell(
                                                          onTap: () => _showFullScreenImage('${ApiConfig.baseUrl}/assets/uploads/${event['Image']}'),
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(4),
                                                            child: Image.network(
                                                              '${ApiConfig.baseUrl}/assets/uploads/${event['Image']}',
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                                            ),
                                                          ),
                                                        )
                                                      : Icon(Icons.image, color: Colors.grey[400]),
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
                                          _buildDataCell('', 200, child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _buildDateInfo('From:', event['From_date']),
                                              const SizedBox(height: 4),
                                              _buildDateInfo('To:', event['To_date']),
                                            ],
                                          )),
                                          // Tax Amount Column
                                          _buildDataCell('', 150, hasDivider: widget.role == 1, child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                              ),
                                              child: Text(
                                                '₹ ${event['TaxAmount'] ?? '0'}',
                                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                          )),
                                          // Actions Column
                                          if (widget.role == 1)
                                            _buildDataCell('', 150, hasDivider: false, child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                _buildIconButton(Icons.edit_outlined, Colors.blue, () => _showUpdateEventDialog(event)),
                                                const SizedBox(width: 8),
                                                _buildIconButton(Icons.delete_outline, Colors.red, () => _showDeleteConfirmationDialog(event)),
                                              ],
                                            )),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_isLoading ? '' : 'Total Events: ${_events.length}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                        const Row(
                          children: [
                            Icon(Icons.chevron_left, color: Colors.black26),
                            SizedBox(width: 16),
                            CircleAvatar(radius: 14, backgroundColor: Color(0xFF3B82F6), child: Text('1', style: TextStyle(color: Colors.white, fontSize: 12))),
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
              child: const Icon(Icons.delete_outline, color: Color(0xFFD81B60), size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Move to Trash?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF172030)),
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

  String _formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr == 'N/A') return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      return dateStr.toString();
    }
  }

  Widget _buildDateInfo(String label, dynamic date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
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
