import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/api_config.dart';

import 'admin_dashboard.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/registration_form.dart';
import 'terms_and_conditions_page.dart';
import 'privacy_policy_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final mobileAadhar = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    if (mobileAadhar.isEmpty || password.isEmpty) {
      showStatusDialog(
        context,
        title: 'Fields Required',
        message: 'Please enter your Mobile number and Password to continue.',
        type: DialogType.warning,
      );
      return;
    }

    if (mobileAadhar.length != 10 && mobileAadhar.length != 12) {
      showStatusDialog(
        context,
        title: 'Invalid Number',
        message: 'Please enter a 10-digit Mobile or 12-digit Aadhar number.',
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
          'mobile_or_aadhar': mobileAadhar,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
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
              ),
            ),
          );
        }
      } else {
        showStatusDialog(
          context,
          title: 'Login Failed',
          message: 'The mobile number or password you entered is incorrect.',
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
                            // Mobile/Aadhar Field
                            _buildTextField(
                              controller: _mobileController,
                              hint: 'Mobile / Aadhar Number',
                              suffixIcon: Icons.person,
                              isMobile: isMobile,
                              maxLength: 12,
                              keyboardType: TextInputType.number,
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
                                onPressed: () {},
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
