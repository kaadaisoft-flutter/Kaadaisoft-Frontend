import 'dart:convert';
import 'dart:async';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'my_details_content.dart';
import 'members_content.dart';
import 'events_content.dart';
import 'coordinators_content.dart';
import 'login_page.dart';
import 'received_applications_content.dart';
import 'payments_content.dart';
import 'reports_content.dart';
import 'update_requests_content.dart';
import 'id_card_benefits_content.dart';
import 'member_details_content.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/payment_form.dart';
import '../widgets/receipt_dialog.dart';
import '../../utils/api_config.dart';
class AdminDashboard extends StatefulWidget {
  final bool showLoginSuccess;
  final String userName;
  final int userRole;
  final dynamic userId;
  final String? initialViewMemberId;
  const AdminDashboard({
    super.key, 
    this.showLoginSuccess = false,
    this.userName = 'Guest',
    this.userRole = 3, // Default to member
    this.userId,
    this.initialViewMemberId,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  // Current active menu item
  String _activeItem = 'Dashboard';
  final List<String> _navigationHistory = [];
  AnimationController? _blinkController;

  int _membersCount = 0;
  int _coordinatorsCount = 3;
  int _approvalsCount = 0;
  int _notificationsCount = 0;
  bool _isLoadingStats = true;
  bool _isLoadingPayments = true;
  bool _shouldShowAssignCoordinator = false;
  bool _showMobileSearchBar = false;
  String _paymentFilter = 'UNPAID';
  final ScrollController _dashboardScrollController = ScrollController();
  final TextEditingController _globalSearchController = TextEditingController();
  Timer? _statsTimer;
  
  Map<String, dynamic>? _myCoordinator;
  bool _isLoadingCoordinator = true;

  void _navigateTo(String item) {
    setState(() {
      if (_activeItem != '') {
        _navigationHistory.add(_activeItem);
      }
      _activeItem = item;
    });
    _saveActiveItem(item);
  }

  Future<bool> _handleBackNavigation() async {
    if (_navigationHistory.isNotEmpty) {
      setState(() {
        _activeItem = _navigationHistory.removeLast();
      });
      _saveActiveItem(_activeItem);
      return false; // Prevent system pop
    } else if (_activeItem != 'Dashboard') {
      setState(() {
        _activeItem = 'Dashboard';
      });
      _saveActiveItem('Dashboard');
      return false; // Prevent system pop
    }
    return true; // Allow system pop (exit app)
  }


  Future<void> _saveActiveItem(String item) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activePage', item);
  }

  Future<void> _loadActiveItem() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getString('activePage');
    if (savedPage != null && mounted) {
      // Check if the saved page is allowed for this role
      bool isAllowed = _menuItems.any((item) => item['title'] == savedPage);
      if (isAllowed) {
        setState(() {
          _activeItem = savedPage;
        });
      }
    }
  }

  List<dynamic> _pendingPayments = [];

