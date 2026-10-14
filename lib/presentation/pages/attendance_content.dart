import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/qr_scanner_dialog.dart';

class AttendanceContent extends StatefulWidget {
  final int? userId;
  final int? role;

  const AttendanceContent({
    super.key,
    this.userId,
    this.role = 3,
  });

  @override
  State<AttendanceContent> createState() => _AttendanceContentState();
}

class _AttendanceContentState extends State<AttendanceContent> {
  bool _isLoading = true;
  bool _isLoadingAttendees = false;
  List<dynamic> _events = [];
  dynamic _selectedEvent;
  List<dynamic> _attendees = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/events'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _events = data;
            if (_events.isNotEmpty) {
              _selectedEvent = _events.first;
            }
            _isLoading = false;
          });
          if (_selectedEvent != null) {
            _fetchAttendees(_selectedEvent['Id']);
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAttendees(dynamic eventId) async {
    if (eventId == null) return;
    setState(() => _isLoadingAttendees = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.attendanceEvent(eventId)));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _attendees = data['records'] as List<dynamic>? ?? [];
            _isLoadingAttendees = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingAttendees = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAttendees = false);
    }
  }

  List<dynamic> get _filteredAttendees {
    if (_searchQuery.trim().isEmpty) return _attendees;
    final q = _searchQuery.trim().toLowerCase();
    return _attendees.where((att) {
      final name = (att['member_name'] ?? '').toString().toLowerCase();
      final fmid = (att['family_id'] ?? '').toString().toLowerCase();
      final phone = (att['member_phone'] ?? '').toString().toLowerCase();
      final village = (att['village'] ?? '').toString().toLowerCase();
      return name.contains(q) || fmid.contains(q) || phone.contains(q) || village.contains(q);
    }).toList();
  }

  Future<void> _startQrScanner() async {
    if (kIsWeb) {
      showStatusDialog(
        context,
        title: 'Mobile App Feature',
        message: 'Camera QR Code Scanning is only available in the Mobile APK. Please use Manual ID Entry on the website.',
        type: DialogType.info,
      );
      return;
    }

    if (_selectedEvent == null) {
      showStatusDialog(
        context,
        title: 'Select Event',
        message: 'Please select an event before scanning attendance.',
        type: DialogType.warning,
      );
      return;
    }

    final scannedIdentifier = await QrScannerDialog.show(context);
    if (scannedIdentifier != null && scannedIdentifier.isNotEmpty && mounted) {
      await _processAttendanceScan(scannedIdentifier);
    }
  }

  Future<void> _showManualCheckInDialog() async {
    if (_selectedEvent == null) {
      showStatusDialog(
        context,
        title: 'Select Event',
        message: 'Please select an event before recording attendance.',
        type: DialogType.warning,
      );
      return;
    }

    final textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Color(0xFFC49A3C)),
            SizedBox(width: 8),
            Text('Manual Attendance Check-In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event: ${_selectedEvent['EventName']}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D1B18)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Member ID / Family ID / Phone',
                hintText: 'e.g., NMK00023 or 9791265880',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D1B18),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final id = textController.text.trim();
              if (id.isNotEmpty) {
                Navigator.pop(ctx);
                _processAttendanceScan(id);
              }
            },
            child: const Text('Submit Check-In'),
          ),
        ],
      ),
    );
  }

  Future<void> _processAttendanceScan(String identifier) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFC49A3C)),
                SizedBox(height: 16),
                Text('Verifying member & marking attendance...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.attendanceScan),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'event_id': _selectedEvent['Id'],
          'scanned_identifier': identifier,
          'scanned_by_id': widget.userId,
        }),
      );

      if (mounted) Navigator.pop(context); // Dismiss loading

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final status = data['status'];
        final member = data['member'] ?? {};
        final attendance = data['attendance'] ?? {};
        final isAlreadyMarked = status == 'already_marked';

        if (mounted) {
          _fetchAttendees(_selectedEvent['Id']);
          _showScanResultPopup(
            member: member,
            attendance: attendance,
            isAlreadyMarked: isAlreadyMarked,
            message: data['message'] ?? '',
          );
        }
      } else {
        String err = 'Member not found or check-in failed';
        try {
          final errJson = jsonDecode(res.body);
          if (errJson['detail'] != null) err = errJson['detail'];
        } catch (_) {}

        if (mounted) {
          showStatusDialog(
            context,
            title: 'Attendance Error',
            message: err,
            type: DialogType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showStatusDialog(
          context,
          title: 'Connection Error',
          message: 'Unable to reach server. Please check your connection.',
          type: DialogType.error,
        );
      }
    }
  }

  void _showScanResultPopup({
    required Map<String, dynamic> member,
    required Map<String, dynamic> attendance,
    required bool isAlreadyMarked,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Badge & Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isAlreadyMarked ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAlreadyMarked ? Colors.orange : Colors.green,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isAlreadyMarked ? Icons.history_toggle_off : Icons.check_circle,
                  color: isAlreadyMarked ? Colors.orange.shade800 : Colors.green.shade700,
                  size: 44,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isAlreadyMarked ? 'ALREADY CHECKED IN' : 'ATTENDANCE RECORDED',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isAlreadyMarked ? Colors.orange.shade900 : Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isAlreadyMarked ? Colors.orange.shade900 : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Member Card Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Member Photo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 70,
                        height: 85,
                        color: Colors.grey.shade200,
                        child: (member['Memberimage'] != null && member['Memberimage'].toString().isNotEmpty)
                            ? Image.network(
                                '${ApiConfig.baseUrl}/assets/uploads/${member['Memberimage']}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: Colors.grey),
                              )
                            : const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['Name'] ?? 'Unknown Member',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D1B18).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Family ID: ${member['Familymembershipid'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D1B18)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '📱 ${member['Phonenumber'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          Text(
                            '📍 ${member['Village'] ?? ''}${member['Village'] != null && member['Taluk'] != null ? ', ' : ''}${member['Taluk'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.done),
                      label: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC49A3C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (kIsWeb) {
                          _showManualCheckInDialog();
                        } else {
                          _startQrScanner();
                        }
                      },
                      icon: Icon(kIsWeb ? Icons.keyboard : Icons.qr_code_scanner),
                      label: Text(kIsWeb ? 'Next Entry' : 'Scan Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAttendance(dynamic attendanceId) async {
    if (attendanceId == null) {
      showStatusDialog(
        context,
        title: 'Error',
        message: 'Could not find attendance record ID to delete.',
        type: DialogType.error,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Check-In?'),
        content: const Text('Are you sure you want to remove this attendance record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final queryParams = (widget.userId != null) ? '?user_id=${widget.userId}' : '';
        final res = await http.delete(
          Uri.parse('${ApiConfig.deleteAttendance(attendanceId)}$queryParams'),
        );
        if (res.statusCode == 200) {
          if (mounted) {
            final evId = _selectedEvent?['Id'] ?? _selectedEvent?['id'];
            if (evId != null) _fetchAttendees(evId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attendance record removed successfully')),
            );
          }
        } else {
          String errMsg = 'Failed to remove attendance record';
          try {
            final data = jsonDecode(res.body);
            if (data['detail'] != null) errMsg = data['detail'].toString();
          } catch (_) {}
          if (mounted) {
            showStatusDialog(
              context,
              title: 'Error',
              message: errMsg,
              type: DialogType.error,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showStatusDialog(
            context,
            title: 'Connection Error',
            message: 'Unable to connect to server.',
            type: DialogType.error,
          );
        }
      }
    }
  }

  void _showManageScannersDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _ScannerPermissionDialog(adminId: widget.userId ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingSpinner(message: 'Loading attendance module...');
    }

    final isMobile = MediaQuery.of(context).size.width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kIsWeb ? 'Event Attendance' : 'Event Attendance Scanner',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D1B18),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kIsWeb
                        ? 'View attendance records, manage scanner access, and record manual check-ins'
                        : 'Scan member ID card QR codes to record event presence',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (widget.role == 1)
                ElevatedButton.icon(
                  onPressed: _showManageScannersDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D1B18),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.admin_panel_settings, size: 18),
                  label: const Text('Manage Scanner Access'),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Event Selection Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Event for Attendance',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
                    ),
                    if (_selectedEvent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.how_to_reg, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '${_attendees.length} Members Checked In',
                              style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_events.isEmpty)
                  const Text('No events found in system. Please create an event first.', style: TextStyle(color: Colors.red))
                else
                  DropdownButtonFormField<int>(
                    value: _selectedEvent?['Id'],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                    items: _events.map<DropdownMenuItem<int>>((ev) {
                      final yr = (ev['year'] ?? ev['Year'])?.toString();
                      final yrDisplay = (yr != null && yr.isNotEmpty) ? ' ($yr)' : '';
                      return DropdownMenuItem<int>(
                        value: ev['Id'],
                        child: Text(
                          '${ev['EventName'] ?? 'Event'}$yrDisplay - Fee: ₹${ev['TaxAmount'] ?? '0'}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D1B18)),
                        ),
                      );
                    }).toList(),
                    onChanged: (newId) {
                      final selected = _events.firstWhere((e) => e['Id'] == newId, orElse: () => null);
                      if (selected != null) {
                        setState(() => _selectedEvent = selected);
                        _fetchAttendees(selected['Id']);
                      }
                    },
                  ),
                const SizedBox(height: 16),

                // Primary Scan Actions
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!kIsWeb)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC49A3C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _startQrScanner,
                        icon: const Icon(Icons.qr_code_scanner, size: 22),
                        label: const Text(
                          'SCAN MEMBER QR CODE',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kIsWeb ? const Color(0xFFC49A3C) : Colors.white,
                        foregroundColor: kIsWeb ? Colors.white : const Color(0xFF2D1B18),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: kIsWeb ? const Color(0xFFC49A3C) : const Color(0xFF2D1B18)),
                        elevation: kIsWeb ? 2 : 0,
                      ),
                      onPressed: _showManualCheckInDialog,
                      icon: const Icon(Icons.keyboard, size: 20),
                      label: const Text(
                        'Manual ID Entry',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (kIsWeb)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_android, size: 18, color: Color(0xFFC49A3C)),
                            SizedBox(width: 8),
                            Text(
                              'Camera QR Scanner is enabled exclusively on the Mobile APK',
                              style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Attendees List Header & Search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Log (${_filteredAttendees.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  if (_selectedEvent != null) _fetchAttendees(_selectedEvent['Id']);
                },
                tooltip: 'Refresh list',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search checked-in attendees by name, ID, phone, village...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),

          const SizedBox(height: 16),

          // Attendees Table / Cards
          if (_isLoadingAttendees)
            const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Color(0xFFC49A3C))))
          else if (_filteredAttendees.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(Icons.how_to_reg_outlined, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No attendance records yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    kIsWeb
                        ? 'Click "Manual ID Entry" above to record attendance, or use the mobile app (APK) to scan QR codes.'
                        : 'Click "SCAN MEMBER QR CODE" above to begin recording attendance.',
                    style: const TextStyle(fontSize: 13, color: Colors.black38),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredAttendees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final att = _filteredAttendees[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // S.No
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),

                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (att['Memberimage'] != null && att['Memberimage'].toString().isNotEmpty)
                            ? NetworkImage('${ApiConfig.baseUrl}/assets/uploads/${att['Memberimage']}')
                            : null,
                        child: (att['Memberimage'] == null || att['Memberimage'].toString().isEmpty)
                            ? const Icon(Icons.person, color: Colors.grey, size: 22)
                            : null,
                      ),
                      const SizedBox(width: 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  att['member_name'] ?? 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D1B18)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.orange.shade300),
                                  ),
                                  child: Text(
                                    att['family_id'] ?? att['member_id'] ?? '',
                                    style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📱 ${att['member_phone'] ?? 'N/A'} • 📍 ${att['village'] ?? att['taluk'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),

                      // Scanned At & By
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              att['scanned_at_formatted'] ?? 'Recorded',
                              style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'By: ${att['scanned_by_name'] ?? 'System'}',
                            style: const TextStyle(fontSize: 11, color: Colors.black38),
                          ),
                        ],
                      ),

                      if (widget.role == 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'Remove attendance',
                          onPressed: () {
                            final attId = att['Id'] ?? att['id'];
                            _deleteAttendance(attId);
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// Dialog for Admins to view and toggle scanner permissions
class _ScannerPermissionDialog extends StatefulWidget {
  final int adminId;

  const _ScannerPermissionDialog({required this.adminId});

  @override
  State<_ScannerPermissionDialog> createState() => _ScannerPermissionDialogState();
}

class _ScannerPermissionDialogState extends State<_ScannerPermissionDialog> {
  bool _isLoading = true;
  List<dynamic> _users = [];
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  int _selectedFilter = 0; // 0: All, 1: Authorized, 2: Coordinators, 3: Members

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.attendanceScanners));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['scanners'] as List<dynamic>? ?? [];
        if (mounted) setState(() { _users = data; _isLoading = false; });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePermission(int targetUserId, bool canScan) async {
    // Optimistically update local state for instant feedback
    setState(() {
      for (var u in _users) {
        if (u['Id'] == targetUserId) {
          u['can_scan_attendance'] = canScan;
          break;
        }
      }
    });

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.toggleScannerPermission),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'admin_id': widget.adminId,
          'target_user_id': targetUserId,
          'can_scan': canScan,
        }),
      );

      if (res.statusCode != 200) {
        // Revert on failure
        setState(() {
          for (var u in _users) {
            if (u['Id'] == targetUserId) {
              u['can_scan_attendance'] = !canScan;
              break;
            }
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update permission'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (_) {
      // Revert on exception
      setState(() {
        for (var u in _users) {
          if (u['Id'] == targetUserId) {
            u['can_scan_attendance'] = !canScan;
            break;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only display approved members (Approvedstatus == 'Verified') and Admins/Coordinators
    final validUsers = _users.where((u) {
      final status = (u['Approvedstatus'] ?? '').toString();
      final role = u['Role'];
      return status == 'Verified' || role == 1 || role == 2;
    }).toList();

    final authorizedCount = validUsers.where((u) {
      final isAdmin = u['Role'] == 1;
      return isAdmin || u['can_scan_attendance'] == true || u['can_scan_attendance']?.toString() == '1';
    }).length;
    final coordCount = validUsers.where((u) => u['Role'] == 2).length;
    final memberCount = validUsers.where((u) => u['Role'] == 3).length;

    final filtered = validUsers.where((u) {
      // Role filter
      if (_selectedFilter == 1) {
        final canScan = u['Role'] == 1 || u['can_scan_attendance'] == true || u['can_scan_attendance']?.toString() == '1';
        if (!canScan) return false;
      } else if (_selectedFilter == 2) {
        if (u['Role'] != 2) return false;
      } else if (_selectedFilter == 3) {
        if (u['Role'] != 3) return false;
      }

      // Search filter
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (u['Name'] ?? '').toString().toLowerCase();
      final fid = (u['Familymembershipid'] ?? '').toString().toLowerCase();
      final phone = (u['Phonenumber'] ?? '').toString().toLowerCase();
      final village = (u['Village'] ?? '').toString().toLowerCase();
      return name.contains(q) || fid.contains(q) || phone.contains(q) || village.contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        height: 700,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield, color: Color(0xFFC49A3C), size: 24),
                    const SizedBox(width: 8),
                    const Text('Attendance Scanner Permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC49A3C).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$authorizedCount Active Scanners',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8C6D23)),
                      ),
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Select coordinators or approved members who are authorized to access the Attendance Scanner module.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, phone, Family ID, or village...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text('All (${validUsers.length})'),
                  selected: _selectedFilter == 0,
                  onSelected: (val) => setState(() => _selectedFilter = 0),
                  selectedColor: const Color(0xFFC49A3C).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _selectedFilter == 0 ? const Color(0xFF8C6D23) : Colors.black87,
                    fontWeight: _selectedFilter == 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                ChoiceChip(
                  label: Text('Authorized ($authorizedCount)'),
                  selected: _selectedFilter == 1,
                  onSelected: (val) => setState(() => _selectedFilter = 1),
                  selectedColor: Colors.green.shade100,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 1 ? Colors.green.shade900 : Colors.black87,
                    fontWeight: _selectedFilter == 1 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                ChoiceChip(
                  label: Text('Coordinators ($coordCount)'),
                  selected: _selectedFilter == 2,
                  onSelected: (val) => setState(() => _selectedFilter = 2),
                  selectedColor: Colors.orange.shade100,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 2 ? Colors.orange.shade900 : Colors.black87,
                    fontWeight: _selectedFilter == 2 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                ChoiceChip(
                  label: Text('Approved Members ($memberCount)'),
                  selected: _selectedFilter == 3,
                  onSelected: (val) => setState(() => _selectedFilter = 3),
                  selectedColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 3 ? Colors.blue.shade900 : Colors.black87,
                    fontWeight: _selectedFilter == 3 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFC49A3C)))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              const Text('No members found matching the criteria', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                          child: RawScrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            thickness: 6,
                            radius: const Radius.circular(8),
                            thumbColor: const Color(0xFFC49A3C).withValues(alpha: 0.5),
                            padding: const EdgeInsets.only(right: 2),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(right: 14),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final user = filtered[index];
                                final isAdmin = user['Role'] == 1;
                                final isCoord = user['Role'] == 2;
                                final canScan = isAdmin || user['can_scan_attendance'] == true || user['can_scan_attendance']?.toString() == '1';

                                final firstLetter = (user['Name'] != null && user['Name'].toString().trim().isNotEmpty)
                                    ? user['Name'].toString().trim()[0].toUpperCase()
                                    : 'M';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  leading: CircleAvatar(
                                    backgroundColor: isAdmin
                                        ? Colors.red.shade100
                                        : (isCoord ? Colors.orange.shade100 : Colors.blue.shade100),
                                    child: Text(
                                      firstLetter,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isAdmin
                                            ? Colors.red.shade900
                                            : (isCoord ? Colors.orange.shade900 : Colors.blue.shade900),
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user['Name'] ?? 'N/A',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (isAdmin)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.red.shade300),
                                          ),
                                          child: Text('Admin', style: TextStyle(color: Colors.red.shade900, fontSize: 10, fontWeight: FontWeight.bold)),
                                        )
                                      else if (isCoord)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.orange.shade300),
                                          ),
                                          child: Text('Coordinator', style: TextStyle(color: Colors.orange.shade900, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${user['Familymembershipid'] ?? ''}'
                                    '${(user['Phonenumber'] != null && user['Phonenumber'].toString().isNotEmpty) ? ' • 📱 ${user['Phonenumber']}' : ''}'
                                    '${(user['Village'] != null && user['Village'].toString().isNotEmpty) ? ' • 📍 ${user['Village']}' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: isAdmin
                                      ? const Padding(
                                          padding: EdgeInsets.only(right: 6),
                                          child: Tooltip(
                                            message: 'Admins always have scanning privileges',
                                            child: Icon(Icons.check_circle, color: Colors.green),
                                          ),
                                        )
                                      : Switch(
                                          value: canScan,
                                          activeThumbColor: const Color(0xFFC49A3C),
                                          activeTrackColor: const Color(0xFFC49A3C).withValues(alpha: 0.4),
                                          onChanged: (val) => _togglePermission(user['Id'], val),
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
