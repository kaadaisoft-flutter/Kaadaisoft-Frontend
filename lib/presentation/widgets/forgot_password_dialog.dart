import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import '../../l10n/app_localizations.dart';
import 'custom_dialog.dart';
import 'custom_phone_field.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  int _step = 1;
  bool _isLoading = false;
  
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  int _selectedMinLength = 10;
  int _selectedMaxLength = 10;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestOTP() async {
    final mobile = _mobileController.text.trim();
    if (mobile.length < _selectedMinLength || mobile.length > _selectedMaxLength) {
      String digitMsg = _selectedMinLength == _selectedMaxLength 
          ? '$_selectedMinLength-digit' 
          : '$_selectedMinLength to $_selectedMaxLength digit';
      showStatusDialog(context, title: 'Invalid Input', message: 'Please enter a valid $digitMsg mobile number.', type: DialogType.warning);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      );
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _step = 2;
          _isLoading = false;
        });
        if (mounted) {
          showStatusDialog(context, title: 'OTP Sent', message: data['message'] ?? 'Check your email for the OTP.', type: DialogType.success, autoDismiss: false);
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          showStatusDialog(context, title: 'Error', message: data['detail'] ?? 'Failed to request OTP.', type: DialogType.error);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showStatusDialog(context, title: 'Connection Error', message: 'Could not connect to the server.', type: DialogType.error);
      }
    }
  }

  Future<void> _resetPassword() async {
    final mobile = _mobileController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (otp.length != 6) {
      showStatusDialog(context, title: 'Invalid OTP', message: 'Please enter a valid 6-digit OTP.', type: DialogType.warning);
      return;
    }
    bool isValidPassword(String p) {
      if (p.length < 8) return false;
      if (p.contains(' ')) return false;
      if (!p.contains(RegExp(r'[A-Z]'))) return false;
      if (!p.contains(RegExp(r'[a-z]'))) return false;
      if (!p.contains(RegExp(r'[0-9]'))) return false;
      if (!p.contains(RegExp(r'[^A-Za-z0-9\s]'))) return false;
      return true;
    }

    if (!isValidPassword(newPassword)) {
      showStatusDialog(
        context, 
        title: 'Invalid Password', 
        message: 'Password must be at least 8 characters long, contain an uppercase letter, a lowercase letter, a number, a special character, and no spaces.', 
        type: DialogType.warning
      );
      return;
    }
    if (newPassword != confirmPassword) {
      showStatusDialog(context, title: 'Password Mismatch', message: 'Passwords do not match.', type: DialogType.warning);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile,
          'otp': otp,
          'new_password': newPassword
        }),
      );
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pop();
          showStatusDialog(context, title: 'Success', message: 'Your password has been reset successfully. You can now login.', type: DialogType.success);
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          showStatusDialog(context, title: 'Error', message: data['detail'] ?? 'Failed to reset password.', type: DialogType.error);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showStatusDialog(context, title: 'Connection Error', message: 'Could not connect to the server.', type: DialogType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _step == 1 
                        ? (localizations?.forgotPasswordTitle ?? 'Forgot Password') 
                        : (localizations?.resetPasswordTitle ?? 'Reset Password'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D1B18)),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (_step == 1) ...[
              Text(
                localizations?.forgotPasswordInstruction ?? 'Enter your registered mobile number. We will send an OTP to the email address linked to your account.',
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 20),
              CustomPhoneField(
                label: '',
                hint: localizations?.mobileNumber ?? 'Mobile Number',
                controller: _mobileController,
                onCountryChanged: (country) {
                  setState(() {
                    _selectedMinLength = country.minLength;
                    _selectedMaxLength = country.maxLength;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D1712),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(localizations?.sendOtp ?? 'Send OTP', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              Text(
                localizations?.resetPasswordInstruction ?? 'Please enter the 6-digit OTP sent to your email and your new password.',
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: localizations?.otpHint ?? 'OTP',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.password),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: localizations?.newPasswordHint ?? 'New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D1712),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(localizations?.resetPasswordButton ?? 'Reset Password', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
