import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFF2D1B18), // Dark brand background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, isMobile ? 36 : 60, 16, isMobile ? 65 : 80),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D1B18), Color(0xFF1E100E)],
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
                      label: const Text(
                        'Back to Login',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.12),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 26 : 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Poondurai Kaadai Kulam Community Platform & Mobile Application',
                    style: TextStyle(
                      color: const Color(0xFFC5A028),
                      fontSize: isMobile ? 14 : 17,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Legally binding terms governing membership access, digital ID usage, and platform conduct.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: isMobile ? 12.5 : 14.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // White Content Card
            Transform.translate(
              offset: const Offset(0, -45),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 960),
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: EdgeInsets.all(isMobile ? 18 : 44),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Last Updated Pill
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
                            ),
                            child: const Text(
                              'EFFECTIVE DATE: NOVEMBER 04, 2026',
                              style: TextStyle(
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Important Notice Banner (Fixed overflow with Expanded)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC49A3C).withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.gavel, color: Color(0xFF8D6E18), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Important Notice to All Members & Users',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF8D6E18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Please read these Terms and Conditions carefully before downloading, registering, or using the Poondurai Kaadai Kulam application. By registering an account or accessing the platform, you acknowledge that you belong to or are affiliated with the Poondurai Kaadai Kulam community and agree to comply with and be legally bound by these terms.',
                            style: TextStyle(
                              fontSize: isMobile ? 13.5 : 14.5,
                              color: const Color(0xFF5D1712),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 1. Acceptance & Eligibility
                    _buildSectionTitle('1. Acceptance of Terms & Eligibility', isMobile),
                    _buildSectionText(
                      'This platform is created exclusively for members and families of the Poondurai Kaadai Kulam community. By registering an account, you represent and warrant that:\n\n'
                      '• You are at least 18 years of age and legally competent to enter into this agreement.\n'
                      '• All lineage and ancestral information provided (Kulam, Valuvu, Thottam, Family relations) is truthful, accurate, and verifiable.\n'
                      '• You will not use this platform for commercial marketing, solicitation, political campaigns, or any activities contrary to community welfare.',
                    ),

                    // 2. Account Registration & Hierarchy
                    _buildSectionTitle('2. User Accounts, Verification & Role Responsibilities', isMobile),
                    _buildSectionText(
                      'To maintain authentic community records, user accounts operate under a structured governance model:\n\n'
                      '• Account Authentication: Accounts are tied to verified mobile phone numbers and family membership records.\n'
                      '• Family Head Responsibility: When an adult family head registers dependents (spouse, children, elderly parents), the head of the family is responsible for ensuring the accuracy of all submitted details.\n'
                      '• Administrative Verification: Submitted registrations and updates are subject to validation and approval by authorized Village Committee Coordinators and Platform Administrators.\n'
                      '• Credential Security: You are solely responsible for maintaining the confidentiality of your login credentials and for all activities conducted through your account.',
                    ),

                    // 3. Digital Member ID Cards & QR Code Usage
                    _buildSectionTitle('3. Digital Member ID Cards & QR Code Verification', isMobile),
                    _buildSectionText(
                      'The platform provides unique digital Member IDs, Permanent Family IDs, and QR-enabled Privilege ID cards:\n\n'
                      '• Personal & Non-Transferable: Your digital ID card and associated QR code are strictly for your personal use. You may not lend, duplicate, falsify, or transfer your ID to another individual.\n'
                      '• Meeting & Attendance Verification: Coordinators and Administrators are authorized to scan your digital ID QR code to verify membership status, record official meeting attendance, or authenticate event entry.\n'
                      '• Revocation: Misuse of the ID card or fraudulent representation will lead to immediate cancellation of digital credentials.',
                    ),

                    // 4. Professional Directory (Doctors & Lawyers)
                    _buildSectionTitle('4. Community Professional Directory Disclosures', isMobile),
                    _buildSectionText(
                      'The application includes an internal community directory highlighting qualified community professionals (e.g., Doctors, Lawyers):\n\n'
                      '• Information Only: Listings in this directory are informational to foster community networking and solidarity. The platform does not operate as an employment agency, medical practice, or formal legal referral service.\n'
                      '• Voluntary Publishing: Professionals voluntarily choose whether their profile is published in the directory and are responsible for the validity of their professional qualifications.',
                    ),

                    // 5. Emergency Blood Group Directory
                    _buildSectionTitle('5. Emergency Blood Group Directory Guidelines', isMobile),
                    _buildSectionText(
                      'The blood group directory is a voluntary community service designed to connect members during critical medical emergencies:\n\n'
                      '• Voluntary Participation: Blood donations are strictly voluntary and altruistic. No commercial transactions, financial compensations, or charges are permitted.\n'
                      '• Medical Responsibility: Medical suitability, blood compatibility testing, and screening are the sole responsibility of certified medical hospitals and blood banks.',
                    ),

                    // 6. Prohibited Activities
                    _buildSectionTitle('6. Prohibited Activities & Community Conduct', isMobile),
                    _buildSectionText(
                      'Users agree not to engage in any prohibited conduct on the platform, including but not limited to:\n\n'
                      '• Falsifying community heritage, lineage, or submitting forged community verification documents.\n'
                      '• Scraping, downloading, or harvesting member contact details for unsolicited bulk messaging, telemarketing, or external commercial databases.\n'
                      '• Harassing, defaming, or violating the privacy of other community members or committee coordinators.\n'
                      '• Attempting to reverse engineer, decompile, exploit, or disrupt the application code, APIs, or database security.',
                    ),

                    // 7. Intellectual Property & Heritage Assets
                    _buildSectionTitle('7. Intellectual Property & Community Heritage Assets', isMobile),
                    _buildSectionText(
                      'All proprietary software code, graphical UI designs, community emblems, trust logos, and compiled registry databases are the intellectual property of the Poondurai Kaadai Kulam Administration. Unauthorized reproduction, modification, or distribution is strictly prohibited.',
                    ),

                    // 8. Termination & Account Suspension
                    _buildSectionTitle('8. Account Suspension, Termination & Deletion', isMobile),
                    _buildSectionText(
                      '• Management Rights: We reserve the right to suspend or terminate any account that violates community guidelines, provides fraudulent records, or engages in harmful behavior.\n'
                      '• Member Right to Delete: Members may request permanent deletion of their account and personal records at any time through the in-app profile settings or by contacting administration via poonduraikaadaikulam2026@gmail.com.',
                    ),

                    // 9. Limitation of Liability
                    _buildSectionTitle('9. Limitation of Liability & Disclaimers', isMobile),
                    _buildSectionText(
                      'The platform is provided on an "as is" and "as available" basis for the benefit of community members. While we strive for continuous service uptime and accurate data maintenance, Poondurai Kaadai Kulam administrators and developers shall not be liable for technical interruptions, server downtime, or indirect damages arising from user-submitted information.',
                    ),

                    // 10. Governing Law & Jurisdiction
                    _buildSectionTitle('10. Governing Law & Jurisdiction', isMobile),
                    _buildSectionText(
                      'These Terms and Conditions shall be governed by and construed in accordance with the laws of the Republic of India. Any disputes or claims arising in connection with the platform shall be subject to the exclusive jurisdiction of the competent courts in Erode / Tamil Nadu, India.',
                    ),

                    // 11. Official Contact Information
                    _buildSectionTitle('11. Contact & Administrative Inquiries', isMobile),
                    _buildSectionText(
                      'If you have any questions or require administrative assistance regarding these Terms and Conditions, please contact us:',
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC49A3C).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Poondurai Kaadai Kulam Administration',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF5D1712)),
                          ),
                          const SizedBox(height: 10),
                          _buildContactRow(Icons.email_outlined, 'Official Email: poonduraikaadaikulam2026@gmail.com'),
                          const SizedBox(height: 8),
                          _buildContactRow(Icons.location_on_outlined, 'Jurisdiction: Erode, Tamil Nadu, India'),
                          const SizedBox(height: 8),
                          _buildContactRow(Icons.verified_user_outlined, 'Platform: Poondurai Kaadai Kulam Android App & Portal'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                '© 2026 Poondurai Kaadai Kulam. All rights reserved.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(top: isMobile ? 26 : 34, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: isMobile ? 18 : 22,
            decoration: BoxDecoration(
              color: const Color(0xFFC49A3C),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 17 : 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D1B18),
                letterSpacing: -0.3,
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
        fontSize: 14.5,
        color: Color(0xFF4B5563),
        height: 1.65,
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: const Color(0xFF5D1712)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500, height: 1.4),
          ),
        ),
      ],
    );
  }
}
