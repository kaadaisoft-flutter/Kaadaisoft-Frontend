import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark top background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section with dark background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 80),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
              child: Column(
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                      label: const Text('Back to Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Legal agreement for using Poondurai Kaadai Kulam platform',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // White Content Section
            Transform.translate(
              offset: const Offset(0, -80),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 900),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 25,
                      offset: const Offset(0, 20),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.8)),
                ),
                padding: const EdgeInsets.all(50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LAST UPDATED: APRIL 30, 2026',
                      style: TextStyle(
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Highlight Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3E0),
                        border: Border(
                          left: BorderSide(color: Color(0xFFE65100), width: 4),
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Please read these terms and conditions carefully before using our services. By using our platform, you agree to comply with and be bound by these terms.',
                        style: TextStyle(
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.bold,
                          fontSize: 16.5,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    _buildSectionTitle('1. Agreement to Terms'),
                    _buildSectionText('By accessing or using our website, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree with any part of these terms, you must not use our services. This agreement constitutes a legally binding contract between you and Kaadaisoft.'),
                    
                    _buildSectionTitle('2. User Registration'),
                    _buildSectionText('To access certain features of the website, you are required to register for an account. You agree to provide accurate, current, and complete information during the registration process (Aadhar, Mobile Number, Address, etc.) and to update such information to keep it accurate, current, and complete.'),
                    
                    _buildSectionTitle('3. Responsibility for Account'),
                    _buildSectionText('You are solely responsible for maintaining the confidentiality of your account password and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account or any other breach of security.'),
                    
                    _buildSectionTitle('4. Use of Information'),
                    _buildSectionText('The information provided on this platform is for community management and membership purposes. While we strive to maintain high data accuracy, we do not warrant the completeness or reliability of user-submitted information at all times.'),
                    
                    _buildSectionTitle('5. Prohibited Activities'),
                    _buildSectionText('You agree not to use the platform for any unlawful purpose or any purpose prohibited under these Terms. Prohibited activities include but are not limited to: uploading false documents, attempting to breach security, or harassing other community members.'),
                    
                    _buildSectionTitle('6. Intellectual Property'),
                    _buildSectionText('All content included on this website, such as custom scripts, branding, UI designs, and logos, is the property of Poondurai Kaadai Kulam or its content suppliers and is protected by copyright laws.'),
                    
                    _buildSectionTitle('7. Termination of Use'),
                    _buildSectionText('We reserve the right to terminate or suspend your access to the platform without notice, for any conduct that we, in our sole discretion, believe is in violation of any applicable law or is harmful to the interests of the community.'),
                    
                    _buildSectionTitle('8. Changes to Terms'),
                    _buildSectionText('We reserve the right to modify these Terms and Conditions at any time. Changes will be effective immediately upon posting. Your continued use of the website following changes will mean that you accept and agree to the modified terms.'),
                    
                    _buildSectionTitle('9. Contact Support'),
                    _buildSectionText('If you have any questions about these Terms and Conditions, please contact the administrator via the official community channels.'),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Text(
                '© 2026 Poondurai Kaadai Kulam. All rights reserved.',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFE65100),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16.5,
        color: Color(0xFF475569),
        height: 1.7,
      ),
    );
  }
}
