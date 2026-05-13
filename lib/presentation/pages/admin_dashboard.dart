import 'dart:convert';
import 'dart:async';
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
import '../widgets/loading_spinner.dart';
import '../widgets/custom_dialog.dart';
import '../../utils/api_config.dart';
class AdminDashboard extends StatefulWidget {
  final bool showLoginSuccess;
  final String userName;
  final int userRole;
  final dynamic userId;
  const AdminDashboard({
    super.key, 
    this.showLoginSuccess = false,
    this.userName = 'Guest',
    this.userRole = 3, // Default to member
    this.userId,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Current active menu item
  String _activeItem = 'Dashboard';
  final List<String> _navigationHistory = [];

  int _membersCount = 0;
  int _coordinatorsCount = 3;
  int _approvalsCount = 0;
  int _notificationsCount = 0;
  bool _isLoadingStats = true;
  bool _isLoadingPayments = true;
  bool _shouldShowAssignCoordinator = false;
  final ScrollController _dashboardScrollController = ScrollController();
  Timer? _statsTimer;

  void _navigateTo(String item) {
    if (_activeItem == item) return;
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
    _dashboardScrollController.dispose();
    _statsTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchPaymentDetails();
    _loadActiveItem();
    
    // Set up polling for stats
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _fetchStats();
      }
    });
    
