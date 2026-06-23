import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/countries.dart';
import '../widgets/custom_phone_field.dart';
import '../../utils/api_config.dart';

import 'admin_dashboard.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/registration_form.dart';
import '../widgets/forgot_password_dialog.dart';
import 'terms_and_conditions_page.dart';
import 'privacy_policy_page.dart';

class LoginPage extends StatefulWidget {
  final String? redirectMemberId;

  const LoginPage({super.key, this.redirectMemberId});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  int _selectedMinLength = 10;
  int _selectedMaxLength = 10;

  Future<void> _handleLogin() async {
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    if (mobile.isEmpty || password.isEmpty) {
      showStatusDialog(
        context,
        title: 'Fields Required',
        message: 'Please enter your Mobile number and Password to continue.',
        type: DialogType.warning,
      );
      return;
    }

    if (mobile.length < _selectedMinLength || mobile.length > _selectedMaxLength) {
      String digitMsg = _selectedMinLength == _selectedMaxLength 
          ? '$_selectedMinLength-digit' 
          : '$_selectedMinLength to $_selectedMaxLength digit';

      showStatusDialog(
        context,
        title: 'Invalid Number',
        message: 'Please enter a valid $digitMsg Mobile number.',
        type: DialogType.warning,
      );
      return;
    }

    if (password.length < 8) {
      showStatusDialog(
        context,
        title: 'Invalid Password',
        message: 'Password must be at least 8 characters long.',
        type: DialogType.warning,
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Connect to the local Python FastAPI backend
      // Note: Use http://10.0.2.2:8000/api/login if running on an Android emulator
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          if (data['user']['is_first_login'] == true) {
            _handleFirstLoginOTP(data['user'], mobile);
            return;
          }

          // Save session data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', data['user']['id']);
          await prefs.setString('userName', data['user']['name'] ?? 'User');
          await prefs.setInt('userRole', data['user']['role'] ?? 3);
          await prefs.setBool('isLoggedIn', true);

          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
              builder: (_) => AdminDashboard(
                showLoginSuccess: true,
                userName: data['user']['name'] ?? 'User',
                userRole: data['user']['role'] ?? 3,
                userId: data['user']['id'],
                initialViewMemberId: widget.redirectMemberId,
              ),
            ),
          );
        }
      } else {
        String errorMsg = 'The mobile number or password you entered is incorrect.';
        try {
          final data = jsonDecode(response.body);
          if (data['detail'] != null) {
            errorMsg = data['detail'];
          }
        } catch (_) {}

        showStatusDialog(
          context,
          title: 'Login Failed',
          message: errorMsg,
          type: DialogType.error,
        );
      }
    } catch (e) {
      showStatusDialog(
        context,
        title: 'Connection Error',
        message: 'Could not connect to the server. Please check your internet or if the backend is running.',
        type: DialogType.error,
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleFirstLoginOTP(Map<String, dynamic> user, String mobile) async {
    setState(() { _isLoading = true; });
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      );
      
      setState(() { _isLoading = false; });
      
      if (res.statusCode == 200) {
        if (mounted) _showResetPasswordDialog(user, mobile);
      } else {
        String errorMsg = 'Could not send OTP.';
        try {
          final data = jsonDecode(res.body);
          if (data['detail'] != null) errorMsg = data['detail'];
        } catch (_) {}
        if (mounted) {
          showStatusDialog(context, title: 'Verification Error', message: errorMsg, type: DialogType.error);
        }
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        showStatusDialog(context, title: 'Connection Error', message: 'Could not connect to server to send OTP.', type: DialogType.error);
      }
    }
  }

  void _showResetPasswordDialog(Map<String, dynamic> user, String mobile) {
    final TextEditingController otpController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isResetting = false;
    String errorMsg = '';
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Set New Password', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D1712))),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Welcome! Since this is your first time logging in, please set a new password for your account. An OTP has been sent to your registered email.',
                        style: TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Enter OTP',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.password),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: newPasswordController,
                        obscureText: !isNewPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(isNewPasswordVisible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setDialogState(() {
                                isNewPasswordVisible = !isNewPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: !isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setDialogState(() {
                                isConfirmPasswordVisible = !isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      if (errorMsg.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(errorMsg, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isResetting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isResetting ? null : () async {
                    if (otpController.text.trim().isEmpty) {
                      setDialogState(() => errorMsg = 'Please enter the OTP sent to your email.');
                      return;
                    }
                    if (newPasswordController.text.length < 8) {
                      setDialogState(() => errorMsg = 'Password must be at least 8 characters long.');
                      return;
                    }
                    if (newPasswordController.text != confirmPasswordController.text) {
                      setDialogState(() => errorMsg = 'Passwords do not match.');
                      return;
                    }

                    setDialogState(() {
                      isResetting = true;
                      errorMsg = '';
                    });

                    try {
                      final res = await http.post(
                        Uri.parse('${ApiConfig.baseUrl}/api/auth/reset-password'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'mobile': mobile,
                          'otp': otpController.text.trim(),
                          'new_password': newPasswordController.text,
                        }),
                      );

                      if (res.statusCode == 200) {
                        Navigator.pop(dialogContext); // Close dialog
                        
                        // Proceed to login completion
                        if (mounted) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('userId', user['id']);
                          await prefs.setString('userName', user['name'] ?? 'User');
                          await prefs.setInt('userRole', user['role'] ?? 3);
                          await prefs.setBool('isLoggedIn', true);

                          Navigator.pushReplacement(
                            context, 
                            MaterialPageRoute(
                              builder: (_) => AdminDashboard(
                                showLoginSuccess: true,
                                userName: user['name'] ?? 'User',
                                userRole: user['role'] ?? 3,
                                userId: user['id'],
                                initialViewMemberId: widget.redirectMemberId,
                              ),
                            ),
                          );
                        }
                      } else {
                        try {
                          final errData = jsonDecode(res.body);
                          if (errData['detail'] != null) {
                            setDialogState(() => errorMsg = errData['detail']);
                          } else {
                            setDialogState(() => errorMsg = 'Failed to reset password. Please try again.');
                          }
                        } catch (_) {
                          setDialogState(() => errorMsg = 'Failed to reset password. Please try again.');
                        }
                      }
                    } catch (e) {
                      setDialogState(() => errorMsg = 'Connection error. Check your internet.');
                    } finally {
                      if (mounted) {
                        setDialogState(() => isResetting = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D1712),
                    foregroundColor: Colors.white,
                  ),
                  child: isResetting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save & Continue'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Kovil.jpeg'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          // Dark overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.25),
          ),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 40,
                        vertical: 20,
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24 : 40,
                          vertical: isMobile ? 24 : 32,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            CircleAvatar(
                              radius: isMobile ? 40 : 48,
                              backgroundColor: Colors.transparent,
                              backgroundImage: const AssetImage(
                                'assets/images/poondurai kaadaikulam image.png',
                              ),
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            Text(
                              'Poondurai Kaadai Kulam',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 20 : 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: isMobile ? 20 : 24),
                            // Mobile Number Field
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme: InputDecorationTheme(
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 20 : 25,
                                      vertical: isMobile ? 15 : 18,
                                    ),
                                    hintStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                child: CustomPhoneField(
                                  label: '',
                                  controller: _mobileController,
                                  hint: 'Mobile Number',
                                  isDarkTheme: true,
                                  showDropdownOnRight: true,
                                  onCountryChanged: (country) {
                                    setState(() {
                                      _selectedMinLength = country.minLength;
                                      _selectedMaxLength = country.maxLength;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            // Password Field
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'Password',
                              isPassword: true,
                              isPasswordVisible: _isPasswordVisible,
                              onToggleVisibility: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const ForgotPasswordDialog(),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: isMobile ? 54 : 58,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading 
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                              ),
                            ),
                            SizedBox(height: isMobile ? 16 : 20),
                            // Register Link
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => const RegistrationForm(),
                                      );
                                    },
                                    child: const Text(
                                      'Register',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildFooter(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _footerLink('Terms & Conditions'),
            const Text(' | ', style: TextStyle(color: Colors.white70)),
            _footerLink('Privacy Policy'),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '© 2026 Poondurai Kaadai Kulam. All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black45,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? suffixIcon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    bool isMobile = false,
    int? maxLength,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 14 : 16,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: Colors.white,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: maxLength != null ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          counterText: "", // Hide character counter
          hintText: hint,
          prefixText: prefixText,
          prefixStyle: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
          hintStyle: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
          suffixIcon: isPassword
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                        size: isMobile ? 18 : 20,
                      ),
                      onPressed: onToggleVisibility,
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: isMobile ? 12 : 15),
                      child: Icon(Icons.lock, color: Colors.white, size: isMobile ? 20 : 22),
                    ),
                  ],
                )
              : Padding(
                  padding: EdgeInsets.only(right: isMobile ? 12 : 15),
                  child: Icon(suffixIcon, color: Colors.white, size: isMobile ? 20 : 22),
                ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 25,
            vertical: isMobile ? 15 : 18,
          ),
        ),
      ),
    );
  }

  Widget _footerLink(String text) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => text == 'Terms & Conditions' 
                ? const TermsAndConditionsPage() 
                : const PrivacyPolicyPage(),
          ),
        );
      },
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black45,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
