import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark top background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section
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
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width < 600 ? 32 : 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your privacy and data security are our top priorities.',
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
                      'LAST UPDATED: MAY 07, 2026',
                      style: TextStyle(
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text(
                      'At **Poondurai Kaadai Kulam**, we are committed to protecting your personal data and ensuring that your privacy is respected. This policy explains how we collect, use, and safeguard your information.',
                      style: TextStyle(
                        fontSize: 16.5,
                        color: Color(0xFF475569),
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Information We Collect
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('1. Information We Collect', marginTop: 0),
                          const Text(
                            'We collect information you provide directly to us when you register for an account, including:',
                            style: TextStyle(
                              fontSize: 16.5,
                              color: Color(0xFF475569),
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBulletItem('Personal Identity', 'Full name and photographs.'),
                          _buildBulletItem('Contact Details', 'Mobile number and physical address.'),
                          _buildBulletItem('Community Data', 'Family membership details and role assignments.'),
                        ],
                      ),
                    ),
                    
                    _buildSectionTitle('2. How We Use Your Information'),
                    _buildSectionText('The information we collect is strictly used for community management purposes:'),
                    const SizedBox(height: 16),
                    _buildSimpleBullet('Verifying community membership and user authenticity.'),
                    _buildSimpleBullet('Processing tax payments and generating official receipts.'),
                    _buildSimpleBullet('Coordinating community events and member updates.'),
                    _buildSimpleBullet('Maintaining a secure and transparent community registry.'),
                    
                    _buildSectionTitle('3. Data Sharing & Disclosure'),
                    _buildSectionText('We do not sell, trade, or rent your personal information to third parties. Your data is only visible to authorized platform administrators and coordinators for verification purposes within the Poondurai Kaadai Kulam community ecosystem.'),
                    
                    _buildSectionTitle('4. Security Measures'),
                    _buildSectionText('We implement a variety of security measures to maintain the safety of your personal information. Your data is stored on secure servers and access is restricted to authorized personnel only. While we strive for absolute security, please note that no method of digital storage is 100% impenetrable.'),
                    
                    _buildSectionTitle('5. Your Data Rights'),
                    _buildSectionText('You have the right to access and update your information at any time. If you wish to correct your data or request account closure, you can manage your profile settings or contact the administrator directly.'),
                    
                    _buildSectionTitle('6. Cookies & Tracking'),
                    _buildSectionText('Our platform may use essential session cookies to keep you logged in and ensure the website functions correctly. We do not use tracking cookies for advertising purposes.'),
                    
                    _buildSectionTitle('7. Changes to This Policy'),
                    _buildSectionText('We may update this Privacy Policy to reflect changes in our practices. Any updates will be posted on this page with an updated "Last Updated" date.'),
                    
                    _buildSectionTitle('8. Contact Our Team'),
                    _buildSectionText('If you have any questions or concerns regarding this Privacy Policy or your data, please reach out to the platform administrator.'),
                    
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
                style: TextStyle(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {double marginTop = 40}) {
    return Padding(
      padding: EdgeInsets.only(top: marginTop, bottom: 20),
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
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
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

  Widget _buildBulletItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16.5, color: Color(0xFF475569), height: 1.7),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16.5,
                color: Color(0xFF475569),
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