  @override
  void dispose() {
    _globalSearchController.dispose();
    _statsTimer?.cancel();
    _dashboardScrollController.dispose();
    _blinkController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _globalSearchController.addListener(() {
      setState(() {});
    });
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _fetchStats();
    _fetchPaymentDetails();
    _fetchMyCoordinator();
    _loadActiveItem();
    
    // Set up polling for stats
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _fetchStats();
      }
    });
    
    if (widget.initialViewMemberId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showViewMemberDialog(widget.initialViewMemberId!);
      });
    }
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/dashboard-stats?user_id=${widget.userId}&role=${widget.userRole}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _membersCount = data['data']['members'];
            _coordinatorsCount = data['data']['coordinators'];
            _approvalsCount = data['data']['approvals'];
            _isLoadingStats = false;
          });
        }
      }

      // Fetch actual update requests count to ensure accuracy
      final updateReqResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/update-requests?user_id=${widget.userId}&role=${widget.userRole}'));
      if (updateReqResponse.statusCode == 200) {
        final updateData = jsonDecode(updateReqResponse.body);
        if (mounted && updateData['status'] == 'success') {
          setState(() {
            _notificationsCount = (updateData['data'] as List).length;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoadingStats = false; });
      }
    }
  }

  Future<void> _fetchMyCoordinator() async {
    if (widget.userRole != 3) {
      if (mounted) setState(() => _isLoadingCoordinator = false);
      return;
    }
    
    try {
      final userResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/user-details/${widget.userId}'));
      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body)['data'];
        final fid = userData['Familymembershipid'];

        if (fid != null && fid.toString().isNotEmpty) {
          final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/member-coordinator-by-fid/$fid'));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (mounted) {
              setState(() {
                _myCoordinator = data['coordinator'];
                _isLoadingCoordinator = false;
              });
            }
          } else {
             if (mounted) setState(() => _isLoadingCoordinator = false);
          }
        } else {
           if (mounted) setState(() => _isLoadingCoordinator = false);
        }
      } else {
         if (mounted) setState(() => _isLoadingCoordinator = false);
      }
    } catch (e) {
      print('Error fetching coordinator details: $e');
      if (mounted) setState(() => _isLoadingCoordinator = false);
    }
  }

  Future<void> _fetchPaymentDetails() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/pending-payments/${widget.userId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            final List<dynamic> paymentsList = List<dynamic>.from(data['data']);
            paymentsList.sort((a, b) => (b['Id'] ?? 0).compareTo(a['Id'] ?? 0));
            _pendingPayments = paymentsList;
            _isLoadingPayments = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingPayments = false);
      }
    } catch (e) {
      print('Error fetching payment details: $e');
      if (mounted) setState(() => _isLoadingPayments = false);
    }
  }

  void _showPaymentDialog(int eventId, {int? year}) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: LoadingSpinner(message: 'Loading Payment Form...')),
    );

    try {
      final userResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/user-details/${widget.userId}'));
      
      if (mounted) Navigator.pop(context); // Close loading

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body)['data'];
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: PaymentForm(
                  memberData: userData,
                  initialYear: year,
                  initialEventId: eventId,
                  onPaymentSuccess: () {
                    _fetchPaymentDetails();
                    _fetchStats();
                  },
                ),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          showStatusDialog(context, title: 'Error', message: 'Failed to load member data', type: DialogType.error);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);
    }
  }

  void _showReceiptDialog(int eventId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: LoadingSpinner(message: 'Loading Receipt...')),
    );

    try {
      final userResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/user-details/${widget.userId}'));
      if (userResponse.statusCode != 200) throw Exception('Failed to load user details');
      final userData = jsonDecode(userResponse.body)['data'];
      final fid = userData['Familymembershipid'];

      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/member-coordinator-by-fid/$fid'));
      
      if (mounted) Navigator.pop(context); // Close loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final receipts = data['receipts'] as List;
        
        final eventReceipt = receipts.firstWhere(
          (r) => (r['Eventid'] ?? r['eventid']).toString() == eventId.toString(),
          orElse: () => null,
        );

        if (eventReceipt != null && mounted) {
          showDialog(
            context: context,
            builder: (context) => ReceiptDialog(
              receiptData: eventReceipt,
              memberData: data['member'],
            ),
          );
        } else if (mounted) {
          showStatusDialog(context, title: 'Error', message: 'Receipt not found', type: DialogType.error);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);
    }
  }

  void _showViewMemberDialog(String memberId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 1100,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Expanded(
                child: MemberDetailsContent(
                  numericId: memberId,
                  familyId: '', // Fetched internally
                  onBack: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _menuItems {
    final allItems = [
      {'title': 'Dashboard', 'icon': Icons.bar_chart, 'color': const Color(0xFF0EA5E9)},
      {'title': 'ID Card Benefits', 'icon': Icons.card_membership, 'color': const Color(0xFFC49A3C)},
      {'title': 'My Details', 'icon': Icons.person_outline, 'color': const Color(0xFF10B981)},
      {'title': 'Coordinators', 'icon': Icons.shopping_cart_checkout, 'color': const Color(0xFFF59E0B)}, 
      {'title': 'Members', 'icon': Icons.group_outlined, 'color': const Color(0xFF8B5CF6)},
      {'title': 'Events', 'icon': Icons.list_alt, 'color': const Color(0xFFEC4899)},
      {'title': 'Payments', 'icon': Icons.credit_card, 'color': const Color(0xFF14B8A6)},
      {'title': 'Reports', 'icon': Icons.file_copy_outlined, 'color': const Color(0xFFF97316)},
      {'title': 'Update Requests', 'icon': Icons.person_add_alt_1, 'color': const Color(0xFF06B6D4)},
      {'title': 'Logout', 'icon': Icons.power_settings_new, 'color': Colors.red},
    ];

    // Role 3 (Member) view
    if (widget.userRole == 3) {
      return allItems.where((item) => 
        item['title'] == 'Dashboard' || 
        item['title'] == 'My Details' || 
        item['title'] == 'Events' || 
        item['title'] == 'Payments' || 
        item['title'] == 'ID Card Benefits' ||
        item['title'] == 'Logout'
      ).toList();
    }

    // Role 2 (Coordinator) view
    if (widget.userRole == 2) {
      return allItems.where((item) => 
        item['title'] != 'Coordinators' && 
        item['title'] != 'Reports'
      ).toList();
    }

    return allItems;
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool currentVisible = false;
    bool newVisible = false;
    bool confirmVisible = false;
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: Container(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Password', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: currentPasswordController,
                    obscureText: !currentVisible,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(currentVisible ? Icons.visibility : Icons.visibility_off, size: 20),
                        onPressed: () => setDialogState(() => currentVisible = !currentVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('New Password', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: newPasswordController,
                    obscureText: !newVisible,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(newVisible ? Icons.visibility : Icons.visibility_off, size: 20),
                        onPressed: () => setDialogState(() => newVisible = !newVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !confirmVisible,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(confirmVisible ? Icons.visibility : Icons.visibility_off, size: 20),
                        onPressed: () => setDialogState(() => confirmVisible = !confirmVisible),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isChanging ? null : () async {
                        if (newPasswordController.text != confirmPasswordController.text) {
                          showStatusDialog(context, title: 'Error', message: 'Passwords do not match', type: DialogType.error);
                          return;
                        }
                        if (newPasswordController.text.isEmpty) {
                           showStatusDialog(context, title: 'Error', message: 'Please enter a new password', type: DialogType.error);
                           return;
                        }
  
                        setDialogState(() => isChanging = true);
                        try {
                          final response = await http.post(
                            Uri.parse('${ApiConfig.baseUrl}/api/change-password'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'user_id': widget.userId,
                              'current_password': currentPasswordController.text,
                              'new_password': newPasswordController.text,
                            }),
                          );
  
                          if (response.statusCode == 200) {
                            if (mounted) Navigator.pop(context);
                            showStatusDialog(context, title: 'Success', message: 'Password changed successfully', type: DialogType.success);
                          } else {
                            final error = jsonDecode(response.body)['detail'] ?? 'Failed to change password';
                            showStatusDialog(context, title: 'Error', message: error, type: DialogType.error);
                          }
                        } catch (e) {
                          showStatusDialog(context, title: 'Error', message: 'Connection error', type: DialogType.error);
                        } finally {
                          setDialogState(() => isChanging = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D1712),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: isChanging 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Change Password'),
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
    if (_blinkController == null) {
      _blinkController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )..repeat(reverse: true);
    }

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White icons
        statusBarBrightness: Brightness.dark,      // For iOS
      ),
      child: WillPopScope(
        onWillPop: _handleBackNavigation,
        child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        drawer: isDesktop ? null : Drawer(
          child: _buildSidebar(),
        ),
        body: Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 280,
                child: _buildSidebar(),
              ),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildMainContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final contentPadding = EdgeInsets.all(isMobile ? 12.0 : 24.0);

    if (_activeItem == 'My Details') {
      return MyDetailsContent(
        key: ValueKey('My Details'),
        userId: widget.userId, 
        userRole: widget.userRole
      );
    }

    if (_activeItem == 'Events') {
      return Padding(
        padding: contentPadding,
        child: EventsContent(
          key: ValueKey('Events'),
          role: widget.userRole,
          globalSearchQuery: _globalSearchController.text,
        ),
      );
    }

    if (_activeItem == 'Members') {
      return Padding(
        padding: contentPadding,
        child: MembersContent(
          key: ValueKey('Members'),
          userId: widget.userId, 
          role: widget.userRole,
          globalSearchQuery: _globalSearchController.text,
          onAssignPressed: () {
            _navigateTo('Coordinators');
          },
        ),
      );
    }

    if (_activeItem == 'Coordinators') {
      final showAssign = _shouldShowAssignCoordinator;
      _shouldShowAssignCoordinator = false;
      return Padding(
        padding: contentPadding,
        child: CoordinatorsContent(
          key: ValueKey('Coordinators'),
          initialShowAssign: showAssign,
          globalSearchQuery: _globalSearchController.text,
          role: widget.userRole,
        ),
      );
    }

    if (_activeItem == 'Payments') {
      return PaymentsContent(
        key: ValueKey('Payments'),
        userId: widget.userId, 
        role: widget.userRole,
        globalSearchQuery: _globalSearchController.text,
      );
    }
    
    if (_activeItem == 'Reports') {
      return ReportsContent(
        key: ValueKey('Reports'),
        userId: widget.userId, 
        role: widget.userRole,
        globalSearchQuery: _globalSearchController.text,
      );
    }

    if (_activeItem == 'Received Applications') {
      return Padding(
        padding: contentPadding,
        child: ReceivedApplicationsContent(
          key: ValueKey('Received Applications'),
          userId: widget.userId,
          role: widget.userRole,
          onBackToDashboard: () {
            _fetchStats();
            _fetchPaymentDetails();
            _navigateTo('Dashboard');
          },
          onStatsUpdated: _fetchStats,
        ),
      );
    }
    
    if (_activeItem == 'Update Requests') {
      return UpdateRequestsContent(
          key: ValueKey('Update Requests'),
          globalSearchQuery: _globalSearchController.text,
          userId: widget.userId,
          userRole: widget.userRole,
          onBackToDashboard: () {
            _fetchStats();
            _fetchPaymentDetails();
            _navigateTo('Dashboard');
          },
          onCountUpdated: (count) {
            setState(() {
              _notificationsCount = count;
            });
          },
      );
    }
    
    if (_activeItem == 'ID Card Benefits') {
      return Padding(
        padding: contentPadding,
        child: const IdCardBenefitsContent(
          key: ValueKey('ID Card Benefits'),
        ),
      );
    }

    // Default: Dashboard Content
    return _buildDashboardContent();
  }

  Widget _buildDashboardContent() {
    if (_isLoadingStats) {
      return const LoadingSpinner(message: 'Updating stats...');
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 32),

          Center(
            child: Text(
              AppLocalizations.of(context)?.paymentPendingDetails ?? 'My Payment Pending Details',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D1B18),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: _buildFilterSelector()),
          const SizedBox(height: 20),
          _buildPaymentTable(),
        ],
      ),
    );
  }


  Widget _buildSidebar() {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Container(
      color: const Color(0xFF2D1B18), // Dark sidebar color matching splash screen
      child: SafeArea(
        child: Column(
          children: [
            // Sidebar Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/poondurai kaadaikulam image.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Poondurai Kaadai Kulam',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isDesktop) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildProfileMenu(inDrawer: true),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: _buildLanguageSwitcher(context, inDrawer: true),
              ),
              const SizedBox(height: 8),
            ],
            const Divider(color: Colors.white24, height: 1),
            // Menu Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final isLogout = item['title'] == 'Logout';
                  if (isLogout) {
                    return Column(
                      children: [
                        const SizedBox(height: 32),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 8),
                        _buildMenuItem(item),
                      ],
                    );
                  }
                  return _buildMenuItem(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTranslatedSidebarLabel(BuildContext context, String title) {
    final loc = AppLocalizations.of(context);
    switch(title) {
      case 'Dashboard': return loc?.dashboard ?? title;
      case 'ID Card Benefits': return loc?.idCardBenefits ?? title;
      case 'My Details': return loc?.myDetails ?? title;
      case 'Coordinators': return loc?.coordinators ?? title;
      case 'Members': return loc?.members ?? title;
      case 'Events': return loc?.events ?? title;
      case 'Payments': return loc?.payments ?? title;
      case 'Reports': return loc?.reports ?? title;
      case 'Update Requests': return loc?.updateRequests ?? title;
      case 'Logout': return loc?.logout ?? title;
      default: return title;
    }
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final isActive = _activeItem == item['title'];
    final isLogout = item['title'] == 'Logout';
    bool isHovered = false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: StatefulBuilder(
        builder: (context, setMenuItemState) {
          final isHighlighted = isActive || isHovered;
          final iconColor = isLogout 
              ? Colors.red 
              : (isHighlighted ? const Color(0xFF0EA5E9) : Colors.white70);
          final textColor = isHighlighted ? Colors.white : Colors.white70;

          return InkWell(
            onHover: (hovering) {
              setMenuItemState(() {
                isHovered = hovering;
              });
            },
            onTap: () async {
              if (item['title'] == 'Logout') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
                return;
              }
              if (item['title'] == 'Dashboard') {
                _fetchStats();
                _fetchPaymentDetails();
              }
              if (item['title'] == _activeItem) {
                // Force a refresh
                _fetchStats();
                _fetchPaymentDetails();
                final currentItem = _activeItem;
                setState(() => _activeItem = '');
                Future.delayed(Duration.zero, () {
                  if (mounted) setState(() => _activeItem = currentItem);
                });
              } else {
                _navigateTo(item['title']);
              }
              
              // Close the hamburger menu (drawer) if we're on mobile/tablet
              final isDesktop = MediaQuery.of(context).size.width >= 900;
              if (!isDesktop && mounted) {
                Navigator.pop(context);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Builder(
              builder: (context) {
                Widget content = AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isHighlighted ? Colors.white.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isHighlighted 
                        ? Border.all(color: (isLogout ? Colors.red : const Color(0xFF0EA5E9)).withOpacity(0.4)) 
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(item['icon'], color: iconColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getTranslatedSidebarLabel(context, item['title']),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: Localizations.localeOf(context).languageCode == 'ta' ? 13 : 15,
                            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (isHighlighted)
                        Icon(Icons.chevron_right, color: isLogout ? Colors.red : const Color(0xFF0EA5E9), size: 18),
                    ],
                  ),
                );

                if (item['title'] == 'ID Card Benefits' && _blinkController != null && !isActive) {
                  return AnimatedBuilder(
                    animation: _blinkController!,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFC49A3C).withOpacity(0.25 * _blinkController!.value),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFC49A3C).withOpacity(0.6 * _blinkController!.value),
                            width: 1.5,
                          ),
                        ),
                        child: child,
                      );
                    },
                    child: content,
                  );
                }

                return content;
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        
        if (isMobile) {
          final topPadding = MediaQuery.of(context).padding.top;
          return Container(
            color: const Color(0xFF2D1B18),
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 12),
            child: Column(
              children: [
                // Top Row: Hamburger, Logo, Title
                // Top Row: Hamburger, Logo, Action Icons, Search
                Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/poondurai kaadaikulam image.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.userRole != 3) ...[
                      _buildNotificationIcon(Icons.person_add_alt_1, Colors.orange, _notificationsCount, 'Update Requests'),
                      const SizedBox(width: 12),
                      _buildNotificationIcon(Icons.notifications_none, Colors.red, _approvalsCount, 'Received Applications'),
                      const SizedBox(width: 12),
                    ],
                    IconButton(
                      icon: Icon(
                        _showMobileSearchBar ? Icons.close : Icons.search,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _showMobileSearchBar = !_showMobileSearchBar;
                        });
                      },
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _showMobileSearchBar
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _globalSearchController,
                                    style: TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)?.searchPlaceholder ?? 'Search ...',
                                      hintStyle: TextStyle(color: Colors.white54),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                Icon(Icons.search, color: Colors.white54, size: 20),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }

        // Desktop View
        return Container(
          height: 85, // Matches sidebar header (20 + 44 + 20 = 84) + Divider (1)
          decoration: const BoxDecoration(
            color: const Color(0xFF2D1B18),
            border: Border(
              bottom: BorderSide(
                color: Colors.white24,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flexible spacer on the left to help center
              const Spacer(),
              
              // Search Bar
              Flexible(
                flex: 2,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _globalSearchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)?.searchPlaceholder ?? 'Search ...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      const Icon(Icons.search, color: Colors.white54, size: 20),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Right Side Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageSwitcher(context),
                  const SizedBox(width: 12),
                  if (widget.userRole != 3) ...[
                    _buildNotificationIcon(Icons.person_add_alt_1, Colors.orange, _notificationsCount, 'Update Requests'),
                    const SizedBox(width: 8),
                    _buildNotificationIcon(Icons.notifications_none, Colors.red, _approvalsCount, 'Received Applications'),
                    const SizedBox(width: 12),
                  ],
                  Container(width: 1, height: 30, color: Colors.white24),
                  const SizedBox(width: 12),
                  _buildProfileMenu(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon(IconData icon, Color color, int count, String targetPage) {
    return Badge(
      label: Text(count.toString()),
      isLabelVisible: count > 0,
      backgroundColor: color == Colors.white ? Colors.red : color,
      child: IconButton(
        icon: Icon(icon, color: color, size: 30),
        onPressed: () => _navigateTo(targetPage),
        tooltip: targetPage,
      ),
    );
  }

  Widget _buildLanguageSwitcher(BuildContext context, {bool inDrawer = false}) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isEnglish = localeProvider.locale.languageCode == 'en';

    return InkWell(
      onTap: () {
        localeProvider.setLocale(Locale(isEnglish ? 'ta' : 'en'));
      },
      borderRadius: BorderRadius.circular(inDrawer ? 8 : 20),
      child: Container(
        width: inDrawer ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: inDrawer ? 10 : 6),
        decoration: BoxDecoration(
          color: inDrawer ? Colors.white.withOpacity(0.05) : Colors.black45,
          borderRadius: BorderRadius.circular(inDrawer ? 8 : 20),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: inDrawer ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: inDrawer ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(Icons.language, color: Colors.white, size: inDrawer ? 18 : 16),
            const SizedBox(width: 8),
            Text(
              isEnglish ? 'தமிழ்' : 'English',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: inDrawer ? 14 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu({bool inDrawer = false}) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) async {
        if (value == 'logout') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        } else if (value == 'change_password') {
          _showChangePasswordDialog();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'change_password',
          child: Row(
            children: [
              Icon(Icons.key, size: 18, color: const Color(0xFF5D1712)),
              SizedBox(width: 12),
              Text('Change Password', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.power_settings_new, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text('Logout', style: TextStyle(fontSize: 14, color: Colors.red)),
            ],
          ),
        ),
      ],
      child: inDrawer 
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF5D1712),
                  child: Icon(Icons.person, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.userName, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.userRole == 2 ? 'COORDINATOR' : (widget.userRole == 3 ? (AppLocalizations.of(context)?.memberRole?.toUpperCase() ?? 'MEMBER') : 'MANAGER'), 
                        style: TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 20),
              ],
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(widget.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    widget.userRole == 2 ? 'COORDINATOR' : (widget.userRole == 3 ? 'MEMBER' : 'MANAGER'), 
                    style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF5D1712),
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 20),
            ],
          ),
    );
  }

  Widget _buildSummaryCards() {
    if (widget.userRole == 3) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final visibleCards = widget.userRole == 2 ? 2 : 3;
        final cardWidth = isMobile
            ? (constraints.maxWidth - (12 * (visibleCards - 1))) / visibleCards
            : ((constraints.maxWidth - (24 * (visibleCards - 1))) / visibleCards).clamp(0.0, 300.0);

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
          spacing: isMobile ? 12 : 24,
          runSpacing: isMobile ? 12 : 24,
          children: [
            if (widget.userRole != 2)
              _StatCard(
                title: AppLocalizations.of(context)?.statCoordinators ?? 'COORDINATORS',
                value: _isLoadingStats ? '...' : _coordinatorsCount.toString(),
                color: const Color(0xFF5D1712),
                width: cardWidth,
                icon: Icons.shopping_cart_outlined,
                onTap: () => _navigateTo('Coordinators'),
              ),
            _StatCard(
              title: AppLocalizations.of(context)?.statTotalMembers ?? 'TOTAL MEMBERS',
              value: _isLoadingStats ? '...' : _membersCount.toString(),
              color: const Color(0xFF0EA5E9),
              width: cardWidth,
              icon: Icons.group_outlined,
              onTap: () => _navigateTo('Members'),
            ),
            _StatCard(
              title: AppLocalizations.of(context)?.statApprovals ?? 'APPROVALS',
              value: _isLoadingStats ? '...' : _approvalsCount.toString(),
              color: const Color(0xFF06B6D4),
              width: cardWidth,
              icon: Icons.person_outline,
              onTap: () {
                _navigateTo('Received Applications');
              },
            ),
          ],
        ));
      },
    );
  }

  Widget _buildMyCoordinatorCard() {
    if (_isLoadingCoordinator) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myCoordinator == null) {
      return const Center(
        child: Text('No coordinator assigned yet.', style: TextStyle(color: Colors.black54)),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Align(
      alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_pin, color: Color(0xFF5D1712), size: 28),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)?.coordinatorDetails ?? 'My Coordinator Details',
                  style: TextStyle(
                    color: Color(0xFF5D1712),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                _buildCoordinatorInfo(AppLocalizations.of(context)?.nameHeader ?? 'Name', _myCoordinator!['Name']?.toString() ?? 'N/A'),
                _buildCoordinatorInfo(AppLocalizations.of(context)?.mobileLabel ?? 'Mobile', _myCoordinator!['Phonenumber']?.toString() ?? 'N/A'),
                _buildCoordinatorInfo(AppLocalizations.of(context)?.villageLabel ?? 'Village', _myCoordinator!['Village']?.toString() ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatorInfo(String label, String value) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFF2D1B18),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterTab('UNPAID', AppLocalizations.of(context)?.unpaidDetails ?? 'Unpaid Details', Icons.pending_actions_outlined),
            _buildFilterTab('PAID', AppLocalizations.of(context)?.paidEvents ?? 'Paid Events', Icons.check_circle_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String filterValue, String label, IconData icon) {
    final isSelected = _paymentFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentFilter = filterValue;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? const LinearGradient(
                  colors: [const Color(0xFF5D1712), const Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5D1712).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTable() {
    if (_isLoadingPayments) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: LoadingSpinner(message: 'Fetching payment details...'),
      );
    }

    final totalPending = _pendingPayments
        .where((payment) => (payment['balanceamount'] ?? 0.0) > 0)
        .fold(0.0, (sum, item) => sum + (item['balanceamount'] ?? 0.0));

    final totalPaid = _pendingPayments
        .where((payment) {
          final bal = double.tryParse(payment['balanceamount']?.toString() ?? '0.0') ?? 0.0;
          return bal <= 0;
        })
        .fold(0.0, (sum, item) {
          final double tax = double.tryParse(item['TaxAmount']?.toString() ?? '0.0') ?? 0.0;
          return sum + tax;
        });

    final filteredPayments = _pendingPayments.where((payment) {
      final balance = double.tryParse(payment['balanceamount']?.toString() ?? '0.0') ?? 0.0;
      final isPaid = balance <= 0;
      
      bool matchesFilter = false;
      if (_paymentFilter == 'PAID') {
        matchesFilter = isPaid;
      } else {
        matchesFilter = !isPaid;
      }

      if (matchesFilter && _globalSearchController.text.isNotEmpty) {
        final query = _globalSearchController.text.toLowerCase();
        final eventName = (payment['EventName']?.toString() ?? '').toLowerCase();
        final year = (payment['year']?.toString() ?? '').toLowerCase();
        final fid = (payment['Fid']?.toString() ?? '').toLowerCase();
        final familyHead = (payment['FamilyHeadName']?.toString() ?? '').toLowerCase();
        
        matchesFilter = eventName.contains(query) || 
                        year.contains(query) || 
                        fid.contains(query) ||
                        familyHead.contains(query);
      }

      return matchesFilter;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final columns = isMobile ? 1 : (constraints.maxWidth > 900 ? 3 : 2);
        final cardWidth = (constraints.maxWidth - (16 * (columns - 1))) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalPendingCard(totalPending, totalPaid),
            const SizedBox(height: 20),
            if (filteredPayments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Icon(
                      _paymentFilter == 'PAID'
                          ? Icons.payment_outlined
                          : Icons.check_circle_outline,
                      color: _paymentFilter == 'PAID' ? Colors.grey : Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _paymentFilter == 'PAID'
                          ? 'No paid payments found'
                          : 'No pending payments found',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: filteredPayments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final payment = entry.value;
                  return _buildPaymentCard(payment, index, cardWidth);
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTotalPendingCard(double totalPending, double totalPaid) {
    final isPaidFilter = _paymentFilter == 'PAID';
    final amount = isPaidFilter ? totalPaid : totalPending;
    final title = isPaidFilter ? (AppLocalizations.of(context)?.totalPaidAmount ?? 'TOTAL PAID AMOUNT') : (AppLocalizations.of(context)?.totalPendingAmount ?? 'TOTAL PENDING AMOUNT');
    final subtitle = isPaidFilter ? (AppLocalizations.of(context)?.paidBalanceFromAllEvents ?? 'Total amount received from paid events') : (AppLocalizations.of(context)?.pendingBalanceFromAllEvents ?? 'Pending balance from all events');

    if (amount <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [const Color(0xFF2D1B18), const Color(0xFF2D1B18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D1B18).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, int index, double width) {
    final balance = double.tryParse(payment['balanceamount']?.toString() ?? '0.0') ?? 0.0;
    final tax = double.tryParse(payment['TaxAmount']?.toString() ?? '0.0') ?? 0.0;
    final paidAmount = tax - balance;
    final isPaid = balance <= 0;
    final isPartial = balance > 0 && balance < tax;
    final eventId = payment['Id'];
    final year = payment['year'];

    final Color badgeBgColor = isPaid
        ? const Color(0xFFE8F5E9)
        : (isPartial ? const Color(0xFFE3F2FD) : const Color(0xFFFFEBEE));
    final Color badgeTextColor = isPaid
        ? const Color(0xFF2E7D32)
        : (isPartial ? const Color(0xFF1565C0) : const Color(0xFFC62828));
    final String statusText = isPaid ? (AppLocalizations.of(context)?.paidLabel ?? 'PAID') : (isPartial ? 'PARTIALLY PAID' : (AppLocalizations.of(context)?.unPaidLabel ?? 'UN PAID'));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        width: width,
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isPaid) {
                _showReceiptDialog(eventId);
              } else {
                _showPaymentDialog(eventId, year: year);
              }
            },
            borderRadius: BorderRadius.circular(16),
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
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF3E0),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPaid ? Icons.check_circle : Icons.payment,
                                color: isPaid ? Colors.green : Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                payment['EventName'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D1B18),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isPaid ? Icons.receipt_long : Icons.chevron_right,
                        color: Colors.black26,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Divider(height: 24, color: const Color(0xFFE2E8F0)),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.taxAmount ?? 'TAX AMOUNT',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '₹${tax.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.paidAmount ?? 'PAID AMOUNT',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '₹${paidAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.balanceAmount ?? 'BALANCE AMOUNT',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '₹${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isPaid ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final Color color;
  final double width;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.width,
    required this.icon,
    this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: widget.width,
          constraints: BoxConstraints(minHeight: isCompact ? 70 : 100),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isHovered ? 0.45 : 0.3),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 10 : 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background watermark icon with animation
                  Positioned(
                    right: isCompact ? -5 : -10,
                    bottom: isCompact ? -5 : -10,
                    child: AnimatedScale(
                      scale: _isHovered ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedRotation(
                        turns: _isHovered ? 0.0 : -0.04,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          widget.icon,
                          size: isCompact ? 40 : 70,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: EdgeInsets.all(isCompact ? 10 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: isCompact ? 0.5 : 1,
                              fontSize: isCompact ? 10 : 13,
                            ),
                          ),
                        ),
                        SizedBox(height: isCompact ? 2 : 6),
                        Text(
                          widget.value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 20 : 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
}