    if (widget.showLoginSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showStatusDialog(
          context,
          title: 'Success',
          message: 'Login successful',
        );
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
      final updateReqResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/update-requests'));
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

  Future<void> _fetchPaymentDetails() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/pending-payments/${widget.userId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _pendingPayments = data['data'];
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

  List<Map<String, dynamic>> get _menuItems {
    final allItems = [
      {'title': 'Dashboard', 'icon': Icons.bar_chart, 'color': const Color(0xFF0EA5E9)},
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
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: isChanging 
                        ? const LoadingSpinner()
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
                width: 260,
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
          role: widget.userRole
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
          initialShowAssign: showAssign
        ),
      );
    }

    if (_activeItem == 'Payments') {
      return PaymentsContent(
        key: ValueKey('Payments'),
        userId: widget.userId, 
        role: widget.userRole
      );
    }
    
    if (_activeItem == 'Reports') {
      return ReportsContent(
        key: ValueKey('Reports'),
        userId: widget.userId, 
        role: widget.userRole
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

    // Default: Dashboard Content
    return _buildDashboardContent();
  }

  Widget _buildDashboardContent() {
    if (_isLoadingStats) {
      return const LoadingSpinner(message: 'Updating stats...');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Payment Pending Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172030),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: _buildPaymentTable()),
        ],
      ),
    );
  }


  Widget _buildSidebar() {
    return Container(
      color: const Color(0xFF172030), // Dark sidebar color
      child: SafeArea(
        child: Column(
          children: [
            // Sidebar Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/poondurai kaadaikulam image.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Poondurai Kaadai Kulam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final isActive = _activeItem == item['title'];
    final iconColor = item['color'] ?? Colors.white70;
    final textColor = isActive ? Colors.white : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
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
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive 
                ? Border.all(color: Colors.cyan.withOpacity(0.5)) 
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(item['icon'], color: iconColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['title'],
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (isActive)
                  const Icon(Icons.chevron_right, color: Colors.cyan, size: 18),
            ],
          ),
        ),
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
            color: const Color(0xFF172030),
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 12),
            child: Column(
              children: [
                // Top Row: Hamburger, Logo, Title
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
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Poondurai Kaadai Kulam',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Middle Row: Actions and Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.userRole != 3) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNotificationIcon(Icons.person_add_alt_1, Colors.orange, _notificationsCount, 'Update Requests'),
                          const SizedBox(width: 20),
                          _buildNotificationIcon(Icons.notifications_none, Colors.white, _approvalsCount, 'Received Applications'),
                        ],
                      ),
                    ],
                    _buildProfileMenu(),
                  ],
                ),
                const SizedBox(height: 16),
                // Bottom Row: Search Bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search ...',
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
              ],
            ),
          );
        }

        // Desktop View
        return Container(
          height: 70,
          color: const Color(0xFF172030),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Search Bar - Centered
              Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 320,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search ...',
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
                ),
              
              // Right Side Actions
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.userRole != 3) ...[
                      _buildNotificationIcon(Icons.person_add_alt_1, Colors.orange, _notificationsCount, 'Update Requests'),
                      const SizedBox(width: 8),
                      _buildNotificationIcon(Icons.notifications_none, Colors.white, _approvalsCount, 'Received Applications'),
                      const SizedBox(width: 12),
                    ],
                    Container(width: 1, height: 30, color: Colors.white24),
                    const SizedBox(width: 12),
                    _buildProfileMenu(),
                  ],
                ),
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
      ),
    );
  }

  Widget _buildProfileMenu() {
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
              Icon(Icons.key, size: 18, color: Colors.blue),
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
      child: Row(
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
            backgroundColor: Colors.blue,
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
        final cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - (24 * (visibleCards - 1))) / visibleCards;

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            if (widget.userRole != 2)
              _StatCard(
                title: 'COORDINATORS',
                value: _isLoadingStats ? '...' : _coordinatorsCount.toString(),
                color: const Color(0xFF3B82F6),
                width: cardWidth,
                icon: Icons.shopping_cart_outlined,
                onTap: () => _navigateTo('Coordinators'),
              ),
            _StatCard(
              title: 'TOTAL MEMBERS',
              value: _isLoadingStats ? '...' : _membersCount.toString(),
              color: const Color(0xFF0EA5E9),
              width: cardWidth,
              icon: Icons.group_outlined,
              onTap: () => _navigateTo('Members'),
            ),
            _StatCard(
              title: 'APPROVALS',
              value: _isLoadingStats ? '...' : _approvalsCount.toString(),
              color: const Color(0xFFF43F5E),
              width: cardWidth,
              icon: Icons.person_outline,
              onTap: () {
                _navigateTo('Received Applications');
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentTable() {
    if (_isLoadingPayments) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: LoadingSpinner(message: 'Fetching payment details...'),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
       child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Scrollbar(
          controller: _dashboardScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _dashboardScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 700,
              child: Column(
                children: [
                  // Table Header
                  Container(
                    color: const Color(0xFF172030),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: const Row(
                      children: [
                        SizedBox(width: 60,  child: Text('SNO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        SizedBox(width: 260, child: Text('EVENT NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        SizedBox(width: 160, child: Text('TAX AMOUNT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        SizedBox(width: 160, child: Text('BALANCE AMOUNT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  // Table Rows
                  if (_pendingPayments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('No pending payments found', style: TextStyle(color: Colors.black54))),
                    )
                  else
                    ..._pendingPayments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final payment = entry.value;
                      final balance = payment['balanceamount'] ?? 0.0;
                      final isPaid = balance <= 0;
                      final isPartial = balance > 0 && balance < (payment['Taxamount'] ?? 0.0);

                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black12)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: Row(
                          children: [
                            SizedBox(width: 60, child: Text('${index + 1}', style: const TextStyle(color: Colors.black87))),
                            SizedBox(
                              width: 260, 
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(payment['eventname'] ?? 'N/A', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPaid ? Colors.green : (isPartial ? Colors.blue : Colors.red),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isPaid ? 'PAID' : (isPartial ? 'PARTIALLY PAID' : 'UN PAID'),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              )
                            ),
                            SizedBox(width: 160, child: Text('${payment['Taxamount'] ?? '0.00'}', style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center)),
                            SizedBox(width: 160, child: Text('${balance.toStringAsFixed(2)}', style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          ],
                        ),
                      );
                    }).toList(),
                  
                  // Total Pending Amount
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.black12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'TOTAL PENDING AMOUNT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172030),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 48),
                        Text(
                          _pendingPayments.fold(0.0, (sum, item) => sum + (item['balanceamount'] ?? 0.0)).toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF172030),
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

  Widget _buildTableRow(String sno, String eventName, String status, String tax, String balance, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 60,  child: Text(sno, style: const TextStyle(color: Colors.black54))),
          SizedBox(
            width: 260,
            child: Row(
              children: [
                Text(eventName, style: const TextStyle(color: Colors.black87)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                  child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(width: 160, child: Text(tax, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center)),
          SizedBox(
            width: 160,
            child: Text(
              balance,
              style: TextStyle(color: balance == '0' ? Colors.green : Colors.red, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
          constraints: const BoxConstraints(minHeight: 140),
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
                    right: -10,
                    bottom: -10,
                    child: AnimatedScale(
                      scale: _isHovered ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedRotation(
                        turns: _isHovered ? 0.0 : -0.04,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          widget.icon,
                          size: 100,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
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

